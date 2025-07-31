import 'package:on_chain_bridge/database/models/table.dart';

enum InitializeDatabaseStatus {
  init,
  ready,
  error;

  bool get isReady => this == ready;
}

abstract class IDatabseInterface<IDB extends IDatabase> {
  const IDatabseInterface();

  /// database
  Future<InitializeDatabaseStatus> openDatabase();
  Future<DATA?> readDb<DATA extends ITableData>(ITableRead<DATA> params);
  Future<bool> removeDb(ITableRemove params);
  Future<bool> writeDb(ITableInsertOrUpdate params);
  Future<List<DATA>> readAllDb<DATA extends ITableData>(
      ITableRead<DATA> params);
  Future<bool> writeAllDb(List<ITableInsertOrUpdate> params);
  Future<bool> removeAllDb(List<ITableRemove> params);
  Future<bool> dropDb(ITableDrop params);

  /// storate
  Future<bool> hasStorage(String key);
  Future<Map<String, String>> readAllStorage({String? prefix});
  Future<Map<String, String>> readMultipleStorage(List<String> keys);
  Future<String?> readStorage(String key);
  Future<List<String>> readKeysStorage({String? prefix});
  Future<bool> removeAllStorage({String? prefix});
  Future<bool> removeMultipleStorage(List<String> keys);
}
