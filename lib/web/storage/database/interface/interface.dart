import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/models/db.dart';
import 'package:on_chain_bridge/web/storage/storage.dart';

class IDatabseInterfaceJS extends DefaultDetabaseApi<EncryptedDatabaseJs> {
  final String dbName;
  final String? debugName;
  final int instanceId;
  IDatabseInterfaceJS(this.dbName, {this.debugName, required this.instanceId});
  final SafeAtomicLock _lock = SafeAtomicLock();
  EncryptedDatabaseJs? _database;
  EncryptedDatabaseJs? get database => _database;

  @override
  Future<EncryptedDatabaseJs> getDatabase() async {
    final database = _database;
    if (database == null) {
      throw IDatabaseException.unexpected(
          'Database not initialized. Please call init() before using the database $dbName.');
    }
    return database;
  }

  Future<Result<void, IException>> openDatabase() async {
    return _lock.run(() async {
      final database = this.database;
      if (database != null) return Ok(database);
      final init = await _openDatabaseInternal();
      return init.map((database) {
        _database = database;
      });
    });
  }

  void _onDBClosed() {}

  Future<Result<EncryptedDatabaseJs, IException>>
      _openDatabaseInternal() async {
    final database = this.database;
    if (database != null) return Ok(database);
    final idb = indexedDB;
    if (idb == null) {
      return Err(IDatabaseException.unsupportedPlatform);
    } else {
      IDBDatabase? db;
      try {
        final request = idb.open(dbName);
        final completer = IDBOpenDBRequestCompleter(
          request: request,
          onUpgradeNeeded: (db) {},
        );
        db = await completer.wait;

        ///
        final database = EncryptedDatabaseJs(
            dbName: dbName,
            database: db,
            instanceId: instanceId,
            ondbclosed: _onDBClosed,
            crypto: ChaCha20Poly1305(List<int>.filled(32, 0)));
        final data = ITableReadStructA(
            tableName: IDatabaseConst.iDatabaseTableName,
            storage: 0,
            storageId: 0,
            key: IDatabaseConst.dbVersion,
            keyA: '');
        final key = await database.readInternal(data);
        final keyData = key?.data;
        if (keyData != null && keyData.length == IDatabaseConst.dbKeyLength) {
          database.setCrypto(ChaCha20Poly1305(keyData));
          return Ok(database);
        }
        final stores = db.objectStoreNames.toDart();
        for (final i in stores) {
          if (i == IDatabaseConst.iDatabaseTableName) continue;
          await database.drop(ITableDropStructA(tableName: i));
        }
        final cryptoKey = QuickCrypto.generateRandom().asImmutableBytes;
        final params = ITableInsertOrUpdateStructA(
            storage: 0,
            storageId: 0,
            data: cryptoKey,
            tableName: IDatabaseConst.iDatabaseTableName,
            key: IDatabaseConst.dbVersion);
        await database.writeInternal(params);
        database.setCrypto(ChaCha20Poly1305(cryptoKey));
        return Ok(database);
      } on IDatabaseException catch (e) {
        return Err(e);
      } catch (e) {
        db?.close();
        return Err(IDatabaseException.unexpected(
            "Failed to initialize index db ${e.toString()}"));
      }
    }
  }
}

class WebPlatformStorage implements PlatformStorage {
  SafeStorage? _storage;
  Future<SafeStorage> _getStorage() async {
    final storage = _storage ??= await SafeStorage.init();
    return storage;
  }

  @override
  Future<bool> hasStorage(String key) async {
    final storage = await _getStorage();
    final data = await storage.read(key);
    return data != null;
  }

  @override
  Future<Map<String, String>> readAllStorage({String? prefix}) async {
    final storage = await _getStorage();
    return storage.all(prefix: prefix);
  }

  @override
  Future<Map<String, String>> readMultipleStorage(List<String> keys) async {
    final storage = await _getStorage();
    return storage.reads(keys);
  }

  @override
  Future<String?> readStorage(String key) async {
    final storage = await _getStorage();
    return storage.read(key);
  }

  @override
  Future<List<String>> readKeysStorage({String? prefix}) async {
    final storage = await _getStorage();
    final keys = await storage.readKeys(prefix: prefix);
    return keys;
  }

  @override
  Future<bool> removeAllStorage({String? prefix}) async {
    final storage = await _getStorage();
    if (prefix != null && prefix.isNotEmpty) {
      final keys = await readKeysStorage(prefix: prefix);
      return removeMultipleStorage(keys);
    }
    await storage.clear();
    return true;
  }

  @override
  Future<bool> removeMultipleStorage(List<String> keys) async {
    final storage = await _getStorage();
    await storage.removes(keys);
    return true;
  }

  @override
  Future<bool> removeSecure(String key) async {
    final storage = await _getStorage();
    await storage.remove(key);
    return true;
  }

  @override
  Future<bool> writeSecure(String key, String value) async {
    final storage = await _getStorage();
    await storage.save(key, value);
    return true;
  }
}
