import 'dart:async';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/net_sdk/types/stream.dart';

abstract class GrpcTransport implements ProtocolTransport {
  Future<Result<List<int>, NetSdkException>> unaray(
      {required String method,
      required List<int> buffer,
      required Duration timeout});
  Stream<List<int>> stream(
      {required String method,
      required List<int> buffer,
      required Duration timeout});
  int get id;
}

class DefaultGrpcTransport implements GrpcTransport {
  final Transport _transport;
  DefaultGrpcTransport(this._transport);
  @override
  int get id => _transport.transportId;

  @override
  Future<Result<List<int>, NetSdkException>> unaray(
      {required String method,
      required List<int> buffer,
      required Duration timeout}) async {
    final result = await _transport.sendRequest<NetResponseGrpcUnary>(
        NetRequestGrpcUnary(data: buffer, method: method), timeout);
    return result.mapErr((e) => NetSdkException(e)).andThen<List<int>>((e) {
      if (e.isOk) return Ok(e.data);
      return Err(NetSdkException(NetResultStatus.connectionError,
          details: {"code": e.code.toString(), "message": e.message}));
    });
  }

  @override
  Stream<List<int>> stream(
      {required String method,
      required List<int> buffer,
      required Duration timeout}) async* {
    bool isClose = true;
    int streamId = -1;
    final cachedClient = CachedStreamController<NetResponseStream>();
    StreamSubscription<NetResponseStream> subscription =
        _transport.stream.listen((e) => cachedClient.add(e));
    try {
      final result = await _transport.sendRequest<NetResponseGrpcSubscribe>(
          NetRequestGrpcStream(data: buffer, method: method), timeout);
      if (result.isErr) {
        throw NetSdkException(result.unwrapErr());
      }
      final response = result.unwrap();
      if (!response.isOk) {
        throw NetSdkException(NetResultStatus.connectionError, details: {
          "code": response.code.toString(),
          "message": response.message
        });
      }
      isClose = false;
      streamId = result.unwrap().id;
      await for (final event
          in cachedClient.stream.where((e) => e.id == streamId)) {
        switch (event) {
          case NetResponseStreamData data:
            yield data.data;
            break;
          case NetResponseStreamClose():
            isClose = true;
            return;
          case NetResponseStreamError error:
            isClose = true;
            throw NetSdkException(error.error, details: {
              "code": error.code.toString(),
              "message": error.message
            });
        }
      }
    } finally {
      subscription.cancel();
      cachedClient.close();
      if (!isClose) {
        final result = await _transport.sendRequest(
            NetRequestGrpcUnsubscribe(streamId), timeout);
        assert(
            result.isOk || result.err() == NetResultStatus.transportNotFound);
        isClose = true;
      }
    }
  }

  @override
  Future<Result<NetResponseClose, NetSdkException>> close(
      {Duration? timeout}) async {
    final result = await _transport.closeTransport(timeout: timeout);
    return result.mapErr((e) => NetSdkException(e));
  }
}
