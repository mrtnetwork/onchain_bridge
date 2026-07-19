part of 'package:on_chain_bridge/native/io_platforms.dart';

class _IoPlatformConst {
  static const String desktopEvent = "onEvent";
  static const String webViewEvent = "webView";
  static const String barcodeScannerEvent = "onBarcodeScanned";
}

class IoNativeChannel {
  final MethodChannel channel = MethodChannel(NativeMethodsConst.channelAuthory);
  final EventChannel networkChannel =
      EventChannel('com.mrtnetwork.on_chain_bridge.methodChannel/network_status');
  late final Stream<AppNativeEvent> networkChannelStream = networkChannel
      .receiveBroadcastStream()
      .map((event) => AppNativeEvent.fromJson(Map<String, dynamic>.from(event)));
}

class IoPlatformInterface extends OnChainBridgeInterface<PlatformCredentialIoResponse,
    PlatformCredentialAutneticateIoRequest, NativeFile> {
  IoNativeChannel? _nativeChannel;

  Result<IoNativeChannel, IException> get channel {
    final channel = _nativeChannel;
    if (channel != null) return Ok(channel);
    return Err(OnChainBridgeException.invalidApiState);
  }

  bool _inited = false;

  StreamController<BarcodeScannerResult>? _barcodeListener;
  WebViewIoInterface? _webView;
  DefaultDesktopPlatformInterface? _desktop;
  final _lock = SafeAtomicLock();

  @override
  Result<WebViewIoInterface, IException> get webView {
    return channel.andThen((_) {
      final webview = _webView;
      if (webview == null) {
        return Err(OnChainBridgeException.unsuported);
      }
      return Ok(webview);
    });
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final Map<String, dynamic> data;
    try {
      data = JsonParser.valueEnsureAsMap<String, dynamic>(call.arguments);
    } catch (e) {
      return;
    }
    switch (call.method) {
      case _IoPlatformConst.desktopEvent:
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          _desktop?._methodCallHandler(data);
        }
        break;
      case _IoPlatformConst.webViewEvent:
        _webView?._methodCallHandler(data);
        break;
      case _IoPlatformConst.barcodeScannerEvent:
        final barcode = BarcodeScannerResult.fromJson(data);
        assert(barcode != null, "unexpected barcode response.");
        if (barcode == null) return;
        _barcodeListener?.add(barcode);
        break;
      default:
    }
  }

  Future<Result<T, IException>> invokeMethod<T extends Object?>(String method,
      [dynamic arguments]) async {
    try {
      return await channel.andThenAsync((channel) async {
        final result = await channel.channel.invokeMethod(method, arguments);
        return Ok(JsonParser.valueAs<T>(result));
      });
    } catch (e, trace) {
      Logging.danger(
        fn: () => LogDataDefault(
            runtime: runtimeType,
            data: method == NativeMethodsConst.secureStorageMethod ? null : arguments,
            trace: trace.toString(),
            message: "invlodeMethod failed. method: $method, error: ${e.toString()}",
            function: "invokeMethod"),
      );
      if (e case OnChainBridgeException()) {
        return Err(e);
      }
      return Err(OnChainBridgeException.unexpectedError);
    }
  }

  @override
  Future<Result<bool, IException>> secureFlag({required bool isSecure}) async {
    return platform.andThenAsync((platform) async {
      if (!platform.isAndroid) {
        return Err(OnChainBridgeException.unsuported);
      }
      final secure = await invokeMethod<bool?>("secureFlag", {'secure': isSecure});
      return secure.map((e) => e ?? false);
    });
  }

  @override
  Future<Result<DeviceInfo, IException>> getDeviceInfo() async {
    final data =
        await invokeMethod<Map<String, dynamic>>(NativeMethodsConst.deviceInfo, {});
    return data.map((data) => DeviceInfo.fromJson(data));
  }

  @override
  Future<Result<bool, IException>> share(IShare<NativeFile> share) async {
    final json = switch (share) {
      IShareText<NativeFile>(:final text, :final subject) => {
          "text": text,
          "subject": subject,
          "path": null,
          "mimetype": null
        },
      IShareFile<NativeFile>(:final message, :final subject, :final file, :final type) =>
        {
          "text": message,
          "subject": subject,
          "path": file.path,
          "mimetype": type.mimeType
        },
    };
    return await invokeMethod<bool>(NativeMethodsConst.shareMethod, json);
  }

  // ios
  @override
  Future<Result<AppPath, IException>> path(String applicationId) async {
    return platform.andThenAsync((platform) async {
      final data =
          await invokeMethod<Map<String, dynamic>>(NativeMethodsConst.pathMethod, {});
      return data.map((data) => AppPath.fromJson(data, platform, Platform.pathSeparator));
    });
  }

  @override
  Future<Result<bool, IException>> launchUri(String uri) async {
    final data =
        await invokeMethod<bool>(NativeMethodsConst.launchUriMethod, {"uri": uri});
    return data;
  }

  @override
  Result<DesktopPlatformInterface, IException> get desktop {
    final desktop = _desktop;
    if (desktop != null) return Ok(desktop);
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return Err(OnChainBridgeException.unsuportedPlatform);
    }
    return Err(OnChainBridgeException.unsuported);
  }

  @override
  Future<Result<Stream<BarcodeScannerResult>, IException>> startBarcodeScanner(
      {required BarcodeScannerParams param}) async {
    if (_barcodeListener != null) {
      return Err(BarcodeException.serviceAlreadyRunnig);
    }
    final result = await invokeMethod("startBarcodeScanner", param.toJson());
    return result.map((_) {
      final controller = _barcodeListener ??= StreamController();
      controller.onCancel = () {
        invokeMethod("stopBarcodeScanner");
        _barcodeListener?.close();
        _barcodeListener = null;
      };
      return controller.stream;
    });
  }

  @override
  Future<Result<void, IException>> stopBarcodeScanner() async {
    final result = await invokeMethod("stopBarcodeScanner", {});
    _barcodeListener?.close();
    _barcodeListener = null;
    return result;
  }

  @override
  Future<Result<bool, IException>> hasBarcodeScanner() async {
    if (Platform.isWindows || Platform.isLinux) return Ok(false);
    if (Platform.isAndroid) return Ok(true);
    return await invokeMethod<bool>("hasBarcodeScanner");
  }

  @override
  Future<Result<PlatformConfig, IException>> initMain(AppConfig config) async {
    return platform.andThenAsync((platform) async {
      return _lock.run(() async {
        if (_inited) {
          return Err(OnChainBridgeException.invalidApiState);
        }
        _inited = true;
        final nativeChannel = _nativeChannel = IoNativeChannel();
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          _desktop = DefaultDesktopPlatformInterface(nativeChannel);
        }
        _webView = WebViewIoInterface(nativeChannel);
        nativeChannel.channel.setMethodCallHandler(_methodCallHandler);
        final path = await this.path(config.applicationId);
        return path.andThenAsync((path) async {
          final barcode = await hasBarcodeScanner();
          return Ok(PlatformConfig(
              platform: platform,
              features: [
                if (barcode.ok() ?? false) PlatformFeatures.barcode,
                if (Platform.isAndroid || Platform.isMacOS) PlatformFeatures.webview
              ],
              isExtension: false));
        });
      });
    });
  }

  @override
  late final Result<AppPlatform, IException> platform = OnChainBridgeIoUtils.platform();

  @override
  Future<Result<String?, IException>> readClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain).catchError((e) => null);
    return Ok(data?.text);
  }

  @override
  Future<Result<bool, IException>> writeClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return Ok(true);
    } catch (_) {
      return Ok(false);
    }
  }

  @override
  Result<Stream<bool>, IException> get onNetworkStatus => channel.map(
        (channel) {
          return channel.networkChannelStream
              .where((e) => e.type == AppNativeEventType.internet)
              .cast<AppNativeEventConnection>()
              .map((e) => e.isOnline);
        },
      );

  @override
  Future<Result<TouchIdStatus, IException>> touchIdStatus() async {
    final result = await invokeMethod<String>(
        NativeMethodsConst.authenticate, {"type": NativeMethodsConst.touchIdStatus});
    return result.map((e) => TouchIdStatus.fromName(e));
  }

  @override
  Future<Result<BiometricResult, IException>> authenticate(
      PlatformCredentialAutneticateIoRequest request) async {
    final result = await invokeMethod<String>(NativeMethodsConst.authenticate, {
      "reason": request.reason,
      "title": request.title,
      "button_title": request.buttonTitle,
      "type": NativeMethodsConst.authenticate
    });
    return result
        .andThenAsync((result) => request.verify(BiometricResult.fromName(result)));
  }

  @override
  Future<Result<PlatformCredentialIoResponse?, IException>> createPlatformCredential(
      PlatformCredentialRequest params) async {
    final result = await invokeMethod<String>(NativeMethodsConst.authenticate, {
      "reason": params.reason,
      "title": params.title,
      "button_title": params.buttonTitle,
      "type": NativeMethodsConst.authenticate
    });
    return result.map((result) {
      final status = BiometricResult.fromName(result);
      if (status == BiometricResult.success) {
        return PlatformCredentialIoResponse();
      }
      return null;
    });
  }

  @override
  Future<Result<PickedFileContent?, IException>> pickAndReadFileContent(
      {PickFileContentEncoding encoding = PickFileContentEncoding.hex,
      AppFileType? type = AppFileType.txt}) async {
    return platform.andThenAsync((platform) async {
      final result = await invokeMethod<String?>(NativeMethodsConst.pickFile, {
        "extension": type?.getPickFileExtenson(platform),
        "mime_type": type?.mimeType
      });
      return result.andThen((result) {
        if (result == null) return Ok(null);
        final file = File(result);
        if (!file.existsSync()) return Ok(null);
        final name = file.path.split("/").last;
        List<int> data;
        try {
          switch (encoding) {
            case PickFileContentEncoding.bytes:
              data = file.readAsBytesSync();
              break;
            case PickFileContentEncoding.utf8:
              data = StringUtils.encode(file.readAsStringSync());
              break;
            case PickFileContentEncoding.hex:
              data = BytesUtils.fromHexString(file.readAsStringSync().trim());
              break;
          }
        } catch (e) {
          return Err(OnChainBridgeException.invalidFileData);
        }

        return Ok(PickedFileContent(name: name, data: data, path: result));
      });
    });
  }

  @override
  Future<Result<NativeFile?, IException>> pickFile({AppFileType? type}) async {
    return platform.andThenAsync((platform) async {
      final result = await invokeMethod<String?>(NativeMethodsConst.pickFile, {
        "extension": type?.getPickFileExtenson(platform),
        "mime_type": type?.mimeType
      });
      return result.andThen((result) {
        if (result == null) return Ok(null);
        return NativeFile.fromPath(result);
      });
    });
  }

  @override
  Future<Result<bool, IException>> saveFile(
      {required NativeFile file,
      String? title,
      AppFileType type = AppFileType.txt}) async {
    return platform.andThenAsync((platform) async {
      final result = await invokeMethod<bool?>(NativeMethodsConst.saveFile, {
        "file_path": file.path,
        "file_name": type.toFileName(file.name),
        "extension": type.getSaveFileExtenson(platform),
        "mime_type": type.mimeType,
        "title": title
      });
      return result.map((e) => e ?? false);
    });
  }

  @override
  Future<void> close() async {}

  @override
  Result<PlatformStorage, IException> platformStorage() {
    final channel = this.channel;
    return channel.map((e) => NativePlatformStorage(e.channel));
  }
}
