#include "include/on_chain_bridge/on_chain_bridge_plugin.h"
#include "include/storage.hpp"
#include "include/utils.hpp"
#include "include/network.hpp"
#include "include/windows_manager.hpp"
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <libsecret/secret.h>
#include <cstring>
#include <glib.h>
#include "on_chain_bridge_plugin_private.h"

#define METHOD_CHANNEL_NAME "com.mrtnetwork.on_chain_bridge.methodChannel"

#define ON_CHAIN_BRIDGE_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), on_chain_bridge_plugin_get_type(), \
                              OnChainBridgePlugin))

struct _OnChainBridgePlugin
{
  GObject parent_instance;
  Storage *storage;
  OnChainBridgeUtils *utils;
  WindowsManager *windows_manager;
  NetworkHandler *network_handler;
};

G_DEFINE_TYPE(OnChainBridgePlugin, on_chain_bridge_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void on_chain_bridge_plugin_handle_method_call(
    OnChainBridgePlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP)
  {
    // If not a map, respond with an error
    fl_method_call_respond(method_call,
                           FL_METHOD_RESPONSE(fl_method_error_response_new(

                               "INVALID_ARGUMENT", // Error code
                               "Expected a map",   // Error message
                               nullptr             // No additional error details
                               )),
                           nullptr);
    return;
  }

  if (strcmp(method, "secureStorage") == 0)
  {
    response = self->storage->hanadle_storage_call(args);
  }
  else if (strcmp(method, "windowsManager") == 0)
  {
    response = self->windows_manager->handle_windows_manager_calls(method, args);
  }
  else
  {
    response = self->utils->handle_utils_calls(method, args);
  }
  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse *get_platform_version()
{
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void on_chain_bridge_plugin_dispose(GObject *object)
{
  G_OBJECT_CLASS(on_chain_bridge_plugin_parent_class)->dispose(object);
}

static void on_chain_bridge_plugin_class_init(OnChainBridgePluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = on_chain_bridge_plugin_dispose;
}

static void on_chain_bridge_plugin_init(OnChainBridgePlugin *plugin)
{
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  OnChainBridgePlugin *plugin = ON_CHAIN_BRIDGE_PLUGIN(user_data);
  on_chain_bridge_plugin_handle_method_call(plugin, method_call);
}

void on_chain_bridge_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  OnChainBridgePlugin *plugin = ON_CHAIN_BRIDGE_PLUGIN(
      g_object_new(on_chain_bridge_plugin_get_type(), nullptr));
  plugin->storage = new Storage(); // Dynamically allocate Storage object
  plugin->storage->setup();
  plugin->utils = new OnChainBridgeUtils();
  FlBinaryMessenger *messenger = fl_plugin_registrar_get_messenger(registrar);
  plugin->network_handler = new NetworkHandler(messenger);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            METHOD_CHANNEL_NAME,
                            FL_METHOD_CODEC(codec));
  plugin->windows_manager = new WindowsManager(registrar, FL_METHOD_CHANNEL(g_object_ref(channel)));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
