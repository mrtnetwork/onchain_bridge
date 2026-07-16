import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

class BarcodeException extends BaseOnChainBridgeException {
  const BarcodeException._(super.message);
  static BarcodeException get serviceAlreadyRunnig =>
      BarcodeException._("service_alraedy_running");

  factory BarcodeException.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.barcodeError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return BarcodeException._(values.rawValueAt(0));
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.barcodeError;
}
