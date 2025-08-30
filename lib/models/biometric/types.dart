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
