#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#pragma once

#define WM_GET_BOUNDS "getBounds"
#define WM_SET_BOUNDS "setBounds"
#define WM_SET_ICON "setIcon"
#define WM_MAXIMUM_SIZE "maximumSize"
#define WM_MINIMUM_SIZE "minimumSize"
#define WM_SET_RESIZABLE "setResizable"
#define WM_IS_RESIZABLE "isResizable"
#define WM_SET_FRAMELESS "setAsFrameless"
#define WM_SET_PREVENT_CLOSE "SetPreventClose"
#define WM_IS_PREVENT_CLOSE "isPreventClose"
#define WM_IS_FULLSCREEN "isFullScreen"
#define WM_IS_MAXIMIZED "isMaximized"
#define WM_IS_MINIMIZED "isMinimized"
#define WM_IS_VISIBLE "isVisible"
#define WM_MINIMIZE "minimize"
#define WM_RESTORE "restore"
#define WM_SET_FULLSCREEN "setFullScreen"
#define WM_UNMAXIMIZE "unmaximize"
#define WM_CLOSE "close"
#define WM_FOCUS "focus"
#define WM_IS_FOCUSED "isFocused"
#define WM_BLUR "blur"
#define WM_HIDE "hide"
#define WM_SHOW "show"
#define WM_INIT "init"

class WindowsManager
{
public:
    WindowsManager(FlPluginRegistrar *registrar, FlMethodChannel *channel);
    void on_windows_event(const char *event_name);
    FlMethodResponse *handle_windows_manager_calls(const gchar *method, FlValue *data);

private:
    static void connect_window_signals(FlView *view, WindowsManager *self);
    FlValue *get_window_bounds();
    bool set_icon(const gchar *path);
    void set_window_bounds(double x, double y, double width, double height);
    void set_minimum_size(double min_width, double min_height);
    void set_maximum_size(double min_width, double min_height);
    void apply_geometry_hints();
    bool set_resizable(bool resizable);
    bool is_resizable() const;
    bool set_frameless();
    bool set_prevent_close(bool prevent_close);
    bool is_prevent_close();
    bool is_fullscreen();
    bool is_maximized();
    bool is_minimized();
    bool is_visible();
    bool minimize();
    bool restore();
    bool set_fullscreen(bool enable);
    bool unmaximize();
    bool close();
    bool focus();
    bool is_focused();
    bool blur();
    bool hide();
    bool show();
    bool is_prevent_close_ = false;

    FlMethodChannel *channel;
    guint debounce_timeout_id = 0;
    GtkWindow *window;
    int last_x = -1;
    int last_y = -1;
    int last_width = -1;
    int last_height = -1;
    bool is_moving_ = false;
    bool is_resizing_ = false;
    bool frameless = false;
    double aspect_ratio_ = 0.0;

    int min_width = -1;
    int min_height = -1;
    int max_width = -1;
    int max_height = -1;
};
bool WindowsManager::hide()
{
    if (!window)
        return false;

    // Hide window completely
    gtk_widget_hide(GTK_WIDGET(window));

    // Remove from taskbar
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), TRUE);

    return true;
}

bool WindowsManager::show()
{
    if (!window)
        return false;

    // Restore taskbar hint
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window), FALSE);

    // Show window
    gtk_widget_show(GTK_WIDGET(window));

    // Give focus to window
    gtk_window_present(GTK_WINDOW(window));

    return true;
}

bool WindowsManager::blur()
{
    if (!window)
        return false;

    bool didSomething = false;

    // 1) GTK polite calls --------------------
#if GTK_CHECK_VERSION(4, 0, 0)
    // GTK4: clear root focus
    GtkWidget *widget = GTK_WIDGET(window);
    GtkRoot *root = gtk_widget_get_root(widget);
    if (root)
    {
        gtk_root_set_focus(root, nullptr);
        didSomething = true;
    }
#else
    gtk_window_set_focus(window, nullptr);
    didSomething = true;
#endif
    return didSomething;
}
bool WindowsManager::close()
{
    if (!window)
        return false;
    // Equivalent to clicking the close button
    gtk_window_close(window);
    return true;
}

