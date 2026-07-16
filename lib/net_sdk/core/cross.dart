import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<INetSdk, NetResultStatus>> createSdk(NetSdkConfig config) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:js_interop or dart:io.');
