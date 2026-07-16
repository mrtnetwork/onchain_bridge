import 'dart:async';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/dart/http/core/http.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<PlatformHttp, NetResultStatus>> httpClient(
        NetAddressInfo addr) async =>
    throw OnChainBridgeException.unsuported;
