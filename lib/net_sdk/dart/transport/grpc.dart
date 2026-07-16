import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/clients/grpc.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/clients.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/dart/types/types.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class GrpcDartTransport implements ITransport, IGrpcTransport {
  final IGrpcClient client;
  final DARTTRANSPORTCALLBACK callback;
  @override
  final NetConfig config;
  final Map<int, StreamSubscription<List<int>>> _subscriber = {};
  final _lock = SafeAtomicLock();
  int _nextSubId = 1;

  GrpcDartTransport._(
      {required this.config, required this.callback, required this.client});
  static Result<GrpcDartTransport, NetResultStatus> create({
    required NetConfig config,
    required DARTTRANSPORTCALLBACK callback,
  }) {
    return Ok(GrpcDartTransport._(
        config: config, callback: callback, client: GrpcClient(config)));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> doRequest(
      NetRequest data) async {
    final request = data.toGrpcRequest();
    return request.andThenAsync((request) async {
      switch (request) {
        case NetRequestGrpcUnary request:
          return unary(request);
        case NetRequestGrpcStream request:
          return stream(request);
        case NetRequestGrpcUnsubscribe request:
          return unsubscribe(request);
      }
    });
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> stream(
      NetRequestGrpcStream data) async {
    final result = await client.stream(data.data, data.method);
    if (result.isErr) return Err(result.unwrapErr());
    final id = await _lock.run(() {
      final id = _nextSubId++;
      final subscribe = result.unwrap().listen((event) {
        callback(NetResponseStreamData(data: event, id: id));
      }, onDone: () {
        callback(NetResponseStreamClose(id: id));
        _lock.run(() {
          _subscriber.remove(id);
        });
      }, onError: (e) {
        callback(NetResponseStreamError.error(
            id: id, error: NetResultStatus.socketError));
        _lock.run(() {
          _subscriber.remove(id);
        });
      });
      _subscriber[id] = subscribe;
      return id;
    });

    return Ok(NetResponseGrpcSubscribe.ok(id));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> unary(
      NetRequestGrpcUnary data) async {
    final result = await client.unary(data.data, data.method);
    if (result.isErr) {
      final error = result.unwrapErr();
      return error.map(
          (e) => NetResponseGrpcUnary.error(message: e.message, code: e.code));
    }
    return Ok(NetResponseGrpcUnary.ok(result.unwrap()));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> unsubscribe(
      NetRequestGrpcUnsubscribe data) async {
    await _lock.run(() {
      final r = _subscriber.remove(data.id);
      r?.cancel().catchError((e) => null);
    });
    return Ok(NetResponseGrpcUnsubscribe(data.id));
  }

  @override
  Future<void> close() async {
    await _lock.run(() async {
      final subs = _subscriber.clone();
      _subscriber.clear();
      for (final i in subs.values) {
        i.cancel().catchError((e) => null);
      }
      await client.close();
    });
  }
}
