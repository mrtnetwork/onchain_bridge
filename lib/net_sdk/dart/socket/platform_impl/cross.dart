import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/socket/core/core.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<PlatformSocket, NetResultStatus>> connectSoc({
  required NetConfig config,
  List<String>? protocols,
  Duration? timeout,
}) =>
    throw UnsupportedError(
        'Cannot create a instance without dart:js_interop or dart:io.');
