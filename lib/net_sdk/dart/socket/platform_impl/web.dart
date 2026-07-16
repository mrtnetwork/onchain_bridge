import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/socket/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/web/web.dart';

Future<Result<PlatformSocket, NetResultStatus>> connectSoc({
  required NetConfig config,
  List<String>? protocols,
  Duration? timeout,
}) async {
  if (config.protocol != NetProtocol.webSocket) {
    return Err(NetResultStatus.invalidConfigParameters);
  }
  return await WebsocketWeb.connect(url: config.address.url, timeout: timeout);
}

class WebsocketWeb implements PlatformSocket {
  final JSWebSocket _socket;
  int? _closeCode;
  String? _closeReason;
  int? get closeCode => _closeCode;
  String? get closeReason => _closeReason;

  late final StreamController<List<int>> _streamController =
      StreamController<List<int>>()..onCancel = _onCloseStream;
  void _onCloseStream() {
    if (!_socket.isClosed) {
      _socket.close(1000, "closed by client.");
      _closeCode = 1000;
      _closeReason = "closed by client.";
    }
    _socket.onopen = null;
    _socket.onclose = null;
    _socket.onmessage = null;
    _socket.onopen = null;
  }

  Completer<WebsocketWeb>? _connectedCompleter = Completer<WebsocketWeb>();
  WebsocketWeb._(this._socket) {
    _socket.onopen = () {
      _connectedCompleter?.complete(this);
      _connectedCompleter = null;
    }.toJS;
    _socket.onmessage = (JSWebScoketMessageEvent msg) {
      if (msg.data.isA<JSString>()) {
        _streamController
            .add(StringUtils.encode((msg.data as JSString).toDart));
      } else if (msg.data.isA<JSArrayBuffer>()) {
        _streamController.add((msg.data as JSArrayBuffer).toDart.asUint8List());
      } else {
        assert(false, "invalid encoding");
      }
    }.toJS;

    _socket.onclose = (JSWebScoketCloseEvent event) {
      _closeCode = event.code;
      _closeReason = event.reason;
      _streamController.close();
      _connectedCompleter?.completeError(NetResultStatus.connectionError);
      _connectedCompleter = null;
    }.toJS;
  }

  @override
  void close() {
    _streamController.close();
  }

  @override
  bool get isConnected => _socket.isOpen;
  @override
  Stream<List<int>> get stream => _streamController.stream;

  static Future<Result<PlatformSocket, NetResultStatus>> connect(
      {required String url,
      Duration? timeout,
      List<String> protocols = const []}) async {
    final socket =
        WebsocketWeb._(JSWebSocket.create(url, protocols: protocols));
    try {
      return switch (timeout) {
        null => Ok(await socket._connectedCompleter!.future),
        Duration timeout =>
          Ok(await socket._connectedCompleter!.future.timeout(timeout)),
      };
    } on NetResultStatus catch (e) {
      return Err(e);
    } on TimeoutException {
      return Err(NetResultStatus.requestTimeout);
    } catch (_) {
      return Err(NetResultStatus.connectionError);
    }
  }

  @override
  void sink(List<int> message) {
    _socket.send_(message);
  }
}
