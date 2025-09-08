#include "on_chain_bridge_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "include/biometric.hpp"
namespace on_chain_bridge
{

	class NetworkEvents : public INetworkListManagerEvents
	{
	public:
		NetworkEvents(std::function<void(bool)> callback) : callback_(callback), ref_count_(1) {}

		STDMETHODIMP QueryInterface(REFIID riid, void **ppv)
		{
			if (riid == IID_IUnknown || riid == IID_INetworkListManagerEvents)
			{
				*ppv = static_cast<INetworkListManagerEvents *>(this);
				AddRef();
				return S_OK;
			}
			*ppv = nullptr;
			return E_NOINTERFACE;
		}

		STDMETHODIMP_(ULONG)
		AddRef()
		{
			return ++ref_count_;
		}

		STDMETHODIMP_(ULONG)
		Release()
		{
			ULONG res = --ref_count_;
			if (res == 0)
			{
				delete this;
			}
			return res;
		}

		STDMETHODIMP ConnectivityChanged(NLM_CONNECTIVITY newConnectivity)
		{
			bool connected = (newConnectivity & (NLM_CONNECTIVITY_IPV4_INTERNET | NLM_CONNECTIVITY_IPV6_INTERNET)) != 0;
			callback_(connected);
			return S_OK;
		}

	private:
		std::function<void(bool)> callback_;
		std::atomic<ULONG> ref_count_;
	};
	class NetworkStreamHandler : public flutter::StreamHandler<flutter::EncodableValue>
	{
	public:
		explicit NetworkStreamHandler(OnChainBridge *plugin) : plugin_(plugin) {}

	protected:
		std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
			const flutter::EncodableValue *arguments,
			std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) override
		{

			{
				std::lock_guard<std::mutex> lock(plugin_->sink_mutex_);
				plugin_->event_sink_ = std::move(events);
			}

			bool connected = plugin_->IsInternetConnected();
			if (plugin_->event_sink_)
			{
				flutter::EncodableMap event_data = {
					{flutter::EncodableValue("type"), flutter::EncodableValue("internet")},
					{flutter::EncodableValue("value"), flutter::EncodableValue(connected)}};
				plugin_->event_sink_->Success(flutter::EncodableValue(event_data));
			}

			return nullptr;
		}

