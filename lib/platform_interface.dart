library;

import 'package:on_chain_bridge/base.dart'
    if (dart.library.js_interop) 'web/web.dart'
    if (dart.library.io) 'native/io_platforms.dart';
import 'on_chain_bridge.dart';
export 'models/models.dart';
export 'net_sdk/net_sdk.dart';
export 'interface/interface.dart';

class PlatformInterface {
  static final OnChainBridgeInterface instance = getPlatformInterface();
}
