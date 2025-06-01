#include "include/onchain_bridge/onchain_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "onchain_bridge_plugin.h"

void OnChainBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  onchain_bridge::OnChainBridge::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
