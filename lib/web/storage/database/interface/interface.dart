import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/synchronized/basic_lock.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/constants/constants.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/models/db.dart';
import 'package:on_chain_bridge/web/storage/storage.dart';

class _IDatabaseInterfaceData {
  final IDatabaseJS database;
  final ChaCha20Poly1305 crypto;
  const _IDatabaseInterfaceData({required this.database, required this.crypto});
}

class IDatabseInterfaceJS extends IDatabseInterface<IDatabaseJS> {
  final bool upgradable;
  IDatabseInterfaceJS({this.upgradable = true});
  final SynchronizedLock _lock = SynchronizedLock();
  InitializeDatabaseStatus _status = InitializeDatabaseStatus.init;
  _IDatabaseInterfaceData? _database;
  IDatabaseJS? get database => _database?.database;
  SafeStorage? _storage;

  _IDatabaseInterfaceData _getDatabase(ITableStructOperation params) {
    final database = _database;
    if (database == null) {
      if (_status == InitializeDatabaseStatus.init) {
        throw IDatabaseException('Database not initialized.');
      }
      throw IDatabaseException(
          'The current environment does not support this database.');
    }
    return database;
  }

  @override
  Future<InitializeDatabaseStatus> openDatabase() async {
    final status = await _initDb();
    return status;
  }

  DATA? _decryptObject<DATA extends ITableData>(
      DATA? data, _IDatabaseInterfaceData db) {
    if (data == null) return null;
    final bytes = data.data;
    if (bytes.length < IDatabaseConst.nonceLength) return null;
    final nonce = bytes.sublist(0, IDatabaseConst.nonceLength);
    final decryptBytes =
        db.crypto.decrypt(nonce, bytes.sublist(IDatabaseConst.nonceLength));
    assert(decryptBytes != null);
    if (decryptBytes == null) return null;
    return data.copyWith(data: decryptBytes) as DATA;
  }

  T _encrypt<T extends ITableInsertOrUpdate>(
      T data, _IDatabaseInterfaceData db) {
    final nonce = QuickCrypto.generateRandom(IDatabaseConst.nonceLength);
    final bytes = data.data;
    final encryptData = db.crypto.encrypt(nonce, bytes);
    return data.copyWith(data: [...nonce, ...encryptData]) as T;
  }

  @override
  Future<DATA?> readDb<DATA extends ITableData>(ITableRead<DATA> params) async {
    final db = _getDatabase(params);
    final data = await db.database.read<DATA>(params);
    return _decryptObject(data, db);
  }

  @override
  Future<List<DATA>> readAllDb<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    final db = _getDatabase(params);
    final data = await db.database.readAll<DATA>(params);
    return data.map((e) => _decryptObject(e, db)).whereType<DATA>().toList();
  }

  @override
  Future<bool> removeDb(ITableRemove params) async {
    final db = _getDatabase(params);
    return await db.database.remove(params);
  }

  @override
  Future<bool> writeDb(ITableInsertOrUpdate params) async {
    final db = _getDatabase(params);
    return await db.database.write(_encrypt(params, db));
  }

  @override
  Future<bool> writeAllDb(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return false;

    final db = _getDatabase(params.first);
    final encrypt = params.map((e) => _encrypt(e, db)).toList();
    return await db.database.writeAll(encrypt);
  }

  @override
  Future<bool> removeAllDb(List<ITableRemove> params) async {
    if (params.isEmpty) return false;
    final db = _getDatabase(params.first);
    return await db.database.removeAll(params);
  }

  @override
  Future<bool> dropDb(ITableDrop params) async {
    final db = _getDatabase(params);
    return await db.database.drop(params);
  }

  void _onDBClosed() {
    _lock.synchronized(() async {
      _status = InitializeDatabaseStatus.init;
      _database = null;
    });
  }

  Future<InitializeDatabaseStatus> _initDb() async {
    if (_status != InitializeDatabaseStatus.init) return _status;
    _status = await _lock.synchronized(() async {
      if (_status != InitializeDatabaseStatus.init) return _status;
      final idb = indexedDB;
      if (idb == null) {
        return InitializeDatabaseStatus.error;
      } else {
        IDBDatabase? db;
        try {
          final request = idb.open(IDatabaseConst.appDbName);
          final completer = IDBOpenDBRequestCompleter(
            request: request,
            onUpgradeNeeded: (db) {},
          );
          db = await completer.wait;

          ///
          final database = IDatabaseJS(
              dbName: IDatabaseConst.appDbName,
              database: db,
              upgradable: upgradable,
              ondbclosed: _onDBClosed);
          await database.lock.synchronized(() async {
            final data = ITableReadStructA(
                tableName: IDatabaseConst.iDatabaseTableName,
                storage: 0,
                storageId: 0,
                key: IDatabaseConst.dbVersion,
                keyA: '');
            final key = await database.readInternal(data);
            if (key != null && key.data.length == IDatabaseConst.dbKeyLength) {
              _database = _IDatabaseInterfaceData(
                database: database,
                crypto: ChaCha20Poly1305(key.data),
              );
              return InitializeDatabaseStatus.ready;
            }
            final stores = database.storeNames;
            for (final i in stores) {
              if (i == IDatabaseConst.iDatabaseTableName) continue;
              await database.dropInternal(ITableDropStructA(tableName: i));
            }
            final cryptoKey = QuickCrypto.generateRandom().asImmutableBytes;
            final params = ITableInsertOrUpdateStructA(
                storage: 0,
                storageId: 0,
                data: cryptoKey,
                tableName: IDatabaseConst.iDatabaseTableName,
                key: IDatabaseConst.dbVersion);
            await database.writeInternal(params);
            _database = _IDatabaseInterfaceData(
              database: database,
              crypto: ChaCha20Poly1305(cryptoKey),
            );
          });
          return InitializeDatabaseStatus.ready;
        } catch (e) {
          db?.close();
          if (e == IDatabaseJSConstants.unableToUpgradeDatabase) {
            return InitializeDatabaseStatus.init;
          }
          return InitializeDatabaseStatus.error;
        }
      }
    });
    return _status;
  }

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
}
