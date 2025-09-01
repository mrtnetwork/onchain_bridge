#include <flutter/method_channel.h>           // REQUIRED: using MethodChannel
#include <flutter/event_channel.h>            // REQUIRED: for EventChannel usage
#include <flutter/plugin_registrar_windows.h> // REQUIRED: PluginRegistrarWindows
#include <flutter/standard_method_codec.h>    // REQUIRED: StandardMethodCodec
#include <flutter/encodable_value.h>          // REQUIRED: flutter::EncodableValue, EncodableMap

#include <windows.h>        // REQUIRED: HWND, RECT, POINT, Windows API functions
#include <dwmapi.h>         // OPTIONAL: needed only if you manipulate title bars or dark mode (DWMWA_USE_IMMERSIVE_DARK_MODE)
#include <shobjidl.h>       // OPTIONAL: only if using Shell COM objects (not used in your snippet)
#include <wincred.h>        // NOT required in WindowsManager.cpp (only needed in Storage)
#include <ShlObj_core.h>    // OPTIONAL: only if using known folders (Storage)
#include <bcrypt.h>         // NOT required here (used in Storage encryption)
#include <Shellapi.h>       // OPTIONAL: for ShellExecute or related API (not used)
#include <VersionHelpers.h> // REQUIRED: you call IsWindows11OrGreater()
#include <netlistmgr.h>     // OPTIONAL: only if you handle network events (used in OnChainBridge, not WindowsManager)
#include <comutil.h>        // OPTIONAL: only if using _bstr_t, VARIANT helpers (not used)
#include <atlbase.h>        // OPTIONAL: only if you use CComPtr (not used here)
#include <atlcomcli.h>      // OPTIONAL: only if you use CComPtr / smart COM pointers (not used here)

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
class WindowsManager
{
public:
    WindowsManager(flutter::PluginRegistrarWindows *registrar, flutter::MethodChannel<flutter::EncodableValue> *channel);
    std::optional<flutter::EncodableValue> HandleWindowsManagerCall(const std::string &method, const flutter::EncodableMap *args);

private:
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
    void SetBounds(const flutter::EncodableMap &args);
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
    bool IsWindows11OrGreater();
    flutter::EncodableMap GetBounds(
        const flutter::EncodableMap &args);
    bool IsResizable();
    void Minimize();
    void SetResizable(const flutter::EncodableMap &args);
    ITaskbarList3 *taskbar_ = nullptr;
    int window_proc_id = -1;
    std::optional<LRESULT> HandleWindowProc(HWND hWnd,
                                            UINT message,
                                            WPARAM wParam,
                                            LPARAM lParam);
    bool g_maximized_before_fullscreen;
    LONG g_style_before_fullscreen;
    std::string g_title_bar_style_before_fullscreen;

    flutter::MethodChannel<flutter::EncodableValue> *channel_;
};