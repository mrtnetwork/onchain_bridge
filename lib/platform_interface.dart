library;

import 'package:onchain_bridge/base.dart'
    if (dart.library.js_interop) 'web/web.dart'
    if (dart.library.io) 'io/io_platforms.dart';
import 'package:onchain_bridge/models/models.dart';
import 'onchain_bridge.dart';

class PlatformInterface {
  static final OnChainBridgeInterface instance = getPlatformInterface();
  static AppPlatform get appPlatform => instance.platform;
  static bool get isWindows => appPlatform == AppPlatform.windows;
  static bool get isWeb => appPlatform == AppPlatform.web;
  static bool get isMacos => appPlatform == AppPlatform.macos;
  static PlatformWebView get webViewController => instance.webView;
}
