import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/authenticated/authenticated.dart';
import 'package:on_chain_bridge/net_sdk/constants/constants.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/gprc.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/http.dart';
import 'package:on_chain_bridge/net_sdk/transport/transports/socket.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class DefaultNetSdkApi implements INetSdkApi {
  final INetSdk netSdk;
  const DefaultNetSdkApi(this.netSdk);

  Result<NetConfigRequest, NetResultStatus> _createConfig({
    required String url,
    required NetProtocol protocol,
    bool? keepHttp1ConnectionAlive,
    bool httpStreaming = false,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
    NetTlsMode tlsmode = NetTlsMode.safe,
    NetConfigRawSocket? rawScoketConfig,
    NetHttpProtocol? httpProtocol,
    HttpAuthenticated? authenticated,
  }) {
    if (mode == NetMode.tor && !torSupported()) {
      return Err(NetResultStatus.unsupportedFeature);
    }
    switch (protocol) {
      case NetProtocol.tcp:
      case NetProtocol.tls:
        final addr = NetAddressInfo.fromProtocol(url, protocol);
        if (addr == null) {
          return Err(NetResultStatus.invalidUrl);
        }
        if (rawScoketConfig == null) {
          return Err(NetResultStatus.invalidConfigParameters);
        }
        url = addr.url;
        break;
      default:
        if (rawScoketConfig != null) {
          return Err(NetResultStatus.invalidConfigParameters);
        }
    }
    return Ok(NetConfigRequest(
        url: url,
        rawScoketConfig: rawScoketConfig,
        mode: mode,
        protocol: protocol,
        timeout: NetSdkConst.defaultConfigRequestTimeout,
        tlsMode: tlsmode,
        http: NetConfigHttp(
            protocol: httpProtocol,
            keepHttp1ConnectionAlive: keepHttp1ConnectionAlive ??
                (authenticated is HttpDigestAuthenticated),
            streaming: httpStreaming,
            defaultHeaders: headers.entries
                .map((e) => NetHttpHeader(key: e.key, value: e.value))
                .toList())));
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createTcpTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = _createConfig(
      url: url,
      mode: mode,
      protocol: NetProtocol.tcp,
      rawScoketConfig: rawScoketConfig,
      headers: headers,
    );
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createTlsTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.tls,
        tlsmode: NetTlsMode.dangerous,
        headers: headers,
        rawScoketConfig: rawScoketConfig);
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createSocketTransport({
    required String url,
    required NetProtocol protocol,
    required NetConfigRawSocket? rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = switch (protocol) {
      NetProtocol.webSocket ||
      NetProtocol.tcp ||
      NetProtocol.tls =>
        _createConfig(
          url: url,
          mode: mode,
          rawScoketConfig: rawScoketConfig,
          protocol: protocol,
          tlsmode: protocol == NetProtocol.tls
              ? NetTlsMode.dangerous
              : NetTlsMode.safe,
          headers: headers,
        ),
      _ => Err<NetConfigRequest, NetResultStatus>(
          NetResultStatus.invalidRequestParameters)
    };
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createWebsocketTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = _createConfig(
      url: url,
      mode: mode,
      protocol: NetProtocol.webSocket,
      headers: headers,
    );
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<GrpcTransport, NetResultStatus>> createGrpcTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
    NetTlsMode tlsMode = NetTlsMode.safe,
  }) async {
    final config = _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.grpc,
        headers: headers,
        tlsmode: tlsMode);
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        return DefaultGrpcTransport(transport);
      });
    });
  }

  @override
  Future<Result<HttpTransport, NetResultStatus>> createHttpTransport(
      {required String url,
      required bool streaming,
      bool? keepHttp1ConnectionAlive,
      Map<String, String> headers = const {},
      NetMode mode = NetMode.clearnet,
      HttpAuthenticated? authenticated,
      NetHttpProtocol? protocol}) async {
    final config = _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.http,
        headers: headers,
        httpProtocol: protocol,
        authenticated: authenticated,
        keepHttp1ConnectionAlive: keepHttp1ConnectionAlive,
        httpStreaming: streaming);
    return config.andThenAsync((config) async {
      final transport = await netSdk.createTransport(config);
      return transport.map((transport) {
        final digestAuth = authenticated?.digestAuthenticated();
        if (digestAuth != null) {
          return DefaultHttpTransportWithDigestAuth(
              transport: transport,
              authenticated: authenticated!,
              digestAuthenticated: digestAuth);
        }
        return DefaultHttpTransport(
            transport: transport, authenticated: authenticated);
      });
    });
  }

  @override
  Future<Result<void, NetResultStatus>> initTor({Duration? timeout}) async {
    final torInited = await netSdk.sendRequest(1, NetRequestInitTor(),
        timeout ?? NetSdkConst.defaultTorInitializationTimeout);
    return torInited;
  }

  @override
  Future<Result<bool, NetResultStatus>> torInited({Duration? timeout}) async {
    final result = await netSdk.sendRequest<NetResponseTorInited>(
        1,
        NetRequestTorInited(),
        timeout ?? NetSdkConst.defaultConfigRequestTimeout);
    return result.map((e) => e.inited);
  }

  @override
  bool torSupported() {
    return netSdk.modes.contains(NetMode.tor);
  }

  @override
  Future<void> closeInstance() async {
    await netSdk.closeInstance();
  }

  @override
  NetApiTarget get target => netSdk.target;

  @override
  List<NetMode> get modes => netSdk.modes;
}

