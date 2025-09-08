import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/models/models.dart';

enum PickFileContentEncoding { utf8, hex, bytes }

enum AppFileType {
  txt(extension: "txt", mimeType: "text/plain");

  final String mimeType;
  final String extension;
  const AppFileType({required this.mimeType, required this.extension});

  String getPickFileExtenson(AppPlatform platform) {
    switch (platform) {
      case AppPlatform.windows:
        return "*.$extension";
      default:
        return extension;
    }
  }

  String getSaveFileExtenson(AppPlatform platform) {
    switch (platform) {
      case AppPlatform.windows:
        return extension;
      default:
        return extension;
    }
  }

  String toFileName(String name, AppPlatform platform) {
    final ext = name.split(".").last;
    if (ext == extension) return name;
    return "$name.$extension";
  }
}

class PickedFileContent {
  final String name;
  final String? path;
  final List<int> data;
  PickedFileContent(
      {required this.name, required List<int> data, required this.path})
      : data = data.asImmutableBytes;
}
