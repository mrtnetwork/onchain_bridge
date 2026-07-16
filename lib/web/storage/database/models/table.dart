import 'dart:async';
import 'dart:js_interop';

import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';
import 'package:on_chain_bridge/web/storage/database/models/completer.dart';
import 'package:on_chain_bridge/web/storage/database/types/types.dart';
import 'package:on_chain_bridge/web/storage/storage/index_db_storage.dart';
import 'db.dart';

abstract class IDtabaseTableJS<
        W extends ITableInsertOrUpdate,
        DATA extends ITableData,
        R extends ITableRead<DATA>,
        RE extends ITableRemove,
        DR extends ITableDrop>
    implements IDatabaseTable<IDatabaseJS, W, DATA, R, RE, DR> {
  void create(IDBDatabase db);

  Future<DATA?> read(IDBDatabase db, R query);
  Future<void> remove(IDBDatabase db, RE query);
  Future<void> write(IDBDatabase db, W data);
  Future<List<DATA>> readAll(IDBDatabase db, R query);
  Future<void> writeAll(IDBDatabase db, List<W> data);
  Future<void> removeAll(IDBDatabase db, List<RE> queries);

  ///
  ///
  Future<void> removeData(IDBDatabase db, RE query);
  Future<void> removeAllData(IDBDatabase db, List<RE> queries);
  Future<void> clearNullableColumn(IDBDatabase db, RE query);
}

