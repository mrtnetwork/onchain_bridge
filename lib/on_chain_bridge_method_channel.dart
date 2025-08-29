import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'on_chain_bridge_platform_interface.dart';

/// An implementation of [OnChainBridgePlatform] that uses method channels.
class MethodChannelOnChainBridge extends OnChainBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('on_chain_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
