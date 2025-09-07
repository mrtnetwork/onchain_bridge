package com.mrtnetwork.on_chain_bridge

import android.app.Activity
import android.content.Context
import androidx.lifecycle.MutableLiveData
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel






interface OnChainCore{
    companion object {



        fun logging(message: String, tag: String? = null) {
            Log.e("on_chain_wallet",message)
        }
        const val REQUEST_CODE_PICK_FILE = 1001
        const val REQUEST_CODE_PICK_DIRECTORY = 2001
        const val REQUEST_CODE_SCAN = 49374;
        const val BARCODE_SUCCESS_TYPE = "success"
        const val BARCODE_SUCCESS_ERROR = "error"
        const val BARCODE_SUCCESS_CANCEL = "cancel"
        const val BARCODE_CHANNEL_RESPONSE_EVENT = "onBarcodeScanned"

        const val INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
        const val INTERNAL_ERROR = "INTERNAL_ERROR"

        @Suppress("UNCHECKED_CAST")
        fun getMapArguments(call: MethodCall, result: MethodChannel.Result): Map<String, Any?>? {
            return try {
                call.arguments as? Map<String, Any?>
            } catch (e: Exception) {
                result.error(
                    "ARGUMENT_CAST_ERROR",
                    "Failed to cast arguments to Map<String, Any?>",
                    e.localizedMessage
                )
                null
            }
        }


    }


    fun onMethodCall(call: MethodCall, result: MethodChannel.Result)
    var methodChannel: MethodChannel
    var mainActivity: Activity?
    var applicationContext: Context
    var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?
    fun getCachePath(): String;

}


