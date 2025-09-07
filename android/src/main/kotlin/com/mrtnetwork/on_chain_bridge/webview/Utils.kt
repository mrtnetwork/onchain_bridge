package com.mrtnetwork.on_chain_bridge.webview
import android.webkit.WebView

interface WebViewUtils {
    companion object {
        fun String.decodeHex(): List<Int>? {
            if (length % 2 != 0) return null
            return chunked(2)
                .map { it.toInt(16) }
                .toList()
        }

        fun toJson(
            id: String,
            eventName: String,
            view: WebView? = null,
            message: String? = null,
            url: String? = null,
            favicon: String? = null,
            progress: Int? = null,
            request: WebViewRequest? = null
        ): WebViewData {
            return WebViewData(
                id,
                eventName,
                url ?: view?.url,
                favicon,
                view?.originalUrl,
                view?.title,
                message,
                progress,
                request
            )
        }
    }
}