bool WindowsManager::focus()
{
    if (!window)
        return false;

#if GTK_CHECK_VERSION(4, 0, 0)
    // GTK4: use gdk_toplevel_present
    GtkWidget *widget = GTK_WIDGET(window);
    GdkSurface *surface = gtk_native_get_surface(gtk_widget_get_native(widget));
    if (!surface)
        return false;
    gdk_toplevel_present(GDK_TOPLEVEL(surface));
#else
    // GTK3: present brings to front & gives focus
    gtk_window_present(window);
#endif

    return true;
}

bool WindowsManager::is_focused()
{
    if (!window)
        return false;

#if GTK_CHECK_VERSION(4, 0, 0)
    GtkWidget *widget = GTK_WIDGET(window);
    GdkSurface *surface = gtk_native_get_surface(gtk_widget_get_native(widget));
    if (!surface)
        return false;
    return gdk_toplevel_get_state(GDK_TOPLEVEL(surface)) & GDK_TOPLEVEL_STATE_FOCUSED;
#else
    GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (!gdk_window)
        return false;
    return gdk_window_is_viewable(gdk_window) &&
           gdk_window_get_state(gdk_window) & GDK_WINDOW_STATE_FOCUSED;
#endif
}

bool WindowsManager::is_fullscreen()
{
    if (!window)
        return false;
#if GTK_CHECK_VERSION(4, 0, 0)
    GtkWidget *widget = GTK_WIDGET(window);
    GdkSurface *surface = gtk_native_get_surface(gtk_widget_get_native(widget));
    if (!surface)
        return false;
    GdkToplevelState state = gdk_toplevel_get_state(GDK_TOPLEVEL(surface));
    return (state & GDK_TOPLEVEL_STATE_FULLSCREEN) != 0;
#else
    GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (!gdk_window)
        return false;
    GdkWindowState state = gdk_window_get_state(gdk_window);
    return (state & GDK_WINDOW_STATE_FULLSCREEN) != 0;
#endif
}

