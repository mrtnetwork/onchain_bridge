import 'dart:async';
import 'dart:js_interop';

import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/synchronized/basic_lock.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/models/table.dart';
import 'package:on_chain_bridge/web/storage/database/types/types.dart';
import 'package:on_chain_bridge/web/storage/storage/index_db_storage.dart';

class IDatabaseJS extends IDatabase {
  final SynchronizedLock _lock = SynchronizedLock();
  final Map<String, IDtabaseTableJS> _tables = {};
  IDatabaseTableJsTransaction getStore(IDtabaseTableJS table,
      {IndexDbStorageMode mode = IndexDbStorageMode.readwrite}) {
    final transaction =
        _database.transaction([table.tableName.toJS].toJS, mode.name);
    final store = transaction.objectStore(table.tableName);

    return IDatabaseTableJsTransaction(transaction: transaction, store: store);
  }

  @override
  final String dbName;
  IDBDatabase _database;
  IDBDatabase get db => _database;
  List<String> get storeNames => JSArray.from<JSString>(db.objectStoreNames)
      .toDart
      .map((e) => e.toDart)
      .toList();
  IDatabaseJS({required this.dbName, required IDBDatabase database})
      : _database = database;

  Future<void> _createStore(IDtabaseTableJS table) async {
    if (_database.objectStoreNames.contains(table.tableName)) return;
    final version = _database.version + 1;
    _database.close();

    final db = indexedDB;
    if (db == null) {
      throw IDatabaseException(
          'IndexedDB is not supported in this browser. Please use a modern browser.');
    }
    final request = db.open(dbName, version);
    final completer = IDBOpenDBRequestCompleter(
      request: request,
      onUpdaradeNeeded: (db) {
        if (!db.objectStoreNames.contains(table.tableName)) {
          table.create(db);
        }
      },
    );
    _database = await completer.wait;
  }

  Future<void> _dropStore(ITableDrop table) async {
    final version = _database.version + 1;
    _database.close();
    final db = indexedDB;
    if (db == null) {
      throw IDatabaseException(
          'IndexedDB is not supported in this browser. Please use a modern browser.');
    }
    final request = db.open(dbName, version);
    final completer = IDBOpenDBRequestCompleter(
      request: request,
      onUpdaradeNeeded: (db) {
        if (_database.objectStoreNames.contains(table.tableName)) {
          db.deleteObjectStore(table.tableName);
        }
      },
    );
    _database = await completer.wait;
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
    await _createStore(newTable);
    _tables[params.tableName] = newTable;
    return newTable as IDATABASETABLEREAD<DATA>;
  }

  @override
  Future<bool> drop(ITableDrop params) async {
    return await _lock.synchronized(() async {
      if (!_database.objectStoreNames.contains(params.tableName)) return false;
      await _dropStore(params);
      _tables.remove(params.tableName);
      return true;
    });
  }

  @override
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable<DATA>(params);
      return await table.read(this, params);
    });
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable<DATA>(params);
      return await table.readAll(this, params);
    });
  }

  @override
  Future<bool> remove(ITableRemove params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      return await table.remove(this, params);
    });
  }

  @override
  Future<bool> removeAll(List<ITableRemove> params) async {
    if (params.isEmpty) return false;
    assert(params.every((e) => e.tableName == params.first.tableName));
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params.first);
      return await table.removeAll(this, params);
    });
  }

  @override
  Future<bool> write(ITableInsertOrUpdate params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      await table.write(this, params);
      return true;
    });
  }

  @override
  Future<bool> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return false;
    return await _lock.synchronized(() async {
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
