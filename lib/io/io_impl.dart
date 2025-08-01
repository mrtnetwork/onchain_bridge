part of 'package:on_chain_bridge/io/io_platforms.dart';

class _IoPlatformConst {
  static const String desktopEvent = "onEvent";
  static const String webViewEvent = "webView";
  static const String barcodeScannerEvent = "onBarcodeScanned";
}

class IoPlatformInterface extends OnChainBridgeInterface {
  static const MethodChannel _methodChannel =
      MethodChannel(NativeMethodsConst.channelAuthory);
  StreamController<BarcodeScannerResult>? _barcodeListener;
  static const EventChannel _networkChannel = EventChannel(
      'com.mrtnetwork.on_chain_bridge.methodChannel/network_status');
  static MethodChannel get channel => _methodChannel;
  final IDatabseInterfaceIo _database = IDatabseInterfaceIo();
  IoPlatformInterface() {
    if (Platform.isWindows || Platform.isMacOS) {
      _desktop = DesktopPlatformInterface();
    }
    _methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final Map<String, dynamic> data;
    try {
      data = (call.arguments as Map).cast();
    } catch (e) {
      return;
    }
    switch (call.method) {
      case _IoPlatformConst.desktopEvent:
        if (Platform.isWindows || Platform.isMacOS) {
          _desktop._methodCallHandler(data);
        }
        break;
      case _IoPlatformConst.webViewEvent:
        webView._methodCallHandler(data);
        break;
      case _IoPlatformConst.barcodeScannerEvent:
        _barcodeListener?.add(BarcodeScannerResult.fromJson(data));
        break;
      default:
    }
  }

  late final DesktopPlatformInterface _desktop;

  @override
  Future<bool> secureFlag({required bool isSecure}) async {
    final secure = await channel.invokeMethod<bool>("secureFlag", {
      'secure': isSecure,
    });

    return secure ?? false;
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    final data = await channel.invokeMethod(NativeMethodsConst.deviceInfo, {});
    return DeviceInfo.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<bool> share(Share share) async {
    final data = await channel.invokeMethod(
        NativeMethodsConst.shareMethod, share.toJson());
    return data;
  }

  // ios
  @override
  Future<AppPath> path() async {
    final data = await channel.invokeMethod(NativeMethodsConst.pathMethod, {});
    return AppPath.fromJson(Map<String, dynamic>.from(data));
  }

  // ios
  @override
  Future<bool> launchUri(String uri) async {
    final data = await channel
        .invokeMethod(NativeMethodsConst.launchUriMethod, {"uri": uri});
    return data;
  }

  @override
  DesktopPlatformInterface get desktop {
    if (Platform.isWindows || Platform.isMacOS) {
      return _desktop;
    }
    throw const OnChainBridgeException(
        "only available in desktop platforms (windows, macos)");
  }

  @override
  Future<Stream<BarcodeScannerResult>> startBarcodeScanner(
      {required BarcodeScannerParams param}) async {
    if (_barcodeListener != null) {
      throw const OnChainBridgeException("Service already running.");
    }
    await channel.invokeMethod("startBarcodeScanner", param.toJson());
    _barcodeListener ??= StreamController();
    _barcodeListener?.onCancel = () {
      channel.invokeMethod("stopBarcodeScanner");
      _barcodeListener?.close();
      _barcodeListener = null;
    };
    return _barcodeListener!.stream;
  }

  @override
  Future<void> stopBarcodeScanner() async {
    await channel.invokeMethod("stopBarcodeScanner", {});
    _barcodeListener?.close();
    _barcodeListener = null;
  }

  @override
  Future<bool> hasBarcodeScanner() async {
    if (Platform.isWindows || Platform.isLinux) return false;
    if (Platform.isAndroid) return true;
    final hasBarcode = await channel.invokeMethod<bool>("hasBarcodeScanner");
    return hasBarcode ?? false;
  }

  @override
  Future<PlatformConfig> init() async {
    final db = await _database.openDatabase();
    final barcode = await hasBarcodeScanner().catchError((e) => false);
    return PlatformConfig(
        platform: platform,
        hasBarcodeScanner: barcode,
        dbSupported: db.isReady,
        supportWebView: Platform.isAndroid || Platform.isMacOS,
        isExtension: false);
  }

  @override
  final WebViewIoInterface webView = WebViewIoInterface();
  AppPlatform _getPlatform() {
    if (Platform.isAndroid) {
      return AppPlatform.android;
    } else if (Platform.isIOS) {
      return AppPlatform.ios;
    } else if (Platform.isWindows) {
      return AppPlatform.windows;
    } else if (Platform.isMacOS) {
      return AppPlatform.macos;
    }
    throw const OnChainBridgeException("Unknown platform.");
  }

  @override
  late final AppPlatform platform = _getPlatform();

  @override
  Future<String?> readClipboard() async {
    final data =
        await Clipboard.getData(Clipboard.kTextPlain).catchError((e) => null);
    return data?.text;
  }

  @override
  Future<bool> writeClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onNetworkStatus => _networkChannel
      .receiveBroadcastStream()
      .map((event) => AppNativeEvent.fromJson(Map<String, dynamic>.from(event)))
      .where((e) => e.type == AppNativeEventType.internet)
      .cast<AppNativeEventConnection>()
      .map((e) => e.isOnline);

  @override
  Future<DATA?> readDb<DATA extends ITableData>(ITableRead<DATA> params) {
    return _database.readDb(params);
  }

  @override
  Future<List<DATA>> readAllDb<DATA extends ITableData>(
      ITableRead<DATA> params) {
    return _database.readAllDb(params);
  }

  @override
  Future<bool> removeDb(ITableRemove params) {
    return _database.removeDb(params);
  }

  @override
  Future<bool> writeDb(ITableInsertOrUpdate params) {
    return _database.writeDb(params);
  }

  @override
  Future<bool> writeAllDb(List<ITableInsertOrUpdate> params) {
    return _database.writeAllDb(params);
  }

  @override
  Future<bool> removeAllDb(List<ITableRemove> params) {
    return _database.removeAllDb(params);
  }

  @override
  Future<bool> dropDb(ITableDrop params) {
    return _database.dropDb(params);
  }
}
