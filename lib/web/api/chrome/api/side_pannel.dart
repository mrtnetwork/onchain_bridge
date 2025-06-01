import 'dart:js_interop';

extension type SidePanel._(JSObject _) {
  external factory SidePanel();
  @JS("open")
  external JSFunction? get openFunc;
  external JSPromise open(SidePannelOpenOptions options);
  external JSPromise setOptions(SidePanelPanelOptions options);
  external JSPromise<SidePanelPanelOptions> getOptions(
      SidePannelGetPanelOptions options);
  Future<SidePanelPanelOptions> getOptions_({int? tabId}) async {
    final future = getOptions(SidePannelGetPanelOptions(tabId: tabId)).toDart;
    return await future;
  }

  Future<void> open_({int? windowId, int? tabId}) async {
    assert(() {
      if (windowId == null && tabId == null) return false;
      if (windowId != null && tabId != null) return false;
      return true;
    }(), "Use windowId for open global sidePanel or tabId for single tab");
    final future =
        open(SidePannelOpenOptions(tabId: tabId, windowId: windowId)).toDart;
    await future;
  }

  Future<void> setOptions_({
    int? tabId,
    String? path,
    bool? enabled,
  }) async {
    final future = setOptions(
            SidePanelPanelOptions(tabId: tabId, path: path, enabled: enabled))
        .toDart;
    await future;
  }
}

extension type SidePannelOpenOptions._(JSObject _) {
  external factory SidePannelOpenOptions({int? tabId, int? windowId});
}
extension type SidePannelGetPanelOptions._(JSObject _) {
  external factory SidePannelGetPanelOptions({int? tabId});
}

extension type SidePanelPanelOptions._(JSObject _) implements JSAny {
  external factory SidePanelPanelOptions(
      {int? tabId, String? path, bool? enabled});
}
