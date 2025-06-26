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

#pragma comment(lib, "version.lib")
#pragma comment(lib, "bcrypt.lib")
#pragma comment(lib, "ole32.lib")

#define STATE_NORMAL 0
#define STATE_MAXIMIZED 1
#define STATE_MINIMIZED 2
#define STATE_FULLSCREEN_ENTERED 3
#define STATE_DOCKED 4

#define DWMWA_USE_IMMERSIVE_DARK_MODE 19

#define APPBAR_CALLBACK WM_USER + 0x01;

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

        void HandleFocusChange(bool hasFocus);
        std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
        ///
        std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
        std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>> stream_handler_;

        std::mutex sink_mutex_;
        std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

        CComPtr<INetworkListManager> network_manager_;
        CComPtr<IConnectionPoint> connection_point_;
        DWORD cookie_ = 0;
        NetworkEvents *events_handler_ = nullptr;

        // windows manager
        static constexpr auto kFlutterViewWindowClassName = L"FLUTTERVIEW";
        HWND native_window;
        HWND GetMainWindow();
        std::string title_bar_style_ = "normal";
        bool g_is_window_fullscreen = false;
        RECT g_frame_before_fullscreen;
        double pixel_ratio_ = 1;
        bool is_frameless_ = false;
        bool IsMaximized();
        bool SetMinimumSize(const flutter::EncodableMap &argsRef);
        bool SetMaximumSize(const flutter::EncodableMap &argsRef);
        bool IsMinimized();
        void Restore();
        bool is_resizable_ = true;
        POINT minimum_size_ = {0, 0};
        POINT maximum_size_ = {-1, -1};
        bool is_resizing_ = false;
        bool is_moving_ = false;
        double aspect_ratio_ = 0;
        int last_state = STATE_NORMAL;
        bool is_always_on_bottom_ = false;
        bool is_prevent_close_ = false;
        void SetAlwaysOnBottom(const flutter::EncodableMap &args);
        void ForceChildRefresh();
        void _EmitEvent(std::string eventName);
        void Hide();
        void Show();
        void Init();
        void OnChainBridge::SetBounds(const flutter::EncodableMap &args);
        bool IsFullScreen();
        void SetFullScreen(const flutter::EncodableMap &args);
        void WaitUntilReadyToShow();
        void Unmaximize();
        bool IsVisible();
        bool IsFocused();
        void Blur();
        void Focus();
        bool IsPreventClose();
        void SetPreventClose(const flutter::EncodableMap &args);
        void Close();
        void SetAsFrameless();
        flutter::EncodableMap GetBounds(
            const flutter::EncodableMap &args);
        bool IsResizable();
        void Minimize();
        void SetResizable(const flutter::EncodableMap &args);
        ITaskbarList3 *taskbar_ = nullptr;
        bool IsInternetConnected();

    private:
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

        // Retrieves the value passed to the given param.
        std::optional<std::string> GetStringArg(
            const std::string &param,
            const flutter::EncodableMap *args);
        std::optional<std::string> GetStringArgOrEmpty(
            const std::string &param,
            const flutter::EncodableMap *args);
        std::optional<std::vector<std::string>> GetStringListArg(
            const std::string &key,
            const flutter::EncodableMap *args);

        // Derive the key for a value given a method argument map.
        std::optional<std::string> OnChainBridge::GetValueKey(const flutter::EncodableMap *args);

        std::optional<std::vector<std::string>> GetListValueKey(const flutter::EncodableMap *args);

        // Removes prefix of the given storage key.
        //
        // The prefix (defined by ELEMENT_PREFERENCES_KEY_PREFIX) is added automatically when writing to storage,
        // to distinguish values that are written by this plugin from values that are not.
        std::string RemoveKeyPrefix(const std::string &key);

        // Gets the string name for the given int error code
        std::string GetErrorString(const DWORD &error_code);
        // Get string name of ntstatus
        std::string NtStatusToString(const CHAR *operation, NTSTATUS status);

        DWORD GetApplicationSupportPath(std::wstring &path);

        std::wstring SanitizeDirString(std::wstring string);

        bool PathExists(const std::wstring &path);

        bool MakePath(const std::wstring &path);

        PBYTE GetEncryptionKey();

        // Stores the given value under the given key.
        void Write(const std::string &key, const std::string &val);

        std::optional<std::string> Read(const std::string &key);

        flutter::EncodableMap ReadAll();
        flutter::EncodableList ReadKeys(const std::string &prefix);
        void Delete(const std::string &key);
        void DeleteAll();
        bool ContainsKey(const std::string &key);
        bool LaunchUrl(const std::string &url);
        flutter::EncodableMap getPaths();
        int window_proc_id = -1;
        std::optional<LRESULT> HandleWindowProc(HWND hWnd,
                                                UINT message,
                                                WPARAM wParam,
                                                LPARAM lParam);
        bool g_maximized_before_fullscreen;
        LONG g_style_before_fullscreen;
        std::string g_title_bar_style_before_fullscreen;
    };

}

#endif
