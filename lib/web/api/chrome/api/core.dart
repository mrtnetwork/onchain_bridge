import 'dart:js_interop';
import 'package:on_chain_bridge/web/api/chrome/api/side_pannel.dart';
import 'package:on_chain_bridge/web/api/chrome/api/sidebar_action.dart';

import 'storage.dart';
import 'tabs.dart';
import 'runtime.dart';
import 'action.dart';
import 'windows.dart';

@JS()
extension type ChromeAPI._(JSObject _) {
  external Storage get storage;
  external Tabs get tabs;
  external Runtime get runtime;
  external Action get action;
  external ChromeWindows get windows;
  external SidePanel get sidePanel;
  @JS("sidePanel")
  external SidePanel? get sidePanelNullable;
  external bool? get mozilla;
  @JS("sidebarAction")
  external SidebarAction? get sidebarActionNullable;
  external SidebarAction get sidebarAction;
  @JS("runtime")
  external Runtime? get runtimeNullable;
}

@JS("chrome")
extension type Chrome._(JSObject _) implements ChromeAPI {
  external factory Chrome();
}

@JS("browser")
extension type Browser._(JSObject _) implements ChromeAPI {
  external factory Browser();
}

@JS("chrome")
external Chrome get _chrome;

@JS("chrome")
external Chrome? get _chromeNullabe;

@JS("browser")
external Browser get _browser;

@JS("browser")
external Browser? get _browserNullabe;

@JS("opr")
external Browser? get oprNullable;

ChromeAPI get extension {
  if (_chromeNullabe?.runtimeNullable?.idNullabe != null) {
    return _chrome;
  }
  return _browser;
}

bool get isMozila => _browserNullabe != null;

bool get isExtension =>
    _chromeNullabe?.runtimeNullable?.idNullabe != null ||
    _browserNullabe?.runtimeNullable?.idNullabe != null;
