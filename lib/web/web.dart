library;

export 'api/api.dart';
export 'wallet/event.dart';
export 'storage/storage.dart';
import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'package:on_chain_bridge/web/api/api.dart';
import 'package:on_chain_bridge/web/storage/database/interface/interface.dart';

OnChainBridgeInterface getPlatformInterface() => WebPlatformInterface._();

class WebPlatformInterface extends OnChainBridgeInterface {
  WebPlatformInterface._();
  late final IDatabseInterfaceJS database;

  @override
  Future<DeviceInfo> getDeviceInfo() {
    throw DeviceInfo();
  }

  @override
  Future<bool> secureFlag({required bool isSecure}) async {
    return false;
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
  Future<AppPath> path(String applicationId) {
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

  // final _database = IDatabseInterfaceJS();

  @override
  Future<PlatformConfig> init(String applicationId,
      {bool upgradableDatebase = true}) async {
    database = IDatabseInterfaceJS(upgradable: upgradableDatebase);
    final open = await database.openDatabase();
    final barcode = await hasBarcodeScanner().catchError((e) => false);
    return PlatformConfig(
        platform: platform,
        hasBarcodeScanner: barcode,
        dbSupported: open.isReady,
        supportWebView: false,
        isExtension: isExtension);
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

  StreamSubscription<dynamic>? _onOnline;
  StreamSubscription<dynamic>? _onOffline;
  late final StreamController<bool> _onNetworkChange =
      StreamController.broadcast(
          sync: true,
          onCancel: () {
            _onOnline?.cancel();
            _onOnline = null;
            _onOffline?.cancel();
            _onOffline = null;
          },
          onListen: () => _onNetworkChange.add(jsWindow.navigator.onLine));
  @override
  Stream<bool> get onNetworkStatus {
    _onOnline ??= jsWindow.stream('online').listen((e) {
      if (_onNetworkChange.hasListener) _onNetworkChange.add(true);
    });
    _onOffline ??= jsWindow.stream('offline').listen((e) {
      if (_onNetworkChange.hasListener) _onNetworkChange.add(false);
    });

    return _onNetworkChange.stream;
  }

  @override
  Future<DATA?> readDb<DATA extends ITableData>(ITableRead<DATA> params) {
    return database.readDb(params);
  }

  @override
  Future<List<DATA>> readAllDb<DATA extends ITableData>(
      ITableRead<DATA> params) {
    return database.readAllDb(params);
  }

  @override
  Future<bool> removeDb(ITableRemove params) {
    return database.removeDb(params);
  }

  @override
  Future<bool> writeDb(ITableInsertOrUpdate params) {
    return database.writeDb(params);
  }

  @override
  Future<bool> writeAllDb(List<ITableInsertOrUpdate> params) {
    return database.writeAllDb(params);
  }

  @override
  Future<bool> removeAllDb(List<ITableRemove> params) {
    return database.removeAllDb(params);
  }

  @override
  Future<bool> dropDb(ITableDrop params) {
    return database.dropDb(params);
  }

  @override
  Future<TouchIdStatus> touchIdStatus() {
    // TODO: implement touchIdStatus
    throw UnimplementedError();
  }

  @override
  Future<BiometricResult> authenticate(String reason,
      {String? title, String? buttonTitle}) {
    throw UnimplementedError();
  }
}
