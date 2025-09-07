import 'package:blockchain_utils/blockchain_utils.dart';

enum PickFileContentEncoding { utf8, hex, bytes }

enum AppFileType {
  txt(extension: "txt", mimeType: "text/plain");

  final String mimeType;
  final String extension;
  const AppFileType({required this.mimeType, required this.extension});
}

class PickedFileContent {
  final String name;
  final String? path;
  final List<int> data;
  PickedFileContent(
      {required this.name, required List<int> data, required this.path})
      : data = data.asImmutableBytes;
}
