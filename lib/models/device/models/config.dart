import 'package:on_chain_bridge/models/device/models/platform.dart';

enum PlatformFeatures {
  barcode,
  webview,
}

class PlatformConfig {
  static const int _storageVersion = 1;
  final AppPlatform platform;
  final int storageVersion;
  final bool isExtension;
  final List<PlatformFeatures> features;
  const PlatformConfig(
      {required this.platform,
      required this.isExtension,
      required this.features,
      this.storageVersion = _storageVersion});

  bool get hasWebview => features.contains(PlatformFeatures.webview);
  bool get hasBarcodeScanner => features.contains(PlatformFeatures.barcode);
}

enum PlatIsolateformInitializationStatus {
  normal,
  unsupportNetSdk,
  failed;

  bool get isNormal => this == normal;
}

class PlatformIsolateConfig {
  final PlatIsolateformInitializationStatus status;
  const PlatformIsolateConfig(this.status);
}
