import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class AppSerializationBinary with AppSerialization {
  final List<int> data;
  AppSerializationBinary(List<int> data) : data = data.asImmutableBytes;

  factory AppSerializationBinary.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.binarySerialization,
        cborBytes: bytes,
        cborObject: obj);
    return AppSerializationBinary(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.binarySerialization;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(data)];
}

class AppSerializationString with AppSerialization {
  final String data;
  const AppSerializationString(this.data);

  factory AppSerializationString.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.stringSerialization,
        cborBytes: bytes,
        cborObject: obj);
    return AppSerializationString(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.stringSerialization;

  @override
  List<CborObject?> get serializationItems => [data.toCbor()];
}

class AppSerializationBoolean with AppSerialization {
  final bool data;
  const AppSerializationBoolean(this.data);

  factory AppSerializationBoolean.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.booleanSerialization,
        cborBytes: bytes,
        cborObject: obj);
    return AppSerializationBoolean(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.booleanSerialization;

  @override
  List<CborObject?> get serializationItems => [data.toCbor()];
}

class AppSerializationBigInt with AppSerialization {
  final BigInt data;
  const AppSerializationBigInt(this.data);

  factory AppSerializationBigInt.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.bigintSerialization,
        cborBytes: bytes,
        cborObject: obj);

    return AppSerializationBigInt(values.rawValueAt(0));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.bigintSerialization;

  @override
  List<CborObject?> get serializationItems => [data.toCbor()];
}
