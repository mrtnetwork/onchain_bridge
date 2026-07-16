import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/clients.dart';
import 'package:on_chain_bridge/net_sdk/dart/socket/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class SocketClient implements IClient<PlatformSocket>, IStreamClient {
  final NetConfig config;
  SocketClient(this.config);
  final _lock = SafeAtomicLock();
  PlatformSocket? _socket;
  final StreamController<Result<List<int>?, NetResultStatus>> _controller =
      StreamController.broadcast();
  @override
  Future<Result<PlatformSocket, NetResultStatus>> connect(
      {Duration? timeout}) async {
    return _lock.run(() async {
      PlatformSocket? socket = _socket;
      if (socket != null && socket.isConnected) {
        return Ok(socket);
      }
      final connection = await PlatformSocket.connect(config: config);
      if (connection.isErr) return Err(connection.unwrapErr());
      socket = _socket = connection.unwrap();
      socket.stream.listen(
        (event) {
          _controller.add(Ok(event));
        },
        onError: (_) {
          _controller.add(Err(NetResultStatus.socketError));
        },
        onDone: () {
          _controller.add(Ok(null));
        },
      );
      return Ok(socket);
    });
  }

  @override
  Future<Result<void, NetResultStatus>> send(List<int> data) async {
    final socket = await connect();
    return socket.map<void>((socket) {
      socket.sink(data);
    });
  }

  @override
  Future<Result<Stream<Result<List<int>?, NetResultStatus>>, NetResultStatus>>
      subscribe() async {
    final socket = await connect();
    return socket.map((_) => _controller.stream);
  }

  @override
  Future<Result<void, NetResultStatus>> close() async {
    await _lock.run(() {
      _socket?.close();
      _socket = null;
    });
    return Ok(null);
  }
}