		std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
			const flutter::EncodableValue *arguments) override
		{

			std::lock_guard<std::mutex> lock(plugin_->sink_mutex_);
			plugin_->event_sink_.reset();
			return nullptr;
		}

	private:
		OnChainBridge *plugin_;
	};

	// static
	void OnChainBridge::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows *registrar)
	{

		auto plugin = std::make_unique<OnChainBridge>(registrar);

		registrar->AddPlugin(std::move(plugin));
	}

	OnChainBridge::OnChainBridge(flutter::PluginRegistrarWindows *registrar) : registrar(registrar)
	{

		channel_ =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(registrar->messenger(),
																			  "com.mrtnetwork.on_chain_bridge.methodChannel",
																			  &flutter::StandardMethodCodec::GetInstance());
		channel_->SetMethodCallHandler(
			[this](const auto &call, auto result)
			{
				HandleMethodCall(call, std::move(result));
			});
		windows_manager = new WindowsManager(registrar, channel_.get());

		stream_handler_ = std::make_unique<NetworkStreamHandler>(this);
		event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
			registrar->messenger(),
			"com.mrtnetwork.on_chain_bridge.methodChannel/network_status",
			&flutter::StandardMethodCodec::GetInstance());

		event_channel_->SetStreamHandler(std::move(stream_handler_));
		if (SUCCEEDED(CoCreateInstance(CLSID_NetworkListManager, nullptr, CLSCTX_ALL, IID_PPV_ARGS(&network_manager_))))
		{
			CComPtr<IConnectionPointContainer> container;
			if (SUCCEEDED(network_manager_->QueryInterface(IID_PPV_ARGS(&container))))
			{
				if (SUCCEEDED(container->FindConnectionPoint(IID_INetworkListManagerEvents, &connection_point_)))
				{
					events_handler_ = new NetworkEvents([this](bool connected)
														{
                    std::lock_guard<std::mutex> lock(sink_mutex_);
                    if (event_sink_) {
						flutter::EncodableMap event_data = {
							{flutter::EncodableValue("type"), flutter::EncodableValue("internet")},
							{flutter::EncodableValue("value"), flutter::EncodableValue(connected)}};
						event_sink_->Success(flutter::EncodableValue(event_data));
                    } });
					connection_point_->Advise(events_handler_, &cookie_);
				}
			}
		}
	}

	OnChainBridge::~OnChainBridge() {}

	std::string OnChainBridge::GetErrorString(const DWORD &error_code)
	{
		switch (error_code)
		{
		case ERROR_NO_SUCH_LOGON_SESSION:
			return "ERROR_NO_SUCH_LOGIN_SESSION";
		case ERROR_INVALID_FLAGS:
			return "ERROR_INVALID_FLAGS";
		case ERROR_BAD_USERNAME:
			return "ERROR_BAD_USERNAME";
		case SCARD_E_NO_READERS_AVAILABLE:
			return "SCARD_E_NO_READERS_AVAILABLE";
		case SCARD_E_NO_SMARTCARD:
			return "SCARD_E_NO_SMARTCARD";
		case SCARD_W_REMOVED_CARD:
			return "SCARD_W_REMOVED_CARD";
		case SCARD_W_WRONG_CHV:
			return "SCARD_W_WRONG_CHV";
		case ERROR_INVALID_PARAMETER:
			return "ERROR_INVALID_PARAMETER";
		default:
			return "UNKNOWN_ERROR";
		}
	}

	void OnChainBridge::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue> &method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
	{
		auto method = method_call.method_name();
		const auto *args = std::get_if<flutter::EncodableMap>(method_call.arguments());
		try
		{
			if (method == "secureStorage")
			{
				auto r = this->storage.HandleStorageCall(method, args);
				if (r.has_value())
				{
					result->Success(r.value());
				}
				else
				{
					result->Error("INVALID_ARGUMENTS", "Some key or value missing.");
				}
			}
			else if (method == "lunch_uri")
			{
				auto val = OnChainWindowsUtils::GetStringArg("uri", args);
				if (val.has_value())
				{
					result->Success(OnChainWindowsUtils::LaunchUrl(val.value()));
				}
				else
				{
					result->Success(false);
				}
			}
			else if (method == "path")
			{
				auto paths = OnChainWindowsUtils::getPaths();
				result->Success(flutter::EncodableValue(paths));
			}
			else if (method == "windowsManager")
			{
				if (this->windows_manager)
				{
					auto r = this->windows_manager->HandleWindowsManagerCall(method, args);
					if (r.has_value())
					{
						result->Success(r.value());
						return;
					}
				}
				result->Error("INVALID_ARGUMENTS", "Some key or value missing.");
			}
			else if (method == "authenticate")
			{
				auto methodType = OnChainWindowsUtils::GetStringArg("type", args);
				if (methodType == "touch_id_status")
				{
					auto shared_result =
						std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
					auto callback = [shared_result](BiometricStatus val) mutable
					{
						shared_result->Success(flutter::EncodableValue(val.name()));
					};
					Biometric::checkStatusAsync(callback);
				}
				else if (methodType == "authenticate")
				{
					auto shared_result =
						std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
					auto callback = [shared_result](BiometricResult val) mutable
					{
						shared_result->Success(flutter::EncodableValue(val.name()));
					};
					Biometric::authenticateAsync(callback);
				}
				else
				{
					result->Error("INVALID_ARGUMENTS", "Unknown method.");
				}
			}
			else if (method == "pick_file")
			{
				auto extension = OnChainWindowsUtils::GetStringArg("extension", args);
				auto mime_type = OnChainWindowsUtils::GetStringArg("mime_type", args);
				auto path = OnChainWindowsUtils::pick_file(extension, mime_type);
				if (path.has_value())
					result->Success(flutter::EncodableValue(path.value()));
				else
					result->Success(flutter::EncodableValue(std::monostate{}));
			}
			else if (method == "save_file")
			{
				auto file_name = OnChainWindowsUtils::GetStringArg("file_name", args);
				auto file_path = OnChainWindowsUtils::GetStringArg("file_path", args);
				auto extension = OnChainWindowsUtils::GetStringArg("extension", args);
				auto mime_type = OnChainWindowsUtils::GetStringArg("mime_type", args);
				if (extension.has_value() && file_path.has_value() && file_name.has_value() && mime_type.has_value())
				{
					result->Success(OnChainWindowsUtils::save_file(file_path.value(), file_name.value(), extension.value(), mime_type.value()));
				}
				else
				{
					result->Error("INVALID_ARGUMENTS", "Unknown method.");
				}
			}

			else
			{
				result->Error("INVALID_ARGUMENTS", "Unknown method.");
			}
		}
		catch (DWORD e)
		{
			auto str_code = this->GetErrorString(e);
			result->Error("Exception encountered: " + str_code, method);
		}
	}

	bool OnChainBridge::IsInternetConnected()
	{
		VARIANT_BOOL isConnected = VARIANT_FALSE;
		if (network_manager_)
		{
			network_manager_->get_IsConnectedToInternet(&isConnected);
		}
		return isConnected == VARIANT_TRUE;
	}
}
