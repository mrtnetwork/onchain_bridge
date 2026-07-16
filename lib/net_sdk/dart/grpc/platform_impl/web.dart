import 'dart:async';
import 'package:blockchain_utils/utils/types/result.dart';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/dev/src/logging.dart';
import 'package:on_chain_bridge/net_sdk/dart/grpc/core/gprc.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_bridge/web/api/api.dart';

Future<Result<PlatformGrpc, NetResultStatus>> dartGrpcClient(
    NetAddressInfo addr) async {
  return Ok(PlatformGrpcWeb(baseUrl: addr.url));
}

class _GrpcFrame {
  final bool isTrailer;
  final Uint8List payload;
  _GrpcFrame(this.isTrailer, this.payload);
}

class _GrpcFrameDecoder {
  final List<int> _buf = [];
  int _offset = 0;

  void addChunk(List<int> chunk) => _buf.addAll(chunk);

  List<_GrpcFrame> drainFrames() {
    final frames = <_GrpcFrame>[];
    while (_buf.length - _offset >= 5) {
      final flag = _buf[_offset];
      final len = (_buf[_offset + 1] << 24) |
          (_buf[_offset + 2] << 16) |
          (_buf[_offset + 3] << 8) |
          _buf[_offset + 4];
      if (_buf.length - _offset - 5 < len) break;
      final start = _offset + 5;
      final payload = Uint8List.fromList(_buf.sublist(start, start + len));
      frames.add(_GrpcFrame(flag & 0x80 != 0, payload));
      _offset = start + len;
    }
    if (_offset > 0) {
      _buf.removeRange(0, _offset);
      _offset = 0;
    }
    return frames;
  }
}

class PlatformGrpcWeb implements PlatformGrpc {
  /// e.g. "https://your-grpc-web-endpoint:443"
  final String baseUrl;
  final Map<String, String>? extraHeaders;
  final List<AbortController> _pendingAborts = [];

  PlatformGrpcWeb({required this.baseUrl, this.extraHeaders});
  Map<String, String> _buildHeaders() {
    final Map<String, String> headers = {...extraHeaders ?? {}};
    headers["Content-Type"] = "application/grpc-web+proto";
    headers["X-Grpc-Web"] = "1";
    headers["Accept"] = "application/grpc-web+proto";
    return headers;
  }

  static Map<String, String> _parseTrailers(Uint8List payload) {
    final map = <String, String>{};
    for (final line in String.fromCharCodes(payload).split('\r\n')) {
      if (line.isEmpty) continue;
      final idx = line.indexOf(':');
      if (idx == -1) continue;
      map[line.substring(0, idx).trim().toLowerCase()] =
          line.substring(idx + 1).trim();
    }
    return map;
  }

  static Uint8List _encodeFrame(List<int> data) {
    final len = data.length;
    final out = Uint8List(5 + len);
    out.setRange(1, 5, len.toU32BeBytes());
    out.setRange(5, 5 + len, data);
    return out;
  }

  Uri _methodUri(String methodName) {
    final path = methodName.startsWith('/') ? methodName : '/$methodName';
    return Uri.parse('$baseUrl$path');
  }

  @override
  Future<Result<List<int>, Result<AppGrpcError, NetResultStatus>>> unary(
      List<int> buffer, String methodName) async {
    try {
      final response = await JSFetchApi.fetchOnce(
        method: HttpMethod.post,
        headers: _buildHeaders(),
        url: _methodUri(methodName),
        body: _encodeFrame(buffer),
      );
      final arrBuffer = await response.arrayBuffer().toDart;

      final decoder = _GrpcFrameDecoder()
        ..addChunk(arrBuffer.toDart.asUint8List());
      final frames = decoder.drainFrames();
      Logg.log("grpc web frames ${frames.length}");
      List<int>? message;
      int status = 0;
      String? statusMessage;
      for (final f in frames) {
        if (f.isTrailer) {
          final trailers = _parseTrailers(f.payload);
          status = int.tryParse(trailers['grpc-status'] ?? '0') ?? 0;
          statusMessage = trailers['grpc-message'];
        } else {
          message = f.payload;
        }
      }

      if (status != 0) {
        return Err(Ok(AppGrpcError(code: status, message: statusMessage)));
      }
      if (message == null) {
        return Err(Ok(AppGrpcError(
            code: GrpcErrorCode.internal.code,
            message: 'no message in response')));
      }
      return Ok(message);
    } catch (_) {
      return Err(Err(NetResultStatus.connectionError));
    }
  }

  @override
  Future<Result<Stream<List<int>>, NetResultStatus>> stream(
      List<int> buffer, String methodName) async {
    try {
      final abort = AbortController();
      final response = await JSFetchApi.fetchOnce(
          method: HttpMethod.post,
          headers: _buildHeaders(),
          url: _methodUri(methodName),
          body: _encodeFrame(buffer),
          signal: abort.signal);
      final body = response.body;
      if (body == null) {
        return Err(NetResultStatus.connectionError);
      }

      _pendingAborts.add(abort);
      final controller = StreamController<List<int>>();
      final reader = body.getReader();
      final decoder = _GrpcFrameDecoder();
      bool released = false;
      controller.onCancel = () {
        if (!released) {
          reader.cancel();
        }
        abort.abort();
        _pendingAborts.remove(abort);
      };

      Future<void> pump() async {
        try {
          while (true) {
            final chunk = await reader.read().toDart;
            if (chunk.done) break;
            final value = chunk.value;
            if (value == null) continue;
            decoder.addChunk(value.toDart);
            final frames = decoder.drainFrames();
            Logg.log("grpc web stream ${frames.length}");
            for (final f in frames) {
              if (f.isTrailer) {
                final trailers = _parseTrailers(f.payload);
                final status =
                    int.tryParse(trailers['grpc-status'] ?? '0') ?? 0;
                if (status != 0) {
                  controller.addError(AppGrpcError(
                      code: status, message: trailers['grpc-message']));
                }
              } else {
                controller.add(f.payload);
              }
            }
          }
        } catch (_) {
          if (!abort.signal.aborted) {
            controller.addError(AppGrpcError(
                code: GrpcErrorCode.unavailable.code,
                message: 'stream failed'));
          }
        } finally {
          released = true;
          reader.releaseLock();
          _pendingAborts.remove(abort);
          await controller.close();
        }
      }

      unawaited(pump());
      return Ok(controller.stream);
    } catch (_) {
      return Err(NetResultStatus.connectionError);
    }
  }

  @override
  Future<Result<void, NetResultStatus>> close() async {
    for (final abort in _pendingAborts) {
      abort.abort();
    }
    _pendingAborts.clear();
    return const Ok(null);
  }
}
