import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/src/exception.dart';

abstract mixin class AppSerialization implements CborTagSerializable {
  @override
  SerializationIdentifier get serializationIdentifier;
  @override
  List<CborObject?> get serializationItems;
  @override
  CborTagValue toCbor() => CborTagValue(
      listFromObjects(serializationItems), [serializationIdentifier.id]);
  static CborObject bytesToCbor(List<int>? bytes) {
    if (bytes == null) return CborNullValue();
    return CborBytesValue(bytes);
  }

  static CborListValue decodeTaggedValue({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
    required SerializationIdentifier? identifier,
  }) {
    try {
      return CborTagSerializable.decodeTaggedValue(
          identifier: identifier,
          cborBytes: cborBytes,
          cborHex: cborHex,
          cborObject: cborObject);
    } catch (e) {
      throw OnChainSerializationException(reason: e.toString(), details: {
        "identifier": identifier.toString(),
      });
    }
  }

  static DecodeTaggedValue<IDENTIFIER>
      decodeTaggedValueWithInfo<IDENTIFIER extends SerializationIdentifier>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
    required List<IDENTIFIER> expectedTags,
  }) {
    try {
      return CborTagSerializable.decodeTaggedValueWithInfo<IDENTIFIER>(
          expectedTags: expectedTags,
          cborBytes: cborBytes,
          cborHex: cborHex,
          cborObject: cborObject);
    } on CborSerializableException catch (e) {
      throw OnChainSerializationException(reason: e.toString(), details: {
        "identifiers": expectedTags.map((e) => e.toString()).join(", "),
        ...e.details
                ?.map((k, v) => MapEntry<String, String>(k, v.toString())) ??
            {}
      });
    } catch (e) {
      throw OnChainSerializationException(reason: e.toString(), details: {
        "identifiers": expectedTags.map((e) => e.toString()).join(", "),
      });
    }
  }

  static T decode<T extends CborObject>({
    List<int>? cborBytes,
    CborObject? cborObject,
    String? cborHex,
  }) {
    try {
      return CborTagSerializable.decode(
          cborBytes: cborBytes, cborHex: cborHex, cborObject: cborObject);
    } catch (e) {
      throw OnChainSerializationException(reason: e.toString());
    }
  }

  static CborListValue listFromObjects(List<CborObject?> items) {
    return CborTagSerializable.listFromDynamic(items);
  }
}
