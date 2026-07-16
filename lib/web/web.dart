library;

export 'api/api.dart';
export 'wallet/event.dart';
export 'storage/storage.dart';
import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/core/interface.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'package:on_chain_bridge/web/api/api.dart';
import 'package:on_chain_bridge/web/interface/interface.dart';
import 'package:on_chain_bridge/web/storage/database/interface/interface.dart';
import 'package:on_chain_bridge/web/types/file.dart';

OnChainBridgeInterface getPlatformInterface() => WebPlatformInterface._();

class WebPlatformInterface extends OnChainBridgeInterface<
    PlatformCredentialWebResponse,
    PlatformCredentialAutneticateWebRequest,
    WebFile> implements IWebOnChainBridgeInterface {
  WebPlatformInterface._();

  @override
  Future<Result<DeviceInfo, IException>> getDeviceInfo() async {
    return Err(OnChainBridgeException.unsuported);
  }

  @override
  Future<Result<bool, IException>> secureFlag({required bool isSecure}) async {
    return Err(OnChainBridgeException.unsuported);
  }

  @override
  Future<Result<bool, IException>> share(IShare<WebFile> share) async {
    return window().andThenAsync((window) async {
      try {
        switch (share) {
          case IShareText<WebFile>():
            await window.navigator.share_(title: share.subject);
            return Ok(true);

          case IShareFile<WebFile>(:final file, :final subject, :final message):
            await window.navigator
                .share_(title: subject, files: [file.file], text: message);
            return Ok(true);
        }
      } catch (_) {
        return Err(OnChainBridgeException.unexpectedError);
      }
    });
  }

  @override
  Future<Result<AppPath, IException>> path(String applicationId) async {
    return Err(OnChainBridgeException.unsuported);
  }

  @override
  Future<Result<bool, IException>> launchUri(String uri) async {
    return window()
        .map((window) => window.open(uri, null, 'noopener,noreferrer') != null);
  }

  @override
  Result<DesktopPlatformInterface, IException> get desktop =>
      Err(OnChainBridgeException.unsuported);

  @override
  Future<Result<Stream<BarcodeScannerResult>, IException>> startBarcodeScanner(
      {BarcodeScannerParams param = const EmptyBarcodeScannerParams()}) {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<Result<void, IException>> stopBarcodeScanner() async {
    return Err(OnChainBridgeException.unsuported);
  }

  @override
  Future<Result<bool, IException>> hasBarcodeScanner() async {
    return window().map((window) => window.barcode.isDefinedAndNotNull);
  }

  @override
  Future<Result<PlatformConfig, IException>> initMain(AppConfig config,
      {bool upgradableDatebase = true}) async {
    final barcode = await hasBarcodeScanner();
    return Ok(PlatformConfig(
        platform: AppPlatform.web,
        isExtension: isExtension,
        features: [if (barcode.ok() ?? false) PlatformFeatures.barcode]));
  }

  @override
  Result<PlatformWebViewInterface, IException> get webView =>
      Err(OnChainBridgeException.unsuported);

  @override
  late final Result<AppPlatform, IException> platform = Ok(AppPlatform.web);

  @override
  Future<Result<String?, IException>> readClipboard() async {
    return window().andThenAsync((window) async =>
        Ok(await window.navigatorNullable?.clipboard?.readText_()));
  }

  @override
  Future<Result<bool, IException>> writeClipboard(String text) async {
    return window().andThenAsync((window) async => Ok(
        await window.navigatorNullable?.clipboard?.writeText_(text) ?? false));
  }

  StreamSubscription<JSObject?>? _onOnline;
  StreamSubscription<JSObject?>? _onOffline;
  late final StreamController<bool> _onNetworkChange =
      StreamController.broadcast(onCancel: () {
    _onOnline?.cancel();
    _onOnline = null;
    _onOffline?.cancel();
    _onOffline = null;
  }, onListen: () {
    final window = jsWindowOrNull;
    if (window == null) return;
    _onNetworkChange.add(window.navigator.onLine);
  });
  @override
  Result<Stream<bool>, IException> get onNetworkStatus {
    return window().map((window) {
      _onOnline ??= window.stream('online').stream.listen((e) {
        if (_onNetworkChange.hasListener) _onNetworkChange.add(true);
      });
      _onOffline ??= window.stream('offline').stream.listen((e) {
        if (_onNetworkChange.hasListener) _onNetworkChange.add(false);
      });

      return _onNetworkChange.stream;
    });
  }

  @override
  Future<Result<TouchIdStatus, IException>> touchIdStatus() async {
    if (isExtension) return Ok(TouchIdStatus.notAvailable);
    return window().mapAsync((window) async {
      final cred = window.navigator.credentials;
      if (cred == null) return TouchIdStatus.notAvailable;
      final platformAuth = await PublicKeyCredential
          .isUserVerifyingPlatformAuthenticatorAvailable_();
      if (platformAuth) return TouchIdStatus.available;
      return TouchIdStatus.notAvailable;
    });
  }

  @override
  Future<Result<BiometricResult, IException>> authenticate(
      PlatformCredentialAutneticateWebRequest request) async {
    return window().andThenAsync((window) async {
      final credential = window.navigator.credentials;
      if (credential == null) return Ok(BiometricResult.notAvailable);
      final response =
          await credential.get_(id: request.id, challenge: request.challange);
      if (response == null) return Ok(BiometricResult.failed);
      return await request.verify(
        InternalPublicKeyWebAuthResponse(
            authenticatorData:
                response.response.authenticatorData.toDart.asUint8List(),
            clientDataJSON:
                response.response.clientDataJSON.toDart.asUint8List(),
            signature: response.response.signature.toDart.asUint8List()),
      );
    });
  }

  @override
  Future<Result<PlatformCredentialWebResponse?, IException>>
      createPlatformCredential(PlatformCredentialRequest params) async {
    return window().andThenAsync((window) async {
      final credential = window.navigatorNullable?.credentials;
      if (credential == null) return Ok(null);
      final id = await credential.create_(
          rpName: params.appName,
          name: params.name,
          displayName: params.displayName,
          id: params.accountId);
      if (id == null) return Ok(null);
      return Ok(PlatformCredentialWebResponse(
          id: id.id.toDart,
          publicKey: BytesUtils.toHexString(
              id.response.getPublicKey().toDart.asUint8List())));
    });
  }

  @override
  Future<Result<PickedFileContent?, IException>> pickAndReadFileContent(
      {PickFileContentEncoding encoding = PickFileContentEncoding.hex,
      AppFileType? type = AppFileType.txt}) async {
    return window().andThenAsync((window) async {
      final file =
          await window.document.pickFile([if (type != null) type.extension]);
      return file.andThenAsync((file) async {
        if (file == null) return Ok(null);
        switch (encoding) {
          case PickFileContentEncoding.bytes:
            final bytes = await file.toBytes();
            return bytes.map(
                (e) => PickedFileContent(name: file.name, data: e, path: null));
          case PickFileContentEncoding.utf8:
            final text = await file.toText();
            return text.map((e) => PickedFileContent(
                name: file.name, data: StringUtils.encode(e), path: null));
          case PickFileContentEncoding.hex:
            final text = await file.toText();
            return text.andThen((e) {
              final toBytes = BytesUtils.tryFromHexString(e);
              if (toBytes == null) {
                return Err(OnChainBridgeException.invalidFileData);
              }
              return Ok(PickedFileContent(
                  name: file.name, data: toBytes, path: null));
            });
        }
      });
    });
  }

  @override
  Future<Result<WebFile?, IException>> pickFile({AppFileType? type}) async {
    return window().andThenAsync((window) async {
      final result =
          await window.document.pickFile([if (type != null) type.extension]);
      return result.map((e) {
        if (e == null) return null;
        return WebFile(e);
      });
    });
  }

  @override
  Future<Result<bool, IException>> saveFile(
      {required WebFile file,
      String? title,
      AppFileType type = AppFileType.txt}) async {
    return window().map((window) {
      window.documentOrNull
          ?.downloadJsFile(file: file.file, fileName: file.name);
      return window.documentOrNull != null;
    });
  }

  @override
  Result<PlatformStorage, IException> platformStorage() {
    return Ok(WebPlatformStorage());
  }

  @override
  Result<ChromeAPI, IException> chromeApi() {
    final chrome = extensionOrNull;
    if (!isExtensionContext || chrome == null) {
      return Err(OnChainBridgeException.unsuported);
    }
    return Ok(chrome);
  }

  @override
  bool get isExtensionContext => isExtension;

  @override
  Result<Window, IException> window() {
    final window = jsWindowOrNull;
    if (window == null) return Err(OnChainBridgeException.unsuported);
    return Ok(window);
  }

  @override
  Future<void> close() async {}
}
