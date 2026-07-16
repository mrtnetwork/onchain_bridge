enum AppPlatform {
  windows,
  web,
  android,
  ios,
  macos,
  linux;

  bool get isDesktop => this == windows || this == macos || this == linux;
  bool get isWeb => this == web;
  bool get isWindows => this == windows;
  bool get isLinux => this == linux;
  bool get isAndroid => this == android;
  bool get isMacos => this == macos;
}

enum AppEnvironment {
  web,
  native;

  bool get isNative => this == native;
  bool get isWeb => this == web;
  // AppEnvironment get currentEnvironment =>
  //   const bool.fromEnvironment('dart.library.js_interop')
  //       ? AppEnvironment.web
  //       : AppEnvironment.native;
}
