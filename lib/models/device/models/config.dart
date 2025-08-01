import 'package:on_chain_bridge/models/device/models/platform.dart';

class PlatformConfig {
  static const int _storageVersion = 1;
  final AppPlatform platform;
  final bool hasBarcodeScanner;
  final int storageVersion;
  final bool supportWebView;
  final bool isExtension;
  final bool dbSupported;
  const PlatformConfig(
      {required this.platform,
      required this.hasBarcodeScanner,
      required this.supportWebView,
      required this.isExtension,
      required this.dbSupported,
      this.storageVersion = _storageVersion});
}
