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

  Future<DATA?> read(IDatabaseJS db, R query);
  Future<bool> remove(IDatabaseJS db, RE query);
  Future<bool> write(IDatabaseJS db, W data);
  Future<List<DATA>> readAll(IDatabaseJS db, R query);
  Future<bool> writeAll(IDatabaseJS db, List<W> data);
  Future<bool> removeAll(IDatabaseJS db, List<RE> queries);
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
      {required IDatabaseJS db,
      IDatabaseQueryOrdering ordering = IDatabaseQueryOrdering.desc,
      bool remove = false,
      int? storage,
      int? storageId,
      String? key,
      String? keyA,
      int? createdAtLt,
      int? createdAtGt,
      int? limit,
      int? offset}) async {
    final transaction = db.db
        .transaction([tableName.toJS].toJS, IndexDbStorageMode.readwrite.name);
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
      completer.completeError(IDatabaseException(
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
          (storageId != null && storageId != value.storageId) ||
          (key != null && key != value.key) ||
          (keyA != null && keyA != value.keyA) ||
          (createdAtLt != null && value.createdAt >= createdAtLt) ||
          (createdAtGt != null && value.createdAt <= createdAtGt)) {
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
      IDatabaseJS db, ITableReadStructA query) async {
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
        storageId: query.storageId);
    return result.firstOrNull;
  }

  @override
  Future<List<ITableDataStructA>> readAll(
      IDatabaseJS db, ITableReadStructA query) async {
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
        storageId: query.storageId);
  }

  @override
  Future<bool> remove(IDatabaseJS db, ITableRemoveStructA query,
      {IDatabaseTableJsTransaction? store}) async {
    await _execute(
        db: db,
        key: query.key,
        keyA: query.keyA,
        storage: query.storage,
        storageId: query.storageId,
        remove: true);
    return true;
  }

  @override
  Future<bool> removeAll(
      IDatabaseJS db, List<ITableRemoveStructA> queries) async {
    final store = db.getStore(this);
    for (final i in queries) {
      await remove(db, i, store: store);
    }
    return true;
  }

  @override
  Future<bool> write(IDatabaseJS db, ITableInsertOrUpdateStructA data,
      {IDatabaseTableJsTransaction? store}) async {
    store ??= db.getStore(this);
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
            data: data.data);
        if (r.id != null) {
          r.data = data.data.map((e) => e.toJS).toList().toJS;
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
              data: data.data);

          final request = store!.store.add<JSNumber>(obj);
          return IDBRequestCompleter(request: request, onResult: (r) => null);
        }
      },
    );
    await completer.wait;
    return true;
  }

  @override
  Future<bool> writeAll(
      IDatabaseJS db, List<ITableInsertOrUpdateStructA> data) async {
    if (data.isEmpty) return false;
    if (data.length == 1) {
      return write(db, data.first);
    }
    final store = db.getStore(this);
    final index = store.store.index("unique_index");
    final request = index.getObject<IDatabaseTableJSStructAScheme?>([
      data.first.storage.toJS,
      data.first.storageId.toJS,
      (data.first.key ?? '').toJS,
      (data.first.keyA ?? '').toJS
    ].toJS);

    Completer putOrAdd(
        IDatabaseTableJSStructAScheme? r, ITableInsertOrUpdateStructA data) {
      r?.data = data.data.map((e) => e.toJS).toList().toJS;
      r ??= IDatabaseTableJSStructAScheme.setup(
          storage: data.storage,
          storageId: data.storageId,
          key: data.key ?? '',
          keyA: data.keyA ?? '',
          createdAt:
              IDatabaseUtils.createOrConvertDateTimeSecound(data.createdAt),
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
    return true;
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
}
