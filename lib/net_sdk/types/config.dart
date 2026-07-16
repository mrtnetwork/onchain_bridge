import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/constants/constants.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_bridge/net_sdk/utils/utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

enum HttpMethod {
  post(1, "POST"),
  get(2, "GET"),
  delete(3, "DELETE"),
  update(4, "UPDATE"),
  closeConnection(5, "close_connection");

  final String name;
  final int value;
  const HttpMethod(this.value, this.name);
  static HttpMethod fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw ItemNotFoundException());
  }

  static HttpMethod fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw ItemNotFoundException());
  }
}

enum NetApiTarget {
  dart(1),
  rust(2);

  final int value;
  const NetApiTarget(this.value);
  static NetApiTarget fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw ItemNotFoundException());
  }
}

enum NetMode {
  tor(1),
  clearnet(2);

  final int value;
  const NetMode(this.value);

  static NetMode fromValue(int value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw ItemNotFoundException());
  }

  bool get isTor => this == tor;
  NetMode operator ~() {
    if (this == NetMode.clearnet) {
      return NetMode.tor;
    }
    return NetMode.clearnet;
  }
}

enum NetHttpProtocol {
  http1(1),
  http2(2);

  final int value;
  const NetHttpProtocol(this.value);

  static NetHttpProtocol fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw ItemNotFoundException());
  }
}

enum StreamEncoding {
  map(1),
  raw(2),
  listOfMap(3),
  string(4),
  json(5);

  bool get isString => this == string;

  final int id;
  const StreamEncoding(this.id);

  static StreamEncoding? fromValueOrNull(int? value) {
    return values.firstWhereNullable((e) => e.id == value);
  }

  static StreamEncoding fromValue(int? value) {
    return values.firstWhere((e) => e.id == value,
        orElse: () => throw ItemNotFoundException());
  }

  Result<T, NetSdkException> decodeBinary<T extends Object?>(List<int> bytes) {
    try {
      final result = switch (this) {
        StreamEncoding.map => JsonParser.valueEnsureAsMap<String, dynamic>(
            StringUtils.decodeJson(bytes)),
        StreamEncoding.raw => bytes,
        StreamEncoding.listOfMap =>
          JsonParser.valueEnsureAsList<Map<String, dynamic>>(
              StringUtils.decodeJson(bytes)),
        StreamEncoding.string => StringUtils.decode(bytes),
        StreamEncoding.json => StringUtils.decodeJson(bytes),
      };
      return Ok(JsonParser.valueAs<T>(result));
    } catch (e) {
      return Err(NetSdkException(NetResultStatus.parsingError,
          details: {"message": e.toString(), "encoding": name}));
    }
  }
}

enum NetTlsMode {
  safe(1),
  dangerous(2);

  final int value;
  const NetTlsMode(this.value);
  bool get insecure => this == NetTlsMode.dangerous;

  static NetTlsMode fromValue(int? value) {
    return values.firstWhere((e) => e.value == value,
        orElse: () => throw ItemNotFoundException());
  }
}

enum NetProtocol {
  http("Http", 1),
  grpc("Grpc", 2),
  webSocket("WebSocket", 3),
  tcp("Tcp", 4),
  tls("Tls", 5);

  final int id;
  final String name;
  const NetProtocol(this.name, this.id);

  static NetProtocol fromValue(int? value) {
    return values.firstWhere((e) => e.id == value,
        orElse: () => throw ItemNotFoundException());
  }

  static NetProtocol fromName(String name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () => throw ItemNotFoundException());
  }
}

class NetDigestAuthenticated with AppSerialization {
  final String username;
  final String password;
  const NetDigestAuthenticated(
      {required this.username, required this.password});
  factory NetDigestAuthenticated.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netSdkNetDigestAuthenticated,
        cborBytes: bytes,
        cborObject: object);
    return NetDigestAuthenticated(
        username: values.rawValueAt(0), password: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetDigestAuthenticated;

  @override
  List<CborObject?> get serializationItems =>
      [username.toCbor(), password.toCbor()];
}

class NetHttpHeader with AppSerialization {
  final String key;
  final String value;

  const NetHttpHeader({
    required this.key,
    required this.value,
  });
  factory NetHttpHeader.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netSdkNetHttpHeader,
        cborBytes: bytes,
        cborObject: object);
    return NetHttpHeader(
        key: values.rawValueAt(0), value: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetHttpHeader;

  @override
  List<CborObject?> get serializationItems => [key.toCbor(), value.toCbor()];
}

