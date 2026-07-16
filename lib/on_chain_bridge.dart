// This Flutter plugin incorporates code inspired by the following projects:

// 1. [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - Some of the methods in this plugin are inspired by the flutter_secure_storage plugin, which is licensed under the BSD license. The original project can be found at: https://github.com/mogol/flutter_secure_storage
// 2. [window_manager](https://pub.dev/packages/window_manager) - Additionally, some methods are inspired by the window_manager plugin, which is licensed under the MIT license. The original project can be found at: https://github.com/leanflutter/window_manager

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class OnChainBridgeInterface<
        CREDENTIALRESPONSE extends PlatformCredentialResponse,
        CREDENTIALAUTHREQUEST extends PlatformCredentialAutneticateRequest,
        FILE extends ICrossFile> extends PlatformInterface
    implements
        IOnChainBridgeInterface<CREDENTIALRESPONSE, CREDENTIALAUTHREQUEST,
            FILE> {
  OnChainBridgeInterface() : super(token: _token);
  static final Object _token = Object();
  @override
  Result<DesktopPlatformInterface, IException> get desktop;
  @override
  Result<PlatformWebViewInterface, IException> get webView;
  @override
  Result<AppPlatform, IException> get platform;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PlatformInterface] when
  /// they register themselves.
  static set instance(OnChainBridgeInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  static void registerWith() {}
}

abstract class PlatformWebViewInterface implements IPlatformWebViewInterface {}

abstract class DesktopPlatformInterface implements IDesktopPlatformInterface {}
