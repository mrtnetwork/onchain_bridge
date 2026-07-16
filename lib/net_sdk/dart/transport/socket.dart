import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/clients/socket.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/dart/types/types.dart';
import 'package:on_chain_bridge/net_sdk/encoder/encoder.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class SocketDartTransport implements ITransport, ISocketTransport {
  @override
  final NetConfig config;
  final SocketClient client;
  final DARTTRANSPORTCALLBACK callback;
  final _lock = SafeAtomicLock();
  StreamSubscription<Result<List<int>?, NetResultStatus>>? _subscribe;

  SocketDartTransport._(
      {required this.config, required this.client, required this.callback});
  static Result<SocketDartTransport, NetResultStatus> create({
    required NetConfig config,
    required DARTTRANSPORTCALLBACK callback,
  }) {
    return Ok(SocketDartTransport._(
        config: config, callback: callback, client: SocketClient(config)));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> doRequest(
      NetRequest data) async {
    final request = data.toSocketRequest();
    return request.andThenAsync((request) async {
      final result = await switch (request) {
        NetRequestSocketSend request => send(request),
        NetRequestSocketSubscribe _ => subscribe(),
        NetRequestSocketUnsubscribe _ => unsubscribe(),
      };
      return result.map((e) => NetResponseSocketStatus.ok());
    });
  }

  @override
  Future<Result<void, NetResultStatus>> send(NetRequestSocketSend data) async {
    final result = await client.send(data.data);
    final eof = config.rawSocketConfig?.eof;
    return result.andThenAsync((_) async {
      if (eof == null || eof.isEmpty) return Ok(null);
      return client.send(eof);
    });
  }

  @override
  Future<Result<void, NetResultStatus>> subscribe() async {
    return await _lock.run(() async {
      final result = await client.subscribe();
      if (result.isErr) return Err(result.unwrapErr());
      if (_subscribe != null) return Ok(null);
      void closeSub() {
        _lock.run(() {
          _subscribe?.cancel();
          _subscribe = null;
        });
      }

      final encoding = StraamBufferEncoder(
          config.rawSocketConfig?.encoding ?? StreamEncoding.raw);
      _subscribe = result.unwrap().listen(
        (event) {
          if (event.isErr) {
            callback(NetResponseStreamError.error(error: event.unwrapErr()));
            closeSub();
            return;
          }
          final result = event.unwrap();
          if (result == null) {
            callback(NetResponseStreamClose());
            closeSub();
            return;
          }
          final encoded = encoding.addBuffer(result);
          if (encoded == null) return;
          callback(NetResponseStreamData(data: encoded));
        },
      );
      return Ok(null);
    });
  }

  @override
  Future<Result<void, NetResultStatus>> unsubscribe() async {
    return await _lock.run(() async {
      _subscribe?.cancel();
      _subscribe = null;
      return await client.close();
    });
  }

  @override
  Future<void> close() async {
    return await _lock.run(() async {
      _subscribe?.cancel();
      _subscribe = null;
      await client.close();
    });
  }
}
