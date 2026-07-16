import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/web/api/chrome/chrome.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_bridge/web/api/web_auth/types.dart';
import 'html.dart';
import 'media_stream.dart';
import 'channel.dart';

@JS("cloneInto")
external T _cloneInto<T extends JSAny>(T? object, JSAny? where);

@JS("cloneInto")
external JSFunction? get cloneInto;

@JS("console")
external JSConsole get jsConsole;

@JS("JSON")
external JSON get jsJson;
@JS("window")
external Window get jsWindow;
@JS("window")
extension type Window._(JSObject _) implements WebEventStream {
  external factory Window();
  external Window? get parent;
  @JS("BarcodeDetector")
  external BarcodeDetector? get barcode;
  @JS("navigator")
  external JSNavigator get navigator;
  @JS("navigator")
  external JSNavigator? get navigatorNullable;
  @JS("URL")
  external URL get url;
  @JS("document")
  external Document get document;
  @JS("document")
  external Document? get documentOrNull;
  @JS("location")
  external Location get location;

  external void close();

  @JS("open")
  external JSAny? open(String? url, String? target, String? windowFeatures);
  @JS("fetch")
  external JSPromise<Response> fetch(String resource);
  @JS("fetch")
  external JSPromise<Response> fetchWithOption(
      String resource, FetchOptions? options);
  @JS("webkit")
  external WebKit get webkit;

  @JS("postMessage")
  external void postMessage(JSAny? message);
  @JS("focus")
  external void focus();

  external set ononline(JSFunction _);
  external set onoffline(JSFunction _);
}

@JS()
extension type WebKitPort._(JSObject _) implements JSAny {
  external void postMessage(JSAny? message);
}
@JS()
extension type WebKitMessageHandlers._(JSObject _) implements JSAny {
  @JS("onChain")
  external WebKitPort get onChain;
}
@JS("webkit")
extension type WebKit._(JSObject _) implements JSAny {
  @JS("messageHandlers")
  external WebKitMessageHandlers get messageHandlers;
}

@JS("location")
extension type Location._(JSObject _) implements WebEventStream {
  external factory Location();
  external String get href;
  external String get host;
  @JS("hostname")
  external String get hostName;
  external String get port;
  external String get origin;
  external String? get search;
}

@JS("Document")
extension type Document._(JSObject _) implements JSObject, WebEventStream {
  external factory Document();
  @JS("createElement")
  external T createElement<T extends HTMLElement>(String tagName);
  @JS("body")
  external JSNode get body;
  external JSAny? get defaultView;
  @JS("hasFocus")
  external bool hasFocus();

  HTMLVideoElement createVideoElement({String type = "video"}) {
    return createElement(type);
  }

  String downloadBlob(
      {required List<int> fileBytes, required String fileName}) {
    final blob = Blob.fromBytes(fileBytes);
    final url = URL.createObjectURL(blob);
    downloadUrl(url: url, fileName: fileName);
    return url;
  }

  void downloadUrl({required String url, required String fileName}) {
    final HTMLAnchorElement anchor = createElement("a");
    anchor.target = "download";
    anchor.href = url;
    anchor.download = fileName;
    jsWindow.document.body.appendChild(anchor);
    anchor.click();
    jsWindow.document.body.removeChild(anchor);
  }

  String downloadJsFile({required JSFile file, required String fileName}) {
    // final blob = Blob.fromBytes(fileBytes);
    final url = URL.createObjectURLFromFile(file);
    downloadUrl(url: url, fileName: fileName);
    return url;
  }