class NetConfigTor with AppSerialization {
  final String cacheDir;
  final String stateDir;

  NetConfigTor({
    required this.cacheDir,
    required this.stateDir,
  });
  factory NetConfigTor.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netSdkNetConfigTor,
        cborBytes: bytes,
        cborObject: object);
    return NetConfigTor(
        cacheDir: values.rawValueAt(0), stateDir: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetConfigTor;

  @override
  List<CborObject?> get serializationItems =>
      [cacheDir.toCbor(), stateDir.toCbor()];
}

class NetConfigHttp with AppSerialization {
  final List<NetHttpHeader> defaultHeaders;
  final NetHttpProtocol? protocol;
  final bool streaming;
  final bool keepHttp1ConnectionAlive;

  const NetConfigHttp({
    required this.defaultHeaders,
    this.protocol,
    required this.streaming,
    required this.keepHttp1ConnectionAlive,
  });

  factory NetConfigHttp.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netSdkNetConfigHttp,
        cborBytes: bytes,
        cborObject: object);
    return NetConfigHttp(
        defaultHeaders: values
            .listAt<CborTagValue>(0)
            .map((e) => NetHttpHeader.deserialize(object: e))
            .toList(),
        protocol: values.maybeRawValueAt<NetHttpProtocol, int>(
            1, NetHttpProtocol.fromValue),
        streaming: values.rawValueAt(2),
        keepHttp1ConnectionAlive: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetConfigHttp;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            defaultHeaders.map((e) => e.toCbor()).toList()),
        protocol?.value.toCbor(),
        streaming.toCbor(),
        keepHttp1ConnectionAlive.toCbor()
      ];
}

