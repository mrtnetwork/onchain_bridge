#ifndef FLUTTER_PLUGIN_ON_CHAIN_BRIDGE_PLUGIN_H_
#define FLUTTER_PLUGIN_ON_CHAIN_BRIDGE_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>
G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

typedef struct _OnChainBridgePlugin OnChainBridgePlugin;
typedef struct
{
  GObjectClass parent_class;
} OnChainBridgePluginClass;

FLUTTER_PLUGIN_EXPORT GType on_chain_bridge_plugin_get_type();

FLUTTER_PLUGIN_EXPORT void on_chain_bridge_plugin_register_with_registrar(
    FlPluginRegistrar *registrar);

FLUTTER_PLUGIN_EXPORT const char *generate_secret_key();

G_END_DECLS

#endif // FLUTTER_PLUGIN_ON_CHAIN_BRIDGE_PLUGIN_H_
