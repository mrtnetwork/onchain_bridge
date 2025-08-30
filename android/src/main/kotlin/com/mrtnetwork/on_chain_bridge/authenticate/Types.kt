package com.mrtnetwork.on_chain_bridge.authenticate

enum class BiometricStatus {
    AVAILABLE,       // Biometric hardware exists and ready to use
    NOT_ENROLLED,    // Hardware exists but no biometrics enrolled
    NOT_AVAILABLE;   // No hardware or unsupported device

     fun value(): String = when(this) {
        AVAILABLE -> "available"
        NOT_ENROLLED -> "notEnrolled"
        NOT_AVAILABLE -> "notAvailable"
    }
}

enum class BiometricResult {
    SUCCESS,
    CANCELLED,
    NOT_AVAILABLE,
    FAILED,
    LOCKED_OUT;

     fun value(): String = when(this) {
        SUCCESS -> "success"
        CANCELLED -> "cancelled"
        NOT_AVAILABLE -> "notAvailable"
        FAILED -> "failed"
        LOCKED_OUT -> "lockedOut"
    }
}