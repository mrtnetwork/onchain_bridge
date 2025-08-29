import 'dart:ffi';

import 'package:on_chain_bridge/io/database/fifi/fifi.dart';

typedef _GetApplicationGetDefultC = IntPtr Function();
typedef _GetApplicationGetDefultDart = int Function();

typedef _GetApplicationIdC = Pointer<Utf8> Function(IntPtr);

typedef _GetApplicationIdDart = Pointer<Utf8> Function(int);

class GioLibrary {
  final DynamicLibrary? library = () {
    try {
      return DynamicLibrary.open('libgio-2.0.so.0');
    } catch (e) {
      return null;
    }
  }();

  String? _appId;

  // Declare the function signature for gio_application_get_application_id
  late final _GetApplicationGetDefultDart? _getApplicationGetDefault = library
      ?.lookupFunction<_GetApplicationGetDefultC, _GetApplicationGetDefultDart>(
          'g_application_get_default');

  ///
  late final _GetApplicationIdDart? _getApplicationId =
      library?.lookupFunction<_GetApplicationIdC, _GetApplicationIdDart>(
          'g_application_get_application_id');

  int? getDefault() {
    final func = _getApplicationGetDefault;
    if (func == null) return null;
    final id = func();
    if (id == 0) return null;
    return id;
  }

  String? getApplicationId() {
    return _appId ??= () {
      final defaultId = getDefault();
      if (defaultId == null) return null;
      final func = _getApplicationId;
      if (func == null) return null;
      final appId = func(defaultId);
      if (appId == nullptr) return null;
      return appId.toDartString();
    }();
  }
}
