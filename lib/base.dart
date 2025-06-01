import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'exception/exception.dart';

OnChainBridgeInterface getPlatformInterface() {
  throw const OnChainBridgeException(
      'Cannot create a client instance dart:html or dart:io.');
}
