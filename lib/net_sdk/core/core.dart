import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/net_sdk/authenticated/authenticated.dart';
import 'package:on_chain_bridge/net_sdk/core/cross.dart'
    if (dart.library.io) '../../native/net_sdk/core/net_sdk.dart'
    if (dart.library.js_interop) '../../web/net_sdk/core/net_sdk.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/gprc.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/http.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/socket.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

import 'default.dart';

abstract class INetSdk {
  static Future<Result<INetSdk, NetResultStatus>> init(
      NetSdkConfig config) async {
    if (config case NetSdkConfigDefault(:final environment)) {
      return Ok(DefaultNetSdk(environment));
    }
    return await createSdk(config);
  }

  Future<Result<RESPONSE, NetResultStatus>>
      sendRequest<RESPONSE extends NetResponseKind>(
          int transportId, NetRequestKind<RESPONSE> request, Duration timeout);
  Future<Result<Transport, NetResultStatus>> createTransport(
      NetConfigRequest config);
  List<NetMode> get modes;
  Future<Result<void, NetResultStatus>> closeInstance();
  NetApiTarget get target;
  AppEnvironment get environment;
}

abstract class INetSdkApi {
  Future<Result<SocketTransport, NetResultStatus>> createTcpTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  });

  Future<Result<SocketTransport, NetResultStatus>> createTlsTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  });

  Future<Result<SocketTransport, NetResultStatus>> createSocketTransport({
    required String url,
    required NetProtocol protocol,
    required NetConfigRawSocket? rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  });

  Future<Result<SocketTransport, NetResultStatus>> createWebsocketTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  });

  Future<Result<GrpcTransport, NetResultStatus>> createGrpcTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
    NetTlsMode tlsMode = NetTlsMode.safe,
  });
  Future<Result<HttpTransport, NetResultStatus>> createHttpTransport(
      {required String url,
      required bool streaming,
      Map<String, String> headers = const {},
      NetMode mode = NetMode.clearnet,
      HttpAuthenticated? authenticated,
      bool? keepHttp1ConnectionAlive,
      NetHttpProtocol? protocol});
  Future<Result<void, NetResultStatus>> initTor({Duration? timeout});

  Future<Result<bool, NetResultStatus>> torInited({Duration? timeout});

  bool torSupported();
  Future<void> closeInstance();
  NetApiTarget get target;
  List<NetMode> get modes;
}
