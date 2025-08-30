import LocalAuthentication

enum TouchIDStatus: String {
    case available       // Touch ID ready to use
    case notEnrolled     // Hardware exists but no fingerprints
    case notAvailable    // No hardware or other issues
}
enum  BiometricResult: String {
    case success
    case cancelled
    case notAvailable
    case failed
    case lockedOut
}
extension LAContext {
    func touchIDStatus() -> TouchIDStatus {
        var error: NSError?

        // Check only biometric (Touch ID / Face ID)
        if self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .available
        }

        if let err = error as? LAError {
            switch err.code {
            case .biometryNotEnrolled:
                return .notEnrolled
            case .biometryNotAvailable, .biometryLockout:
                return .notAvailable
            default:
                return .notAvailable
            }
        }

        return .notAvailable
    }
    
    func authenticate(reason: String, completion: @escaping (BiometricResult) -> Void) {
        var error: NSError?
       

        if self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    if success {
                        completion(.success)
                    } else if let laError = evalError as? LAError {
                        switch laError.code {
                        case .userCancel, .systemCancel, .appCancel:
                            completion(.cancelled)
                        case .biometryLockout:
                            completion(.lockedOut)
                        case .biometryNotAvailable:
                            completion(.notAvailable)
                        default:
                            completion(.failed)
                        }
                    } else {
                        completion(.failed)
                    }
                }
            }
        } else {
            completion(.notAvailable)
        }
    }

}
