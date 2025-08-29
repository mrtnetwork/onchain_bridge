#include <atomic>
#include <mutex>
#include <flutter_linux/flutter_linux.h>
#include <glib.h>
#include <gio/gio.h>
#define NETWORK_CHANNEL_NAME "com.mrtnetwork.on_chain_bridge.methodChannel/network_status"
#define NETWORK_CHANGED_EVENT_NAME "network-changed"

class NetworkHandler
{
public:
    NetworkHandler(FlBinaryMessenger *messenger);
    ~NetworkHandler();

    void SendConnectivityEvent(int connected);

private:
    FlEventChannel *channel;
    GNetworkMonitor *monitor;
    guint monitor_signal_id;
    std::mutex sink_mutex;
    int last_connectivity = 2;

    static FlMethodErrorResponse *OnListen(FlEventChannel *channel, FlValue *args, gpointer user_data);
    static FlMethodErrorResponse *OnCancel(FlEventChannel *channel, FlValue *args, gpointer user_data);

    static void on_network_changed(GNetworkMonitor *monitor, gboolean available, gpointer user_data);
};

NetworkHandler::NetworkHandler(FlBinaryMessenger *messenger)
{
    channel = fl_event_channel_new(
        messenger,
        NETWORK_CHANNEL_NAME,
        FL_METHOD_CODEC(fl_standard_method_codec_new()));

    fl_event_channel_set_stream_handlers(
        channel,
        OnListen,
        OnCancel,
        this,
        nullptr);

    monitor = g_network_monitor_get_default();
    monitor_signal_id = g_signal_connect(
        monitor,
        NETWORK_CHANGED_EVENT_NAME,
        G_CALLBACK(NetworkHandler::on_network_changed),
        this);
}

NetworkHandler::~NetworkHandler()
{
    if (monitor && monitor_signal_id != 0)
    {
        g_signal_handler_disconnect(monitor, monitor_signal_id);
        monitor_signal_id = 0;
    }

    if (channel)
    {
        fl_event_channel_set_stream_handlers(channel, nullptr, nullptr, nullptr, nullptr);
        g_clear_object(&channel);
    }
}

void NetworkHandler::SendConnectivityEvent(int connected)
{
    std::lock_guard<std::mutex> lock(sink_mutex);
    if (connected == last_connectivity)
        return;
    last_connectivity = connected;
    g_autoptr(FlValue) event = fl_value_new_map();
    fl_value_set_string(event, "type", fl_value_new_string("internet"));
    fl_value_set_string(event, "value", fl_value_new_bool(connected == 0 ? false : true));

    GError *error = nullptr;
    gboolean success = fl_event_channel_send(channel, event, nullptr, &error);

    if (!success && error != nullptr)
    {
        g_error_free(error);
    }
}

FlMethodErrorResponse *NetworkHandler::OnListen(FlEventChannel *channel, FlValue *args, gpointer user_data)
{
    NetworkHandler *self = static_cast<NetworkHandler *>(user_data);
    gboolean connected = g_network_monitor_get_network_available(self->monitor);
    self->SendConnectivityEvent(connected);

    return nullptr;
}

FlMethodErrorResponse *NetworkHandler::OnCancel(FlEventChannel *channel, FlValue *args, gpointer user_data)
{
    NetworkHandler *self = static_cast<NetworkHandler *>(user_data);
    std::lock_guard<std::mutex> lock(self->sink_mutex);
    self->last_connectivity = 2;
    return nullptr;
}

void NetworkHandler::on_network_changed(GNetworkMonitor *monitor, gboolean available, gpointer user_data)
{
    NetworkHandler *self = static_cast<NetworkHandler *>(user_data);
    if (!self)
        return;
    self->SendConnectivityEvent(available ? 1 : 0);
}
