package com.mrtnetwork.on_chain_bridge

import android.companion.CompanionDeviceManager.RESULT_CANCELED
import android.companion.CompanionDeviceManager.RESULT_OK
import android.content.Intent
import androidx.biometric.BiometricPrompt
import com.google.zxing.client.android.Intents
import com.journeyapps.barcodescanner.ScanOptions
import com.mrtnetwork.on_chain_bridge.authenticate.Authenticate
import com.mrtnetwork.on_chain_bridge.barcode.CaptureActivityPortrait
import com.mrtnetwork.on_chain_bridge.encryptions.EncryptionImpl
import com.mrtnetwork.on_chain_bridge.share.ShareImpl
import com.mrtnetwork.on_chain_bridge.webview.WebViewInterface
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.service.ServiceAware
import io.flutter.embedding.engine.plugins.service.ServicePluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener


abstract class PluginService : ActivityAware, EncryptionImpl, ShareImpl, WebViewInterface,
    PluginRegistry.NewIntentListener, ServiceAware, ActivityResultListener, Authenticate{


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mainActivity = binding.activity
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)


    }




    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "secureStorage" -> {
                super<EncryptionImpl>.onMethodCall(call, result)
            }

            "share" -> {
                super<ShareImpl>.onMethodCall(call, result)
            }

            "stopBarcodeScanner" -> {
                result.success(true);
            }

            "startBarcodeScanner" -> {
                barcodeScan(result);
            }
            "webView"-> {
                super<WebViewInterface>.onMethodCall(call, result)
            }
            "authenticate"-> {
                super<Authenticate>.onMethodCall(call, result)
            }
        }

    }

    override fun onDetachedFromActivityForConfigChanges() {
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        binding.addOnNewIntentListener(this)
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mainActivity = null

    }

    override fun onAttachedToService(binding: ServicePluginBinding) {
    }


    override fun onDetachedFromService() {
    }



    private fun barcodeScan(result: MethodChannel.Result) {
        try {
            val options = ScanOptions()
            options.setCaptureActivity(CaptureActivityPortrait::class.java)
            options.setPrompt("Barcode scan")
            options.setBeepEnabled(true)
            val intent = options.createScanIntent(mainActivity)
            mainActivity?.startActivityForResult(intent, OnChainCore.REQUEST_CODE_SCAN)
            result.success(true)
        } catch (e: Exception) {
            result.error("BARCODE_SCAN_ERROR", "Error occurred during barcode scan", e.localizedMessage)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == OnChainCore.REQUEST_CODE_SCAN) {
            val info = HashMap<String, Any?>()
            when (resultCode) {
                RESULT_OK -> {
                    info["type"] = OnChainCore.BARCODE_SUCCESS_TYPE
                    val contents: String? = data?.getStringExtra(Intents.Scan.RESULT)
                    info["message"] = contents
                }

                RESULT_CANCELED -> {
                    info["type"] = OnChainCore.BARCODE_SUCCESS_CANCEL
                }
                else -> {
                    info["type"] = OnChainCore.BARCODE_SUCCESS_ERROR
                }
            }
            methodChannel.invokeMethod(OnChainCore.BARCODE_CHANNEL_RESPONSE_EVENT,info)
            return true
        }
        return false
    }

}

