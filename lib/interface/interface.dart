import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/database/core/interface.dart';
import 'package:on_chain_bridge/models/models.dart';

abstract class IOnChainBridgeInterface<
    CREDENTIALRESPONSE extends PlatformCredentialResponse,
    CREDENTIALAUTHREQUEST extends PlatformCredentialAutneticateRequest,
    FILE extends ICrossFile> {
  Result<IDesktopPlatformInterface, IException> get desktop;
  Result<IPlatformWebViewInterface, IException> get webView;
  Result<AppPlatform, IException> get platform;
  Future<Result<bool, IException>> secureFlag({required bool isSecure});
  Future<Result<bool, IException>> share(IShare<FILE> share);

  Future<Result<AppPath, IException>> path(String applicationId);
  Future<Result<DeviceInfo, IException>> getDeviceInfo();
  Future<Result<bool, IException>> launchUri(String uri);
  Future<Result<Stream<BarcodeScannerResult>, IException>> startBarcodeScanner(
      {required BarcodeScannerParams param});
  Future<Result<void, IException>> stopBarcodeScanner();
  Future<Result<bool, IException>> hasBarcodeScanner();
  Future<Result<PlatformConfig, IException>> initMain(AppConfig config);
  Future<Result<String?, IException>> readClipboard();
  Future<Result<bool, IException>> writeClipboard(String text);
  Result<Stream<bool>, IException> get onNetworkStatus;

  /// biometric
  Future<Result<TouchIdStatus, IException>> touchIdStatus();
  Future<Result<BiometricResult, IException>> authenticate(
      CREDENTIALAUTHREQUEST request);

  Future<Result<CREDENTIALRESPONSE?, IException>> createPlatformCredential(
      PlatformCredentialRequest params);

  ///
  Future<Result<PickedFileContent?, IException>> pickAndReadFileContent(
      {PickFileContentEncoding encoding = PickFileContentEncoding.hex,
      AppFileType? type = AppFileType.txt});
  Future<Result<bool, IException>> saveFile(
      {required FILE file, String? title, AppFileType type = AppFileType.txt});

  Future<void> close();
  Result<PlatformStorage, IException> platformStorage();

  Future<Result<ICrossFile?, IException>> pickFile({AppFileType? type});
}

abstract class IPlatformWebViewInterface {
  bool get supported;
  Future<Object?> loadScript(
      {required String viewType, required String script});
  Future<void> openUrl({required String viewType, required String url});
  Future<bool> canGoForward(String viewType);
  Future<bool> canGoBack(String viewType);
  Future<void> goBack(String viewType);
  Future<void> goForward(String viewType);
  Future<void> reload(String viewType);
  Future<void> dispose(String viewType);
  Future<void> addJsInterface({required String viewType, required String name});
  Future<void> removeJsInterface(
      {required String viewType, required String name});
  Future<void> updateFrame(
      {required String viewType, required WidgetSize size});
  Future<void> init(String viewType,
      {String url = "https://google.com", String? jsInterface = "onChain"});
  Future<void> clearCache(String viewType);
  void addListener(WebViewListener listener);
  void removeListener(WebViewListener listener);
}

abstract class IDesktopPlatformInterface {
  Future<bool> show();
  Future<bool> hide();
  Future<bool> init();
  Future<bool> setIcon(String path);
  Future<bool> setMaximumSize(WidgetSize size);
  Future<bool> setMinimumSize(WidgetSize size);
  Future<void> setBounds(
      {required double pixelRatio,
      WidgetRect? bounds,
      WidgetOffset? position,
      WidgetSize? size,
      bool animate = false});
  Future<bool> setPreventClose(bool preventClose);

  Future<bool> setFullScreen(bool isFullScreen);
  Future<bool> isFullScreen();
  Future<bool> restore();
  Future<bool> minimize();
  Future<bool> isMinimized();
  Future<bool> unmaximize();
  Future<bool> isMaximized();
  Future<bool> isVisible();
  Future<void> waitUntilReadyToShow();
  Future<bool> isFocused();
  Future<bool> blur();
  Future<bool> focus();
  Future<bool> isPreventClose();
  Future<bool> close();
  Future<bool> setAsFrameless();
  Future<bool> isResizable();
  Future<bool> setResizable(bool isResizable);
  Future<WidgetRect> getBounds(double pixelRatio);

  void addListener(WindowListener listener);

  void removeListener(WindowListener listener);
}
