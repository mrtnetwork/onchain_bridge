package com.mrtnetwork.on_chain_bridge.authenticate
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import com.mrtnetwork.on_chain_bridge.OnChainCore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor


interface Authenticate : OnChainCore {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST") val args: Map<String, Any?> =
            call.arguments as Map<String, Any?>
        val type = args["type"] as String?
        when(type){
            "touch_id_status"->{
                val status = getBiometricStatus()
                result.success(status.value())
            }/// INVALID_ARGUMENT
            "authenticate"->{
                val reason = args["reason"] as String?
                val title = args["title"] as String?
                val buttonTitle = args["button_title"] as String?
                if(reason!=null){
                    var isActive: Boolean = true
                    authenticate(reason,title,buttonTitle) { auth ->
                        if (!isActive) return@authenticate // ignore if already handled
                        isActive = false
                        result.success(auth.value())
                    };
                }else{
                  result.error(OnChainCore.INVALID_ARGUMENTS, null, null)

                }
            }
            else -> result.error(OnChainCore.INVALID_ARGUMENTS, null, null)

        }

    }
    /** Detect biometric status, similar to macOS TouchIDStatus */
    fun getBiometricStatus(): BiometricStatus {
        val biometricManager = BiometricManager.from(applicationContext)
        return when (biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.BIOMETRIC_WEAK
        )) {
            BiometricManager.BIOMETRIC_SUCCESS -> BiometricStatus.AVAILABLE

            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> BiometricStatus.NOT_ENROLLED

            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> BiometricStatus.NOT_AVAILABLE

            else -> BiometricStatus.NOT_AVAILABLE
        }
    }

    fun authenticate(reason: String,  title:String? = null,buttonTitle:String?= null, callback: (BiometricResult) -> Unit,
                   ) {

        // Check if biometric is available
        if (getBiometricStatus() == BiometricStatus.NOT_AVAILABLE ) {
            callback(BiometricResult.NOT_AVAILABLE)
            return
        }

        val executor: Executor = ContextCompat.getMainExecutor(applicationContext)

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title?:title?: "Authenticate")
            .setSubtitle(reason)
            .setNegativeButtonText(buttonTitle?:buttonTitle?: "Cancel")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.BIOMETRIC_WEAK
            )
            .build()

        val biometricPrompt = BiometricPrompt(
            mainActivity as FragmentActivity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {

                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)

                    callback(BiometricResult.SUCCESS)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)

                    when (errorCode) {
                        BiometricPrompt.ERROR_CANCELED,
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_NEGATIVE_BUTTON -> callback(BiometricResult.CANCELLED)

                        BiometricPrompt.ERROR_LOCKOUT,
                        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> callback(BiometricResult.LOCKED_OUT)

                        else -> callback(BiometricResult.FAILED)
                    }
                }
            }
        )

        biometricPrompt.authenticate(promptInfo)
    }
}