typedef CbGetNetSdk = Future<Result<INetSdk, NetResultStatus>> Function();

class LazyNetSdkApi implements INetSdkApi {
  INetSdk? _netSdk;
  final _lock = SafeAtomicLock();
  final CbGetNetSdk getNetSdkCallback;
  @override
  final NetApiTarget target;

  @override
  final List<NetMode> modes;
  LazyNetSdkApi({
    required this.getNetSdkCallback,
    required this.target,
    required List<NetMode> modes,
  }) : modes = modes.immutable;

  Future<Result<INetSdk, NetResultStatus>> _getNetSdk() async {
    final netsdk = _netSdk;
    if (netsdk != null) return Ok(netsdk);
    return _lock.run(() async {
      if (netsdk != null) return Ok(netsdk);
      final result = await getNetSdkCallback();
      return result.mapAsync((sdk) {
        _netSdk = sdk;
        return sdk;
      });
    });
  }

  Future<Result<(NetConfigRequest, INetSdk), NetResultStatus>> _createConfig({
    required String url,
    required NetProtocol protocol,
    bool? keepHttp1ConnectionAlive,
    bool httpStreaming = false,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
    NetTlsMode tlsmode = NetTlsMode.safe,
    NetConfigRawSocket? rawScoketConfig,
    NetHttpProtocol? httpProtocol,
    HttpAuthenticated? authenticated,
  }) async {
    final netsdk = await _getNetSdk();
    return netsdk.andThen((netsdk) {
      if (mode == NetMode.tor && !torSupported()) {
        return Err(NetResultStatus.unsupportedFeature);
      }
      switch (protocol) {
        case NetProtocol.tcp:
        case NetProtocol.tls:
          final addr = NetAddressInfo.fromProtocol(url, protocol);
          if (addr == null) {
            return Err(NetResultStatus.invalidUrl);
          }
          if (rawScoketConfig == null) {
            return Err(NetResultStatus.invalidConfigParameters);
          }
          url = addr.url;
          break;
        default:
          if (rawScoketConfig != null) {
            return Err(NetResultStatus.invalidConfigParameters);
          }
      }
      final config = NetConfigRequest(
          url: url,
          rawScoketConfig: rawScoketConfig,
          mode: mode,
          protocol: protocol,
          timeout: NetSdkConst.defaultConfigRequestTimeout,
          tlsMode: tlsmode,
          http: NetConfigHttp(
              protocol: httpProtocol,
              keepHttp1ConnectionAlive: keepHttp1ConnectionAlive ??
                  (authenticated is HttpDigestAuthenticated),
              streaming: httpStreaming,
              defaultHeaders: headers.entries
                  .map((e) => NetHttpHeader(key: e.key, value: e.value))
                  .toList()));
      return Ok((config, netsdk));
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createTcpTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = await _createConfig(
      url: url,
      mode: mode,
      protocol: NetProtocol.tcp,
      rawScoketConfig: rawScoketConfig,
      headers: headers,
    );
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createTlsTransport({
    required String url,
    required NetConfigRawSocket rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = await _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.tls,
        tlsmode: NetTlsMode.dangerous,
        headers: headers,
        rawScoketConfig: rawScoketConfig);
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createSocketTransport({
    required String url,
    required NetProtocol protocol,
    required NetConfigRawSocket? rawScoketConfig,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final Result<(NetConfigRequest, INetSdk), NetResultStatus> config =
        await switch (protocol) {
      NetProtocol.webSocket ||
      NetProtocol.tcp ||
      NetProtocol.tls =>
        _createConfig(
          url: url,
          mode: mode,
          rawScoketConfig: rawScoketConfig,
          protocol: protocol,
          tlsmode: protocol == NetProtocol.tls
              ? NetTlsMode.dangerous
              : NetTlsMode.safe,
          headers: headers,
        ),
      _ => Future.value(Err<(NetConfigRequest, INetSdk), NetResultStatus>(
          NetResultStatus.invalidRequestParameters))
    };
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<SocketTransport, NetResultStatus>> createWebsocketTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
  }) async {
    final config = await _createConfig(
      url: url,
      mode: mode,
      protocol: NetProtocol.webSocket,
      headers: headers,
    );
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        return DefaultSocketTransport(transport);
      });
    });
  }

