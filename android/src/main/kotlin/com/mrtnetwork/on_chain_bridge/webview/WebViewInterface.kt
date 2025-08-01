package com.mrtnetwork.on_chain_bridge.webview

import com.mrtnetwork.on_chain_bridge.OnChainCore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

interface WebViewInterface : OnChainCore {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val args: Map<String, Any?> = OnChainCore.getMapArguments(call, result) ?: return
        val type: String = args["type"] as String? ?: return
        when (type) {
            WebViewConst.createWebView -> {
                result.success(
                    WebViewHandlers.initFactory(
                        args,
                        methodChannel,
                        applicationContext,
                        flutterPluginBinding
                    )
                )
            }

            else -> {
                val webViewFactory = WebViewHandlers.getWebView(args)
                if (webViewFactory == null) {
                    result.error("-1", "webView factory not found", null)
                    return
                }
                when (type) {
                    WebViewConst.openPage -> {
                        val url: String? = args["url"] as String?
                        if (url == null) {
                            result.error("-1", "url missing", null)
                            return
                        }
                        webViewFactory.openPage(url);
                        result.success(true)
                    }

                    WebViewConst.addInterface -> {
                        val name: String? = args["name"] as String?
                        if (name == null) {
                            result.error("-1", "interface name missing", null)
                            return
                        }
                        webViewFactory.addJsInterface(name)
                        result.success(true)
                    }
                    WebViewConst.dispose -> {
                        result.success(null)
                    }

                    WebViewConst.removeInterface -> {
                        val name: String? = args["name"] as String?
                        if (name == null) {
                            result.error("-1", "interface name missing", null)
                            return
                        }
                        webViewFactory.removeJsInterface(name)
                        result.success(true)
                    }

                    WebViewConst.canGoForward -> {
                        result.success(webViewFactory.canGoForward() ?: false)
                    }

                    WebViewConst.canGoBack -> {
                        result.success(webViewFactory.canGoBack() ?: false)
                    }

                    WebViewConst.goBack -> {
                        webViewFactory.goBack()
                        result.success(null)
                    }

                    WebViewConst.goForward -> {
                        webViewFactory.goForward()
                        result.success(null)
                    }

                    WebViewConst.reload -> {
                        webViewFactory.reload()
                        result.success(null)
                    }
                    WebViewConst.clearCache -> {
                        webViewFactory.clearCache()
                        result.success(null)
                    }
                    WebViewConst.injectJavaScript -> {
                        val script: String? = args["script"] as String?
                        if (script == null) {
                            result.error("-1", "script missing", null)
                            return
                        }
                        webViewFactory.injectJavaScript(script, object : Callback<String?> {
                            override fun onSuccess(data: String?) {
                                result.success(data)
                            }

                            override fun onFailure(message: String) {
                                result.error("-1", message, null)
                            }

                        })
                    }
                }

            }
        }
    }

}
