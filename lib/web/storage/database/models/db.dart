import 'dart:async';
import 'dart:js_interop';

import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/models/table.dart';
import 'package:on_chain_bridge/web/storage/database/types/types.dart';

typedef ONDBCLOSED = void Function();

class IDatabaseData {
  final String name;
  final IDBDatabase database;
  final List<String> storeNames;
  bool closed = false;
  IDatabaseData({required this.database, required this.name})
      : storeNames = database.objectStoreNames.toDart().toImutableList;
  void close() {
    closed = true;
    database.close();
  }

  int get version => database.version;

  Future<IDatabaseData> upgrade(
      {required Future<IDatabaseData> Function() newDb,
      required IDtabaseTableJS table,
      required bool remove}) async {
    final db = indexedDB;
    if (db == null) {
      throw IDatabaseException.unexpected(
          'IndexedDB is not supported in this browser. Please use a modern browser.');
    }
    final request = db.open(name, version + 1);

    final completer = IDBOpenDBRequestCompleter(
      request: request,
      onUpgradeNeeded: (db) {
        if (remove) {
          if (storeNames.contains(table.tableName)) {
            db.deleteObjectStore(table.tableName);
          }
          return;
        }
        if (!storeNames.contains(table.tableName)) {
          table.create(db);
        }
      },
    );
    final result = await completer.wait;
    if (closed) {
      result.close();
      final db = await newDb();
      bool tableExists = db.storeNames.contains(table.tableName);
      bool update =
          switch (remove) { true => tableExists, false => !tableExists };
      if (update) return db.upgrade(newDb: newDb, table: table, remove: remove);
      return db;
    }
    return IDatabaseData(name: name, database: result);
  }
}

class IDatabaseJS extends IDatabase {
  final SafeAtomicLock lock = SafeAtomicLock();
  final Map<String, IDtabaseTableJS> _tables = {};
  final ONDBCLOSED ondbclosed;
  final int instanceId;
  @override
  final String dbName;
  IDatabaseData? _database;
  Future<dynamic>? _r;
  int? get version => _database?.version;

  void onDbChanged(IDBVersionChangeEvent event) {
    _r = Future.delayed(Duration(milliseconds: instanceId * 100));
    _database?.close();
    _database = null;
  }

  IDatabaseJS({
    required this.dbName,
    required this.ondbclosed,
    required IDBDatabase database,
    required this.instanceId,
  }) {
    _database = IDatabaseData(database: database, name: dbName);
    _database?.database.onversionchange = onDbChanged.toJS;
  }
  Future<IDatabaseData> _getDatabase() async {
    await _r;
    final database = _database;
    if (database != null) return database;
    final db = indexedDB;
    if (db == null) {
      throw IDatabaseException.unexpected(
          'IndexedDB is not supported in this browser. Please use a modern browser.');
    }
    final request = db.open(dbName);
    final completer = IDBOpenDBRequestCompleter(
      request: request,
      onUpgradeNeeded: (p0) {},
    );
    final result = await completer.wait;
    final newDatabase =
        _database = IDatabaseData(database: result, name: dbName);
    newDatabase.database.onversionchange = onDbChanged.toJS;
    return newDatabase;
  }

  Future<R> getOrCreateTable<R extends Object?, T extends ITableData>({
    required ITableStructOperation params,
    required Future<R> Function(IDBDatabase db, IDATABASETABLEREAD<T> table)
        transaction,
    bool remove = false,
  }) async {
    IDatabaseData database = await _getDatabase();
    final IDtabaseTableJS table = _tables[params.tableName] ??= switch (
        params.struct) {
      IDatabaseTableStruct.a => IDatabaseTableJSStructA(params.tableName)
    };
    bool tableExists = database.storeNames.contains(params.tableName);
    bool update =
        switch (remove) { true => tableExists, false => !tableExists };
    if (update) {
      database = _database = await database.upgrade(
          newDb: _getDatabase, remove: remove, table: table);
      database.database.onversionchange = onDbChanged.toJS;
    }
    if (remove) {
      _tables.remove(params.tableName);
    }

    return transaction(database.database, table as IDATABASETABLEREAD<T>);
  }

