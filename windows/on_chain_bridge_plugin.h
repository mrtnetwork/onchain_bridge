#ifndef FLUTTER_PLUGIN_ON_CHAIN_BRIDGE_PLUGIN_H_
#define FLUTTER_PLUGIN_ON_CHAIN_BRIDGE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

// This must be included before many other Windows headers.
#include <windows.h>
#include <dwmapi.h>
#include <shobjidl.h>
#include <wincred.h>
#include <atlstr.h>
#include <ShlObj_core.h>
#include <sys/stat.h>
#include <errno.h>
#include <direct.h>
#include <bcrypt.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <map>
#include <memory>
#include <sstream>
#include <iostream>
#include <fstream>
#include <string>
#include <regex>
#include <Shellapi.h>
#include <comutil.h>
#include <atomic>
#include <mutex>
#include <netlistmgr.h>
#include <atlbase.h>
#include <atlcomcli.h>
#include "include/storage.hpp"
#include "include/windows_manager.hpp"
#pragma comment(lib, "version.lib")
#pragma comment(lib, "bcrypt.lib")
#pragma comment(lib, "ole32.lib")

namespace on_chain_bridge
{
    class NetworkEvents;
    class NetworkStreamHandler;
    class OnChainBridge : public flutter::Plugin
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
        OnChainBridge(flutter::PluginRegistrarWindows *registrar);
        virtual ~OnChainBridge();
        // Disallow copy and assign.
        OnChainBridge(const OnChainBridge &) = delete;
        OnChainBridge &operator=(const OnChainBridge &) = delete;
        flutter::PluginRegistrarWindows *registrar;
        std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
        std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
        std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> stream_handler_;
        std::mutex sink_mutex_;
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
        CComPtr<INetworkListManager> network_manager_;
        CComPtr<IConnectionPoint> connection_point_;
        DWORD cookie_ = 0;
        NetworkEvents *events_handler_ = nullptr;
        bool IsInternetConnected();
        Storage storage;
        WindowsManager *windows_manager = nullptr;

    private:
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        // Gets the string name for the given int error code
        std::string GetErrorString(const DWORD &error_code);
    };

}

#endif
