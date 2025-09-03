import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/exception/exception.dart';

enum TouchIdStatus {
  available,
  notEnrolled,
  notAvailable;

  static TouchIdStatus fromName(String? v) {
    return values.firstWhere((e) => e.name == v,
        orElse: () => throw OnChainBridgeException("Invalid touch id status."));
  }
}

enum BiometricResult {
  success,
  cancelled,
  notAvailable,
  failed,
  lockedOut;

  static BiometricResult fromName(String? v) {
    return values.firstWhere((e) => e.name == v,
        orElse: () =>
            throw OnChainBridgeException("Invalid biometric result."));
  }
}

class PlatformCredentialRequest {
  final String appName;
  final String name;
  final String displayName;
  final List<int> accountId;
  final String? title;
  final String? buttonTitle;
  final String reason;
  PlatformCredentialRequest(
      {required this.name,
      required this.appName,
      required this.displayName,
      required this.accountId,
      this.title,
      this.buttonTitle,
      required this.reason});
}

class PlatformCredentialWebResponse implements PlatformCredentialResponse {
  final String id;
  final String publicKey;
  const PlatformCredentialWebResponse(
      {required this.id, required this.publicKey});
}

abstract class PlatformCredentialResponse {}

class PlatformCredentialIoResponse implements PlatformCredentialResponse {}

abstract class PlatformCredentialAutneticateRequest<T> {
  final String? title;
  final String? buttonTitle;
  final String reason;
  const PlatformCredentialAutneticateRequest(
      {this.title, this.buttonTitle, required this.reason});
  Future<BiometricResult> verify(T response);
}

class PlatformCredentialAutneticateIoRequest
    extends PlatformCredentialAutneticateRequest<BiometricResult> {
  PlatformCredentialAutneticateIoRequest(
      {required super.reason, super.buttonTitle, super.title});

  @override
  Future<BiometricResult> verify(BiometricResult response) async {
    return response;
  }
}

class InternalPublicKeyWebAuthResponse {
  final List<int> authenticatorData;
  final List<int> clientDataJSON;
  final List<int> signature;
  InternalPublicKeyWebAuthResponse({
    required List<int> authenticatorData,
    required List<int> clientDataJSON,
    required List<int> signature,
  })  : authenticatorData = authenticatorData.asImmutableBytes,
        clientDataJSON = clientDataJSON.asImmutableBytes,
        signature = signature.asImmutableBytes;
}

class PlatformCredentialAutneticateWebRequest
    extends PlatformCredentialAutneticateRequest<
        InternalPublicKeyWebAuthResponse> {
  PlatformCredentialAutneticateWebRequest(
      {required List<int> id,
      required super.reason,
      required List<int> challange,
      super.buttonTitle,
      super.title})
      : challange = challange.asImmutableBytes,
        id = id.asImmutableBytes;
  final List<int> id;
  final List<int> challange;
  @override
  Future<BiometricResult> verify(
      InternalPublicKeyWebAuthResponse response) async {
    return BiometricResult.success;
  }
}
