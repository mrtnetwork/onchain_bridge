import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/grpc/platform_impl/cross.dart'
    if (dart.library.js_interop) '../platform_impl/web.dart'
    if (dart.library.io) '../platform_impl/io.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class AppGrpcError {
  final int code;
  final String? message;
  AppGrpcError({required this.code, this.message});
  @override
  String toString() => 'GrpcError(code: $code, message: $message)';
}

class DartGrpcClient {
  static Future<Result<PlatformGrpc, NetResultStatus>> client(
          NetAddressInfo addr) =>
      dartGrpcClient(addr);
}

abstract class PlatformGrpc {
  Future<Result<List<int>, Result<AppGrpcError, NetResultStatus>>> unary(
      List<int> buffer, String methodName);
  Future<Result<Stream<List<int>>, NetResultStatus>> stream(
      List<int> buffer, String methodName);
  Future<Result<void, NetResultStatus>> close();
}
