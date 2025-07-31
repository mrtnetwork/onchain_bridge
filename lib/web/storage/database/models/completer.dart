import 'dart:async';
import 'dart:js_interop';

import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/web.dart';

typedef ONUPGRADENEEDED<T extends IDBDatabase?> = void Function(T);

class IDBOpenDBRequestCompleter<T extends IDBDatabase?> {
  final Completer<T> completer;
  final IDBOpenDBRequest<T> request;
  const IDBOpenDBRequestCompleter._(
      {required this.request, required this.completer});
  factory IDBOpenDBRequestCompleter(
      {required IDBOpenDBRequest<T> request,
      required ONUPGRADENEEDED<T> onUpdaradeNeeded}) {
    final Completer<T> completer = Completer<T>();
    request.onupgradeneeded = (WebEvent<IDBOpenDBRequest<T>> event) {
      final T result = event.target.result;
      onUpdaradeNeeded(result);
    }.toJS;
    request.onblocked = (IDBVersionChangeEvent _) {
      completer.completeError(IDatabaseException(
        "IndexedDB upgrade blocked: another tab or window is still using the database.",
      ));
    }.toJS;
    request.onerror = () {
      completer.completeError(IDatabaseException(
        "Failed to open the IndexedDB database. Check browser support or permissions.",
      ));
    }.toJS;
    request.onsuccess = (WebEvent<IDBOpenDBRequest<T>> event) {
      final T result = event.target.result;
      completer.complete(result);
    }.toJS;
    return IDBOpenDBRequestCompleter<T>._(
        request: request, completer: completer);
  }
  Future<T> get wait => completer.future;
}

class IDBRequestCompleter<T extends JSAny?> {
  final Completer<T> completer;
  final IDBRequest<T> request;
  const IDBRequestCompleter._({required this.request, required this.completer});
  factory IDBRequestCompleter({required IDBRequest<T> request}) {
    final Completer<T> completer = Completer<T>();
    request.onerror = () {
      completer.completeError(IDatabaseException(
          "IndexedDB error: the database operation failed."));
    }.toJS;
    request.onsuccess = (WebEvent<IDBRequest<T>> event) {
      final T result = event.target.result;
      completer.complete(result);
    }.toJS;
    return IDBRequestCompleter<T>._(request: request, completer: completer);
  }
  Future<T> get wait => completer.future;
}
