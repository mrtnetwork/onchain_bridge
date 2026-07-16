import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/serialization/cbor/cbor.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class OnChainSerializationException extends BaseOnChainBridgeException {
  const OnChainSerializationException._(super.message, {super.details});
  OnChainSerializationException({String? reason, Map<String, String?>? details})
      : super("invalid_serialization_data",
            details: {"reason": reason, ...details ?? {}});

  factory OnChainSerializationException.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.serializationError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return OnChainSerializationException._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.serializationError;
}