  Future<Result<JSFile?, OnChainBridgeException>> pickFile(
      List<String> extensions) async {
    Completer<Result<JSFile?, OnChainBridgeException>> completer = Completer();
    final HTMLInputElement anchor = createElement("input");
    void compelete(JSFile? data) {
      if (completer.isCompleted) return;
      completer.complete(Ok(data));
    }

    void error() {
      if (completer.isCompleted) return;
      completer.complete(Err(OnChainBridgeException.invalidFileData));
    }

    anchor.onchange = () {
      final files = anchor.files;
      if (files == null || files.length != 1) {
        compelete(null);
        return;
      }
      final file = files.item(0);
      compelete(file);
    }.toJS;
    anchor.onerror = () {
      compelete(null);
      error();
    }.toJS;
    anchor.oncancel = () {
      compelete(null);
    }.toJS;
    anchor.accept = extensions.isEmpty
        ? "*/*"
        : extensions.map((e) {
            if (e.contains("/")) return e;
            if (!e.startsWith(".")) return ".$e";
            return e;
          }).join(",");
    anchor.type = "file";
    jsWindow.document.body.appendChild(anchor);
    anchor.click();
    jsWindow.document.body.removeChild(anchor);
    final data = await completer.future;
    return data;
  }
}
@JS("Clipboard")
extension type Clipboard._(JSObject _) implements JSObject {
  external factory Clipboard();
  external JSPromise writeText(String? text);
  external JSPromise<JSString?> readText();
  Future<bool> writeText_(String text) async {
    try {
      if (!jsWindow.document.hasFocus()) {
        jsWindow.focus();
      }
      await writeText(text).toDart;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> readText_() async {
    try {
      final text = await readText().toDart;
      return text?.toDart;
    } catch (e) {
      return null;
    }
  }
}
@JS("navigator")
extension type JSNavigator._(JSObject _) implements JSObject {
  external factory JSNavigator();
  external MediaDevices get mediaDevices;
  external String? get userAgent;
  external bool get onLine;
  external CredentialsContainer? get credentials;
  bool get isWebKit => userAgent?.contains("AppleWebKit") ?? false;
  bool get isFirefoxMobile {
    final ua = userAgent?.toLowerCase();
    if (ua == null) return false;
    return ua.contains('fxios') ||
        (ua.contains('firefox') && ua.contains('android'));
  }

  bool get isFirefox {
    final ua = userAgent?.toLowerCase();
    if (ua == null) return false;
    return isFirefoxMobile || (ua.contains('firefox') && !ua.contains('fxios'));
  }

  bool get isSafari {
    final ua = userAgent?.toLowerCase();
    if (ua == null) return false;
    return ua.contains('safari') &&
        !ua.contains('chrome') &&
        !ua.contains('crios') &&
        !ua.contains('fxios') &&
        !ua.contains('edgios');
  }

  bool get isChromeMobile {
    final ua = userAgent?.toLowerCase();
    if (ua == null) return false;
    // Chrome on Android or iOS
    final isAndroidChrome = ua.contains('chrome') && ua.contains('android');
    final isIosChrome = ua.contains('crios');
    return isAndroidChrome || isIosChrome;
  }

  bool get isChrome {
    final ua = userAgent?.toLowerCase();
    if (ua == null) return false;
    return (ua.contains('chrome') &&
            !ua.contains('edge') &&
            !ua.contains('opr')) ||
        isChromeMobile;
  }

  external JSPromise share(
      String? url, String? text, String? title, JSArray<JSFile>? files);
  external Clipboard? get clipboard;

  /// navigator.clipboard.writeText(text)
  Future<void> share_({
    List<JSFile> files = const [],
    String? url,
    String? text,
    String? title,
  }) async {
    final future = share(url, text, title, files.toJS).toDart;
    await future;
  }
}
@JS("MediaDevices")
extension type MediaDevices._(JSObject _) implements JSObject {
  external factory MediaDevices();
  @JS("getUserMedia")
  external JSPromise<MediaStream> getUserMedia(JSAny? constraints);

  Future<MediaStream> getUserMedia_(
      {bool video = true,
      bool audio = false,
      Map<String, dynamic>? constraints}) async {
    final future =
        getUserMedia((constraints ?? {"video": video, "audio": audio}).jsify())
            .toDart;
    return await future;
  }
}

@JS("BarcodeDetector")
extension type BarcodeDetector._(JSObject _) implements JSObject {
  external factory BarcodeDetector(JSAny? formats);
  factory BarcodeDetector.withFormats(List<String> formats) {
    return BarcodeDetector({"formats": formats}.jsify());
  }
  external JSPromise<JSArray<DetectedBarcode>> detect(
      HTMLVideoElement imageBitmapSource);
  Stream<String> stream(HTMLVideoElement element,
          {Duration interval = const Duration(milliseconds: 300)}) =>
      Stream.periodic(interval)
          .asyncMap((_) async {
            final future = (await detect(element).toDart).toDart;
            final value = future.firstOrNull?.rawValue;
            if (value != null) {
              return value;
            }
            return null;
          })
          .where((event) => event != null)
          .cast<String>();
}
@JS()
extension type BarcodeDetectorOptions._(JSObject _) implements JSObject {
  external factory BarcodeDetectorOptions(JSArray<JSString>? formats);
  external JSArray<JSString>? get formats;
}
@JS("BarcodeDetector")
extension type DetectedBarcode._(JSObject _) implements JSObject {
  external factory DetectedBarcode();
  external String? get rawValue;
  external String? get format;
}
@JS("URL")
extension type URL._(JSObject _) implements JSObject {
  external factory URL();
  @JS("createObjectURL")
  external static String createObjectURL(Blob object);
  @JS("createObjectURL")
  external static String createObjectURLFromFile(JSFile object);
}

extension type JSFileOption._(JSObject _) implements JSObject {
  external JSFileOption({String? type, String? endings, int? lastModified});
  external String? get type;
  external String? get endings;
  external int? get lastModified;
}

@JS("File")
extension type JSFile._(JSObject _) implements JSObject {
  external JSFile(
      JSArray<JSAny> fileBits, String fileName, JSFileOption? options);
  external JSArray<JSArrayBuffer>? get fileBits;
  // external String? get fileName;
  external String get name;
  external JSFileOption? get options;
  external JSPromise<JSArrayBuffer> arrayBuffer();
  external JSPromise<JSString> text();

  Future<Result<List<int>, OnChainBridgeException>> toBytes() async {
    try {
      final bytes = await arrayBuffer().toDart;
      final content = bytes.toDart.asUint8List().toList();
      return Ok(content);
    } catch (_) {
      return Err(OnChainBridgeException.invalidFileData);
    }
  }

  Future<Result<String, OnChainBridgeException>> toText() async {
    try {
      final bytes = await text().toDart;
      return Ok(bytes.toDart);
    } catch (_) {
      return Err(OnChainBridgeException.invalidFileData);
    }
  }
}
@JS("FileList")
extension type FileList._(JSObject _) implements JSObject {
  external FileList();
  external int get length;
  external JSFile item(int index);
}

@JS("Blob")
extension type Blob._(JSObject _) implements JSObject {
  external factory Blob(JSArray<JSAny> blobParts, BlobOptions? options);
  factory Blob.fromBytes(List<int> bytes, {BlobOptions? options}) {
    final data = JsUtils.toUint8Array(bytes).buffer.toJS;
    return Blob([data].toJS, options);
  }
  external JSAny? get blobParts;
  external JSObject? get options;

  external JSPromise<JSArrayBuffer> arrayBuffer();
}

extension type BlobOptions._(JSObject _) implements JSAny {
  external factory BlobOptions({String? type});
}

@JS('ReadableStream')
extension type ReadableStream._(JSObject _) implements JSObject {
  external ReadableStreamDefaultReader getReader();
}

@JS('ReadableStreamDefaultReader')
extension type ReadableStreamDefaultReader._(JSObject _) implements JSObject {
  external JSPromise<ReadableStreamReadResult> read();
  external void cancel();
  external void releaseLock();
}

extension type ReadableStreamReadResult._(JSObject _) implements JSObject {
  external bool get done;
  external JSUint8Array? get value;
}

@JS('Response')
extension type Response._(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external Headers get headers;
  external ReadableStream? get body;
  external JSPromise<JSArrayBuffer> arrayBuffer();

  @JS("text")
  external JSPromise<JSString> text();

  Future<ByteBuffer> arrayBuffer_() async {
    final data = await arrayBuffer().toDart;
    return data.toDart;
  }

  Future<String> text_() async {
    final data = await text().toDart;
    return data.toDart;
  }

  // Future<Uint8List> arrayBuffer_() async {
  //   final buffer = await arrayBuffer().toDart;
  //   return buffer.toDart.asUint8List();
  // }
}
// @JS("Response")
// extension type Response._(JSObject _) implements JSObject {
//   external factory Response();

//   @JS("ok")
//   external bool get ok;
//   @JS("status")
//   external int get status;
//   @JS("arrayBuffer")
//   external JSPromise<JSArrayBuffer> arrayBuffer();
//   @JS("text")
//   external JSPromise<JSString> text();

//   Future<ByteBuffer> arrayBuffer_() async {
//     final data = await arrayBuffer().toDart;
//     return data.toDart;
//   }

//   Future<String> text_() async {
//     final data = await text().toDart;
//     return data.toDart;
//   }
// }

@JS("Worker")
extension type Worker._(JSObject _)
    implements JSObject, WebEventStream, IJSMessagePort {
  external factory Worker(String? aURL, WorkerOptions? options);
  external String? get aURL;
  external WorkerOptions? get options;
  @JS("terminate")
  external void terminate();

  external set onerror(JSFunction _);

  external set onmessage(JSFunction? _);
}
extension type WorkerOptions._(JSObject _) implements JSObject {
  external factory WorkerOptions(
      {String? type, String? credentials, String? name});

  external String? get type;
  external set type(String? type);
  external String? get credentials;
  external set credentials(String? type);
  external String? get name;
  external set name(String? type);
}

@JS("Event")
extension type WebEvent<TARGET extends JSAny?>._(JSObject _)
    implements EventInit<TARGET> {
  external factory WebEvent(String? type, EventInit<TARGET>? options);
  external String? get type;
}
@JS()
extension type EventInit<TARGET extends JSAny?>._(JSObject _)
    implements JSObject {
  external bool? get bubbles;
  external bool? get cancelable;
  external bool? get composed;
  external JSAny? get detail;
  external TARGET get target;
  external set bubbles(bool? bubbles);
  external set cancelable(bool? cancelable);
  external set composed(bool? composed);
  external set detail(JSAny? detail);
  external set data(JSAny? data);
  external factory EventInit(
      {bool? bubbles,
      bool? cancelable,
      bool? composed,
      JSAny? detail,
      JSAny? data});

  List<int>? detailBytes() {
    return JsUtils.toDartBytes(detail);
  }
}

@JS("Event")
extension type MessageEvent<T extends JSAny?>._(JSObject _)
    implements WebEvent {
  external factory MessageEvent();
  external T get data;
}
extension type WebEventStream._(JSObject _) {
  @JS("addEventListener")
  external void addEventListener(String type, JSFunction callback);
  @JS("removeEventListener")
  external void removeEventListener(String type, JSFunction callback);

  external void dispatchEvent(WebEvent event);

  ({Stream<T> stream, StreamController<T> controller})
      stream<T extends JSObject?>(String type, {bool broadcast = false}) {
    final StreamController<T> controller = switch (broadcast) {
      false => StreamController(),
      true => StreamController.broadcast()
    };
    final callback = (MessageEvent<JSObject?> event) {
      controller.add(event.data.dartify() as T);
    }.toJS;
    controller.onCancel = () {
      removeEventListener(type, callback);
    };
    controller.onListen = () {
      addEventListener(type, callback);
    };
    return (stream: controller.stream, controller: controller);
  }
}

@JS("CustomEvent")
extension type CustomEvent._(JSObject _) implements WebEvent {
  external factory CustomEvent(String? type, EventInit? options);
  factory CustomEvent.create(
      {required String? type,
      JSAny? detail,
      JSAny? data,
      bool bubbles = true,
      bool cancelable = false,
      bool clone = false}) {
    if (clone && isExtension && cloneInto != null) {
      detail = _cloneInto(detail, jsWindow.document.defaultView);
    }

    return CustomEvent(
      type,
      EventInit(
          bubbles: bubbles, cancelable: cancelable, detail: detail, data: data),
    );
  }
}

@JS("JSON")
extension type JSON._(JSObject _) implements JSObject {
  external factory JSON();
  @JS("parse")
  external JSObject? parse(String? text);
  @JS("stringify")
  external String stringify(JSAny? object, [JSFunction? encodable]);
}
@JS("console")
extension type JSConsole._(JSObject _) implements JSObject {
  external factory JSConsole();
  external void log(String? text);

  @JS("log")
  external void log_(JSAny? text);
  @JS("log")
  external JSFunction get logFunc;
  @JS("log")
  external set setLog(JSFunction _);

  external void debug(String? text);
  external void info(String? text);

  @JS("info")
  external JSFunction get infoFunc;

  @JS("info")
  external set setInfo(JSFunction _);

  external void error(String? text);
  @JS("error")
  external void errorObject(JSAny? obj);
}
@JS("Reflect")
extension type Reflect._(JSObject _) implements JSAny {
  external factory Reflect();
  @JS("get")
  external static JSAny? get(JSAny? object, JSAny? prop, JSAny? receiver);
  @JS("ownKeys")
  external static JSArray<JSString> ownKeys(JSAny? object);

  static List<String> ownKeys_(JSAny? object) {
    if (object.isUndefinedOrNull) return [];
    return ownKeys(object).toDart.map((e) => e.toDart).toList();
  }
}
// extension type FetchOptions._(JSObject _) implements JSAny {
//   external FetchOptions({JSString? method, JSAny? headers, JSAny? body});
// external set method(JSString _);
// external set headers(JSAny? _);
// external set body(JSAny? _);
// }
extension type FetchOptions._(JSObject _) implements JSObject {
  external factory FetchOptions({
    String? method,
    Headers? headers,
    JSAny? body,
    AbortSignal? signal,
  });
  external set method(JSString _);
  external set headers(Headers? _);
  external set body(JSAny? _);
}
@JS('Headers')
extension type Headers._(JSObject _) implements JSObject {
  external factory Headers();
  external void append(String name, String value);
  external void forEach(JSFunction callback);
}

@JS("ErrorEvent")
extension type ErrorEvent._(JSObject _) implements WebEvent {
  external factory ErrorEvent(String? type, EventInit? options);
  external String? get message;
}
@JS('AbortController')
extension type AbortController._(JSObject _) implements JSObject {
  external factory AbortController();
  external AbortSignal get signal;
  external void abort();
}

@JS('AbortSignal')
extension type AbortSignal._(JSObject _) implements JSObject {
  external bool get aborted;
}
