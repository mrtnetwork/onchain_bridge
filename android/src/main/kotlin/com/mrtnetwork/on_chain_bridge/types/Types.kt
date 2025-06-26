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