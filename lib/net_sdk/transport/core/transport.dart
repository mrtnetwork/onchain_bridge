import 'dart:async';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/constants/constants.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class Transport {
  final int transportId;
  final Stream<NetResponseStream> stream;
  final INetSdk lib;
  final NetConfigRequest config;
  const Transport(
      {required this.stream,
      required this.transportId,
      required this.lib,
      required this.config});
  Future<Result<RESPONSE, NetResultStatus>>
      sendRequest<RESPONSE extends NetResponseKind>(
          NetRequestKind<RESPONSE> request, Duration timeout) async {
    return await lib.sendRequest<RESPONSE>(transportId, request, timeout);
  }

  Future<Result<NetResponseClose, NetResultStatus>> closeTransport(
      {Duration? timeout}) async {
    return await sendRequest<NetResponseClose>(NetRequestCloseTransport(),
        timeout ?? NetSdkConst.defaultConfigRequestTimeout);
  }
}

abstract class ProtocolTransport {
  Future<Result<NetResponseClose, NetSdkException>> close({Duration? timeout});
}
