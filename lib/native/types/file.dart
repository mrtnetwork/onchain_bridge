import 'dart:io';

import 'package:blockchain_utils/utils/types/result.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/models.dart';

class NativeFile implements ICrossFile {
  final String path;
  @override
  final String name;
  NativeFile._({required this.path, required this.name});
  factory NativeFile.fromFile(File file) {
    final path = file.path;
    final name = path.split("/").last;
    return NativeFile._(path: path, name: name);
  }
  static Result<NativeFile, OnChainBridgeException> fromPath(String path) {
    try {
      if (FileSystemEntity.typeSync(path) == FileSystemEntityType.file) {
        final name = path.split("/").last;
        return Ok(NativeFile._(path: path, name: name));
      }
    } catch (_) {}
    return Err(OnChainBridgeException.invalidFileData);
  }

  Future<Result<File, BaseOnChainBridgeException>> _getFile() async {
    final file = File(path);
    if (await file.exists()) return Ok(file);
    return Err(OnChainBridgeException.fileDoesNotExists);
  }

  @override
  Future<Result<List<int>, BaseOnChainBridgeException>> readBytes() async {
    final file = await _getFile();
    try {
      return file.mapAsync((file) async {
        return await file.readAsBytes();
      });
    } on PlatformException {
      return Err(OnChainBridgeException.fileReadPlatformError);
    }
  }

  @override
  Future<Result<String, BaseOnChainBridgeException>> readString() async {
    final file = await _getFile();
    try {
      return file.mapAsync((file) async {
        return await file.readAsString();
      });
    } on PlatformException {
      return Err(OnChainBridgeException.fileReadPlatformError);
    }
  }
}
