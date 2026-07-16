import 'dart:io';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';

class LinuxPathUtils {
  static final _env = Platform.environment;

  static String _home() {
    final home = _env["HOME"];
    if (home == null) {
      throw OnChainBridgeException.pathUnexpectedError;
    }
    return home;
  }

  /// Returns XDG_DATA_HOME or ~/.local/share
  static String get _dataHome =>
      _env["XDG_DATA_HOME"] ?? "${_home()}/.local/share";

  /// Returns XDG_CACHE_HOME or ~/.cache
  static String get _cacheHome => _env["XDG_CACHE_HOME"] ?? "${_home()}/.cache";

  /// Returns XDG_CONFIG_HOME or ~/.config
  // static String get _configHome => _env["XDG_CONFIG_HOME"] ?? "${_home()}/.config";

  /// Get Documents dir using xdg-user-dir, fallback ~/Documents
  static Future<String> get _documents async {
    try {
      final result = await Process.run("xdg-user-dir", ["DOCUMENTS"]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).split("\n")[0];
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return "${_home()}/Documents";
  }

  static String _getApplicationId({String fallback = "myapp"}) {
    return fallback;
  }

  static Future<String> _getApplicationSupport({String? appId}) async {
    appId ??= _getApplicationId();
    return "$_dataHome/$appId";
  }

  static Future<String> _getApplicationCache({String? appId}) async {
    appId ??= _getApplicationId();
    return "$_cacheHome/$appId";
  }

  // static Future<String> _getApplicationConfig({String? appId}) async {
  //   appId ??= _getApplicationId();
  //   return "$_configHome/$appId";
  // }

  static Future<Result<AppPath, IException>> getPath(
      String applicationId) async {
    final home = _env["HOME"];
    if (home == null) {
      return Err(OnChainBridgeException.pathUnexpectedError);
    }
    final support = await _getApplicationSupport(appId: applicationId);
    final cache = await _getApplicationCache(appId: applicationId);
    final doc = await _documents;
    return Ok(AppPath(
        documentUri: doc,
        cacheUri: cache,
        separator: Platform.pathSeparator,
        supportUri: support,
        platform: AppPlatform.linux));
  }
}