class NetConfigRequest with AppSerialization {
  final String url;
  final NetMode mode;
  final NetProtocol protocol;
  final NetConfigHttp http;
  final NetTlsMode tlsMode;
  final NetConfigRawSocket? rawScoketConfig;
  final Duration timeout;
  factory NetConfigRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netSdkNetConfigRequest,
        cborBytes: bytes,
        cborObject: object);
    return NetConfigRequest(
        url: values.rawValueAt(0),
        mode: NetMode.fromValue(values.rawValueAt(1)),
        protocol: NetProtocol.fromValue(values.rawValueAt(2)),
        http: NetConfigHttp.deserialize(object: values.objectAt(3)),
        rawScoketConfig: values.maybeObjectAt<NetConfigRawSocket, CborTagValue>(
            4, (e) => NetConfigRawSocket.deserialize(object: e)),
        tlsMode: NetTlsMode.fromValue(
          values.rawValueAt(5),
        ),
        timeout: Duration(seconds: values.rawValueAt(6)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetConfigRequest;

  @override
  List<CborObject?> get serializationItems => [
        url.toCbor(),
        mode.value.toCbor(),
        protocol.id.toCbor(),
        http.toCbor(),
        rawScoketConfig?.toCbor(),
        tlsMode.value.toCbor(),
        timeout.inSeconds.toCbor()
      ];

  const NetConfigRequest(
      {required this.url,
      required this.mode,
      required this.protocol,
      required this.tlsMode,
      required this.http,
      required this.rawScoketConfig,
      required this.timeout});
  factory NetConfigRequest.wasm({
    required String url,
    required NetProtocol protocol,
    required NetConfigHttp http,
    required StreamEncoding encoding,
    Duration timeout = NetSdkConst.defaultConfigRequestTimeout,
  }) {
    return NetConfigRequest(
        url: url,
        mode: NetMode.clearnet,
        protocol: protocol,
        tlsMode: NetTlsMode.safe,
        rawScoketConfig: null,
        timeout: timeout,
        http: http);
  }

  NetConfigRequest copyWith(
      {String? url,
      NetMode? mode,
      NetProtocol? protocol,
      NetConfigHttp? http,
      NetTlsMode? tlsMode,
      NetConfigRawSocket? rawScoketConfig,
      Duration? timeout}) {
    return NetConfigRequest(
        url: url ?? this.url,
        mode: mode ?? this.mode,
        protocol: protocol ?? this.protocol,
        tlsMode: tlsMode ?? this.tlsMode,
        http: http ?? this.http,
        rawScoketConfig: rawScoketConfig ?? this.rawScoketConfig,
        timeout: timeout ?? this.timeout);
  }

  Result<NetConfig, NetResultStatus> toConfig() {
    final address = switch (protocol) {
      NetProtocol.http || NetProtocol.grpc => NetAddressInfo.http(url),
      NetProtocol.webSocket => NetAddressInfo.wss(url),
      NetProtocol.tcp => NetAddressInfo.tcp(url),
      NetProtocol.tls => NetAddressInfo.tls(url),
    };
    if (address == null) return Err(NetResultStatus.invalidUrl);
    return Ok(NetConfig(
        address: address,
        protocol: protocol,
        tlsMode: tlsMode,
        rawSocketConfig: rawScoketConfig,
        http: http));
  }
}

class NetConfigRawSocket with AppSerialization {
  final List<int> eof;
  final StreamEncoding encoding;
  const NetConfigRawSocket({required this.eof, required this.encoding});
  factory NetConfigRawSocket.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netSdkNetConfigRawSocket,
        cborBytes: bytes,
        cborObject: object);
    return NetConfigRawSocket(
        eof: values.rawValueAt(0),
        encoding: StreamEncoding.fromValue(values.rawValueAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkNetConfigRawSocket;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(eof), encoding.id.toCbor()];
}

class NetAddressInfo with Equality {
  final String host;
  final String url;
  final int port;
  final bool isTls;
  final Uri uri;
  const NetAddressInfo(
      {required this.host,
      required this.port,
      required this.url,
      required this.isTls,
      required this.uri});
  static NetAddressInfo? fromProtocol(String url, NetProtocol protocol) {
    return switch (protocol) {
      NetProtocol.http || NetProtocol.grpc => http(url),
      NetProtocol.webSocket => wss(url),
      NetProtocol.tcp => tcp(url),
      NetProtocol.tls => tls(url),
    };
  }

  static NetAddressInfo? http(String url) {
    return NetSdkUtils.parseHttpUrl(url);
  }

  static NetAddressInfo? tcp(String url) {
    return NetSdkUtils.parseHostPort(url, false);
  }

  static NetAddressInfo? tls(String url) {
    return NetSdkUtils.parseHostPort(url, true);
  }

  static NetAddressInfo? wss(String url) {
    return NetSdkUtils.parseWebsocketUrl(url);
  }

  @override
  List<dynamic> get variables => [host, isTls, port];
}

class NetConfig {
  final NetAddressInfo address;
  final NetProtocol protocol;
  final NetTlsMode tlsMode;
  final NetConfigRawSocket? rawSocketConfig;
  final NetConfigHttp http;
  const NetConfig(
      {required this.address,
      required this.protocol,
      required this.tlsMode,
      required this.rawSocketConfig,
      required this.http});
}

sealed class NetSdkConfig {
  final NetCreateInstanceConfig config;
  const NetSdkConfig({required this.config});
}

class NetSdkConfigDefault extends NetSdkConfig {
  final AppEnvironment environment;
  NetSdkConfigDefault({required super.config, required this.environment});
}

class NetSdkConfigNative extends NetSdkConfig {
  final String libUri;

  const NetSdkConfigNative({
    required this.libUri,
    required super.config,
  });
}

sealed class NetSdkConfigWeb extends NetSdkConfig {
  String get moduleUrl;
  final Duration timeout;
  const NetSdkConfigWeb({required super.config, required this.timeout});
}

class NetSdkConfigWebWasm extends NetSdkConfigWeb {
  final WasmModuleInfo info;
  const NetSdkConfigWebWasm(
      {required this.info, required super.config, required super.timeout});

  @override
  String get moduleUrl => info.moduleUrl;
}

class NetSdkConfigWebJsModule extends NetSdkConfigWeb {
  @override
  final String moduleUrl;
  const NetSdkConfigWebJsModule(
      {required this.moduleUrl, required super.config, required super.timeout});
}

extension HEADERGETTER on Iterable<NetHttpHeader> {
  String? getString(String key) {
    return firstWhereNullable((e) => e.key == key)?.value;
  }

  int? getInt(String key) {
    return JsonParser.valueAsInt(
        firstWhereNullable((e) => e.key == key)?.value);
  }

  int? tryGetInt(String key) {
    try {
      return JsonParser.valueAsInt(
          firstWhereNullable((e) => e.key == key)?.value);
    } on JsonParserError {
      return null;
    }
  }

  int? getContentLength() {
    return tryGetInt("content-length") ?? tryGetInt("Content-Length");
  }
}
