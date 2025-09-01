#include "include/windows_manager.hpp"
#include "include/utils.hpp"

WindowsManager::WindowsManager(flutter::PluginRegistrarWindows *registrar, flutter::MethodChannel<flutter::EncodableValue> *channel)
{
    native_window = ::GetAncestor(registrar->GetView()->GetNativeWindow(), GA_ROOT);
    channel_ = channel;
    window_proc_id = registrar->RegisterTopLevelWindowProcDelegate(
        [this](HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
        {
            return HandleWindowProc(hWnd, message, wParam, lParam);
        });
}

HWND WindowsManager::GetMainWindow()
{
    return native_window;
}
const flutter::EncodableValue *ValueOrNull(const flutter::EncodableMap &map,
                                           const char *key)
{
    auto it = map.find(flutter::EncodableValue(key));
    if (it == map.end())
    {
        return nullptr;
    }
    return &(it->second);
}
bool WindowsManager::IsWindows11OrGreater()
{
    DWORD dwVersion = 0;
    DWORD dwBuild = 0;

#pragma warning(push)
#pragma warning(disable : 4996)
    dwVersion = GetVersion();
    // Get the build number.
    if (dwVersion < 0x80000000)
        dwBuild = (DWORD)(HIWORD(dwVersion));
#pragma warning(pop)

    return dwBuild < 22000;
}
std::optional<LRESULT> WindowsManager::HandleWindowProc(HWND hWnd,
                                                        UINT message,
                                                        WPARAM wParam,
                                                        LPARAM lParam)
{
    std::optional<LRESULT> result = std::nullopt;
    if (message == WM_DPICHANGED)
    {
        pixel_ratio_ = (float)LOWORD(wParam) / USER_DEFAULT_SCREEN_DPI;
    }
    if (message == HC_ACTION && wParam == WM_KEYDOWN)
    {
        std::cerr << "fileBuffer HeapAlloc failed" << std::endl;
    }
    if (wParam && message == WM_NCCALCSIZE)
    {
        if (g_is_window_fullscreen && title_bar_style_ != "normal")
        {
            if (is_frameless_)
            {
                NCCALCSIZE_PARAMS *sz = reinterpret_cast<NCCALCSIZE_PARAMS *>(lParam);
                sz->rgrc[0].left += 8;
                sz->rgrc[0].top += 8;
                sz->rgrc[0].right -= 8;
                sz->rgrc[0].bottom -= 8;
            }
            return 0;
        }
        if (is_frameless_)
        {
            NCCALCSIZE_PARAMS *sz = reinterpret_cast<NCCALCSIZE_PARAMS *>(lParam);
            if (IsMaximized())
            {
                // Add borders when maximized so app doesn't get cut off.
                sz->rgrc[0].left += 8;
                sz->rgrc[0].top += 8;
                sz->rgrc[0].right -= 8;
                sz->rgrc[0].bottom -= 9;
            }
            return 0;
        }
        // This must always be last.
        if (wParam && title_bar_style_ == "hidden")
        {
            NCCALCSIZE_PARAMS *sz = reinterpret_cast<NCCALCSIZE_PARAMS *>(lParam);

            // Add 8 pixel to the top border when maximized so the app isn't cut off
            if (IsMaximized())
            {
                sz->rgrc[0].top += 8;
            }
            else
            {
                // on windows 10, if set to 0, there's a white line at the top
                // of the app and I've yet to find a way to remove that.
                sz->rgrc[0].top += IsWindows11OrGreater() ? 0 : 1;
            }
            sz->rgrc[0].right -= 8;
            sz->rgrc[0].bottom -= 8;
            sz->rgrc[0].left -= -8;

            // Previously (WVR_HREDRAW | WVR_VREDRAW), but returning 0 or 1 doesn't
            // actually break anything so I've set it to 0. Unless someone pointed a
            // problem in the future.
            return 0;
        }
    }
    else if (message == WM_NCHITTEST)
    {
        if (!is_resizable_)
        {
            return HTNOWHERE;
        }
    }
    else if (message == WM_GETMINMAXINFO)
    {
        MINMAXINFO *info = reinterpret_cast<MINMAXINFO *>(lParam);
        // For the special "unconstrained" values, leave the defaults.
        if (minimum_size_.x != 0)
            info->ptMinTrackSize.x =
                static_cast<LONG>(minimum_size_.x *
                                  pixel_ratio_);
        if (minimum_size_.y != 0)
            info->ptMinTrackSize.y =
                static_cast<LONG>(minimum_size_.y *
                                  pixel_ratio_);
        if (maximum_size_.x != -1)
            info->ptMaxTrackSize.x =
                static_cast<LONG>(maximum_size_.x *
                                  pixel_ratio_);
        if (maximum_size_.y != -1)
            info->ptMaxTrackSize.y =
                static_cast<LONG>(maximum_size_.y *
                                  pixel_ratio_);
        result = 0;
    }
    else if (message == WM_NCACTIVATE)
    {
        if (wParam == TRUE)
        {
            _EmitEvent("focus");
        }
        else
        {
            _EmitEvent("blur");
        }

        if (title_bar_style_ == "hidden" ||
            is_frameless_)
            return 1;
    }
    else if (message == WM_EXITSIZEMOVE)
    {
        if (is_resizing_)
        {
            _EmitEvent("resized");
            is_resizing_ = false;
        }
        if (is_moving_)
        {
            _EmitEvent("moved");
            is_moving_ = false;
        }
        return false;
    }
    else if (message == WM_MOVING)
    {
        is_moving_ = true;
        _EmitEvent("move");
        return false;
    }
    else if (message == WM_SIZING)
    {
        is_resizing_ = true;
        _EmitEvent("resize");

        if (aspect_ratio_ > 0)
        {
            RECT *rect = (LPRECT)lParam;

            double aspect_ratio = aspect_ratio_;

            int new_width = static_cast<int>(rect->right - rect->left);
            int new_height = static_cast<int>(rect->bottom - rect->top);

            bool is_resizing_horizontally =
                wParam == WMSZ_LEFT || wParam == WMSZ_RIGHT ||
                wParam == WMSZ_TOPLEFT || wParam == WMSZ_BOTTOMLEFT;

            if (is_resizing_horizontally)
            {
                new_height = static_cast<int>(new_width / aspect_ratio);
            }
            else
            {
                new_width = static_cast<int>(new_height * aspect_ratio);
            }

            int left = rect->left;
            int top = rect->top;
            int right = rect->right;
            int bottom = rect->bottom;

            switch (wParam)
            {
            case WMSZ_RIGHT:
            case WMSZ_BOTTOM:
                right = new_width + left;
                bottom = top + new_height;
                break;
            case WMSZ_TOP:
                right = new_width + left;
                top = bottom - new_height;
                break;
            case WMSZ_LEFT:
            case WMSZ_TOPLEFT:
                left = right - new_width;
                top = bottom - new_height;
                break;
            case WMSZ_TOPRIGHT:
                right = left + new_width;
                top = bottom - new_height;
                break;
            case WMSZ_BOTTOMLEFT:
                left = right - new_width;
                bottom = top + new_height;
                break;
            case WMSZ_BOTTOMRIGHT:
                right = left + new_width;
                bottom = top + new_height;
                break;
            }

            rect->left = left;
            rect->top = top;
            rect->right = right;
            rect->bottom = bottom;
        }
    }
    else if (message == WM_SIZE)
    {
        LONG_PTR gwlStyle =
            GetWindowLongPtr(GetMainWindow(), GWL_STYLE);
        if ((gwlStyle & (WS_CAPTION | WS_THICKFRAME)) == 0 &&
            wParam == SIZE_MAXIMIZED)
        {
            _EmitEvent("enter-full-screen");
            last_state = STATE_FULLSCREEN_ENTERED;
        }
        else if (last_state == STATE_FULLSCREEN_ENTERED &&
                 wParam == SIZE_RESTORED)
        {
            ForceChildRefresh();
            _EmitEvent("leave-full-screen");
            last_state = STATE_NORMAL;
        }
        else if (wParam == SIZE_MAXIMIZED)
        {
            _EmitEvent("maximize");
            last_state = STATE_MAXIMIZED;
        }
        else if (wParam == SIZE_MINIMIZED)
        {
            _EmitEvent("minimize");
            last_state = STATE_MINIMIZED;
            return 0;
        }
        else if (wParam == SIZE_RESTORED)
        {
            if (last_state == STATE_MAXIMIZED)
            {
                _EmitEvent("unmaximize");
                last_state = STATE_NORMAL;
            }
            else if (last_state == STATE_MINIMIZED)
            {
                _EmitEvent("restore");
                last_state = STATE_NORMAL;
            }
        }
    }
    else if (message == WM_CLOSE)
    {
        _EmitEvent("close");
        if (is_prevent_close_)
        {
            return -1;
        }
    }
    else if (message == WM_SHOWWINDOW)
    {
        if (wParam == TRUE)
        {
            _EmitEvent("show");
        }
        else
        {
            _EmitEvent("hide");
        }
    }
    else if (message == WM_WINDOWPOSCHANGED)
    {
        if (is_always_on_bottom_)
        {
            const flutter::EncodableMap &args = {
                {flutter::EncodableValue("isAlwaysOnBottom"),
                 flutter::EncodableValue(true)}};
            SetAlwaysOnBottom(args);
        }
    }

    return result;
}

bool WindowsManager::IsMaximized()
{
    HWND mainWindow = GetMainWindow();
    WINDOWPLACEMENT windowPlacement;
    GetWindowPlacement(mainWindow, &windowPlacement);

    return windowPlacement.showCmd == SW_MAXIMIZE;
}
bool WindowsManager::SetMaximumSize(const flutter::EncodableMap &argsRef)
{
    // Assuming "maxWidth" and "maxHeight" are the keys in the EncodableMap
    if (argsRef.find(flutter::EncodableValue("width")) != argsRef.end() &&
        argsRef.find(flutter::EncodableValue("height")) != argsRef.end())
    {

        double maxWidth = std::get<double>(argsRef.at(flutter::EncodableValue("width")));
        double maxHeight = std::get<double>(argsRef.at(flutter::EncodableValue("height")));

        maximum_size_.x = static_cast<LONG>(maxWidth);
        maximum_size_.y = static_cast<LONG>(maxHeight);
        return true;
    }
    return false;
}
bool WindowsManager::SetMinimumSize(const flutter::EncodableMap &argsRef)
{
    if (argsRef.find(flutter::EncodableValue("width")) != argsRef.end() &&
        argsRef.find(flutter::EncodableValue("height")) != argsRef.end())
    {

        double minWidth = std::get<double>(argsRef.at(flutter::EncodableValue("width")));
        double minHeight = std::get<double>(argsRef.at(flutter::EncodableValue("height")));

        minimum_size_.x = static_cast<LONG>(minWidth);
        minimum_size_.y = static_cast<LONG>(minHeight);
        return true;
    }
    return false;
}
void WindowsManager::SetAlwaysOnBottom(const flutter::EncodableMap &args)
{
    is_always_on_bottom_ =
        std::get<bool>(args.at(flutter::EncodableValue("isAlwaysOnBottom")));

    SetWindowPos(
        GetMainWindow(),
        is_always_on_bottom_ ? HWND_BOTTOM : HWND_NOTOPMOST,
        0,
        0,
        0,
        0,
        SWP_NOMOVE | SWP_NOSIZE);
}
void WindowsManager::ForceChildRefresh()
{
    HWND hWnd = GetWindow(GetMainWindow(), GW_CHILD);

    RECT rect;

    GetWindowRect(hWnd, &rect);
    SetWindowPos(
        hWnd, nullptr, rect.left, rect.top, rect.right - rect.left + 1,
        rect.bottom - rect.top,
        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_FRAMECHANGED);
    SetWindowPos(
        hWnd, nullptr, rect.left, rect.top, rect.right - rect.left,
        rect.bottom - rect.top,
        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_FRAMECHANGED);
}
void WindowsManager::_EmitEvent(std::string eventName)
{
    flutter::EncodableMap args = flutter::EncodableMap();
    args[flutter::EncodableValue("eventName")] =
        flutter::EncodableValue(eventName);
    channel_->InvokeMethod("onEvent",
                           std::make_unique<flutter::EncodableValue>(args));
}
void WindowsManager::Hide()
{
    ShowWindow(GetMainWindow(), SW_HIDE);
}
void WindowsManager::Show()
{
    HWND hWnd = GetMainWindow();
    DWORD gwlStyle = GetWindowLong(hWnd, GWL_STYLE);
    gwlStyle = gwlStyle | WS_VISIBLE;
    if ((gwlStyle & WS_VISIBLE) == 0)
    {
        SetWindowLong(hWnd, GWL_STYLE, gwlStyle);
        ::SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE);
    }

    ShowWindowAsync(GetMainWindow(), SW_SHOW);
    SetForegroundWindow(GetMainWindow());
}

