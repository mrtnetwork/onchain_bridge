import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

abstract class ISocketTransport {
  Future<Result<void, NetResultStatus>> send(NetRequestSocketSend send);
  Future<Result<void, NetResultStatus>> subscribe();
  Future<Result<void, NetResultStatus>> unsubscribe();
}

abstract class IGrpcTransport {
  Future<Result<NetResponseKind, NetResultStatus>> unary(
      NetRequestGrpcUnary data);
  Future<Result<NetResponseKind, NetResultStatus>> stream(
      NetRequestGrpcStream data);

  Future<Result<NetResponseKind, NetResultStatus>> unsubscribe(
      NetRequestGrpcUnsubscribe data);
}

abstract class IHttpTransport {
  Future<Result<NetResponseKind, NetResultStatus>> send(NetRequestHttp data);
  Future<Result<NetResponseKind, NetResultStatus>> sendStream(
      NetRequestHttp data);
}

abstract class ITransport {
  abstract final NetConfig config;
  Future<Result<NetResponseKind, NetResultStatus>> doRequest(NetRequest data);
  Future<void> close();
}
