import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class IDatabaseException extends BaseOnChainBridgeException {
  const IDatabaseException._(super.message, {super.details});
  static IDatabaseException unexpected(String? reason) =>
      IDatabaseException._("database_unexpected_error",
          details: {"reason": reason});
  static IDatabaseException get unsupportedPlatform =>
      const IDatabaseException._("unsupported_platform");
  static IDatabaseException get misingDatabaseLiberary =>
      const IDatabaseException._("mising_database_liberary");
  static const onDatabaseBlockError =
      IDatabaseException._("IndexedDB upgrade blocked.");
  static const unableToUpgradeDatabase =
      IDatabaseException._("Database upgrade failed.");
  factory IDatabaseException.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.databaseError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return IDatabaseException._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.databaseError;
}