  @override
  Future<Result<GrpcTransport, NetResultStatus>> createGrpcTransport({
    required String url,
    Map<String, String> headers = const {},
    NetMode mode = NetMode.clearnet,
    NetTlsMode tlsMode = NetTlsMode.safe,
  }) async {
    final config = await _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.grpc,
        headers: headers,
        tlsmode: tlsMode);
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        return DefaultGrpcTransport(transport);
      });
    });
  }

  @override
  Future<Result<HttpTransport, NetResultStatus>> createHttpTransport(
      {required String url,
      required bool streaming,
      bool? keepHttp1ConnectionAlive,
      Map<String, String> headers = const {},
      NetMode mode = NetMode.clearnet,
      HttpAuthenticated? authenticated,
      NetHttpProtocol? protocol}) async {
    final config = await _createConfig(
        url: url,
        mode: mode,
        protocol: NetProtocol.http,
        headers: headers,
        httpProtocol: protocol,
        authenticated: authenticated,
        keepHttp1ConnectionAlive: keepHttp1ConnectionAlive,
        httpStreaming: streaming);
    return config.andThenAsync((config) async {
      final transport = await config.$2.createTransport(config.$1);
      return transport.map((transport) {
        final digestAuth = authenticated?.digestAuthenticated();
        if (digestAuth != null) {
          return DefaultHttpTransportWithDigestAuth(
              transport: transport,
              authenticated: authenticated!,
              digestAuthenticated: digestAuth);
        }
        return DefaultHttpTransport(
            transport: transport, authenticated: authenticated);
      });
    });
  }

  @override
  Future<Result<void, NetResultStatus>> initTor({Duration? timeout}) async {
    final netsdk = await _getNetSdk();
    return netsdk.andThenAsync((netSdk) async {
      final torInited = await netSdk.sendRequest(1, NetRequestInitTor(),
          timeout ?? NetSdkConst.defaultTorInitializationTimeout);
      return torInited;
    });
  }

  @override
  Future<Result<bool, NetResultStatus>> torInited({Duration? timeout}) async {
    final netsdk = await _getNetSdk();
    return netsdk.andThenAsync((netSdk) async {
      final result = await netSdk.sendRequest<NetResponseTorInited>(
          1,
          NetRequestTorInited(),
          timeout ?? NetSdkConst.defaultConfigRequestTimeout);
      return result.map((e) => e.inited);
    });
  }

  @override
  bool torSupported() {
    return modes.contains(NetMode.tor);
  }

  @override
  Future<void> closeInstance() async {
    await _lock.run(() async {
      await _netSdk?.closeInstance();
      _netSdk = null;
    });
  }
}
