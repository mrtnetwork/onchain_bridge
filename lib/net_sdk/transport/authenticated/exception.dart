import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/serialization/cbor/cbor.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class HttpDigestAuthenticatedError extends BaseOnChainBridgeException {
  const HttpDigestAuthenticatedError._(super.message);
  static HttpDigestAuthenticatedError get invalidOrUnsuportedDigestAuth =>
      HttpDigestAuthenticatedError._("invalid_or_unsuported_dgiest_auth");

  factory HttpDigestAuthenticatedError.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.digestAuthError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return HttpDigestAuthenticatedError._(values.rawValueAt(0));
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.digestAuthError;
}
