import 'dart:async';
import 'dart:js_interop';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import 'package:onchain_bridge/exception/exception.dart';
import 'package:onchain_bridge/web/api/window/indexed_db.dart';
import 'package:onchain_bridge/web/storage/constant/constant.dart';
import 'package:onchain_bridge/web/storage/storage.dart';

enum IndexDbStorageMode { readwrite, readonly, readwriteflush }

class IndexDbStorage extends SafeStorage {
  static Future<T> _requestHandler<T extends JSAny?>(IDBRequest<T> request) {
    final Completer<T> completer = Completer();
    request.onsuccess = (JSAny _) {
      completer.complete(request.result);
    }.toJS;
    request.onerror = (JSAny _) {
      completer.completeError(OnChainBridgeException(
          'An unexpected error occurred while sending request to IndexedDB database.'));
    }.toJS;
    return completer.future.timeout(const Duration(seconds: 10));
  }

  static Future<void> _transactionHandler(IDBTransaction transaction) {
    final Completer completer = Completer();
    transaction.oncomplete = (JSAny _) {
      completer.complete();
    }.toJS;
    transaction.onerror = (JSAny _) {
      completer.completeError(OnChainBridgeException(
          'An unexpected error occurred while sending request to IndexedDB database.'));
    }.toJS;
    return completer.future.timeout(const Duration(seconds: 10));
  }

  static Future<(bool, ChaCha20Poly1305)> _getOrCreateKey(
      {required IDBDatabase database}) async {
    final store = getStore(database).$1;
    final request = store.getStr<APPIndexedDBDefaultScheme?>(StorageConst.key);
    final keyHex = (await _requestHandler(request))?.value;
    final key = SafestorageUtils.getOrCreateKey(key: keyHex);
    if (key.$1 != keyHex) {
      final scheme =
          APPIndexedDBDefaultScheme(id: StorageConst.key, value: key.$1);
      final request = store.put<JSString>(scheme);
      await _requestHandler(request);
      return (false, key.$2);
    }

    return (true, key.$2);
  }

  final IDBDatabase database;
  static (IDBObjectStore, IDBTransaction) getStore(IDBDatabase database,
      {IndexDbStorageMode mode = IndexDbStorageMode.readwrite}) {
    final transaction = database.transaction(
        [StorageConst.indexedDbStoreName.toJS].toJS, mode.name);
    final store = transaction.objectStore(StorageConst.indexedDbStoreName);
    return (store, transaction);
  }

  const IndexDbStorage._(this.database, super.chacha);
  static Future<(IndexDbStorage, bool)> init(
      {String? dbName, bool retry = false}) async {
    final db = indexedDB;
    if (db == null) {
      throw OnChainBridgeException('IndexedDB not supported on this browser.');
    }

    final request = db.open(dbName ?? StorageConst.dbName);
    final Completer<IDBDatabase> completer = Completer();
    request.onupgradeneeded = (JSAny _) {
      if (!request.result.objectStoreNames
          .contains(StorageConst.indexedDbStoreName)) {
        request.result.createObjectStore(
            StorageConst.indexedDbStoreName,
            IDBObjectStoreCreateObjectStore(
                autoIncrement: true, keyPath: StorageConst.indexedDbKeyPath));
      }
    }.toJS;
    request.onsuccess = (JSAny _) {
      completer.complete(request.result);
    }.toJS;
    request.onerror = (JSAny _) {
      if (!completer.isCompleted) {
        completer.completeError(OnChainBridgeException(
            'An unexpected error occurred while opening the IndexedDB database.'));
      }
    }.toJS;
    final database = await completer.future;
    if (!database.objectStoreNames.contains(StorageConst.indexedDbStoreName)) {
      if (retry) {
        throw OnChainBridgeException(
            'An unexpected error occurred while opening the IndexedDB database.');
      }
      database.close();
      final r = db.deleteDatabase(dbName ?? StorageConst.dbName);
      await _requestHandler(r);
      return init(dbName: dbName, retry: true);
    }
    final chacha = await _getOrCreateKey(database: database);
    final storage = IndexDbStorage._(database, chacha.$2);
    return (storage, chacha.$1);
  }

  @override
  Future<Map<String, String>> all({String? prefix}) async {
    final store = getStore(database, mode: IndexDbStorageMode.readonly).$1;
    final request = store.getAll<APPIndexedDBDefaultScheme>();
    final response = (await _requestHandler(request)).toDart;
    if (prefix != null) {
      response.removeWhere((e) {
        final id = e.id;
        if (id == null) return true;
        return !id.startsWith(prefix);
      });
    }
    final Map<String, String> result = {};
    for (final i in response) {
      final key = i.id;
      final value = i.value;
      if (key == null || value == null) continue;
      final decode = decrypt(value);
      if (decode == null) continue;
      result[key] = decode;
    }

    return result;
  }

  @override
  Future<void> clear() async {
    final store = getStore(database).$1;
    final request = store.clear();
    await _requestHandler(request);
  }

  @override
  Future<String?> read(String key, {IDBObjectStore? store}) async {
    if (key == StorageConst.key) {
      return null;
    }
    store ??= getStore(database, mode: IndexDbStorageMode.readonly).$1;
    final request = store.getStr<APPIndexedDBDefaultScheme?>(key);
    final response = (await _requestHandler(request))?.value;
    if (response == null) return null;
    return decrypt(response);
  }

  @override
  Future<Map<String, String>> reads(List<String> keys) async {
    final store = getStore(database, mode: IndexDbStorageMode.readonly);
    final Map<String, String> result = {};
    final futures = keys.map((key) async {
      final value = await read(key, store: store.$1);
      if (value != null) {
        result[key] = value;
      }
    });
    await Future.wait(futures);
    return result;
  }

  @override
  Future<List<String>> readKeys({String? prefix}) async {
    final store = getStore(database, mode: IndexDbStorageMode.readonly).$1;
    final request = store.getAllKeysStr();
    final response = await _requestHandler(request);
    return response.toDart.map((e) => e.toDart).toList();
  }

  @override
  Future<void> remove(String key) async {
    if (key == StorageConst.key) {
      return;
    }
    final store = getStore(database).$1;
    final request = store.deleteStr(key);
    await _requestHandler(request);
  }

  @override
  Future<void> removes(List<String> keys) async {
    final store = getStore(database);
    for (final i in keys) {
      if (i == StorageConst.key) {
        continue;
      }
      store.$1.deleteStr(i);
    }
    await _transactionHandler(store.$2);
  }

  @override
  Future<void> save(String key, String value) async {
    if (key == StorageConst.key) {
      return;
    }
    final enc = encrypt(value);
    final scheme = APPIndexedDBDefaultScheme(id: key, value: enc);
    final store = getStore(database).$1;
    final request = store.put<JSString>(scheme);
    await _requestHandler(request);
  }

  @override
  Future<String?> getItem(String key) async {
    final store = getStore(database, mode: IndexDbStorageMode.readonly).$1;
    final request = store.getStr<APPIndexedDBDefaultScheme>(key);
    return (await _requestHandler(request)).value;
  }

  @override
  Future<void> setItem(String key, String value) async {
    final store = getStore(database).$1;
    final scheme = APPIndexedDBDefaultScheme(id: key, value: value);
    final request = store.put<JSString>(scheme);
    await _requestHandler(request);
  }

  void close() {
    database.close();
  }
}
