import 'dart:async';
import 'dart:js_interop';

import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/constants/constants.dart';
import 'package:on_chain_bridge/web/web.dart';

typedef ONUPGRADENEEDED<T extends IDBDatabase?> = void Function(T);

class IDBOpenDBRequestCompleter<T extends IDBDatabase?> {
  final Completer<T> completer;
  final IDBOpenDBRequest<T> request;
  const IDBOpenDBRequestCompleter._(
      {required this.request, required this.completer});
  factory IDBOpenDBRequestCompleter(
      {required IDBOpenDBRequest<T> request,
      required ONUPGRADENEEDED<T> onUpgradeNeeded}) {
    final Completer<T> completer = Completer<T>();
    request.onupgradeneeded = (WebEvent<IDBOpenDBRequest<T>> event) {
      final T result = event.target.result;
      onUpgradeNeeded(result);
    }.toJS;
    request.onblocked = (IDBVersionChangeEvent _) {
      completer.completeError(IDatabaseJSConstants.onDatabaseBlockError);
    }.toJS;
    request.onerror = () {
      completer.completeError(IDatabaseException(
        "Failed to open the IndexedDB database. Check browser support or permissions.",
      ));
    }.toJS;
    request.onsuccess = (WebEvent<IDBOpenDBRequest<T>> event) {
      if (completer.isCompleted) return;

      final T result = event.target.result;
      completer.complete(result);
    }.toJS;
    return IDBOpenDBRequestCompleter<T>._(
        request: request, completer: completer);
  }
  Future<T> get wait => completer.future;
}

typedef ONREQUESTRESULT<T extends JSAny?, R> = R Function(T r);

class IDBRequestCompleter<T extends JSAny?, R extends Object?> {
  final Completer<R> completer;
  final IDBRequest<T> request;
  const IDBRequestCompleter._({required this.request, required this.completer});
  factory IDBRequestCompleter(
      {required IDBRequest<T> request,
      required ONREQUESTRESULT<T, R> onResult}) {
    final Completer<R> completer = Completer<R>();
    request.onerror = () {
      completer.completeError(IDatabaseException(
          "IndexedDB error: the database operation failed."));
    }.toJS;
    request.onsuccess = (WebEvent<IDBRequest<T>> event) {
      final T result = event.target.result;
      final r = onResult(result);
      completer.complete(r);
    }.toJS;
    return IDBRequestCompleter<T, R>._(request: request, completer: completer);
  }
  Future<R> get wait => completer.future;
}