void WindowsManager::SetBounds(const flutter::EncodableMap &args)
{
    HWND hwnd = GetMainWindow();

    double devicePixelRatio =
        std::get<double>(args.at(flutter::EncodableValue("devicePixelRatio")));

    auto *null_or_x = std::get_if<double>(ValueOrNull(args, "x"));
    auto *null_or_y = std::get_if<double>(ValueOrNull(args, "y"));
    auto *null_or_width = std::get_if<double>(ValueOrNull(args, "width"));
    auto *null_or_height = std::get_if<double>(ValueOrNull(args, "height"));

    int x = 0;
    int y = 0;
    int width = 0;
    int height = 0;
    UINT uFlags = NULL;

    if (null_or_x != nullptr && null_or_y != nullptr)
    {
        x = static_cast<int>(*null_or_x * devicePixelRatio);
        y = static_cast<int>(*null_or_y * devicePixelRatio);
    }
    if (null_or_width != nullptr && null_or_height != nullptr)
    {
        width = static_cast<int>(*null_or_width * devicePixelRatio);
        height = static_cast<int>(*null_or_height * devicePixelRatio);
    }

    if (null_or_x == nullptr || null_or_y == nullptr)
    {
        uFlags = SWP_NOMOVE;
    }
    if (null_or_width == nullptr || null_or_height == nullptr)
    {
        uFlags = SWP_NOSIZE;
    }

    SetWindowPos(hwnd, HWND_TOP, x, y, width, height, uFlags);
}
bool WindowsManager::IsFullScreen()
{
    return g_is_window_fullscreen;
}
bool WindowsManager::IsMinimized()
{
    HWND mainWindow = GetMainWindow();
    WINDOWPLACEMENT windowPlacement;
    GetWindowPlacement(mainWindow, &windowPlacement);

    return windowPlacement.showCmd == SW_SHOWMINIMIZED;
}

