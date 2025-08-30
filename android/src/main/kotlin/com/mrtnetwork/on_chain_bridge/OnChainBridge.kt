package com.mrtnetwork.on_chain_bridge

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.WindowManager
import com.mrtnetwork.on_chain_bridge.encryptions.EncryptionImpl
import com.mrtnetwork.on_chain_bridge.webview.WebViewFactory
import com.mrtnetwork.on_chain_bridge.types.AppNativeEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.util.PathUtils
import android.content.BroadcastReceiver
import io.flutter.plugin.common.EventChannel
import android.net.ConnectivityManager
import android.net.NetworkInfo
import android.content.IntentFilter
import android.util.Log

class OnChainBridge : FlutterPlugin, MethodChannel.MethodCallHandler,EventChannel.StreamHandler, PluginService() {
    override lateinit var methodChannel: MethodChannel
    override lateinit var applicationContext: Context
    override var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var connectivityReceiver: BroadcastReceiver? = null

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false;
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data.toString()
            val event = AppNativeEvent(AppNativeEvent.EventType.DEEPLINK, uri)
            eventSink?.success(event.toJson())
        }
    }

    override var mainActivity: Activity? = null


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

        this.applicationContext = flutterPluginBinding.applicationContext

        this.methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger, "com.mrtnetwork.on_chain_bridge.methodChannel"
        )
        this.methodChannel.setMethodCallHandler(this)
        EncryptionImpl.init(applicationContext)
        this.flutterPluginBinding = flutterPluginBinding
        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.mrtnetwork.on_chain_bridge.methodChannel/network_status")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        unregisterReceiver()

    }
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerReceiver()
        // Send initial status
        sendNetworkStatus()
    }

    override fun onCancel(arguments: Any?) {
        unregisterReceiver()
        eventSink = null
    }

    private fun registerReceiver() {
        if (connectivityReceiver == null) {
            connectivityReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    sendNetworkStatus()
                }
            }
            val filter = IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION)
            applicationContext.registerReceiver(connectivityReceiver, filter)
        }
    }

    private fun unregisterReceiver() {
        if (connectivityReceiver != null) {
            applicationContext.unregisterReceiver(connectivityReceiver)
            connectivityReceiver = null
        }
    }

    private fun sendNetworkStatus() {
        val cm = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork: NetworkInfo? = cm.activeNetworkInfo
        val isConnected = activeNetwork?.isConnectedOrConnecting == true
        val event = AppNativeEvent(AppNativeEvent.EventType.INTERNET, true)
        eventSink?.success(event.toJson())
    }



    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "logging" -> {
            }

            "secureFlag" -> {
                val args: Map<String, Any?> = OnChainCore.getMapArguments(call, result) ?: return
                try {
                    val secure = args["secure"] as Boolean
                    val isSecure = secureApplication(secure)
                    result.success(isSecure)
                } catch (e: Exception) {
                    result.error("secureFlag", e.message, "")
                }
            }

            "path" -> result.success(getPath())
            "info" -> result.success(deviceInfo())
            "lunch_uri" -> {
                val args: Map<String, Any?> = OnChainCore.getMapArguments(call, result) ?: return
                result.success(lunchUrl(args["uri"] as String?))
            }
            else -> super.onMethodCall(call, result)

        }
    }


    private fun secureApplication(secure: Boolean): Boolean {
        if (secure) {
            mainActivity?.window?.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE
            )

        } else {
            mainActivity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        return secure
    }


    private fun lunchUrl(uri: String?): Boolean {
        try {

            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
            mainActivity!!.startActivity(browserIntent)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    @Suppress("DEPRECATION")
    private fun appVersion(): String? {
        val packageManager = applicationContext.packageManager
        val appInfo = packageManager.getPackageInfo(applicationContext.packageName, 0)
        return appInfo.versionName
    }

    private fun deviceInfo(): HashMap<String, Any?> {

        val info = HashMap<String, Any?>()
        info["brand"] = Build.BRAND
        info["device"] = Build.DEVICE
        info["display"] = Build.DISPLAY
        info["id"] = Build.ID
        info["model"] = Build.MODEL
        info["product"] = Build.PRODUCT
        info["app_version"] = appVersion()
        info["sdk_version"] = Build.VERSION.SDK_INT
        return info
    }

    private fun getPath(): HashMap<String, Any?> {

        val info = HashMap<String, Any?>()
        info["document"] = PathUtils.getDataDirectory(applicationContext)
        info["cache"] = applicationContext.cacheDir.path
        info["support"] = PathUtils.getFilesDir(applicationContext)
        return info
    }


}
