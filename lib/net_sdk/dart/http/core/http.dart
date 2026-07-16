import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/http/platform_impl/cross.dart'
    if (dart.library.js_interop) '../platform_impl/web.dart'
    if (dart.library.io) '../platform_impl/io.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

abstract class PlatformHttp {
  abstract final NetAddressInfo addr;
  Future<Result<NetResponseHttp, NetResultStatus>> send(
      {required Uri url,
      required HttpMethod method,
      NetHttpRetryConfig? retryConfig,
      List<int>? body,
      Map<String, String>? headers});
  Future<Result<(NetResponseHttp, Stream<List<int>>?), NetResultStatus>>
      sendStream({
    required Uri url,
    required HttpMethod method,
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? retryConfig,
  });
  static Future<Result<PlatformHttp, NetResultStatus>> create(
          NetAddressInfo addr) async =>
      httpClient(addr);
  void close();
}
