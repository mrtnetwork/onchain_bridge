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
import com.mrtnetwork.on_chain_bridge.types.FilePickCallback
import com.mrtnetwork.on_chain_bridge.webview.WebViewInterface
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.service.ServiceAware
import io.flutter.embedding.engine.plugins.service.ServicePluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import com.mrtnetwork.on_chain_bridge.types.WriteFileInterface


abstract class PluginService : ActivityAware, EncryptionImpl, ShareImpl, WebViewInterface,
    PluginRegistry.NewIntentListener, ServiceAware, ActivityResultListener, Authenticate{
    private var writeFileCallBack: WriteFileInterface? = null
    private var filePickCallback: FilePickCallback? = null

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mainActivity = binding.activity
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)


    }




    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST") val args: Map<String, Any?> =
            call.arguments as Map<String, Any?>
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
            "pick_file"->{
                val mimeType = args["mime_type"] as String?
                if(filePickCallback!=null){
                    result.error(OnChainCore.INTERNAL_ERROR, null, null)
                    return
                }
                openFilePicker(object : FilePickCallback {
                    override val mimeType: String? = mimeType
                    override fun onFilePicked(filePath: String) {
                        result.success(filePath)
                    }

                    override fun onCancelled() {
                        result.success(null)
                    }

                    override fun onError(errorMessage: String) {
                        result.error(OnChainCore.INTERNAL_ERROR, errorMessage, null)
                    }
                })
            }
            "save_file"->{
                val fileName = args["file_name"] as String?
                val filePath = args["file_path"] as String?
                val extension = args["extension"] as String?
                val mimeType = args["mime_type"] as String?
                if(fileName==null || filePath == null ||mimeType == null || extension ==null){
                    result.error(OnChainCore.INVALID_ARGUMENTS, null, null)
                    return
                }
                if(writeFileCallBack!=null){
                    result.error(OnChainCore.INTERNAL_ERROR, null, null)
                    return
                }
                val writeFileCallBack = object : WriteFileInterface {
                    override var filePath: String = filePath
                    override var fileName: String = fileName
                    override var extension: String = extension
                    override var mimeType: String = mimeType
                    override fun onPicked(success: Boolean) {
                        result.success(success)
                    }

                    override fun onError(errorMessage: String) {
                        result.error(OnChainCore.INTERNAL_ERROR, errorMessage, null)
                    }
                }
                pickDirectory(writeFileCallBack)
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
      return  when(requestCode){
            OnChainCore.REQUEST_CODE_SCAN-> onScannerActivityResult(requestCode,resultCode,data)
            OnChainCore.REQUEST_CODE_PICK_FILE-> onPickFileActivityResult(requestCode,resultCode,data)
            OnChainCore.REQUEST_CODE_PICK_DIRECTORY-> onPickDirectoryActivityResult(requestCode,resultCode,data)
            else -> false
        }
    }

    private  fun onScannerActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean{
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

    private  fun onPickFileActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean{
        val callback = filePickCallback ?: return false
        filePickCallback = null // reset
        when (resultCode) {
            RESULT_OK -> {
                val uri: Uri? = data?.data
                if(uri!=null){
                    try {

                        val path = copyUriToTempFile(uri)
                        callback.onFilePicked(path)
                    } catch (e: Exception) {
                        callback.onError(e.localizedMessage ?: "Unknown error")
                    }
                }else{
                    callback.onCancelled()
                }
            }
            else -> {
                callback.onCancelled()
            }
        }
        return true
    }


    private  fun onPickDirectoryActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean{
        val callback = writeFileCallBack ?: return false
        writeFileCallBack = null
        when (resultCode) {
            RESULT_OK -> {
                val treeUri: Uri? = data?.data;
                if(treeUri!=null){
                    try {
                        val takeFlags = Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                      applicationContext.contentResolver.takePersistableUriPermission(treeUri, takeFlags)

                        val pickedDir = DocumentFile.fromTreeUri(applicationContext, treeUri)
                        var fileName = callback.fileName
                        var counter = 1

// Generate unique file name if already exists
                        while (pickedDir?.findFile(fileName) != null) {
                            val name = callback.fileName.substringBeforeLast(".")
                            val ext = callback.fileName.substringAfterLast(".", "")
                            fileName = "$name ($counter).$ext"
                            counter++
                        }
                        val newFile = pickedDir?.createFile(callback.mimeType, fileName)
                        newFile?.uri?.let {fileUri->
                            applicationContext.contentResolver.openOutputStream(fileUri).use { output ->
                                File(callback.filePath).inputStream().use { input ->
                                    input.copyTo(output!!)
                                }
                            }
                            callback.onPicked(true)
                        }
                    } catch (e: Exception) {
                        callback.onError(e.localizedMessage ?: "Unknown error")
                    }
                }else{
                    callback.onPicked(false)
                }
            }
            else -> {
                callback.onPicked(false)
            }
        }
        return true
    }

    private fun openFilePicker(callback: FilePickCallback) {
        filePickCallback = callback
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = callback.mimeType?:"*/*"
        }
        mainActivity?. startActivityForResult(intent, OnChainCore.REQUEST_CODE_PICK_FILE)
    }

    private fun copyUriToTempFile(uri: Uri): String {
        val tempFile = File(getCachePath(), "picked_file_${System.currentTimeMillis()}")
       applicationContext. contentResolver.openInputStream(uri).use { input ->
            tempFile.outputStream().use { output ->
                input?.copyTo(output)
            }
        }
        return tempFile.absolutePath
    }

    private fun pickDirectory(callback: WriteFileInterface) {
        writeFileCallBack = callback
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        mainActivity?.startActivityForResult(intent, OnChainCore. REQUEST_CODE_PICK_DIRECTORY)
    }
}

