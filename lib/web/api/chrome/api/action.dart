import 'dart:js_interop';

import 'package:on_chain_bridge/web/api/chrome/api/events.dart';
import 'package:on_chain_bridge/web/api/chrome/api/runtime.dart';

@JS("Action")
extension type Action._(JSObject _) {
  external factory Action();
  external JSPromise<JSAny?> openPopup(OpenPopupOptions? options);
  external JSEvent<void Function(RuntimePort port)> get onClicked;
}
@JS("OpenPopupOptions")
extension type OpenPopupOptions._(JSObject _) {
  external factory OpenPopupOptions({int? number, int? tabId});
  external int? get number;
  external int? get tabId;
}
