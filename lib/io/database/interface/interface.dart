import 'dart:ffi';
import 'dart:io';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_bridge/constant/constant.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/io/database/fifi/fifi.dart';
import 'package:on_chain_bridge/io/database/models/db.dart';
import 'package:on_chain_bridge/io/database/types/types.dart';
import 'package:on_chain_bridge/io/io_platforms.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/synchronized/basic_lock.dart';

typedef ONGETAPPPATH = Future<AppPath> Function();

class IDatabseInterfaceIo extends IDatabseInterface<IDatabaseIo> {
  AppPath? _appPath;
  final SynchronizedLock _lock = SynchronizedLock();
  late final DynamicLibrary _library;
  InitializeDatabaseStatus _status = InitializeDatabaseStatus.init;
  IDatabaseIo? _databases;
  IDatabseInterfaceIo();

  String _joinPathWithRoot(List<String> parts) {
    bool isAbsolute =
        parts.isNotEmpty && parts.first.startsWith(RegExp(r'^[/\\]'));
    final joined = parts
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.replaceAll(RegExp(r'^[/\\]+|[/\\]+$'), ''))
        .join('/');
    return isAbsolute ? '/$joined' : joined;
  }

  Future<String> _dbPath() async {
    AppPath? path = _appPath;
    if (path == null) {
      final data = await IoPlatformInterface.channel
          .invokeMethod(NativeMethodsConst.pathMethod, {});
      _appPath = path = AppPath.fromJson(Map<String, dynamic>.from(data));
    }
    return _joinPathWithRoot([path.support, IDatabaseConst.dbFolderName]);
  }

  Future<String> _getDbUrl(String dbName) async {
    final path = await _dbPath();
    Directory(path).createSync(recursive: true);
    return _joinPathWithRoot([path, "$dbName.db"]);
  }

  Future<bool> _removeDb() async {
    _databases?.closeDb();
    _databases = null;
    final url = await _getDbUrl(NativeMethodsConst.appDbName);
    final file = File(url);
    if (file.existsSync()) {
      file.deleteSync();
    }
    return true;
  }

  Future<bool> closeDb(String dbName) async {
    await _lock.synchronized(() async {
      _databases?.closeDb();
    });
    return true;
  }

  Future<bool> _getOrWriteTableVersion<DATA extends ITableData>(
      IDatabaseIo database) async {
    try {
      final version = ITableReadStructA(
          tableName: IDatabaseConst.iDatabaseTableName,
          storage: 0,
          storageId: 0,
          key: IDatabaseConst.dbVersion);
      final read = await database.read(version);
      if (read != null) {
        return true;
      }
      final write = ITableInsertOrUpdateStructA(
          data: [],
          tableName: IDatabaseConst.iDatabaseTableName,
          storage: 0,
          storageId: 0,
          key: IDatabaseConst.dbVersion);
      await database.write(write);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<InitializeDatabaseStatus> openDatabase() async {
    if (_status != InitializeDatabaseStatus.init) return _status;
    await _lock.synchronized(() async {
      _status = await _initDb();
    });
    return _status;
  }

  Future<InitializeDatabaseStatus> _initDb() async {
    if (_status != InitializeDatabaseStatus.init) return _status;
    if (Platform.isAndroid) {
      _library = DynamicLibrary.open('libsqlite3mc.so');
    } else if (Platform.isWindows) {
      _library = DynamicLibrary.open('libsqlite3mc.dll');
    } else {
      _library = DynamicLibrary.open('libsqlite3mc.dylib');
    }
    String? key = await readStorage(NativeMethodsConst.appDbName);
    if (key == null) {
      await _removeDb();
      key = BytesUtils.toHexString(QuickCrypto.generateRandom());
      await writeSecure(NativeMethodsConst.appDbName, key);
    }
    final open = _library.lookupFunction<Sqlite3OpenNative, Sqlite3OpenDart>(
      'sqlite3_open',
    );
    final exec = _library.lookupFunction<Sqlite3ExecNative, Sqlite3ExecDart>(
      'sqlite3_exec',
    );
    final dbPath = await _getDbUrl(NativeMethodsConst.appDbName);
    final path = dbPath.toNativeUtf8();
    final keyStmt = "PRAGMA hexkey = '$key';".toNativeUtf8();
    final errMsg = SafePointer(calloc<Pointer<Utf8>>());
    final dbPtr = SafePointer(calloc<Pointer<Void>>());
    try {
      final rc = open(path.ptr, dbPtr.ptr);
      if (rc != 0) {
        dbPtr.free();
        return InitializeDatabaseStatus.error;
      }
      final db = dbPtr.ptr.value;

      final rcKey = exec(db, keyStmt.ptr, nullptr, nullptr, errMsg.ptr);
      if (rcKey != 0) {
        final _ = errMsg.ptr.value.toDartString();
        dbPtr.free();
        return InitializeDatabaseStatus.error;
      }
      final newDb = IDatabaseIo(
        dbName: NativeMethodsConst.appDbName,
        dbPointer: dbPtr,
        lib: _library,
      );
      final write = await _getOrWriteTableVersion(newDb);
      if (!write) {
        dbPtr.free();
        return InitializeDatabaseStatus.error;
      }
      _databases = newDb;
      return InitializeDatabaseStatus.ready;
    } finally {
      path.free();
      keyStmt.free();
      errMsg.free();
    }
  }

  IDatabaseIo getDatabase(String name) {
    final database = _databases;
    if (database == null) {
      throw IDatabaseException(
        'Database not initialized. Please call init() before using the database $_status $name.',
      );
    }
    return database;
  }

  @override
  Future<DATA?> readDb<DATA extends ITableData>(ITableRead<DATA> params) async {
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.read<DATA>(params);
  }

  @override
  Future<List<DATA>> readAllDb<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.readAll<DATA>(params);
  }

  @override
  Future<bool> removeDb(ITableRemove params) async {
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.remove(params);
  }

  @override
  Future<bool> writeDb(ITableInsertOrUpdate params) async {
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.write(params);
  }

  @override
  Future<bool> writeAllDb(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return false;

    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.writeAll(params);
  }

  @override
  Future<bool> removeAllDb(List<ITableRemove> params) async {
    if (params.isEmpty) return false;
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.removeAll(params);
  }

  @override
  Future<bool> dropDb(ITableDrop params) async {
    final db = getDatabase(NativeMethodsConst.appDbName);
    return await db.drop(params);
  }

  @override
  Future<bool> hasStorage(String key) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
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
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "readAll"});

    Map<String, String> values = Map<String, String>.from(data!);
    if (prefix != null) {
      values = values..removeWhere((k, v) => !k.startsWith(prefix));
    }
    return Map<String, String>.from(values);
  }

  @override
  Future<Map<String, String>> readMultipleStorage(List<String> keys) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"keys": keys, "type": "readMultiple"});

    return Map<String, String>.from(data);
  }

  @override
  Future<String?> readStorage(String key) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"key": key, "type": "read"});

    return data;
  }

  @override
  Future<List<String>> readKeysStorage({String? prefix}) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
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
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "removeAll"});

    return data;
  }

  Future<bool> writeSecure(String key, String value) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"type": "write", "key": key, "value": value});

    return data;
  }

  Future<bool> removeSecure(String key) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod, {"type": "remove", "key": key});
    return data;
  }

  @override
  Future<bool> removeMultipleStorage(List<String> keys) async {
    final data = await IoPlatformInterface.channel.invokeMethod(
        NativeMethodsConst.secureStorageMethod,
        {"keys": keys, "type": "removeMultiple"});
    return data;
  }
}
