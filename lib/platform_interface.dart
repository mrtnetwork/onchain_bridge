library;

import 'package:on_chain_bridge/base.dart'
    if (dart.library.js_interop) 'web/web.dart'
    if (dart.library.io) 'io/io_platforms.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'on_chain_bridge.dart';

class PlatformInterface {
  static final OnChainBridgeInterface instance = getPlatformInterface();
  static AppPlatform get appPlatform => instance.platform;
  static bool get isWindows => appPlatform == AppPlatform.windows;
  static bool get isWeb => appPlatform == AppPlatform.web;
  static bool get isMacos => appPlatform == AppPlatform.macos;
  static bool get isLinux => appPlatform == AppPlatform.linux;

  static PlatformWebView get webViewController => instance.webView;
}
