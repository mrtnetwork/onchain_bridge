import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/window/window.dart';

@JS("MessagePort")
extension type JSMessagePort._(JSObject _)
    implements JSObject, WebEventStream, IJSMessagePort {
  external factory JSMessagePort();
  external void close();
  external void start();
  external set onmessage(JSFunction? _);
  external set onmessageerror(JSFunction? _);
}
@JS("MessageChannel")
extension type JSMessageChannel._(JSObject _) implements JSObject {
  external factory JSMessageChannel();
  external JSMessagePort get port1;
  external JSMessagePort get port2;
}

/// Interface for objects that support postMessage with transferable buffers
@JS()
@staticInterop
extension type IJSMessagePort._(JSObject _) implements JSObject {
  external void postMessage(JSAny? message);

  @JS('postMessage')
  external void postMessageWithTransferables(
      JSAny? message, JSArray<JSAny> buffers);
  @JS('close')
  external JSFunction? get close;
}
