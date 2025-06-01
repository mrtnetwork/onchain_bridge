library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onchain_bridge/exception/exception.dart';
import 'package:onchain_bridge/models/models.dart';
import 'package:onchain_bridge/onchain_bridge.dart';
import 'package:onchain_bridge/constant/constant.dart';

part 'webview.dart';
part 'io_impl.dart';
part 'desktop_impl.dart';

OnChainBridgeInterface getPlatformInterface() => IoPlatformInterface();