class IDatabaseTableJSStructA
    implements
        IDatabaseTableStructA<IDatabaseJS>,
        IDtabaseTableJS<ITableInsertOrUpdateStructA, ITableDataStructA,
            ITableReadStructA, ITableRemoveStructA, ITableDropStructA> {
  @override
  final String tableName;
  const IDatabaseTableJSStructA(this.tableName);

  Future<List<ITableDataStructA>> _execute(
      {required IDBDatabase db,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
      bool remove = false,
      bool removeNullabeData = false,
      int? storage,
      int? storageId,
      String? key,
      String? keyA,
      int? createdAtLt,
      int? createdAtGt,
      int? updatedAtLt,
      int? updatedAtGt,
      int? limit,
      int? offset}) async {
    final transaction = db.transaction(
        [tableName.toJS].toJS, IndexDbStorageMode.readwrite.name);
    final store = transaction.objectStore(tableName);
    IDBIndex? index;
    if (storage != null && storageId != null && key != null && keyA != null) {
      index = store.index("unique_index");
      final params = [storage.toJS, storageId.toJS, key.toJS, keyA.toJS].toJS;
      final request = index.getObject<IDatabaseTableJSStructAScheme?>(params);
      final result = (await IDBRequestCompleter(
        request: request,
        onResult: (r) {
          return r?.toData(tableName);
        },
      ).wait);
      if (result == null) return [];
      if (remove) {
        final deleteReq = store.delete(result.id.toJS);
        await IDBRequestCompleter(request: deleteReq, onResult: (r) => null)
            .wait;
        return [];
      }
      return [result];
    }

    IDBKeyRange? keyRange;
    if (storage != null && storageId != null) {
      index = store.index("storage_and_storage_id_index");
      keyRange = IDBKeyRange.only([storage.toJS, storageId.toJS].toJS);
    } else if (storageId != null) {
      index = store.index("storage_id_index");
      keyRange = IDBKeyRange.only([storageId.toJS].toJS);
    } else if (storage != null) {
      index = store.index("storage_index");
      keyRange = IDBKeyRange.only([storage.toJS].toJS);
    }
    IDBRequest<IDBCursorWithValue<IDatabaseTableJSStructAScheme?>> request;
    final direction = ordering == IDatabaseQueryOrdering.desc ? 'prev' : 'next';
    if (index == null) {
      request =
          store.openCursor<IDatabaseTableJSStructAScheme?>(keyRange, direction);
    } else {
      request =
          index.openCursor<IDatabaseTableJSStructAScheme?>(keyRange, direction);
    }
    final Completer completer = Completer();
    request.onerror = () {
      completer.completeError(IDatabaseException.unexpected(
          "IndexedDB error: the database operation failed."));
    }.toJS;
    // final request = ;
    bool skip = false;

    final List<IDatabaseTableJSStructAScheme> matched = [];
    request.onsuccess = (WebEvent<
            IDBRequest<IDBCursorWithValue<IDatabaseTableJSStructAScheme>?>>
        event) {
      final cursor = event.target.result;
      if (cursor == null) {
        completer.complete();
        return;
      }
      if (offset != null && !skip) {
        cursor.advance(offset);
        skip = true;
        return;
      }

      final value = cursor.value;
      if ((storage != null && storage != value.storage) ||
          (removeNullabeData && value.data != null) ||
          (storageId != null && storageId != value.storageId) ||
          (key != null && key != value.key) ||
          (keyA != null && keyA != value.keyA) ||
          (createdAtLt != null && value.createdAt >= createdAtLt) ||
          (createdAtGt != null && value.createdAt <= createdAtGt) ||
          (updatedAtLt != null && (value.updateAt ?? 0) >= updatedAtLt) ||
          (updatedAtGt != null && (value.updateAt ?? 0) <= updatedAtGt)) {
        cursor.continue_();
        return;
      }

      if (remove) {
        cursor.delete();
      } else {
        matched.add(value);
      }
      if (limit != null && matched.length >= limit) {
        completer.complete();
      } else {
        cursor.continue_();
      }
    }.toJS;

    await completer.future;
    if (remove) {
      return [];
    } else {
      return matched
          .map((e) => e.toData(tableName))
          .whereType<ITableDataStructA>()
          .toList();
    }
  }

  @override
  Future<ITableDataStructA?> read(
      IDBDatabase db, ITableReadStructA query) async {
    final result = await _execute(
        db: db,
        ordering: query.ordering,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        key: query.key,
        keyA: query.keyA,
        limit: 1,
        offset: null,
        remove: false,
        storage: query.storage,
        storageId: query.storageId,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt);
    return result.firstOrNull;
  }

  @override
  Future<List<ITableDataStructA>> readAll(
      IDBDatabase db, ITableReadStructA query) async {
    return await _execute(
        db: db,
        ordering: query.ordering,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        key: query.key,
        keyA: query.keyA,
        limit: query.limit,
        offset: query.offset,
        remove: false,
        storage: query.storage,
        storageId: query.storageId,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt);
  }

  IDatabaseTableJsTransaction getStore(IDBDatabase database,
      {IndexDbStorageMode mode = IndexDbStorageMode.readwrite}) {
    final transaction = database.transaction([tableName.toJS].toJS, mode.name);
    final store = transaction.objectStore(tableName);

    return IDatabaseTableJsTransaction(transaction: transaction, store: store);
  }

  @override
  Future<void> remove(IDBDatabase db, ITableRemoveStructA query,
      {IDatabaseTableJsTransaction? store}) async {
    await _execute(
        db: db,
        key: query.key,
        keyA: query.keyA,
        storage: query.storage,
        storageId: query.storageId,
        remove: true);
  }

  @override
  Future<void> removeAll(
      IDBDatabase db, List<ITableRemoveStructA> queries) async {
    final store = getStore(db);
    for (final i in queries) {
      await remove(db, i, store: store);
    }
  }

  Future<void> _write({
    required IDBDatabase db,
    IDatabaseTableJsTransaction? store,
    required _ITableInsertOrUpdateStructA data,
  }) async {
    store ??= getStore(db);
    final index = store.store.index("unique_index");
    final request = index.getObject<IDatabaseTableJSStructAScheme?>([
      data.storage.toJS,
      data.storageId.toJS,
      (data.key ?? '').toJS,
      (data.keyA ?? '').toJS
    ].toJS);
    final completer = IDBRequestCompleter(
      request: request,
      onResult: (r) {
        r ??= IDatabaseTableJSStructAScheme.setup(
            storage: data.storage,
            storageId: data.storageId,
            key: data.key ?? '',
            keyA: data.keyA ?? '',
            createdAt:
                IDatabaseUtils.createOrConvertDateTimeSecound(data.createdAt),
            data: data.data,
            updateAt: IDatabaseUtils.createOrConvertDateTimeSecound());
        if (r.id != null) {
          r.data = data.data?.map((e) => e.toJS).toList().toJS;
          r.updateAt = IDatabaseUtils.createOrConvertDateTimeSecound();
          final request = store!.store.put<JSNumber>(r);
          return IDBRequestCompleter(request: request, onResult: (r) => null);
          // await completer.wait;
        } else {
          final obj = IDatabaseTableJSStructAScheme.setup(
              storage: data.storage,
              storageId: data.storageId,
              key: data.key ?? '',
              keyA: data.keyA ?? '',
              createdAt:
                  IDatabaseUtils.createOrConvertDateTimeSecound(data.createdAt),
              updateAt: IDatabaseUtils.createOrConvertDateTimeSecound(),
              data: data.data);

          final request = store!.store.add<JSNumber>(obj);
          return IDBRequestCompleter(request: request, onResult: (r) => null);
        }
      },
    );
    await completer.wait;
  }

  @override
  Future<void> write(IDBDatabase db, ITableInsertOrUpdateStructA data,
      {IDatabaseTableJsTransaction? store}) async {
    return _write(db: db, data: data.toInnerStruct(), store: store);
  }

  Future<void> _writeAll(
      IDBDatabase db, List<_ITableInsertOrUpdateStructA> data) async {
    if (data.isEmpty) return;
    if (data.length == 1) {
      return _write(db: db, data: data.first);
    }
    final store = getStore(db);
    final index = store.store.index("unique_index");
    final request = index.getObject<IDatabaseTableJSStructAScheme?>([
      data.first.storage.toJS,
      data.first.storageId.toJS,
      (data.first.key ?? '').toJS,
      (data.first.keyA ?? '').toJS
    ].toJS);

    Completer putOrAdd(
        IDatabaseTableJSStructAScheme? r, _ITableInsertOrUpdateStructA data) {
      r ??= IDatabaseTableJSStructAScheme.setup(
          storage: data.storage,
          storageId: data.storageId,
          key: data.key ?? '',
          keyA: data.keyA ?? '',
          createdAt:
              IDatabaseUtils.createOrConvertDateTimeSecound(data.createdAt),
          updateAt: IDatabaseUtils.createOrConvertDateTimeSecound(),
          data: data.data);
      if (r.id != null) {
        r.data = data.data?.map((e) => e.toJS).toList().toJS;
        r.updateAt = IDatabaseUtils.createOrConvertDateTimeSecound();
        final request = store.store.put<JSNumber>(r);
        return IDBRequestCompleter(
          request: request,
          onResult: (r) => null,
        ).completer;
        // await completer.wait;
      } else {
        final request = store.store.add<JSNumber>(r);
        return IDBRequestCompleter(request: request, onResult: (r) => null)
            .completer;
      }
    }

    final completer = IDBRequestCompleter(
      request: request,
      onResult: (result) {
        return [
          putOrAdd(result, data.first),
          ...List.generate(data.length - 1, (l) {
            final i = data[l + 1];
            return IDBRequestCompleter(
              request: index.getObject<IDatabaseTableJSStructAScheme?>([
                i.storage.toJS,
                i.storageId.toJS,
                (i.key ?? '').toJS,
                (i.keyA ?? '').toJS
              ].toJS),
              onResult: (result) {
                return putOrAdd(result, i);
              },
            ).completer;
          })
        ];
      },
    );
    final r = await completer.wait;
    await Future.wait(r.map((e) => e.future));
  }

  @override
  Future<void> writeAll(
      IDBDatabase db, List<ITableInsertOrUpdateStructA> data) async {
    if (data.isEmpty) return;
    if (data.length == 1) {
      return write(db, data.first);
    }
    final store = getStore(db);
    final index = store.store.index("unique_index");
    final request = index.getObject<IDatabaseTableJSStructAScheme?>([
      data.first.storage.toJS,
      data.first.storageId.toJS,
      (data.first.key ?? '').toJS,
      (data.first.keyA ?? '').toJS
    ].toJS);

    Completer putOrAdd(
        IDatabaseTableJSStructAScheme? r, ITableInsertOrUpdateStructA data) {
      r?.data = data.data?.map((e) => e.toJS).toList().toJS;
      r ??= IDatabaseTableJSStructAScheme.setup(
          storage: data.storage,
          storageId: data.storageId,
          key: data.key ?? '',
          keyA: data.keyA ?? '',
          createdAt:
              IDatabaseUtils.createOrConvertDateTimeSecound(data.createdAt),
          updateAt: IDatabaseUtils.createOrConvertDateTimeSecound(),
          data: data.data);
      if (r.id != null) {
        final request = store.store.put<JSNumber>(r);
        return IDBRequestCompleter(
          request: request,
          onResult: (r) => null,
        ).completer;
        // await completer.wait;
      } else {
        final request = store.store.add<JSNumber>(r);
        return IDBRequestCompleter(request: request, onResult: (r) => null)
            .completer;
      }
    }

    final completer = IDBRequestCompleter(
      request: request,
      onResult: (result) {
        return [
          putOrAdd(result, data.first),
          ...List.generate(data.length - 1, (l) {
            final i = data[l + 1];
            return IDBRequestCompleter(
              request: index.getObject<IDatabaseTableJSStructAScheme?>([
                i.storage.toJS,
                i.storageId.toJS,
                (i.key ?? '').toJS,
                (i.keyA ?? '').toJS
              ].toJS),
              onResult: (result) {
                return putOrAdd(result, i);
              },
            ).completer;
          })
        ];
      },
    );
    final r = await completer.wait;
    await Future.wait(r.map((e) => e.future));
  }

  @override
  void create(IDBDatabase db) {
    final store = db.createObjectStore(tableName,
        IDBObjectStoreCreateObjectStore(keyPath: "id", autoIncrement: true));
    store.createIndex(
        "unique_index",
        ["storage", "storage_id", "key", "key_a"]
            .map((e) => e.toJS)
            .toList()
            .toJS,
        IDBObjectStoreCreateIndexOptions(unique: true));
    store.createIndex("storage_index", ["storage".toJS].toJS,
        IDBObjectStoreCreateIndexOptions(unique: false));
    store.createIndex("storage_id_index", ["storage_id".toJS].toJS,
        IDBObjectStoreCreateIndexOptions(unique: false));
    store.createIndex(
        "storage_and_storage_id_index",
        ["storage", "storage_id"].map((e) => e.toJS).toList().toJS,
        IDBObjectStoreCreateIndexOptions(unique: false));
  }

  @override
  IDatabaseTableStruct get struct => IDatabaseTableStruct.a;

  @override
  Future<void> clearNullableColumn(
      IDBDatabase db, ITableRemoveStructA query) async {
    await _execute(
        db: db,
        key: query.key,
        keyA: query.keyA,
        storage: query.storage,
        storageId: query.storageId,
        remove: true,
        removeNullabeData: true,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt);
  }

  @override
  Future<void> removeAllData(
      IDBDatabase db, List<ITableRemoveStructA> queries) async {
    final data = (await (Future.wait(queries.map((e) async {
      return await readAll(
          db,
          ITableReadStructA(
              tableName: tableName,
              storage: e.storage,
              storageId: e.storageId,
              key: e.key,
              keyA: e.keyA,
              createdAtGt: e.createdAtGt,
              createdAtLt: e.createdAtLt,
              updatedAtGt: e.updatedAtGt,
              updatedAtLt: e.updatedAtLt));
    }))))
        .expand((e) => e);
    return _writeAll(
        db,
        data
            .where((e) => e.data != null)
            .map((e) => _ITableInsertOrUpdateStructA(
                data: null,
                storage: e.storage,
                storageId: e.storageId,
                key: e.key,
                keyA: e.keyA))
            .toList());
  }

  @override
  Future<void> removeData(IDBDatabase db, ITableRemoveStructA query) async {
    return removeAllData(db, [query]);
  }
}

class _ITableInsertOrUpdateStructA {
  final List<int>? data;
  final int storage;
  final int storageId;
  final String? key;
  final String? keyA;
  final DateTime? createdAt;
  const _ITableInsertOrUpdateStructA(
      {required this.data,
      required this.storage,
      required this.storageId,
      this.key,
      this.keyA,
      this.createdAt});
}

extension _ITableInsertHelper on ITableInsertOrUpdateStructA {
  _ITableInsertOrUpdateStructA toInnerStruct() {
    return _ITableInsertOrUpdateStructA(
        data: data,
        storage: storage,
        storageId: storageId,
        key: key,
        keyA: keyA,
        createdAt: createdAt);
  }
}
