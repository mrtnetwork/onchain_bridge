import 'dart:js_interop';
import 'dart:typed_data' show Uint8List;
import 'window.dart';

@JS("WebSocket")
extension type JSWebSocket._(JSObject _) implements JSObject, WebEventStream {
  external factory JSWebSocket(String url, [JSArray<JSString>? protocols]);
  factory JSWebSocket.create(String url, {List<String> protocols = const []}) {
    return JSWebSocket(url, protocols.map((e) => e.toJS).toList().toJS);
  }

  external int get readyState;
  external String get url;
  external void close([int? code, String? reason]);
  external void send(JSAny data);

  external set onerror(JSFunction? _);
  external set onclose(JSFunction? _);
  external set onmessage(JSFunction? _);
  external set onopen(JSFunction? _);

  bool get isOpen => readyState == 1;
  bool get isClosed => readyState == 3;

  void send_(List<int> bytes) {
    final data = Uint8List.fromList(bytes).buffer.toJS;
    send(data);
  }
}
extension type JSWebScoketCloseEvent._(JSObject _) implements JSAny {
  external int? get code;
  external String? get reason;
  external bool? get wasClean;
}
extension type JSWebScoketMessageEvent._(JSObject _)
    implements MessageEvent<JSString> {
  external JSString get data;
}
