import 'dart:js_interop';

import 'package:on_chain_bridge/web/web.dart';

@JS("indexedDB")
external JSIndexedDB? get indexedDB;
@JS("indexedDB")
extension type JSIndexedDB._(JSObject _) implements JSAny {
  external factory JSIndexedDB();
  external IDBOpenDBRequest<IDBDatabase> open(String name, [int? version]);
  external IDBOpenDBRequest<IDBDatabase?> deleteDatabase(String name,
      [int? version]);
}
@JS("IDBDatabase")
extension type IDBDatabase._(JSObject _) implements JSAny {
  external factory IDBDatabase();
  external String get name;
  external int get version;
  external IDBTransaction transaction(JSArray<JSString> storeNames,
      [String? mode, IDBTransactionOpenOptions? options]);
  external void close();
  external DOMStringList get objectStoreNames;
  external IDBObjectStore createObjectStore(String name,
      [IDBObjectStoreCreateObjectStore? opetions]);
  external void deleteObjectStore(String name);
  external set onclose(JSFunction? _);
}
@JS()
extension type IDBObjectStoreCreateObjectStore._(JSObject _) implements JSAny {
  external factory IDBObjectStoreCreateObjectStore(
      {String? keyPath, bool? autoIncrement});
}
@JS()
extension type IDBTransactionOpenOptions._(JSObject _) implements JSAny {
  external factory IDBTransactionOpenOptions({String? durability});
}
@JS("IDBTransaction")
extension type IDBTransaction._(JSObject _) implements WebEventStream {
  external factory IDBTransaction();
  external String get durability;
  external IDBDatabase get db;
  external String get mode;
  external DOMStringList get objectStoreNames;
  external IDBObjectStore objectStore(String name);
  external set onabort(JSFunction _);
  external set oncomplete(JSFunction? _);
  external set onerror(JSFunction? _);
}

@JS("DOMStringList")
extension type DOMStringList._(JSObject _) implements JSObject {
  external factory DOMStringList();
  external int get length;
  external bool contains(String _);
}
@JS("IDBObjectStore")
extension type IDBObjectStore._(JSObject _) implements JSAny {
  external factory IDBObjectStore();
  external JSNumber get length;
  external JSArray<IDBObjectStore> get indexNames;
  external JSAny get keyPath;
  external String get name;
  external IDBTransaction get transaction;
  external bool get autoIncrement;
  external IDBRequest<T> add<T extends JSAny?>(JSAny value, [JSAny? key]);
  @JS("add")
  external IDBRequest? addString(String value, [String? key]);
  external IDBRequest clear();
  external IDBRequest count([IDBKeyRange? query]);
  external IDBIndex createIndex(String indexName, JSArray<JSString> keyPath,
      [IDBObjectStoreCreateIndexOptions? options]);
  external IDBRequest delete(JSAny key);
  @JS("delete")
  external IDBRequest<JSAny?> deleteStr(String key);
  external void deleteIndex(String indexName);
  external IDBRequest key(JSAny key);
  external IDBRequest<JSArray<T>> getAll<T extends JSAny>(
      [JSAny? query, int? count]);
  external IDBRequest getAllKeys([JSAny? query, int? count]);
  @JS("getAllKeys")
  external IDBRequest<JSArray<JSString>> getAllKeysStr(
      [JSAny? query, int? count]);
  external IDBRequest<T> getKey<T extends JSAny?>(JSAny key);
  external IDBRequest<T> get<T extends JSAny?>(JSAny key);
  @JS("get")
  external IDBRequest<T> getStr<T extends JSAny?>(String key);
  external IDBIndex index(String name);
  external IDBRequest<IDBCursorWithValue<T>> openCursor<T extends JSAny?>(
      [IDBKeyRange? query, String? direction]);
  external IDBRequest<IDBCursor> openKeyCursor(
      [IDBKeyRange? query, String? direction]);
  external IDBRequest<T> put<T extends JSAny?>(JSAny item, [JSAny? key]);
}
@JS("IDBRequest")
extension type IDBRequest<RESULT extends JSAny?>._(JSObject _)
    implements WebEventStream, JSAny {
  external factory IDBRequest();
  external DOMException? get error;
  external RESULT get result;
  external set onerror(JSFunction _);
  external set onsuccess(JSFunction? _);

  // external IDBIndex get source;
}
@JS("DOMException")
extension type DOMException._(JSObject _) implements JSAny {
  external factory DOMException();
  external int get code;
  external String get message;
  external String get name;
}
@JS("IDBIndex")
extension type IDBIndex._(JSObject _) implements JSAny {
  external factory IDBIndex();
  @JS("get")
  external IDBRequest<T> getObject<T extends JSAny?>(JSAny key);
  external IDBRequest<IDBCursorWithValue<T>> openCursor<T extends JSAny?>(
      [IDBKeyRange? query, String? direction]);
  external IDBRequest<IDBCursor> openKeyCursor(
      [IDBKeyRange? query, String? direction]);
}
@JS("IDBKeyRange")
extension type IDBKeyRange._(JSObject _) implements JSAny {
  external factory IDBKeyRange();
  external static IDBKeyRange bound(JSAny lower, JSAny upper,
      [bool lowerOpen, bool upperOpen]);
  external static IDBKeyRange lowerBound(JSAny lower, [bool open]);
  external static IDBKeyRange only(JSAny value);
  external static IDBKeyRange upperBound(JSAny upper, [bool open]);
}
@JS("IDBOpenDBRequest")
extension type IDBOpenDBRequest<T extends IDBDatabase?>._(JSObject _)
    implements IDBRequest<T>, JSAny {
  external set onblocked(JSFunction _);
  external set onupgradeneeded(JSFunction _);
}
@JS("IDBVersionChangeEvent")
extension type IDBVersionChangeEvent<T extends JSAny?>._(JSObject _)
    implements JSAny {
  external int get oldVersion;
  external int get newVersion;
}

@JS()
extension type IDBObjectStoreCreateIndexOptions<T extends JSAny?>._(JSObject _)
    implements JSAny {
  external factory IDBObjectStoreCreateIndexOptions(
      {bool? unique, bool? multientry});

  /// If true, the index will not allow duplicate values for a single key. Defaults to false.
  external set unique(bool _);

  /// If true, the index will add an entry in the index for each array element when the keyPath resolves to an array. If false, it will add one single entry containing the array. Defaults to false.
  external set multientry(bool _);
}

extension type IDBCursor._(JSObject _) implements JSAny {
  external JSAny get source;
  external String get direction;
  external JSAny? get key;
  external JSAny? get primaryKey;
  external void advance(int _);
  @JS("continue")
  external void continue_([JSAny? key]);

  external void continuePrimaryKey(JSAny key, JSAny primarykey);
  external IDBRequest delete();
  external IDBRequest update();
}
extension type IDBCursorWithValue<T extends JSAny?>._(JSObject _)
    implements IDBCursor {
  external T get value;
}

@JS()
extension type APPIndexedDBDefaultScheme._(JSObject _) implements JSAny {
  external factory APPIndexedDBDefaultScheme({String? id, String? value});
  external String? get value;
  external String? get id;
}
