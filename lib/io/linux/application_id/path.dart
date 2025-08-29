import 'dart:io';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/path/path.dart';

class LinuxPathUtils {
  static final _env = Platform.environment;

  static String _home() {
    final home = _env["HOME"];
    if (home == null) {
      throw OnChainBridgeException("Environment variable HOME is not set.");
    }
    return home;
  }

  /// Returns XDG_DATA_HOME or ~/.local/share
  static String get dataHome =>
      _env["XDG_DATA_HOME"] ?? "${_home()}/.local/share";

  /// Returns XDG_CACHE_HOME or ~/.cache
  static String get cacheHome => _env["XDG_CACHE_HOME"] ?? "${_home()}/.cache";

  /// Returns XDG_CONFIG_HOME or ~/.config
  static String get configHome =>
      _env["XDG_CONFIG_HOME"] ?? "${_home()}/.config";

  /// Get Documents dir using xdg-user-dir, fallback ~/Documents
  static Future<String> get documents async {
    try {
      final result = await Process.run("xdg-user-dir", ["DOCUMENTS"]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).split("\n")[0];
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return "${_home()}/Documents";
  }

  static String getApplicationId({String fallback = "myapp"}) {
    return fallback;
  }

  static Future<String> getApplicationSupport({String? appId}) async {
    appId ??= getApplicationId();
    return "$dataHome/$appId";
  }

  static Future<String> getApplicationCache({String? appId}) async {
    appId ??= getApplicationId();
    return "$cacheHome/$appId";
  }

  static Future<String> getApplicationConfig({String? appId}) async {
    appId ??= getApplicationId();
    return "$configHome/$appId";
  }

  static Future<AppPath> getPath(String applicationId) async {
    final support =
        await LinuxPathUtils.getApplicationSupport(appId: applicationId);
    final cache =
        await LinuxPathUtils.getApplicationCache(appId: applicationId);
    final doc = await LinuxPathUtils.documents;
    return AppPath(document: doc, cache: cache, support: support);
  }
}
