import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/networks/types/network.dart';
import 'package:on_chain_bridge/database/exception/exception.dart';
import 'package:on_chain_bridge/models/barcode/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/authenticated/exception.dart';
import 'package:on_chain_bridge/serialization/src/exception.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

abstract class BaseOnChainBridgeException extends IException {
  const BaseOnChainBridgeException(super.message, {super.details});

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier;
  factory BaseOnChainBridgeException.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(
      expectedTags: OnChainBrdigeSerializationIdentifier.values,
      cborBytes: bytes,
      cborObject: obj,
    );
    final identifier = values.identifier;
    return switch (identifier) {
      OnChainBrdigeSerializationIdentifier.bridgePluginError =>
        OnChainBridgeException.deserialize(obj: values.tag),
      OnChainBrdigeSerializationIdentifier.databaseError =>
        IDatabaseException.deserialize(obj: values.tag),
      OnChainBrdigeSerializationIdentifier.netSdkError =>
        NetSdkException.deserialize(obj: values.tag),
      OnChainBrdigeSerializationIdentifier.digestAuthError =>
        HttpDigestAuthenticatedError.deserialize(obj: values.tag),
      OnChainBrdigeSerializationIdentifier.barcodeError =>
        BarcodeException.deserialize(obj: values.tag),
      OnChainBrdigeSerializationIdentifier.serializationError =>
        OnChainSerializationException.deserialize(obj: values.tag),
      _ => throw OnChainSerializationException(
          reason: "Unknown exception identifier",
          details: {"identifier": identifier.name})
    };
  }

  @override
  BlockchainNetwork? get relatedNetwork => null;
}

class OnChainBridgeException extends BaseOnChainBridgeException {
  const OnChainBridgeException._(super.message, {super.details});
  static OnChainBridgeException unsuported =
      const OnChainBridgeException._("unsuported_feature");
  static OnChainBridgeException unsuportedPlatform =
      const OnChainBridgeException._("unsupported_platform");
  static OnChainBridgeException pathUnexpectedError =
      const OnChainBridgeException._("path_unexpected_error");
  static OnChainBridgeException unexpectedBiometricResult =
      const OnChainBridgeException._("path_unexpected_error");
  static OnChainBridgeException unexpectedError =
      const OnChainBridgeException._("unexpected_error");

  ///

  static OnChainBridgeException invalidFileData =
      const OnChainBridgeException._("failed_to_read_content");

  static OnChainBridgeException invalidApiState =
      const OnChainBridgeException._("invalid_api_state");
  static OnChainBridgeException invalidAppConfigResources =
      const OnChainBridgeException._("invalid_app_config_resources");
  static OnChainBridgeException fileDoesNotExists =
      const OnChainBridgeException._("file_does_not_exist");

  static OnChainBridgeException fileReadPlatformError =
      const OnChainBridgeException._(
          "failed_read_file_content_due_platform_error");
  factory OnChainBridgeException.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
      identifier: OnChainBrdigeSerializationIdentifier.bridgePluginError,
      cborBytes: bytes,
      cborObject: obj,
    );
    return OnChainBridgeException._(
      values.rawValueAt(0),
      details: values.maybeRawMapAt<String, String?>(1),
    );
  }

  @override
  OnChainBrdigeSerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.bridgePluginError;
}
