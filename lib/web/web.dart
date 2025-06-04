library;

export 'api/api.dart';
export 'wallet/event.dart';
export 'storage/storage.dart';
import 'dart:js_interop';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';
import 'package:on_chain_bridge/web/storage/safe_storage/safestorage.dart';
import 'package:on_chain_bridge/web/storage/storage/index_db_storage.dart';

OnChainBridgeInterface getPlatformInterface() => WebPlatformInterface._();

class WebPlatformInterface extends OnChainBridgeInterface {
  WebPlatformInterface._();
  IndexDbStorage? _storage;
  IndexDbStorage get storage => _storage!;
  Future<void> _initDatabase() async {
    _storage?.close();
    _storage = null;
    _storage = await SafeStorage.init();
    _storage?.database.onclose = () {
      SafeStorage.init().then((e) => _storage = e);
    }.toJS;
  }

  @override
  void addNetworkListener(NetworkStatusListener listener) {}

  @override
  Future<bool> containsKeySecure(String key) async {
    final data = await storage.read(key);
    return data != null;
  }

  @override
  Future<NetworkEvent> deviceConnectionStatus() {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<DeviceInfo> getDeviceInfo() {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<Map<String, String>> readAllSecure({String? prefix}) async {
    return storage.all(prefix: prefix);
  }

  @override
  Future<Map<String, String>> readMultipleSecure(List<String> keys) async {
    return storage.reads(keys);
  }

  @override
  Future<String?> readSecure(String key) async {
    return storage.read(key);
  }

  @override
  Future<List<String>> readKeys({String? prefix}) async {
    final keys = await storage.readKeys(prefix: prefix);
    return keys;
  }

  @override
  Future<bool> removeAllSecure({String? prefix}) async {
    if (prefix != null && prefix.isNotEmpty) {
      final keys = await readKeys(prefix: prefix);
      return removeMultipleSecure(keys);
    }
    await storage.clear();
    await _initDatabase();
    return true;
  }

  @override
  Future<bool> removeMultipleSecure(List<String> keys) async {
    await storage.removes(keys);
    return true;
  }

  @override
  void removeNetworkListener(NetworkStatusListener listener) {}

  @override
  Future<bool> removeSecure(String key) async {
    await storage.remove(key);
    return true;
  }

  @override
  Future<bool> secureFlag({required bool isSecure}) async {
    return false;
  }

  @override
  Future<bool> writeSecure(String key, String value) async {
    await storage.save(key, value);
    return true;
  }

  @override
  Future<bool> share(Share share) {
    return _share(share);
  }

  String _toFilePath(String path) {
    if (path.startsWith("blob:")) {
      return path.replaceFirst("blob:", "");
    }
    return path;
  }

  Future<bool> _share(Share share) async {
    try {
      List<JSFile> files = [];
      if (share.isFile) {
        final response = await jsWindow.fetch_(_toFilePath(share.path!));
        if (response.status != 200) return false;
        final file = JSFile([await response.arrayBuffer().toDart].toJS,
            share.fileName!, JSFileOption(type: share.getMimeType()));
        files.add(file);
      }
      await jsWindow.navigator
          .share_(title: share.subject, text: share.text, files: files);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AppPath> path() {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<bool> launchUri(String uri) async {
    final result = jsWindow.open(uri, null, 'noopener,noreferrer');
    return result != null;
  }

  @override
  SpecificPlatfromMethods get desktop => throw UnimplementedError(
      "only available in desktop platforms (windows, macos)");

  @override
  Future<Stream<BarcodeScannerResult>> startBarcodeScanner(
      {BarcodeScannerParams param = const EmptyBarcodeScannerParams()}) {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<void> stopBarcodeScanner() {
    throw OnChainBridgeException.unsuported;
  }

  @override
  Future<bool> hasBarcodeScanner() async {
    return jsWindow.barcode != null;
  }

  @override
  Future<PlatformConfig> getConfig() async {
    await _initDatabase();
    final barcode = await hasBarcodeScanner().catchError((e) => false);
    return PlatformConfig(
        platform: platform,
        hasBarcodeScanner: barcode,
        platformSupported: _storage != null,
        supportWebView: false);
  }

  @override
  PlatformWebView get webView => throw UnimplementedError();

  @override
  AppPlatform get platform => AppPlatform.web;

  @override
  Future<String?> readClipboard() async {
    return jsWindow.navigatorNullable?.clipboard?.readText_();
  }

  @override
  Future<bool> writeClipboard(String text) async {
    return await jsWindow.navigatorNullable?.clipboard?.writeText_(text) ??
        false;
  }
}
