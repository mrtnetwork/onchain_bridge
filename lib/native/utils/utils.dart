import 'dart:ffi';
import 'dart:io';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';

class OnChainBridgeIoUtils {
  static String? getDynamicLiberaryPath(String name) {
    if (Platform.isMacOS) {
      return "$name.dylib";
    } else if (Platform.isWindows) {
      return "$name.dll";
    } else if (Platform.isAndroid || Platform.isLinux) {
      return "$name.so";
    }
    return null;
  }

  static bool libExists(String name) {
    final libName = getDynamicLiberaryPath(name);
    if (libName == null) return false;
    try {
      final _ = DynamicLibrary.open(libName);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static Result<AppPlatform, IException> platform() {
    if (Platform.isAndroid) {
      return Ok(AppPlatform.android);
    } else if (Platform.isIOS) {
      return Ok(AppPlatform.ios);
    } else if (Platform.isWindows) {
      return Ok(AppPlatform.windows);
    } else if (Platform.isMacOS) {
      return Ok(AppPlatform.macos);
    } else if (Platform.isLinux) {
      return Ok(AppPlatform.linux);
    }
    return Err(OnChainBridgeException.unsuportedPlatform);
  }
}
