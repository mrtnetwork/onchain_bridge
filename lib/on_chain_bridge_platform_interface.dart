import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'on_chain_bridge_method_channel.dart';

abstract class OnChainBridgePlatform extends PlatformInterface {
  /// Constructs a OnChainBridgePlatform.
  OnChainBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static OnChainBridgePlatform _instance = MethodChannelOnChainBridge();

  /// The default instance of [OnChainBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelOnChainBridge].
  static OnChainBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OnChainBridgePlatform] when
  /// they register themselves.
  static set instance(OnChainBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
