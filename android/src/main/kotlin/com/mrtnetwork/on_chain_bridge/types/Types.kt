package com.mrtnetwork.on_chain_bridge.types


data class AppNativeEvent(
    val type: EventType,
    val value: Any?
) {
    fun toJson(): HashMap<String, Any?> {
        return hashMapOf(
            "type" to type.name.lowercase(),
            "value" to value
        )
    }

    enum class EventType {
        INTERNET,
        DEEPLINK
    }
}



interface FilePickCallback {

    val mimeType: String?
    fun onFilePicked(filePath: String)
    fun onCancelled()
    fun onError(errorMessage: String)
}

interface WriteFileInterface {
    val filePath: String
    val fileName: String
    val extension: String

    val mimeType: String
    fun onPicked(success: Boolean)
    fun onError(errorMessage: String)
}