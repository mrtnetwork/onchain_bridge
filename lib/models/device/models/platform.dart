import 'package:on_chain_bridge/exception/exception.dart';

enum AppPlatform {
  windows,
  web,
  android,
  ios,
  macos,
  linux;

  bool get isDesktop =>
      this == AppPlatform.windows ||
      this == AppPlatform.macos ||
      this == AppPlatform.linux;

  static AppPlatform fromName(String? name) {
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () =>
          throw const OnChainBridgeException("Invalid platform name."),
    );
  }
}