bool WindowsManager::is_maximized()
{
    if (!window)
        return false;
#if GTK_CHECK_VERSION(4, 0, 0)
    GtkWidget *widget = GTK_WIDGET(window);
    GdkSurface *surface = gtk_native_get_surface(gtk_widget_get_native(widget));
    if (!surface)
        return false;
    GdkToplevelState state = gdk_toplevel_get_state(GDK_TOPLEVEL(surface));
    return (state & GDK_TOPLEVEL_STATE_MAXIMIZED) != 0;
#else
    GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (!gdk_window)
        return false;
    GdkWindowState state = gdk_window_get_state(gdk_window);
    return (state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
#endif
}

bool WindowsManager::is_minimized()
{
    if (!window)
        return false;
#if GTK_CHECK_VERSION(4, 0, 0)
    GtkWidget *widget = GTK_WIDGET(window);
    GdkSurface *surface = gtk_native_get_surface(gtk_widget_get_native(widget));
    if (!surface)
        return false;
    GdkToplevelState state = gdk_toplevel_get_state(GDK_TOPLEVEL(surface));
    return (state & GDK_TOPLEVEL_STATE_MINIMIZED) != 0;
#else
    GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (!gdk_window)
        return false;
    GdkWindowState state = gdk_window_get_state(gdk_window);
    return (state & GDK_WINDOW_STATE_ICONIFIED) != 0;
#endif
}

bool WindowsManager::is_visible()
{
    if (!window)
        return false;

    // Returns true if the window is mapped and not hidden
    return gtk_widget_get_visible(GTK_WIDGET(window));
}

bool WindowsManager::minimize()
{
    if (!window)
        return false;

    // Iconify the window (minimize to taskbar)
    gtk_window_iconify(GTK_WINDOW(window));
    return true;
}

bool WindowsManager::restore()
{
    if (!window)
        return false;

    // Restore from minimized state
    gtk_window_deiconify(GTK_WINDOW(window));

    // Restore from maximized state
    if (gtk_window_get_window_type(GTK_WINDOW(window)) == GTK_WINDOW_TOPLEVEL)
    {
        gtk_window_unmaximize(GTK_WINDOW(window));
    }

    // Restore from fullscreen state
    gtk_window_unfullscreen(GTK_WINDOW(window));

    // Optionally bring window to front
    gtk_window_present(GTK_WINDOW(window));

    return true;
}

bool WindowsManager::set_fullscreen(bool enable)
{
    if (!window)
        return false;

    // Ensure window is mapped
    if (!gtk_widget_get_visible(GTK_WIDGET(window)))
        gtk_widget_show(GTK_WIDGET(window));

    if (enable)
    {
        gtk_window_fullscreen(GTK_WINDOW(window));
    }
    else
    {
        gtk_window_unfullscreen(GTK_WINDOW(window));

        // Optional: bring back to front and restore normal size
        gtk_window_present(GTK_WINDOW(window));
        gtk_window_unmaximize(GTK_WINDOW(window));
    }

    return true;
}

bool WindowsManager::unmaximize()
{
    if (!window)
        return false;
    gtk_window_unmaximize(window);
    return true;
}
FlValue *WindowsManager::get_window_bounds()
{
    if (!window)
        return fl_value_new_null();

    int x = 0, y = 0, width = 0, height = 0;

#if GTK_CHECK_VERSION(4, 0, 0)
    if (GtkWidget *widget = GTK_WIDGET(window))
    {
        GdkRectangle geom;
        if (gdk_window_get_geometry(gtk_widget_get_window(widget), &geom.x, &geom.y, &geom.width, &geom.height))
        {
            x = geom.x;
            y = geom.y;
            width = geom.width;
            height = geom.height;
        }
    }
#else
    gtk_window_get_position(window, &x, &y);
    gtk_window_get_size(window, &width, &height);
#endif

    g_autoptr(FlValue) bounds = fl_value_new_map();
    fl_value_set_string(bounds, "x", fl_value_new_float(x));
    fl_value_set_string(bounds, "y", fl_value_new_float(y));
    fl_value_set_string(bounds, "width", fl_value_new_float(width));
    fl_value_set_string(bounds, "height", fl_value_new_float(height));

    return fl_value_ref(bounds);
}
bool WindowsManager::is_resizable() const
{
    if (!window)
        return false;
    return gtk_window_get_resizable(window);
}
bool WindowsManager::set_resizable(bool resizable)
{
    if (!window)
        return false;

    gtk_window_set_resizable(window, resizable);
    return true;
}

bool WindowsManager::set_prevent_close(bool prevent_close)
{
    is_prevent_close_ = prevent_close;
    return true;
}
bool WindowsManager::is_prevent_close()
{
    return is_prevent_close_;
}
void WindowsManager::set_minimum_size(double w, double h)
{
    min_width = static_cast<int>(w);
    min_height = static_cast<int>(h);
    apply_geometry_hints();
}

void WindowsManager::set_maximum_size(double w, double h)
{
    max_width = static_cast<int>(w);
    max_height = static_cast<int>(h);
    apply_geometry_hints();
}

WindowsManager::WindowsManager(FlPluginRegistrar *registrar, FlMethodChannel *channel)
{
    this->channel = channel;
    FlView *view = fl_plugin_registrar_get_view(registrar);
    this->window = GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
    connect_window_signals(view, this);
}

void WindowsManager::set_window_bounds(double x, double y, double width, double height)
{
    if (!window)
        return;

    // GTK expects integers
    int ix = static_cast<int>(x);
    int iy = static_cast<int>(y);
    int iw = static_cast<int>(width);
    int ih = static_cast<int>(height);

    // Move the window
    gtk_window_move(window, ix, iy);

    // Resize the window
    gtk_window_resize(window, iw, ih);

    // Update internal last known bounds to avoid false resize/move events
    last_x = ix;
    last_y = iy;
    last_width = iw;
    last_height = ih;
}
void WindowsManager::on_windows_event(const char *event_name)
{
    if (!channel)
        return;

    g_autoptr(FlValue) args = fl_value_new_map();
    fl_value_set_string(args, "eventName", fl_value_new_string(event_name));

    fl_method_channel_invoke_method(channel,
                                    "onEvent",
                                    args,
                                    nullptr,
                                    nullptr,
                                    nullptr);
}

void WindowsManager::apply_geometry_hints()
{
    if (!window)
        return;

    GdkGeometry hints = {};
    guint hints_mask = 0;

    if (min_width > 0 && min_height > 0)
    {
        hints.min_width = min_width;
        hints.min_height = min_height;
        hints_mask |= GDK_HINT_MIN_SIZE;
    }

    if (max_width > 0 && max_height > 0)
    {
        hints.max_width = max_width;
        hints.max_height = max_height;
        hints_mask |= GDK_HINT_MAX_SIZE;
    }

    gtk_window_set_geometry_hints(window, nullptr, &hints, static_cast<GdkWindowHints>(hints_mask));
}

void WindowsManager::connect_window_signals(FlView *view, WindowsManager *manager)
{
    GtkWindow *window = manager->window;

#if GTK_MAJOR_VERSION >= 4
    // GTK4 signals
    g_signal_connect(window, "map", G_CALLBACK(+[](GtkWidget *, gpointer user_data)
                                               {
                                                   WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                   mgr->on_windows_event("show");
                                               }),
                     manager);

    g_signal_connect(window, "unmap", G_CALLBACK(+[](GtkWidget *, gpointer user_data)
                                                 {
                                                     WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                     mgr->on_windows_event("hide");
                                                 }),
                     manager);

    g_signal_connect(window, "close-request", G_CALLBACK(+[](GtkWindow *, gpointer user_data) -> gboolean
                                                         {
                                                             WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                             mgr->on_windows_event("close");
                                                             return FALSE; // allow close
                                                         }),
                     manager);

#else
    // GTK3 signals
    g_signal_connect(window, "map-event", G_CALLBACK(+[](GtkWidget *, GdkEvent *, gpointer user_data) -> gboolean
                                                     {
                                                         WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                         mgr->on_windows_event("show");
                                                         return FALSE;
                                                     }),
                     manager);

    g_signal_connect(window, "unmap-event", G_CALLBACK(+[](GtkWidget *, GdkEvent *, gpointer user_data) -> gboolean
                                                       {
                                                           WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                           mgr->on_windows_event("hide");
                                                           return FALSE;
                                                       }),
                     manager);

    g_signal_connect(window, "delete-event", G_CALLBACK(+[](GtkWidget *, GdkEvent *, gpointer user_data) -> gboolean
                                                        {
                                                            WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                            mgr->on_windows_event("close");
                                                            if (mgr->is_prevent_close_)
                                                                return TRUE;

                                                            return FALSE;
                                                        }),
                     manager);
#endif

    // Focus signals (same for GTK3 & GTK4)
    g_signal_connect(window, "focus-in-event", G_CALLBACK(+[](GtkWidget *, GdkEvent *, gpointer user_data) -> gboolean
                                                          {
                                                              WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                              mgr->on_windows_event("focus");
                                                              return FALSE;
                                                          }),
                     manager);

    g_signal_connect(window, "focus-out-event", G_CALLBACK(+[](GtkWidget *, GdkEvent *, gpointer user_data) -> gboolean
                                                           {
                                                               WindowsManager *mgr = static_cast<WindowsManager *>(user_data);
                                                               mgr->on_windows_event("blur");
                                                               return FALSE;
                                                           }),
                     manager);

    // Window state changes
    g_signal_connect(window, "window-state-event", G_CALLBACK(+[](GtkWidget *, GdkEventWindowState *e, gpointer user_data) -> gboolean
                                                              {
                                                                  WindowsManager *mgr = static_cast<WindowsManager *>(user_data);

                                                                  if (e->new_window_state & GDK_WINDOW_STATE_MAXIMIZED)
                                                                      mgr->on_windows_event("maximize");
                                                                  else if (e->changed_mask & GDK_WINDOW_STATE_MAXIMIZED)
                                                                      mgr->on_windows_event("unmaximize");

                                                                  if (e->new_window_state & GDK_WINDOW_STATE_ICONIFIED)
                                                                      mgr->on_windows_event("minimize");
                                                                  else if (e->changed_mask & GDK_WINDOW_STATE_ICONIFIED)
                                                                      mgr->on_windows_event("restore");

                                                                  if (e->new_window_state & GDK_WINDOW_STATE_FULLSCREEN)
                                                                      mgr->on_windows_event("enter-full-screen");
                                                                  else if (e->changed_mask & GDK_WINDOW_STATE_FULLSCREEN)
                                                                      mgr->on_windows_event("leave-full-screen");

                                                                  return FALSE;
                                                              }),
                     manager);

    // Move & Resize
    g_signal_connect(window, "configure-event", G_CALLBACK(+[](GtkWidget *w, GdkEventConfigure *e, gpointer user_data) -> gboolean
                                                           {
                                                               WindowsManager *mgr = static_cast<WindowsManager *>(user_data);

                                                               bool moved = (e->x != mgr->last_x || e->y != mgr->last_y);
                                                               bool resized = (e->width != mgr->last_width || e->height != mgr->last_height);

                                                               if (moved && !mgr->is_moving_)
                                                               {
                                                                   mgr->is_moving_ = true;
                                                                   mgr->on_windows_event("move");
                                                               }

                                                               if (resized && !mgr->is_resizing_)
                                                               {
                                                                   mgr->is_resizing_ = true;
                                                                   mgr->on_windows_event("resize");
                                                               }

                                                               // Optional: enforce aspect ratio
                                                               if (mgr->aspect_ratio_ > 0 && resized)
                                                               {
                                                                   int new_width = e->width;
                                                                   int new_height = e->height;
                                                                   double ratio = mgr->aspect_ratio_;

                                                                   if ((double)new_width / new_height > ratio)
                                                                       new_width = static_cast<int>(new_height * ratio);
                                                                   else
                                                                       new_height = static_cast<int>(new_width / ratio);

                                                                   gtk_window_resize(GTK_WINDOW(w), new_width, new_height);
                                                               }

                                                               mgr->last_x = e->x;
                                                               mgr->last_y = e->y;
                                                               mgr->last_width = e->width;
                                                               mgr->last_height = e->height;

                                                               if (mgr->debounce_timeout_id)
                                                                   g_source_remove(mgr->debounce_timeout_id);

                                                               mgr->debounce_timeout_id = g_timeout_add(100, [](gpointer user_data) -> gboolean
                                                                                                        {
                             WindowsManager *mgr2 = static_cast<WindowsManager *>(user_data);

                             if (mgr2->is_moving_)
                             {
                                 mgr2->on_windows_event("moved");
                                 mgr2->is_moving_ = false;
                             }

                             if (mgr2->is_resizing_)
                             {
                                 mgr2->on_windows_event("resized");
                                 mgr2->is_resizing_ = false;
                             }

                             mgr2->debounce_timeout_id = 0;
                             return FALSE; }, mgr);

                                                               return FALSE;
                                                           }),
                     manager);
}

bool WindowsManager::set_frameless()
{
    if (!window)
        return false;

    if (!frameless)
    {
        // Remove titlebar and window borders
        gtk_window_set_decorated(window, FALSE);

        // Optional: remove window manager shadows for some DEs
        GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
        if (gdk_window)
            gdk_window_set_override_redirect(gdk_window, TRUE);
        frameless = true;
    }
    else
    {
        // Restore titlebar and decorations
        gtk_window_set_decorated(window, TRUE);

        GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
        if (gdk_window)
            gdk_window_set_override_redirect(gdk_window, FALSE);
        frameless = false;
    }
    return true;
}

bool WindowsManager::set_icon(const gchar *path)
{
    if (window == nullptr)
    {
        return false;
    }

#if GTK_CHECK_VERSION(4, 0, 0)
    // GTK4: set application-wide default icon
    GFile *file = g_file_new_for_path(path);
    if (!g_file_query_exists(file, NULL))
    {
        g_object_unref(file);
        return false;
    }

    GIcon *icon = g_file_icon_new(file);
    g_application_set_default_icon(icon);

    g_object_unref(icon);
    g_object_unref(file);

    return true;
#else
    // GTK3: set icon for this window
    gboolean success = gtk_window_set_icon_from_file(GTK_WINDOW(window), path, nullptr);
    return success;
#endif
}

FlMethodResponse *WindowsManager::handle_windows_manager_calls(const gchar *method, FlValue *data)
{
    FlValue *type = fl_value_lookup_string(data, "type");
    if (type == nullptr ||
        fl_value_get_type(type) != FL_VALUE_TYPE_STRING)

    {
        return FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGUMENT",
            "Invalid Map argument or windows manager operation type.", nullptr));
    }
    const gchar *string_type = fl_value_get_string(type);
    if (strcmp(string_type, WM_GET_BOUNDS) == 0)
    {
        FlValue *result = get_window_bounds();
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_SET_ICON) == 0)
    {
        FlValue *path = fl_value_lookup_string(data, "path");
        if (path &&
            fl_value_get_type(path) == FL_VALUE_TYPE_STRING)
        {
            const gchar *string_path = fl_value_get_string(path);
            bool success = set_icon(string_path);
            g_autoptr(FlValue) result = fl_value_new_bool(success);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, WM_SET_BOUNDS) == 0)
    {
        FlValue *width = fl_value_lookup_string(data, "width");
        FlValue *height = fl_value_lookup_string(data, "height");
        FlValue *x = fl_value_lookup_string(data, "x");
        FlValue *y = fl_value_lookup_string(data, "y");

        if (width && height && x && y &&
            fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
            fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT &&
            fl_value_get_type(x) == FL_VALUE_TYPE_FLOAT &&
            fl_value_get_type(y) == FL_VALUE_TYPE_FLOAT)
        {
            double dx = fl_value_get_float(x);
            double dy = fl_value_get_float(y);
            double dw = fl_value_get_float(width);
            double dh = fl_value_get_float(height);

            set_window_bounds(dx, dy, dw, dh);

            g_autoptr(FlValue) result = fl_value_new_null();
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }

    else if (strcmp(string_type, WM_MAXIMUM_SIZE) == 0)
    {
        FlValue *width = fl_value_lookup_string(data, "width");
        FlValue *height = fl_value_lookup_string(data, "height");

        if (width && height && fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
            fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT)
        {
            double dw = fl_value_get_float(width);
            double dh = fl_value_get_float(height);
            set_maximum_size(dw, dh);
            g_autoptr(FlValue) result = fl_value_new_bool(true);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, WM_MINIMUM_SIZE) == 0)
    {
        FlValue *width = fl_value_lookup_string(data, "width");
        FlValue *height = fl_value_lookup_string(data, "height");

        if (width && height && fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
            fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT)
        {
            double dw = fl_value_get_float(width);
            double dh = fl_value_get_float(height);
            set_minimum_size(dw, dh);
            g_autoptr(FlValue) result = fl_value_new_bool(true);
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, WM_SET_RESIZABLE) == 0)
    {
        FlValue *isResizable = fl_value_lookup_string(data, "isResizable");

        if (isResizable && fl_value_get_type(isResizable) == FL_VALUE_TYPE_BOOL)
        {
            bool resizable = fl_value_get_bool(isResizable);
            g_autoptr(FlValue) result = fl_value_new_bool(set_resizable(resizable));
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, WM_IS_RESIZABLE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_resizable());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_SET_FRAMELESS) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(set_frameless());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_SET_PREVENT_CLOSE) == 0)
    {
        FlValue *prevent_close = fl_value_lookup_string(data, "isPreventClose");

        if (prevent_close && fl_value_get_type(prevent_close) == FL_VALUE_TYPE_BOOL)
        {
            g_autoptr(FlValue) result = fl_value_new_bool(set_prevent_close(fl_value_get_bool(prevent_close)));
            return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
        }
    }
    else if (strcmp(string_type, WM_IS_PREVENT_CLOSE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_prevent_close());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_IS_FULLSCREEN) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_fullscreen());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_IS_MAXIMIZED) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_maximized());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_IS_MINIMIZED) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_minimized());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_IS_VISIBLE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_visible());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_MINIMIZE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(minimize());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_RESTORE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(restore());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_SET_FULLSCREEN) == 0)
    {
        {
            FlValue *fullscreen = fl_value_lookup_string(data, "isFullScreen");

            if (fullscreen && fl_value_get_type(fullscreen) == FL_VALUE_TYPE_BOOL)
            {
                g_autoptr(FlValue) result = fl_value_new_bool(set_fullscreen(fl_value_get_bool(fullscreen)));
                return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
            }
        }
    }
    else if (strcmp(string_type, WM_UNMAXIMIZE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(unmaximize());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_CLOSE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(close());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_FOCUS) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(focus());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_IS_FOCUSED) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(is_focused());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_BLUR) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(blur());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_HIDE) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(hide());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_SHOW) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(show());
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, WM_INIT) == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(window != nullptr);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
    else if (strcmp(string_type, "waitUntilReadyToShow") == 0)
    {
        g_autoptr(FlValue) result = fl_value_new_bool(window != nullptr);
        return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }

    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT",          // Error code
        "Some key or value missing", // Error message
        nullptr                      // No additional error details
        ));
}
