import 'package:onchain_bridge/onchain_bridge.dart';
import 'exception/exception.dart';

OnChainBridgeInterface getPlatformInterface() {
  throw const OnChainBridgeException(
      'Cannot create a client instance dart:html or dart:io.');
}
