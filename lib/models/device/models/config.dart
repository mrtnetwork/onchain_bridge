import 'package:on_chain_bridge/models/device/models/platform.dart';

class PlatformConfig {
  static const int _storageVersion = 1;
  final AppPlatform platform;
  final bool hasBarcodeScanner;
  final int storageVersion;
  final bool platformSupported;
  final bool supportWebView;
  const PlatformConfig(
      {required this.platform,
      required this.hasBarcodeScanner,
      required this.platformSupported,
      required this.supportWebView,
      this.storageVersion = _storageVersion});
}
