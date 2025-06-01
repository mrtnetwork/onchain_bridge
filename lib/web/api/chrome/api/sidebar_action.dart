import 'dart:js_interop';

extension type SidebarAction._(JSObject _) {
  external factory SidebarAction();
  @JS("open")
  external JSFunction? get openFunc;
  external JSPromise open();
  external JSPromise close();
  Future<void> open_() async {
    final future = open().toDart;
    await future;
  }

  Future<void> close_() async {
    final future = close().toDart;
    await future;
  }
}
