import 'dart:async';
import 'dart:io';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/socket/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<PlatformSocket, NetResultStatus>> connectSoc({
  required NetConfig config,
  List<String>? protocols,
  Duration? timeout,
}) async {
  switch (config.protocol) {
    case NetProtocol.webSocket:
      return await WebsocketIO.connect(
          url: config.address.url, timeout: timeout);
    case NetProtocol.tls:
      return SocketIo.tls(
          host: config.address.host,
          port: config.address.port,
          insecure: config.tlsMode.insecure,
          timeout: timeout);
    case NetProtocol.tcp:
      return SocketIo.tcp(
          host: config.address.host,
          port: config.address.port,
          timeout: timeout);

    default:
      return Err(NetResultStatus.invalidConfigParameters);
  }
}

class WebsocketIO implements PlatformSocket {
  final WebSocket _socket;
  late StreamController<List<int>>? _streamController =
      StreamController<List<int>>()..onCancel = _onCloseStream;
  void _onCloseStream() {
    _socket.close(1000, "closed by client.");
  }

  @override
  bool get isConnected => _socket.readyState == WebSocket.open;
  WebsocketIO._(this._socket) {
    _socket.listen(
      (dynamic data) {
        final List<int>? result = switch (data) {
          final String r => StringUtils.encode(r),
          final List<int> bytes => bytes,
          _ => null
        };
        assert(result != null,
            "unexpected web socket response ${data.runtimeType}");
        if (result == null) return;
        _streamController?.add(result);
      },
      onDone: () {
        close();
      },
      onError: (dynamic error) {
        _streamController?.addError(error);
      },
    );
  }

  @override
  void close() {
    _streamController?.close();
    _streamController = null;
  }

  @override
  Stream<List<int>> get stream {
    assert(_streamController != null, "socket already closed.");
    final stream = _streamController?.stream;
    return stream ?? Stream.empty();
  }

  static Future<Result<PlatformSocket, NetResultStatus>> connect(
      {required String url,
      required Duration? timeout,
      List<String>? protocols}) async {
    try {
      final socket = switch (timeout) {
        Duration timeout =>
          await WebSocket.connect(url, protocols: protocols).timeout(timeout),
        null => await WebSocket.connect(url, protocols: protocols),
      };
      return Ok(WebsocketIO._(socket));
    } on TimeoutException {
      return Err(NetResultStatus.requestTimeout);
    } catch (e) {
      return Err(NetResultStatus.connectionError);
    }
  }

  @override
  void sink(List<int> message) {
    _socket.add(message);
  }

  int? get closeCode => _socket.closeCode;
  String? get closeReason => _socket.closeReason;
}

class SocketIo implements PlatformSocket {
  final Socket _socket;
  bool _isConnected = true;
  @override
  bool get isConnected => _isConnected;
  late StreamController<List<int>>? _streamController =
      StreamController<List<int>>()..onCancel = _onCloseStream;

  SocketIo._(this._socket) {
    _socket.listen(
      (dynamic data) {
        final List<int>? result = switch (data) {
          final String r => StringUtils.encode(r),
          final List<int> r => r,
          _ => null
        };
        assert(result != null,
            "unexpected web socket response ${data.runtimeType}");
        if (result == null) return;
        _streamController?.add(result);
      },
      onDone: () {
        close();
        _isConnected = false;
      },
      onError: (dynamic error) {
        _streamController?.addError(error);
        _isConnected = false;
      },
    );
  }

  static Future<Result<SocketIo, NetResultStatus>> tcp({
    required String host,
    required int port,
    Duration? timeout,
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      return Ok(SocketIo._(socket));
    } on TimeoutException {
      return Err(NetResultStatus.requestTimeout);
    } catch (e) {
      return Err(NetResultStatus.connectionError);
    }
  }

  static Future<Result<SocketIo, NetResultStatus>> tls(
      {required String host,
      required int port,
      Duration? timeout,
      bool insecure = false}) async {
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        timeout: timeout,
        onBadCertificate: (certificate) => insecure,
      );
      return Ok(SocketIo._(socket));
    } on TimeoutException {
      return Err(NetResultStatus.requestTimeout);
    } catch (e) {
      return Err(NetResultStatus.connectionError);
    }
  }

  @override
  void sink(List<int> message) {
    _socket.add(message);
  }

  void _onCloseStream() {
    _socket.close();
  }

  @override
  void close() {
    _streamController?.close();
    _streamController = null;
  }

  @override
  Stream<List<int>> get stream {
    assert(_streamController != null, "socket already closed.");
    final stream = _streamController?.stream;
    return stream ?? Stream.empty();
  }
}
