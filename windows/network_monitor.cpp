// windows/network_monitor.cpp

#include "network_monitor.h"
#include <windows.h>
#include <netlistmgr.h>
#include <wrl/client.h>
#include <wrl/implements.h>

using Microsoft::WRL::ComPtr;

class NetworkEventSink : public Microsoft::WRL::RuntimeClass<
                             Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
                             INetworkListManagerEvents> {
 public:
  NetworkEventSink(std::function<void(bool)> callback) : callback_(callback) {}

  IFACEMETHODIMP ConnectivityChanged(NLM_CONNECTIVITY newConnectivity) override {
    bool connected = newConnectivity & (NLM_CONNECTIVITY_IPV4_INTERNET | NLM_CONNECTIVITY_IPV6_INTERNET);
    callback_(connected);
    return S_OK;
  }

 private:
  std::function<void(bool)> callback_;
};

NetworkMonitor::NetworkMonitor(flutter::PluginRegistrarWindows *registrar) : registrar_(registrar) {}

NetworkMonitor::~NetworkMonitor() {
  StopMonitoring();
}

void NetworkMonitor::StartMonitoring(std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink) {
  event_sink_ = std::move(sink);

  HRESULT hr = CoCreateInstance(CLSID_NetworkListManager, nullptr, CLSCTX_ALL,
                                IID_PPV_ARGS(&network_list_manager_));
  if (FAILED(hr)) return;

  ComPtr<IConnectionPointContainer> container;
  hr = network_list_manager_.As(&container);
  if (FAILED(hr)) return;

  ComPtr<IConnectionPoint> connection_point;
  hr = container->FindConnectionPoint(__uuidof(INetworkListManagerEvents), &connection_point);
  if (FAILED(hr)) return;

  auto event_handler = Microsoft::WRL::Make<NetworkEventSink>(
      [this](bool connected) {
        if (event_sink_) {
          event_sink_->Success(flutter::EncodableValue(connected ? "connected" : "disconnected"));
        }
      });

  hr = connection_point->Advise(event_handler.Get(), &cookie_);
}

void NetworkMonitor::StopMonitoring() {
  // Cleanup connection point if needed
}
