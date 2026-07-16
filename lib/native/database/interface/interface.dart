import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:blockchain_utils/blockchain_utils.dart' hide Pointer;
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:on_chain_bridge/constant/constant.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
import 'package:on_chain_bridge/native/database/models/db.dart';
import 'package:on_chain_bridge/native/database/types/types.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_bridge/models/models.dart';

typedef ONGETAPPPATH = Future<AppPath> Function();

class IDatabseInterfaceIo extends DefaultDetabaseApi<IDatabaseIo> {
  final AppPath appPath;
  final String dbName;
  final SafeAtomicLock _lock = SafeAtomicLock();
  IDatabaseIo? _databases;

  IDatabseInterfaceIo({required this.dbName, required this.appPath});

  Future<String> _getOrCreateDatabase(List<int> keyBytes) async {
    final checksum =
        BytesUtils.toHexString(QuickCrypto.blake2b128Hash(keyBytes));
    final path = appPath.toDirectoryPath(
      directory: AppPathDirectory.support,
      relativePath: IDatabaseConst.dbFolderName,
    );
    Directory(path).createSync(recursive: true);
    return appPath.toFilePath(
      directory: AppPathDirectory.support,
      relativePath: "${IDatabaseConst.dbFolderName}/${dbName}_$checksum.db",
    );
  }

  Future<void> closeDb(String dbName) async {
    await _lock.run(() async {
      _databases?.closeDb();
    });
  }

  Future<Result<String?, IException>> openDatabase(String? key) async {
    return _lock.run(() async {
      final database = _databases;
      if (database != null) return Ok(null);
      final libPath =
          OnChainBridgeIoUtils.getDynamicLiberaryPath("libsqlite3mc");
      if (libPath == null) {
        return Err(IDatabaseException.unsupportedPlatform);
      }
      DynamicLibrary library;
      try {
        library = DynamicLibrary.open(libPath);
      } on PlatformException {
        return Err(IDatabaseException.misingDatabaseLiberary);
      }

      List<int>? keyBytes;
      if (key != null) {
        keyBytes = BytesUtils.tryFromHexString(key);
      } else {
        keyBytes = QuickCrypto.generateRandom(QuickCrypto.sha256DigestSize);
      }
      if (keyBytes == null || keyBytes.length != QuickCrypto.sha256DigestSize) {
        return Err(IDatabaseException.unexpected("Invalid database key."));
      }
      final open = library.lookupFunction<Sqlite3OpenNative, Sqlite3OpenDart>(
        'sqlite3_open',
      );
      final exec = library.lookupFunction<Sqlite3ExecNative, Sqlite3ExecDart>(
        'sqlite3_exec',
      );

      final dbPath = await _getOrCreateDatabase(keyBytes);
      final path = dbPath.toNativeUtf8();
      final keyStmt = "PRAGMA hexkey = '$key';".toNativeUtf8();
      final errMsg = SafePointer(calloc<Pointer<Utf8>>());
      final dbPtr = SafePointer(calloc<Pointer<Void>>());
      try {
        final rc = open(path.ptr, dbPtr.ptr);
        if (rc != 0) {
          dbPtr.free();
          return Err(IDatabaseException.unexpected("Failed to open db file."));
        }
        final db = dbPtr.ptr.value;

        final rcKey = exec(db, keyStmt.ptr, nullptr, nullptr, errMsg.ptr);
        if (rcKey != 0) {
          final _ = errMsg.ptr.value.toDartString();
          dbPtr.free();
          return Err(IDatabaseException.unexpected(
              "Failed to open database. maybe invalid key."));
        }
        _databases = IDatabaseIo(
          dbName: dbName,
          dbPointer: dbPtr,
          lib: library,
        );
        return Ok(BytesUtils.toHexString(keyBytes));
      } finally {
        path.free();
        keyStmt.free();
        errMsg.free();
      }
    });
  }

  @override
  Future<IDatabaseIo> getDatabase() async {
    final database = _databases;
    if (database == null) {
      throw IDatabaseException.unexpected(
          'Database not initialized. Please call init() before using the database $dbName.');
    }
    return database;
  }
}

class NativePlatformStorage implements PlatformStorage {
  final MethodChannel _channel;
  const NativePlatformStorage(this._channel);

  @override
  Future<bool> hasStorage(String key) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"key": key, "type": "containsKey"});

    return data;
  }

  @override
  Future<Map<String, String>> readAllStorage({String? prefix}) async {
    if (prefix != null && prefix.isNotEmpty) {
      final keys = await readKeysStorage(prefix: prefix);
      return readMultipleStorage(keys);
    }
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "readAll"});

    Map<String, String> values = Map<String, String>.from(data!);
    if (prefix != null) {
      values = values..removeWhere((k, v) => !k.startsWith(prefix));
    }
    return Map<String, String>.from(values);
  }

  @override
  Future<Map<String, String>> readMultipleStorage(List<String> keys) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"keys": keys, "type": "readMultiple"});

    return Map<String, String>.from(data);
  }

  @override
  Future<String?> readStorage(String key) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"key": key, "type": "read"});

    return data;
  }

  @override
  Future<List<String>> readKeysStorage({String? prefix}) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"key": prefix ?? '', "type": "readKeys"});
    return (data as List).cast<String>();
  }

  @override
  Future<bool> removeAllStorage({String? prefix}) async {
    if (prefix != null && prefix.isNotEmpty) {
      final keys = await readKeysStorage(prefix: prefix);
      return removeMultipleStorage(keys);
    }
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "removeAll"});

    return data;
  }

  @override
  Future<bool> writeSecure(String key, String value) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"type": "write", "key": key, "value": value});

    return data;
  }

  @override
  Future<bool> removeSecure(String key) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "remove", "key": key});
    return data;
  }

  @override
  Future<bool> removeMultipleStorage(List<String> keys) async {
    final data = await _channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"keys": keys, "type": "removeMultiple"});
    return data;
  }
}
