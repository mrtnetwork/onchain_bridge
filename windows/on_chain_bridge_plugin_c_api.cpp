#include "include/on_chain_bridge/on_chain_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "on_chain_bridge_plugin.h"
// #include "on_chain_bridge_plugin_c_api.h"

void OnChainBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  on_chain_bridge::OnChainBridge::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

