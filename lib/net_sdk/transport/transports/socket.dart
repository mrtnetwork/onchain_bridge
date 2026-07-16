import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/constants/constants.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/net_sdk/types/stream.dart';

abstract class SocketTransport implements ProtocolTransport {
  Stream<List<int>> get stream;
  Future<Result<NetResponseSocketStatus, NetSdkException>> send(List<int> data,
      {Duration? timeout});
  Future<Result<NetResponseSocketStatus, NetSdkException>> unsubscribe(
      {Duration? timeout});
  Future<Result<Stream<List<int>>, NetSdkException>> connect(
      {Duration? timeout});
  int get id;
}

class DefaultSocketTransport implements SocketTransport {
  final Transport transport;
  @override
  int get id => transport.transportId;
  DefaultSocketTransport(this.transport);
  final _lock = SafeAtomicLock();
  CachedStreamController<List<int>>? _controller;
  bool get hasListener => _controller?.controller.hasListener ?? false;

  @override
  Stream<List<int>> get stream async* {
    final result = await _getOrCreateController();
    yield* result.fold(
      onOk: (value) => value.stream,
      onErr: (error) => throw error,
    );
  }

  Future<Result<CachedStreamController<List<int>>, NetSdkException>>
      _getOrCreateController({Duration? timeount}) async {
    return _lock.run(() async {
      final controller = _controller;
      if (controller != null) return Ok(controller);
      final result = await transport.sendRequest<NetResponseSocketStatus>(
          NetRequestSocketSubscribe(),
          timeount ?? NetSdkConst.defaultConfigRequestTimeout);
      return result.mapErr((e) => NetSdkException(e)).andThenAsync((e) async {
        if (!e.isOk) {
          return Err(NetSdkException(NetResultStatus.socketError,
              details: {"message": e.message}));
        }
        final controller = CachedStreamController<List<int>>(
          broadcast: true,
          onCancel: () {
            _lock.run(() {
              transport
                  .sendRequest<NetResponseSocketStatus>(
                      NetRequestSocketUnsubscribe(),
                      NetSdkConst.defaultConfigRequestTimeout)
                  .then((result) {
                assert((result.ok()?.isOk ?? false) ||
                    result.err() == NetResultStatus.transportNotFound);
              });
              _controller = null;
            });
          },
        );
        StreamSubscription<NetResponseStream>? subscribtion;
        subscribtion = transport.stream.listen((e) {
          switch (e) {
            case NetResponseStreamData():
              controller.add(e.data);
              break;
            case NetResponseStreamClose():
            case NetResponseStreamError():
              _lock.run(() {
                if (e case NetResponseStreamError(:final error)) {
                  controller.addErr(NetSdkException(error));
                }
                controller.close();
                subscribtion?.cancel();
                subscribtion = null;
                _controller = null;
              });
              break;
          }
        });
        _controller = controller;
        return Ok(controller);
      });
    });
  }

  @override
  Future<Result<Stream<List<int>>, NetSdkException>> connect(
      {Duration? timeout}) async {
    final result = await _getOrCreateController(timeount: timeout);
    return result.map((e) => e.stream);
  }

  @override
  Future<Result<NetResponseSocketStatus, NetSdkException>> send(List<int> data,
      {Duration? timeout}) async {
    final result = await transport.sendRequest<NetResponseSocketStatus>(
        NetRequestSocketSend(data),
        timeout ?? NetSdkConst.defaultConfigRequestTimeout);
    return result.mapErr((e) => NetSdkException(e)).andThen((e) {
      if (e.isOk) return Ok(e);
      final exp = NetSdkException(NetResultStatus.socketError,
          details: {"message": e.message});
      return Err(exp);
    });
  }

  Future<Result<NetResponseSocketStatus, NetSdkException>> _unsubscribe(
      {Duration? timeout}) async {
    final result = await transport.sendRequest(NetRequestSocketUnsubscribe(),
        timeout ?? NetSdkConst.defaultConfigRequestTimeout);
    return result.mapErr((e) => NetSdkException(e)).andThen((e) {
      if (e.isOk) return Ok(e);
      final exp = NetSdkException(NetResultStatus.socketError,
          details: {"message": e.message});
      return Err(exp);
    });
  }

  @override
  Future<Result<NetResponseSocketStatus, NetSdkException>> unsubscribe(
      {Duration? timeout}) async {
    return _lock.run(() async {
      return await _unsubscribe(timeout: timeout);
    });
  }

  @override
  Future<Result<NetResponseClose, NetSdkException>> close(
      {Duration? timeout}) async {
    await _lock.run(() async {
      if (_controller != null) {
        final unsubscribe = await _unsubscribe();
        assert(unsubscribe.isOk ||
            unsubscribe.err()?.error == NetResultStatus.transportNotFound);
      }
      _controller?.close();
      _controller = null;
    });
    final close = await transport.closeTransport(timeout: timeout);
    return close.mapErr((e) => NetSdkException(e));
  }
}
