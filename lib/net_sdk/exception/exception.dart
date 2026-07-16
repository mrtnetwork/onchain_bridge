import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

class NetSdkException extends BaseOnChainBridgeException {
  final NetResultStatus error;

  NetSdkException(this.error, {super.details}) : super(error.dsecription);
  static NetSdkException get internalError {
    return NetSdkException(NetResultStatus.internalError);
  }

  factory NetSdkException.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.netSdkError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return NetSdkException(
      NetResultStatus.fromValue(values.rawValueAt(0)),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.netSdkError;

  @override
  List<dynamic> get variables => [error];
}
