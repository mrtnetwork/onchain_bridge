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
      {required IDatabaseTableJsTransaction store,
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
    IDBIndex? index;
    if (storage != null && storageId != null && key != null && keyA != null) {
      index = store.store.index("unique_index");
      final params = [storage.toJS, storageId.toJS, key.toJS, keyA.toJS].toJS;
      final request = index.getObject<IDatabaseTableJSStructAScheme?>(params);
      final result =
          (await IDBRequestCompleter(request: request).wait)?.toData(tableName);
      if (result == null) return [];
      if (remove) {
        final deleteReq = store.store.delete(result.id.toJS);
        await IDBRequestCompleter(request: deleteReq).wait;
        return [];
      }
      return [result];
    }

    IDBKeyRange? keyRange;
    if (storage != null && storageId != null) {
      index = store.store.index("storage_and_storage_id_index");
      keyRange = IDBKeyRange.only([storage.toJS, storageId.toJS].toJS);
    } else if (storageId != null) {
      index = store.store.index("storage_id_index");
      keyRange = IDBKeyRange.only([storageId.toJS].toJS);
    } else if (storage != null) {
      index = store.store.index("storage_index");
      keyRange = IDBKeyRange.only([storage.toJS].toJS);
    }
    IDBRequest<IDBCursorWithValue<IDatabaseTableJSStructAScheme>> request;
    final direction = ordering == IDatabaseQueryOrdering.desc ? 'prev' : 'next';
    if (index == null) {
      request = store.store
          .openCursor<IDatabaseTableJSStructAScheme>(keyRange, direction);
    } else {
      request =
          index.openCursor<IDatabaseTableJSStructAScheme>(keyRange, direction);
    }
    final Completer completer = Completer();
    request.onerror = () {
      completer.completeError(IDatabaseException(
          "IndexedDB error: the database operation failed."));
    }.toJS;
    // final request = ;
    bool skip = false;

    final List<IDatabaseTableJSStructAScheme> matched = [];

    StreamSubscription? sub;
    sub = request
        .streamObject<
                WebEvent<
                    IDBRequest<
                        IDBCursorWithValue<IDatabaseTableJSStructAScheme>?>>>(
            "success")
        .listen((event) {
      final cursor = event.target.result;
      if (cursor == null) {
        sub?.cancel();
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
        sub?.cancel();
        completer.complete();
      } else {
        cursor.continue_();
      }
    });
    await completer.future;
    sub.cancel();
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
        store: db.getStore(this, mode: IndexDbStorageMode.readonly),
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
        store: db.getStore(this, mode: IndexDbStorageMode.readonly),
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
        store: store ?? db.getStore(this),
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
    final completer = IDBRequestCompleter(request: request);
    final result = await completer.wait;
    if (result != null) {
      result.data = data.data.map((e) => e.toJS).toList().toJS;
      final request = store.store.put<JSNumber>(result);
      final completer = IDBRequestCompleter(request: request);
      await completer.wait;
    } else {
      final obj = IDatabaseTableJSStructAScheme.setup(
          storage: data.storage,
          storageId: data.storageId,
          key: data.key ?? '',
          keyA: data.keyA ?? '',
          createdAt: IDatabaseUtils.createOrConvertDateTimeSecound(),
          data: data.data);
      final request = store.store.add<JSNumber>(obj);
      final completer = IDBRequestCompleter(request: request);
      await completer.wait;
    }
    return true;
  }

  @override
  Future<bool> writeAll(
      IDatabaseJS db, List<ITableInsertOrUpdateStructA> data) async {
    final store = db.getStore(this);
    for (final i in data) {
      await write(db, i, store: store);
    }
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
