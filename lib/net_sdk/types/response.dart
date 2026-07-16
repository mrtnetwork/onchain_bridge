import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

enum NetResponseType {
  socket(0),
  grpcUnary(1),
  grpcSubscribe(2),
  grpcUnsubscribe(3),
  http(4),
  streamData(5),
  streamError(6),
  streamClose(7),
  responseError(8),
  transportClosed(9),
  torInited(10);

  final int value;
  const NetResponseType(this.value);

  static NetResponseType fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(),
    );
  }
}

class NetResponseSocketStatus extends NetResponseKind with AppSerialization {
  final int code;
  final String? message;
  const NetResponseSocketStatus._({required this.code, required this.message})
      : super(type: NetResponseType.socket);
  factory NetResponseSocketStatus.ok() {
    return NetResponseSocketStatus._(code: -1, message: null);
  }
  factory NetResponseSocketStatus.err(String message) {
    return NetResponseSocketStatus._(code: 0, message: message);
  }
  factory NetResponseSocketStatus.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netResponseSocketStatus,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseSocketStatus._(
        code: values.rawValueAt(0), message: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseSocketStatus;

  @override
  List<CborObject?> get serializationItems =>
      [code.toCbor(), message?.toCbor()];

  bool get isOk => code.isNegative;
}

sealed class NetResponseGrpc extends NetResponseKind {
  const NetResponseGrpc({required super.type});
}

class NetResponseGrpcSubscribe extends NetResponseGrpc with AppSerialization {
  final int id;
  final int code;
  final String? message;
  bool get isOk => code.isNegative;

  const NetResponseGrpcSubscribe._(
      {required this.id, required this.code, required this.message})
      : super(type: NetResponseType.grpcSubscribe);
  factory NetResponseGrpcSubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netResponseGrpcSubscribe,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseGrpcSubscribe._(
      id: values.rawValueAt<int>(0),
      message: values.rawValueAt(1),
      code: values.rawValueAt(2),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseGrpcSubscribe;

  @override
  List<CborObject?> get serializationItems =>
      [id.toCbor(), message?.toCbor(), code.toCbor()];
  factory NetResponseGrpcSubscribe.error(
      {required int code, required String? message}) {
    return NetResponseGrpcSubscribe._(
        id: 0, message: message?.isEmpty ?? true ? null : message, code: code);
  }
  factory NetResponseGrpcSubscribe.ok(int id) {
    return NetResponseGrpcSubscribe._(id: id, message: null, code: -1);
  }
}

class NetResponseGrpcUnsubscribe extends NetResponseGrpc with AppSerialization {
  final int id; // u32
  const NetResponseGrpcUnsubscribe(this.id)
      : super(type: NetResponseType.grpcUnsubscribe);
  factory NetResponseGrpcUnsubscribe.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.netResponseGrpcUnsubscribe,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseGrpcUnsubscribe(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseGrpcUnsubscribe;

  @override
  List<CborObject?> get serializationItems => [id.toCbor()];
}

class NetResponseGrpcUnary extends NetResponseGrpc with AppSerialization {
  final List<int> data;
  final int code;
  final String? message;

  const NetResponseGrpcUnary._(
      {required this.data, required this.message, required this.code})
      : super(type: NetResponseType.grpcUnary);
  factory NetResponseGrpcUnary.error(
      {required int code, required String? message}) {
    return NetResponseGrpcUnary._(
        data: [],
        message: message?.isEmpty ?? true ? null : message,
        code: code);
  }
  factory NetResponseGrpcUnary.ok(List<int> data) {
    return NetResponseGrpcUnary._(data: data, message: null, code: -1);
  }
  factory NetResponseGrpcUnary.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseGrpcUnary,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseGrpcUnary._(
        data: values.rawValueAt(0),
        message: values.rawValueAt(1),
        code: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseGrpcUnary;
  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(data), message?.toCbor(), code.toCbor()];

  bool get isOk => code.isNegative;
}

/// HTTP
class NetResponseHttp extends NetResponseKind with AppSerialization {
  final int statusCode; // u16
  final List<int> body;
  final List<NetHttpHeader> headers;
  final int? streamId;
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  Map<String, String> headersMap() => Map<String, String>.fromEntries(
      headers.map((e) => MapEntry<String, String>(e.key, e.value)));

