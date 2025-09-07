import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/window/window.dart';

import 'media_stream.dart';

@JS("Node")
extension type JSNode._(JSObject _) implements WebEventStream {
  external factory JSNode();
  @JS("appendChild")
  external void appendChild(HTMLElement aChild);
  @JS("removeChild")
  external void removeChild(HTMLElement aChild);
}

@JS("Element")
extension type Element._(JSObject _) implements JSNode {
  external factory Element();
  external String? get id;
  external set id(String? id);
  @JS("click")
  external void click();
}
@JS("HTMLElement")
extension type HTMLElement._(JSObject _) implements Element {
  external factory HTMLElement();
  external String? get id;
  external set id(String? id);
  external String? get src;
  external set src(String? src);
}
@JS("HTMLMediaElement")
extension type HTMLMediaElement._(JSObject _) implements HTMLElement {
  external factory HTMLMediaElement();
  external bool? get autoplay;
  external set autoplay(bool? autoplay);
}

@JS("HTMLAnchorElement")
extension type HTMLAnchorElement._(JSObject _) implements HTMLElement {
  external factory HTMLAnchorElement();
  external String? get href;
  external String? get target;
  external String? get download;
  external set href(String? href);
  external set target(String? target);
  external set download(String? download);
}

@JS()
extension type HTMLVideoElement._(JSObject _) implements HTMLMediaElement {
  external factory HTMLVideoElement();
  external MediaStream? get srcObject;

  external set srcObject(MediaStream? srcObject);

  external int? get videoHeight;
  external set videoHeight(int? videoHeight);
  external int? get videoWidth;
  external set videoWidth(int? videoWidth);

  external int? get width;
  external set width(int? width);
}
@JS()
extension type HTMLInputElement._(JSObject _) implements HTMLElement {
  external factory HTMLInputElement();
  external String? get accept;
  external set accept(String? accept);
  external String? get type;
  external set type(String? type);
  external set onchange(JSFunction? _);
  external set onerror(JSFunction? _);
  external set oncancel(JSFunction? _);
  external FileList? get files;
}
