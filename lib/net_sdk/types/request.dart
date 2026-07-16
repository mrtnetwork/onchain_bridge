import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class NetRequestGrpcUnary extends NetRequestGrpc<NetResponseGrpcUnary> {
  final String method;
  final List<int> data;

  const NetRequestGrpcUnary({
    required this.method,
    required this.data,
  }) : super(type: NetRequestType.grpcUnary);
  factory NetRequestGrpcUnary.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestGrpcUnary,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestGrpcUnary(
        method: values.rawValueAt(0), data: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestGrpcUnary;

  @override
  List<CborObject?> get serializationItems =>
      [method.toCbor(), CborBytesValue(data)];
}

class NetRequestGrpcStream extends NetRequestGrpc<NetResponseGrpcSubscribe> {
  final String method;
  final List<int> data;

  const NetRequestGrpcStream({
    required this.method,
    required this.data,
  }) : super(type: NetRequestType.grpcStream);
  factory NetRequestGrpcStream.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestGrpcStream,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestGrpcStream(
        method: values.rawValueAt(0), data: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestGrpcStream;

  @override
  List<CborObject?> get serializationItems =>
      [method.toCbor(), CborBytesValue(data)];
}

class NetRequestGrpcUnsubscribe
    extends NetRequestGrpc<NetResponseGrpcUnsubscribe> {
  final int id;
  NetRequestGrpcUnsubscribe(this.id)
      : super(type: NetRequestType.grpcUnsubscribe);
  factory NetRequestGrpcUnsubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netRequestGrpcUnsubscribe,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestGrpcUnsubscribe(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestGrpcUnsubscribe;

  @override
  List<CborObject?> get serializationItems => [id.toCbor()];
}

sealed class NetRequestGrpc<RESPONSE extends NetResponseGrpc>
    extends NetRequestKind<RESPONSE> with AppSerialization {
  const NetRequestGrpc({required super.type});
}

/// HTTP
class NetRequestHttp extends NetRequestKind<NetResponseHttp>
    with AppSerialization {
  final HttpMethod method;
  final String url;
  final List<int>? body;
  final List<NetHttpHeader> headers;
  final NetHttpRetryConfig retryConfig;
  final int streamId;
  factory NetRequestHttp.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestHttp,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestHttp(
        method: HttpMethod.fromName(values.rawValueAt(0)),
        url: values.rawValueAt(1),
        body: values.rawValueAt(2),
        headers: values
            .listAt<CborObject>(3)
            .map((e) => NetHttpHeader.deserialize(object: e))
            .toList(),
        retryConfig: NetHttpRetryConfig.deserialize(object: values.objectAt(4)),
        streamId: values.rawValueAt(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestHttp;

  @override
  List<CborObject?> get serializationItems => [
        method.name.toCbor(),
        url.toCbor(),
        AppSerialization.bytesToCbor(body),
        AppSerialization.listFromObjects(
            headers.map((e) => e.toCbor()).toList()),
        retryConfig.toCbor(),
        streamId.toCbor()
      ];

  NetRequestHttp._(
      {required this.method,
      required this.url,
      required this.headers,
      this.body,
      required this.retryConfig,
      required this.streamId})
      : super(type: NetRequestType.http);

  factory NetRequestHttp({
    required HttpMethod method,
    required String url,
    int? streamId,
    List<NetHttpHeader> headers = const [],
    List<int>? body,
    NetHttpRetryConfig? retryConfig,
  }) {
    assert(streamId == null || method == HttpMethod.closeConnection);
    return NetRequestHttp._(
        method: method,
        url: url,
        body: body,
        headers: headers,
        streamId: streamId ?? 0,
        retryConfig: retryConfig ??
            NetHttpRetryConfig(
                maxRetry: 1, retryStatus: [], retryDelay: Duration.zero));
  }
}

class NetRequestSocketSend extends NetRequestSocket with AppSerialization {
  final List<int> data;
  const NetRequestSocketSend(this.data)
      : super(type: NetRequestType.socketSend);
  factory NetRequestSocketSend.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestSocketSend,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestSocketSend(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestSocketSend;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(data)];
}

class NetRequestSocketSubscribe extends NetRequestSocket {
  const NetRequestSocketSubscribe()
      : super(type: NetRequestType.socketSubscribe);

  factory NetRequestSocketSubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netRequestSocketSubscribe,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestSocketSubscribe();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestSocketSubscribe;

  @override
  List<CborObject?> get serializationItems => [];
}

class NetRequestSocketUnsubscribe extends NetRequestSocket {
  const NetRequestSocketUnsubscribe()
      : super(type: NetRequestType.socketUnsubscribe);
  factory NetRequestSocketUnsubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netRequestSocketUnsubscribe,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestSocketUnsubscribe();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestSocketUnsubscribe;

  @override
  List<CborObject?> get serializationItems => [];
}

sealed class NetRequestSocket extends NetRequestKind<NetResponseSocketStatus>
    with AppSerialization {
  const NetRequestSocket({required super.type});
}

class NetRequestInitTor extends NetRequestKind<NetResponseTorInited>
    with AppSerialization {
  const NetRequestInitTor() : super(type: NetRequestType.initTor);
  factory NetRequestInitTor.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestInitTor,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestInitTor();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestInitTor;

  @override
  List<CborObject?> get serializationItems => [];
}

class NetRequestTorInited extends NetRequestKind<NetResponseTorInited>
    with AppSerialization {
  const NetRequestTorInited() : super(type: NetRequestType.torInited);
  factory NetRequestTorInited.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestTorInited,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestTorInited();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestTorInited;

  @override
  List<CborObject?> get serializationItems => [];
}

class NetRequestCloseTransport extends NetRequestKind<NetResponseClose>
    with AppSerialization {
  NetRequestCloseTransport() : super(type: NetRequestType.closeTransport);
  factory NetRequestCloseTransport.deserialize(
      {List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netRequestCloseTransport,
        cborBytes: bytes,
        cborObject: object);
    return NetRequestCloseTransport();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequestCloseTransport;

  @override
  List<CborObject?> get serializationItems => [];
}

sealed class NetRequestKind<RESPONSE extends NetResponseKind>
    with AppSerialization {
  final NetRequestType type;
  const NetRequestKind({required this.type});
  Result<RESPONSE, NetResultStatus> toResponse(NetResponseKind response) {
    try {
      return Ok(response.cast<RESPONSE>());
    } on CastFailedException {
      return Err(NetResultStatus.unknownResponse);
    }
  }
}

enum NetRequestType {
  socketSubscribe(0),
  socketUnsubscribe(1),
  socketSend(2),
  grpcUnary(3),
  grpcStream(4),
  grpcUnsubscribe(5),
  http(6),
  initTor(7),
  torInited(8),
  closeTransport(9);

  final int value;
  const NetRequestType(this.value);

  static NetRequestType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(),
    );
  }
}

class NetRequest with AppSerialization {
  final int transportId;
  final int id;
  final Duration timoutSecs;
  final NetRequestKind kind;
  factory NetRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequest,
        cborBytes: bytes,
        cborObject: object);

    final kindValues = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netRequestKind,
        cborObject: values.objectAt<CborTagValue>(3));
    final type = NetRequestType.fromValue(kindValues.rawValueAt(0));
    final kindTag = kindValues.objectAt<CborTagValue>(1);
    return NetRequest(
        transportId: values.rawValueAt(0),
        id: values.rawValueAt(1),
        timoutSecs: Duration(seconds: values.rawValueAt(2)),
        kind: switch (type) {
          NetRequestType.socketSubscribe =>
            NetRequestSocketSubscribe.deserialize(object: kindTag),
          NetRequestType.socketUnsubscribe =>
            NetRequestSocketUnsubscribe.deserialize(object: kindTag),
          NetRequestType.socketSend =>
            NetRequestSocketSend.deserialize(object: kindTag),
          NetRequestType.grpcUnary =>
            NetRequestGrpcUnary.deserialize(object: kindTag),
          NetRequestType.grpcStream =>
            NetRequestGrpcStream.deserialize(object: kindTag),
          NetRequestType.grpcUnsubscribe =>
            NetRequestGrpcUnsubscribe.deserialize(object: kindTag),
          NetRequestType.http => NetRequestHttp.deserialize(object: kindTag),
          NetRequestType.initTor =>
            NetRequestInitTor.deserialize(object: kindTag),
          NetRequestType.torInited =>
            NetRequestTorInited.deserialize(object: kindTag),
          NetRequestType.closeTransport =>
            NetRequestCloseTransport.deserialize(object: kindTag),
        });
  }

  NetRequest(
      {required this.transportId,
      required this.id,
      required this.kind,
      required Duration timoutSecs})
      : timoutSecs =
            Duration(seconds: IntUtils.max(timoutSecs.inSeconds.asU32, 1));

  Result<NetRequestGrpc, NetResultStatus> toGrpcRequest() {
    switch (kind) {
      case NetRequestGrpc request:
        return Ok(request);
      default:
        return Err(NetResultStatus.invalidRequestParameters);
    }
  }

  Result<NetRequestSocket, NetResultStatus> toSocketRequest() {
    switch (kind) {
      case NetRequestSocket request:
        return Ok(request);
      default:
        return Err(NetResultStatus.invalidRequestParameters);
    }
  }

  Result<NetRequestHttp, NetResultStatus> toHttpRequest() {
    switch (kind) {
      case NetRequestHttp request:
        return Ok(request);
      default:
        return Err(NetResultStatus.invalidRequestParameters);
    }
  }

  @override
  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netRequest;

  @override
  List<CborObject?> get serializationItems => [
        transportId.toCbor(),
        id.toCbor(),
        timoutSecs.inSeconds.toCbor(),
        CborTagValue(
            AppSerialization.listFromObjects(
                [kind.type.value.toCbor(), kind.toCbor()]),
            [OnChainBrdigeSerializationIdentifier.netRequestKind.id])
      ];
}

class NetHttpRetryConfig with AppSerialization {
  final int maxRetry;
  final List<int> retryStatus;
  final Duration retryDelay;
  factory NetHttpRetryConfig.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netHttpRetryConfig,
        cborBytes: bytes,
        cborObject: object);
    return NetHttpRetryConfig(
        maxRetry: values.rawValueAt(0),
        retryStatus:
            values.listAt<CborIntValue>(1).map((e) => e.value).toList(),
        retryDelay: Duration(milliseconds: values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netHttpRetryConfig;

  @override
  List<CborObject?> get serializationItems => [
        maxRetry.toCbor(),
        AppSerialization.listFromObjects(
            retryStatus.map((e) => CborIntValue(e)).toList()),
        retryDelay.inMilliseconds.toCbor()
      ];

  NetHttpRetryConfig({
    required int maxRetry,
    required List<int> retryStatus,
    required this.retryDelay,
  })  : maxRetry = IntUtils.max(maxRetry.asU8, 1),
        retryStatus = retryStatus.map((e) => e.asU16).toList(),
        assert(
            retryStatus
                .every((e) => !ServiceProviderUtils.isSuccessStatusCode(e)),
            "Retry on sucess status");
}