  NetResponseHttp copyWith(
      {int? statusCode,
      List<int>? body,
      List<NetHttpHeader>? headers,
      int? streamId}) {
    return NetResponseHttp(
        statusCode: statusCode ?? this.statusCode,
        body: body ?? this.body,
        headers: headers ?? this.headers,
        streamId: streamId ?? this.streamId);
  }

  const NetResponseHttp(
      {required this.statusCode,
      required this.body,
      required this.headers,
      this.streamId})
      : super(type: NetResponseType.http);

  factory NetResponseHttp.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseHttp,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseHttp(
        statusCode: values.rawValueAt(0),
        body: values.rawValueAt(1),
        headers: values
            .listAt<CborObject>(2)
            .map((e) => NetHttpHeader.deserialize(object: e))
            .toList(),
        streamId: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseHttp;

  @override
  List<CborObject?> get serializationItems => [
        statusCode.toCbor(),
        CborBytesValue(body),
        AppSerialization.listFromObjects(
            headers.map((e) => e.toCbor()).toList()),
        streamId?.toCbor()
      ];
}

///
sealed class NetResponseStream extends NetResponseKind with AppSerialization {
  final int? id;
  const NetResponseStream({required this.id, required super.type});
  factory NetResponseStream.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      OnChainBrdigeSerializationIdentifier.netResponseStreamClose,
      OnChainBrdigeSerializationIdentifier.netResponseStreamError,
      OnChainBrdigeSerializationIdentifier.netResponseStreamData,
    ], cborBytes: bytes, cborObject: object);
    return switch (decode.identifier) {
      OnChainBrdigeSerializationIdentifier.netResponseStreamClose =>
        NetResponseStreamClose.deserialize(object: decode.tag),
      OnChainBrdigeSerializationIdentifier.netResponseStreamError =>
        NetResponseStreamError.deserialize(object: decode.tag),
      OnChainBrdigeSerializationIdentifier.netResponseStreamData =>
        NetResponseStreamData.deserialize(object: decode.tag),
      _ => throw OnChainSerializationException(reason: "Unexpected identifier.")
    };
  }
}

class NetResponseStreamData extends NetResponseStream with AppSerialization {
  final List<int> data;
  const NetResponseStreamData({required this.data, super.id})
      : super(type: NetResponseType.streamData);
  factory NetResponseStreamData.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseStreamData,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseStreamData(
        id: values.rawValueAt(0), data: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseStreamData;

  @override
  List<CborObject?> get serializationItems =>
      [id?.toCbor(), CborBytesValue(data)];
}

class NetResponseStreamClose extends NetResponseStream {
  const NetResponseStreamClose({super.id})
      : super(type: NetResponseType.streamClose);
  factory NetResponseStreamClose.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseStreamClose,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseStreamClose(id: values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseStreamClose;

  @override
  List<CborObject?> get serializationItems => [id?.toCbor()];

  @override
  String toString() {
    return "NetResponseStreamClose($id)";
  }
}

class NetResponseStreamError extends NetResponseStream {
  final NetResultStatus error;
  final int code;
  final String? message;
  const NetResponseStreamError.error(
      {super.id, required this.error, this.code = -1, this.message})
      : super(type: NetResponseType.streamError);
  factory NetResponseStreamError.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseStreamError,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseStreamError.error(
        id: values.rawValueAt(0),
        error: NetResultStatus.fromValue(values.rawValueAt(1)),
        code: values.rawValueAt(2),
        message: values.rawValueAt(3));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseStreamError;
  @override
  List<CborObject?> get serializationItems =>
      [id?.toCbor(), error.value.toCbor(), code.toCbor(), message?.toCbor()];

