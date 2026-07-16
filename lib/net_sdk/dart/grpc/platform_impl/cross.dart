import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/grpc/core/gprc.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<PlatformGrpc, NetResultStatus>> dartGrpcClient(
        NetAddressInfo addr) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:js_interop or dart:io.');
