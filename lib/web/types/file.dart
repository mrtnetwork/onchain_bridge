import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/web/api/api.dart';

class WebFile implements ICrossFile {
  final JSFile file;
  @override
  final String name;
  WebFile(this.file) : name = file.name;

  @override
  Future<Result<List<int>, BaseOnChainBridgeException>> readBytes() {
    return file.toBytes();
  }

  @override
  Future<Result<String, BaseOnChainBridgeException>> readString() {
    return file.toText();
  }
}
