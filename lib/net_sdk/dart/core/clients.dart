import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/grpc/core/gprc.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

abstract class IClient<T extends Object> {
  Future<Result<T, NetResultStatus>> connect({Duration? timeout});
  Future<Result<void, NetResultStatus>> close();
}

abstract class IStreamClient {
  Future<Result<void, NetResultStatus>> send(List<int> data);
  Future<Result<void, NetResultStatus>> close();
  Future<Result<Stream<Result<List<int>?, NetResultStatus>>, NetResultStatus>>
      subscribe();
}

abstract class IGrpcClient {
  Future<Result<List<int>, Result<AppGrpcError, NetResultStatus>>> unary(
      List<int> buffer, String methodName);
  Future<Result<Stream<List<int>>, NetResultStatus>> stream(
      List<int> buffer, String methodName);
  Future<Result<void, NetResultStatus>> close();
}

abstract class IHttpClient {
  Future<Result<NetResponseHttp, NetResultStatus>> send(
    String url,
    HttpMethod method, {
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? retryConfig,
  });
  Future<Result<(NetResponseHttp, Stream<List<int>>?), NetResultStatus>>
      sendStream({
    required String url,
    required HttpMethod method,
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? retryConfig,
  });
  Future<Result<void, NetResultStatus>> close();
}
