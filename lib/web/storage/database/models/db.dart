import 'dart:async';
import 'dart:js_interop';

import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/synchronized/basic_lock.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/constants/constants.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/models/table.dart';
import 'package:on_chain_bridge/web/storage/database/types/types.dart';
import 'package:on_chain_bridge/web/storage/storage/index_db_storage.dart';

typedef ONDBCLOSED = void Function();
// typedef ONUPGRADENEEDED = void Function();

class IDatabaseJS extends IDatabase {
  final bool upgradable;
  final SynchronizedLock lock = SynchronizedLock();
  final Map<String, IDtabaseTableJS> _tables = {};
  final ONDBCLOSED ondbclosed;
  IDatabaseTableJsTransaction getStore(IDtabaseTableJS table,
      {IndexDbStorageMode mode = IndexDbStorageMode.readwrite}) {
    final transaction =
        _database.transaction([table.tableName.toJS].toJS, mode.name);
    final store = transaction.objectStore(table.tableName);

    return IDatabaseTableJsTransaction(transaction: transaction, store: store);
  }

  @override
  final String dbName;
  late IDBDatabase _database;
  IDBDatabase get db => _database;
  List<String> get storeNames => JSArray.from<JSString>(db.objectStoreNames)
      .toDart
      .map((e) => e.toDart)
      .toList();
  void onDbChanged(JSAny _) {
    lock.synchronized(() async {
      _database.close();
      ondbclosed();
    });
  }

  IDatabaseJS(
      {required this.dbName,
      required this.ondbclosed,
      required IDBDatabase database,
      this.upgradable = false}) {
    _database = database;
    if (!upgradable) {
      _database.onversionchange = onDbChanged.toJS;
    }
  }

  Future<IDBDatabase> _updateDbVersion({
    required String tableName,
    required ONUPGRADENEEDED<IDBDatabase> onUpgradeNeeded,
  }) async {
    final db = indexedDB;
    if (db == null) {
      throw IDatabaseException(
          'IndexedDB is not supported in this browser. Please use a modern browser.');
    }
    if (!upgradable) {
      throw IDatabaseJSConstants.unableToUpgradeDatabase;
    }
    final version = _database.version + 1;
    _database.close();
    Future<IDBDatabase?> updateDb() async {
      try {
        final request = db.open(dbName, version);
        final completer = IDBOpenDBRequestCompleter(
          request: request,
          onUpgradeNeeded: onUpgradeNeeded,
        );
        return await completer.wait;
      } on IDatabaseException catch (e) {
        if (e == IDatabaseJSConstants.onDatabaseBlockError) {
          return null;
        }
        rethrow;
      }
    }

    IDBDatabase? newDatabase = await updateDb();
    newDatabase ??= await Future.delayed(const Duration(seconds: 2), updateDb);
    if (newDatabase == null) {
      throw IDatabaseJSConstants.onDatabaseBlockError;
    }
    if (!upgradable) newDatabase.onversionchange = onDbChanged.toJS;
    return newDatabase;
  }

  Future<void> _dropStore(ITableDrop table) async {
    _database = await _updateDbVersion(
        tableName: table.tableName,
        onUpgradeNeeded: (db) {
          if (db.objectStoreNames.contains(table.tableName)) {
            db.deleteObjectStore(table.tableName);
          }
        });
  }

  Future<IDATABASETABLEREAD<DATA>> _getOrCreateTable<DATA extends ITableData>(
      ITableStructOperation params) async {
    final t = _tables[params.tableName];
    if (t != null) {
      if (t.struct != params.struct) {
        throw IDatabaseException("Invalid database request.");
      }
      return t as IDATABASETABLEREAD<DATA>;
    }
    final IDtabaseTableJS newTable = switch (params.struct) {
      IDatabaseTableStruct.a => IDatabaseTableJSStructA(params.tableName)
    };
    if (!_database.objectStoreNames.contains(newTable.tableName)) {
      _database = await _updateDbVersion(
          tableName: newTable.tableName,
          onUpgradeNeeded: (db) {
            if (!db.objectStoreNames.contains(newTable.tableName)) {
              newTable.create(db);
            }
          });
    }
    _tables[params.tableName] = newTable;
    return newTable as IDATABASETABLEREAD<DATA>;
  }

  Future<bool> dropInternal(ITableDrop params) async {
    if (!_database.objectStoreNames.contains(params.tableName)) return false;
    await _dropStore(params);
    _tables.remove(params.tableName);
    return true;
  }

  @override
  Future<bool> drop(ITableDrop params) async {
    return await lock.synchronized(() async {
      return await dropInternal(params);
    });
  }

  Future<DATA?> readInternal<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    final table = await _getOrCreateTable<DATA>(params);
    return await table.read(this, params);
  }

  @override
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params) async {
    return await lock.synchronized(() async {
      return await readInternal(params);
    });
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return await lock.synchronized(() async {
      final table = await _getOrCreateTable<DATA>(params);
      return await table.readAll(this, params);
    });
  }

  @override
  Future<bool> remove(ITableRemove params) async {
    return await lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      return await table.remove(this, params);
    });
  }

  @override
  Future<bool> removeAll(List<ITableRemove> params) async {
    if (params.isEmpty) return false;
    assert(params.every((e) => e.tableName == params.first.tableName));
    return await lock.synchronized(() async {
      final table = await _getOrCreateTable(params.first);
      return await table.removeAll(this, params);
    });
  }

  Future<bool> writeInternal(ITableInsertOrUpdate params) async {
    final table = await _getOrCreateTable(params);
    return await table.write(this, params);
  }

  @override
  Future<bool> write(ITableInsertOrUpdate params) async {
    return await lock.synchronized(() async {
      return await writeInternal(params);
    });
  }

  @override
  Future<bool> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return false;
    return await lock.synchronized(() async {
      assert(params.every((e) => e.tableName == params.first.tableName));
      final table = await _getOrCreateTable(params.first);

      switch (table.struct) {
        case IDatabaseTableStruct.a:
          await table.writeAll(
              this, List<ITableInsertOrUpdateStructA>.from(params));
          break;
      }
      return true;
    });
  }
}
