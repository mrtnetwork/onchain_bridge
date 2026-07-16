import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'exception/exception.dart';

OnChainBridgeInterface getPlatformInterface() {
  throw OnChainBridgeException.unsuportedPlatform;
}
