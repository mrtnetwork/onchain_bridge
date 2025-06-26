// windows/network_monitor.h

#ifndef FLUTTER_PLUGIN_NETWORK_MONITOR_H_
#define FLUTTER_PLUGIN_NETWORK_MONITOR_H_

#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>
#include <wrl/client.h>
#include <netlistmgr.h>
#include <windows.h>

class NetworkMonitor {
 public:
  explicit NetworkMonitor(flutter::PluginRegistrarWindows *registrar);
  ~NetworkMonitor();

  void StartMonitoring(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink);
  void StopMonitoring();

 private:
  flutter::PluginRegistrarWindows *registrar_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  Microsoft::WRL::ComPtr<INetworkListManager> network_list_manager_;
  DWORD cookie_;
};

#endif  // FLUTTER_PLUGIN_NETWORK_MONITOR_H_
