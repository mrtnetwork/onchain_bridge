library;

import 'dart:async';
import 'dart:io';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/services.dart'
    show EventChannel, MethodChannel, Clipboard, ClipboardData, MethodCall;
import 'package:on_chain_bridge/database/core/interface.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/native/database/database.dart';
import 'package:on_chain_bridge/native/linux/linux.dart';
import 'package:on_chain_bridge/native/types/file.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_bridge/models/barcode/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/on_chain_bridge.dart';
import 'package:on_chain_bridge/constant/constant.dart';
part 'webview.dart';
part 'io_impl.dart';
part 'desktop_impl.dart';

OnChainBridgeInterface getPlatformInterface() {
  if (Platform.isLinux) return IoLinuxPlatformInterface();
  return IoPlatformInterface();
}
