import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/utils/utils.dart';

enum AppPathDirectory {
  cache(0),
  support(1);

  final int value;
  const AppPathDirectory(this.value);

  static AppPathDirectory fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(),
    );
  }
}

class AppPath {
  AppPath({
    required this.documentUri,
    required this.cacheUri,
    required this.supportUri,
    required this.platform,
    required this.separator,
  });

  AppPath.fromJson(Map<String, dynamic> json, this.platform, this.separator)
      : documentUri = json["document"],
        cacheUri = json["cache"],
        supportUri = json["support"];

  final String? documentUri;
  final String cacheUri;
  final String supportUri;
  final AppPlatform platform;
  final String separator;

  String _root(AppPathDirectory directory) {
    switch (directory) {
      case AppPathDirectory.cache:
        return cacheUri;
      case AppPathDirectory.support:
        return supportUri;
    }
  }

  bool _isValidRelativePath(String path) {
    if (path.isEmpty) return false;

    if (path.startsWith("/") || path.startsWith("\\")) {
      return false;
    }

    return true;
  }

  String toFilePath({
    required AppPathDirectory directory,
    required String relativePath,
  }) =>
      _path(
          directory: directory, relativePath: relativePath, isDirectory: false);
  String toDirectoryPath({
    required AppPathDirectory directory,
    required String relativePath,
  }) =>
      _path(
          directory: directory, relativePath: relativePath, isDirectory: true);

  String _path({
    required AppPathDirectory directory,
    required String relativePath,
    bool isDirectory = false,
  }) {
    assert(
      _isValidRelativePath(relativePath),
      "Path must be relative.",
    );

    final result = OnChainBridgeUtils.joinPathWithRoot([
      _root(directory),
      relativePath,
    ], separator: separator);

    return isDirectory && !result.endsWith(separator)
        ? "$result$separator"
        : result;
  }

  @override
  String toString() {
    return "document: $documentUri\ncache: $cacheUri\nsupport: $supportUri";
  }
}
