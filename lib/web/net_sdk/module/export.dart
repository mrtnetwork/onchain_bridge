import 'dart:js_interop';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/web/net_sdk/module/module.dart';

@JS("createNetworkSdk")
external set createNetworkSdk(JSFunction fn);

NetSdkWebModuleInterface creaeteSdk() => createJSInteropWrapper(
        NetSdkWebModuleDefault(DefaultNetSdk(AppEnvironment.web)))
    as NetSdkWebModuleInterface;

void netSdkModuleExport() {
  createNetworkSdk = creaeteSdk.toJS;
}
