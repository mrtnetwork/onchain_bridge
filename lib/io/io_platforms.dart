library;

import 'dart:async';
import 'dart:io';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/io/database/database.dart';
import 'package:on_chain_bridge/io/linux/linux.dart';
import 'package:on_chain_bridge/models/biometric/types.dart';
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