  @override
  String toString() {
    return "NetResponseStreamError(${error.name})";
  }
}

class NetResponseError extends NetResponseKind with AppSerialization {
  final NetResultStatus error;
  const NetResponseError(this.error)
      : super(type: NetResponseType.responseError);
  factory NetResponseError.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseError,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseError(NetResultStatus.fromValue(values.rawValueAt(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseError;
  @override
  List<CborObject?> get serializationItems => [error.value.toCbor()];
}

class NetResponseClose extends NetResponseKind with AppSerialization {
  const NetResponseClose() : super(type: NetResponseType.transportClosed);
  factory NetResponseClose.deserialize({List<int>? bytes, CborObject? object}) {
    AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseClosed,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseClose();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseClosed;
  @override
  List<CborObject?> get serializationItems => [];
}

class NetResponseTorInited extends NetResponseKind with AppSerialization {
  final bool inited;
  const NetResponseTorInited(this.inited)
      : super(type: NetResponseType.torInited);
  factory NetResponseTorInited.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseTorInited,
        cborBytes: bytes,
        cborObject: object);
    return NetResponseTorInited(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponseTorInited;
  @override
  List<CborObject?> get serializationItems => [inited.toCbor()];

  @override
  String toString() {
    return "NetResponseTorInited($inited)";
  }
}

class NetResponse with AppSerialization {
  final int transportId;
  final int requestId;
  final NetResponseKind kind;

  NetResponse({
    required int transportId,
    required int requestId,
    required this.kind,
  })  : transportId = transportId.asU32,
        requestId = requestId.asU32;
  factory NetResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponse,
        cborBytes: bytes,
        cborObject: object);
    final kindValues = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.netResponseKind,
        cborObject: values.objectAt<CborTagValue>(2));
    final type = NetResponseType.fromValue(kindValues.rawValueAt(0));
    final kindTag = kindValues.objectAt<CborTagValue>(1);
    return NetResponse(
        transportId: values.rawValueAt(0),
        requestId: values.rawValueAt(1),
        kind: switch (type) {
          NetResponseType.socket =>
            NetResponseSocketStatus.deserialize(object: kindTag),
          NetResponseType.grpcUnary =>
            NetResponseGrpcUnary.deserialize(object: kindTag),
          NetResponseType.grpcSubscribe =>
            NetResponseGrpcSubscribe.deserialize(object: kindTag),
          NetResponseType.grpcUnsubscribe =>
            NetResponseGrpcUnsubscribe.deserialize(object: kindTag),
          NetResponseType.http => NetResponseHttp.deserialize(object: kindTag),
          NetResponseType.streamData =>
            NetResponseStreamData.deserialize(object: kindTag),
          NetResponseType.streamError =>
            NetResponseStreamError.deserialize(object: kindTag),
          NetResponseType.streamClose =>
            NetResponseStreamClose.deserialize(object: kindTag),
          NetResponseType.responseError =>
            NetResponseError.deserialize(object: kindTag),
          NetResponseType.transportClosed =>
            NetResponseClose.deserialize(object: kindTag),
          NetResponseType.torInited =>
            NetResponseTorInited.deserialize(object: kindTag),
        });
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netResponse;
  NetResponse copyWith({
    int? transportId,
    int? requestId,
    NetResponseKind? kind,
  }) {
    return NetResponse(
        transportId: transportId ?? this.transportId,
        requestId: requestId ?? this.requestId,
        kind: kind ?? this.kind);
  }

  @override
  List<CborObject?> get serializationItems => [
        transportId.toCbor(),
        requestId.toCbor(),
        CborTagValue(
            AppSerialization.listFromObjects(
                [kind.type.value.toCbor(), kind.toCbor()]),
            [OnChainBrdigeSerializationIdentifier.netResponseKind.id])
      ];
}

sealed class NetResponseKind with AppSerialization {
  final NetResponseType type;
  const NetResponseKind({required this.type});

  T cast<T extends NetResponseKind>() {
    if (this is! T) {
      throw CastFailedException();
    }
    return this as T;
  }
}

class NetResponseHttpStream {
  final Stream<List<int>> stream;
  final NetResponseHttp response;
  final int? contentLength;
  const NetResponseHttpStream(
      {required this.stream,
      required this.response,
      required this.contentLength});
  factory NetResponseHttpStream.fromResponse(
      Stream<List<int>> stream, NetResponseHttp response) {
    return NetResponseHttpStream(
        stream: stream,
        response: response,
        contentLength: response.headers.getContentLength());
  }
}
