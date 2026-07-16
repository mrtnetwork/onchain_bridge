import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

import '../platform_impl/cross.dart'
    if (dart.library.js_interop) '../platform_impl/web.dart'
    if (dart.library.io) '../platform_impl/io.dart';

abstract class PlatformSocket {
  void close();
  void sink(List<int> message);
  Stream<List<int>> get stream;
  bool get isConnected;
  static Future<Result<PlatformSocket, NetResultStatus>> connect({
    required NetConfig config,
    List<String>? protocols,
    Duration? timeout,
  }) async =>
      connectSoc(
        config: config,
        timeout: timeout,
        protocols: protocols,
      );
}