  @override
  Future<void> drop(ITableDrop params) async {
    return await lock.run(() async {
      return getOrCreateTable<void, ITableData>(
          params: params, transaction: (db, table) async {}, remove: true);
    });
  }

  Future<DATA?> readInternal<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return getOrCreateTable<DATA?, DATA>(
      params: params,
      transaction: (db, table) async {
        return await table.read(db, params);
      },
    );
  }

  @override
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params) async {
    return await lock.run(() async {
      return await readInternal(params);
    });
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return await lock.run(() async {
      return getOrCreateTable<List<DATA>, DATA>(
        params: params,
        transaction: (db, table) async {
          return await table.readAll(db, params);
        },
      );
    });
  }

  @override
  Future<void> remove(ITableRemove params) async {
    return await lock.run(() async {
      return getOrCreateTable<void, ITableData>(
        params: params,
        transaction: (db, table) async {
          return await table.remove(db, params);
        },
      );
    });
  }

  @override
  Future<void> removeAll(List<ITableRemove> params) async {
    if (params.isEmpty) return;
    assert(params.every((e) => e.tableName == params.first.tableName));
    return await lock.run(() async {
      return getOrCreateTable<void, ITableData>(
        params: params.first,
        transaction: (db, table) async {
          return await table.removeAll(db, params);
        },
      );
    });
  }

  @override
  Future<void> clearNullableColumn(ITableRemove params) async {
    return await lock.run(() async {
      return getOrCreateTable<void, ITableData>(
        params: params,
        transaction: (db, table) async {
          return await table.clearNullableColumn(db, params);
        },
      );
    });
  }

  Future<void> writeInternal(ITableInsertOrUpdate params) async {
    return getOrCreateTable<void, ITableData>(
      params: params,
      transaction: (db, table) async {
        return await table.write(db, params);
      },
    );
  }

  @override
  Future<void> write(ITableInsertOrUpdate params) async {
    return await lock.run(() async {
      return await writeInternal(params);
    });
  }

  @override
  Future<void> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return;
    return await lock.run(() async {
      assert(params.every((e) => e.tableName == params.first.tableName));
      return getOrCreateTable<void, ITableData>(
        params: params.first,
        transaction: (db, table) async {
          return await table.writeAll(
              db, List<ITableInsertOrUpdateStructA>.from(params));
        },
      );
    });
  }
}

class EncryptedDatabaseJs extends IDatabaseJS {
  ChaCha20Poly1305 _crypto;
  EncryptedDatabaseJs({
    required super.dbName,
    required super.ondbclosed,
    required super.database,
    required super.instanceId,
    required ChaCha20Poly1305 crypto,
  }) : _crypto = crypto;
  DATA? _decryptObject<DATA extends ITableData>(DATA? data, bool encrypted) {
    final bytes = data?.data;
    if (!encrypted || bytes == null) return data;
    if (bytes.length < IDatabaseConst.nonceLength) return null;
    final nonce = bytes.sublist(0, IDatabaseConst.nonceLength);
    final decryptBytes =
        _crypto.decrypt(nonce, bytes.sublist(IDatabaseConst.nonceLength));
    assert(decryptBytes != null);
    if (decryptBytes == null) return null;
    return data?.copyWith(data: decryptBytes) as DATA;
  }

  T _encrypt<T extends ITableInsertOrUpdate>(T data) {
    if (!data.encrypted) return data;
    final bytes = data.data;
    if (bytes == null) return data;
    final nonce = QuickCrypto.generateRandom(IDatabaseConst.nonceLength);

    final encryptData = _crypto.encrypt(nonce, bytes);
    return data.copyWith(data: [...nonce, ...encryptData]) as T;
  }

  @override
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params) async {
    final data = await super.read<DATA>(params);
    return _decryptObject(data, params.encrypted);
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    final data = await super.readAll<DATA>(params);
    return data
        .map((e) => _decryptObject(e, params.encrypted))
        .whereType<DATA>()
        .toList();
  }

  @override
  Future<void> write(ITableInsertOrUpdate params) async {
    return await super.write(_encrypt(params));
  }

  @override
  Future<void> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return;
    final encrypt = params.map((e) => _encrypt(e)).toList();
    return await super.writeAll(encrypt);
  }

  void setCrypto(ChaCha20Poly1305 crypto) => _crypto = crypto;
}