void WindowsManager::SetFullScreen(const flutter::EncodableMap &args)
{
    bool isFullScreen =
        std::get<bool>(args.at(flutter::EncodableValue("isFullScreen")));

    HWND mainWindow = GetMainWindow();

    // Previously inspired by how Chromium does this
    // https://src.chromium.org/viewvc/chrome/trunk/src/ui/views/win/fullscreen_handler.cc?revision=247204&view=markup
    // Instead, we use a modified implementation of how the media_kit package implements this
    // (we got permission from the author, I believe)
    // https://github.com/alexmercerind/media_kit/blob/1226bcff36eab27cb17d60c33e9c15ca489c1f06/media_kit_video/windows/utils.cc

    // Save current window state if not already fullscreen.
    if (!g_is_window_fullscreen)
    {
        // Save current window information.
        g_maximized_before_fullscreen = ::IsZoomed(mainWindow);
        g_style_before_fullscreen = GetWindowLong(mainWindow, GWL_STYLE);
        ::GetWindowRect(mainWindow, &g_frame_before_fullscreen);
        g_title_bar_style_before_fullscreen = title_bar_style_;
    }

    if (isFullScreen)
    {
        ::SendMessage(mainWindow, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
        if (!is_frameless_)
        {
            auto monitor = MONITORINFO{};
            auto placement = WINDOWPLACEMENT{};
            monitor.cbSize = sizeof(MONITORINFO);
            placement.length = sizeof(WINDOWPLACEMENT);
            ::GetWindowPlacement(mainWindow, &placement);
            ::GetMonitorInfo(::MonitorFromWindow(mainWindow, MONITOR_DEFAULTTONEAREST),
                             &monitor);
            ::SetWindowLongPtr(mainWindow, GWL_STYLE, g_style_before_fullscreen & ~WS_OVERLAPPEDWINDOW);
            ::SetWindowPos(mainWindow, HWND_TOP, monitor.rcMonitor.left,
                           monitor.rcMonitor.top, monitor.rcMonitor.right - monitor.rcMonitor.left,
                           monitor.rcMonitor.bottom - monitor.rcMonitor.top,
                           SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
        }
    }
    else
    {
        if (!g_maximized_before_fullscreen)
            Restore();
        ::SetWindowLongPtr(mainWindow, GWL_STYLE, g_style_before_fullscreen | WS_OVERLAPPEDWINDOW);
        if (::IsZoomed(mainWindow))
        {
            // Refresh the parent mainWindow.
            ::SetWindowPos(mainWindow, nullptr, 0, 0, 0, 0,
                           SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER |
                               SWP_FRAMECHANGED);
            auto rect = RECT{};
            ::GetClientRect(mainWindow, &rect);
            auto flutter_view =
                ::FindWindowEx(mainWindow, nullptr, kFlutterViewWindowClassName, nullptr);
            ::SetWindowPos(flutter_view, nullptr, rect.left, rect.top,
                           rect.right - rect.left, rect.bottom - rect.top,
                           SWP_NOACTIVATE | SWP_NOZORDER);
            if (g_maximized_before_fullscreen)
                PostMessage(mainWindow, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
        }
        else
        {
            ::SetWindowPos(
                mainWindow, nullptr, g_frame_before_fullscreen.left,
                g_frame_before_fullscreen.top,
                g_frame_before_fullscreen.right - g_frame_before_fullscreen.left,
                g_frame_before_fullscreen.bottom - g_frame_before_fullscreen.top,
                SWP_NOACTIVATE | SWP_NOZORDER);
        }
    }

    g_is_window_fullscreen = isFullScreen;
}
void WindowsManager::Restore()
{
    HWND mainWindow = GetMainWindow();
    WINDOWPLACEMENT windowPlacement;
    GetWindowPlacement(mainWindow, &windowPlacement);

    if (windowPlacement.showCmd != SW_NORMAL)
    {
        PostMessage(mainWindow, WM_SYSCOMMAND, SC_RESTORE, 0);
    }
}
void WindowsManager::WaitUntilReadyToShow()
{
    ::CoCreateInstance(CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER,
                       IID_PPV_ARGS(&taskbar_));
}
void WindowsManager::Unmaximize()
{
    HWND mainWindow = GetMainWindow();
    WINDOWPLACEMENT windowPlacement;
    GetWindowPlacement(mainWindow, &windowPlacement);

    if (windowPlacement.showCmd != SW_NORMAL)
    {
        PostMessage(mainWindow, WM_SYSCOMMAND, SC_RESTORE, 0);
    }
}
bool WindowsManager::IsVisible()
{
    bool isVisible = IsWindowVisible(GetMainWindow());
    return isVisible;
}
bool WindowsManager::IsFocused()
{
    return GetMainWindow() == GetActiveWindow();
}
void WindowsManager::Blur()
{
    HWND hWnd = GetMainWindow();
    HWND next_hwnd = ::GetNextWindow(hWnd, GW_HWNDNEXT);
    while (next_hwnd)
    {
        if (::IsWindowVisible(next_hwnd))
        {
            ::SetForegroundWindow(next_hwnd);
            return;
        }
        next_hwnd = ::GetNextWindow(next_hwnd, GW_HWNDNEXT);
    }
}
void WindowsManager::Focus()
{
    HWND hWnd = GetMainWindow();
    if (IsMinimized())
    {
        Restore();
    }

    ::SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE);
    SetForegroundWindow(hWnd);
}
bool WindowsManager::IsPreventClose()
{
    return is_prevent_close_;
}
void WindowsManager::SetPreventClose(const flutter::EncodableMap &args)
{

    is_prevent_close_ =
        std::get<bool>(args.at(flutter::EncodableValue("isPreventClose")));
}
void WindowsManager::Close()
{
    HWND hWnd = GetMainWindow();
    PostMessage(hWnd, WM_SYSCOMMAND, SC_CLOSE, 0);
}
void WindowsManager::SetAsFrameless()
{
    is_frameless_ = true;
    HWND hWnd = GetMainWindow();

    RECT rect;

    GetWindowRect(hWnd, &rect);
    SetWindowPos(hWnd, nullptr, rect.left, rect.top, rect.right - rect.left,
                 rect.bottom - rect.top,
                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE | SWP_NOSIZE |
                     SWP_FRAMECHANGED);
}
flutter::EncodableMap WindowsManager::GetBounds(
    const flutter::EncodableMap &args)
{
    HWND hwnd = GetMainWindow();
    double devicePixelRatio =
        std::get<double>(args.at(flutter::EncodableValue("devicePixelRatio")));

    flutter::EncodableMap resultMap = flutter::EncodableMap();
    RECT rect;
    if (GetWindowRect(hwnd, &rect))
    {
        double x = rect.left / devicePixelRatio * 1.0f;
        double y = rect.top / devicePixelRatio * 1.0f;
        double width = (rect.right - rect.left) / devicePixelRatio * 1.0f;
        double height = (rect.bottom - rect.top) / devicePixelRatio * 1.0f;

        resultMap[flutter::EncodableValue("x")] = flutter::EncodableValue(x);
        resultMap[flutter::EncodableValue("y")] = flutter::EncodableValue(y);
        resultMap[flutter::EncodableValue("width")] =
            flutter::EncodableValue(width);
        resultMap[flutter::EncodableValue("height")] =
            flutter::EncodableValue(height);
    }
    return resultMap;
}
void WindowsManager::SetResizable(const flutter::EncodableMap &args)
{
    HWND hWnd = GetMainWindow();
    is_resizable_ =
        std::get<bool>(args.at(flutter::EncodableValue("isResizable")));
    DWORD gwlStyle = GetWindowLong(hWnd, GWL_STYLE);
    if (is_resizable_)
    {
        gwlStyle |= WS_THICKFRAME;
    }
    else
    {
        gwlStyle &= ~WS_THICKFRAME;
    }
    ::SetWindowLong(hWnd, GWL_STYLE, gwlStyle);
}
bool WindowsManager::IsResizable()
{
    return is_resizable_;
}
void WindowsManager::Minimize()
{
    HWND mainWindow = GetMainWindow();
    WINDOWPLACEMENT windowPlacement;
    GetWindowPlacement(mainWindow, &windowPlacement);

    if (windowPlacement.showCmd != SW_SHOWMINIMIZED)
    {
        PostMessage(mainWindow, WM_SYSCOMMAND, SC_MINIMIZE, 0);
    }
}

std::optional<flutter::EncodableValue> WindowsManager::HandleWindowsManagerCall(const std::string &method, const flutter::EncodableMap *args)
{
    auto methodType = OnChainWindowsUtils::GetStringArg("type", args);
    if (methodType == "show")
    {
        Show();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "hide")
    {
        Hide();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "init")
    {
        // Init();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "setBounds")
    {
        const flutter::EncodableMap &argsRef = *args;
        SetBounds(argsRef);
        return flutter::EncodableValue(true);
    }
    else if (methodType == "isFullScreen")
    {
        return flutter::EncodableValue(IsFullScreen());
    }
    else if (methodType == "setFullScreen")
    {
        const flutter::EncodableMap &argsRef = *args;
        SetFullScreen(argsRef);
        return flutter::EncodableValue(true);
    }
    else if (methodType == "maximumSize")
    {
        const flutter::EncodableMap &argsRef = *args;
        return flutter::EncodableValue(SetMaximumSize(argsRef));
    }
    else if (methodType == "minimumSize")
    {
        const flutter::EncodableMap &argsRef = *args;
        return flutter::EncodableValue(SetMinimumSize(argsRef));
    }
    else if (methodType == "isMaximized")
    {
        return flutter::EncodableValue(IsMaximized());
    }
    else if (methodType == "isMinimized")
    {
        return flutter::EncodableValue(IsMinimized());
    }
    else if (methodType == "restore")
    {
        Restore();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "unmaximize")
    {
        Unmaximize();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "waitUntilReadyToShow")
    {
        WaitUntilReadyToShow();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "isVisible")
    {
        return flutter::EncodableValue(IsVisible());
    }
    else if (methodType == "isFocused")
    {
        return flutter::EncodableValue(IsFocused());
    }
    else if (methodType == "blur")
    {
        Blur();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "focus")
    {
        Focus();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "isPreventClose")
    {
        return flutter::EncodableValue(IsPreventClose());
    }
    else if (methodType == "setPreventClose")
    {
        const flutter::EncodableMap &argsRef = *args;
        SetPreventClose(argsRef);
        return flutter::EncodableValue(true);
    }
    else if (methodType == "close")
    {
        Close();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "setAsFrameless")
    {
        SetAsFrameless();
        return flutter::EncodableValue(true);
    }
    else if (methodType == "getBounds")
    {
        const flutter::EncodableMap &argsRef = *args;
        return flutter::EncodableValue(GetBounds(argsRef));
    }
    else if (methodType == "setResizable")
    {
        const flutter::EncodableMap &argsRef = *args;
        SetResizable(argsRef);
        return flutter::EncodableValue(true);
    }
    else if (methodType == "isResizable")
    {
        return flutter::EncodableValue(IsResizable());
    }
    else if (methodType == "minimize")
    {
        Minimize();
        return flutter::EncodableValue(true);
    }
    return std::nullopt;
}