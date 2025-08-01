import 'dart:js_interop';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/web/api/window/indexed_db.dart';
import 'package:on_chain_bridge/web/storage/database/models/table.dart';

@JS()
extension type IDatabaseTableJSStructAScheme._(JSObject _) implements JSAny {
  factory IDatabaseTableJSStructAScheme.setup({
    required int storage,
    required int storageId,
    required String key,
    required String keyA,
    required List<int> data,
    required int createdAt,
  }) {
    final obj = IDatabaseTableJSStructAScheme._(JSObject())
      ..storage = storage
      ..storageId = storageId
      ..key = key
      ..keyA = keyA
      ..data = data.map((e) => e.toJS).toList().toJS
      ..createdAt = createdAt;
    return obj;
  }
  external int? get id;
  external set id(int? _);
  external int get storage;
  external set storage(int _);
  @JS("storage_id")
  external int get storageId;
  @JS("storage_id")
  external set storageId(int _);
  external String get key;
  external set key(String _);
  @JS("key_a")
  external String get keyA;
  @JS("key_a")
  external set keyA(String _);
  external JSArray<JSNumber> get data;
  external set data(JSArray<JSNumber> _);
  external int get createdAt;
  external set createdAt(int _);
  ITableDataStructA? toData(String tableName) {
    try {
      final data = (this.data).toDart;
      return ITableDataStructA(
          storage: storage,
          storageId: storageId,
          id: id!,
          key: key,
          keyA: keyA,
          data: data.map((e) => e.toDartInt).toList(),
          tableName: tableName);
    } catch (_) {
      return null;
    }
  }
}

typedef IDATABASETABLEREAD<DATA extends ITableData> = IDtabaseTableJS<
    ITableInsertOrUpdate, DATA, ITableRead<DATA>, ITableRemove, ITableDrop>;

class IDatabaseTableJsTransaction {
  final IDBTransaction transaction;
  final IDBObjectStore store;
  const IDatabaseTableJsTransaction(
      {required this.transaction, required this.store});
}
