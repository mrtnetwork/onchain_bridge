import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';

typedef ONSTORAGEACTION = Future<T> Function<T>(IStorageAction<T> action);

class LogWriterDatabase implements LogWriter {
  final ONSTORAGEACTION action;
  final int storage;
  final String tableId;
  final int storageActionId;
  @override
  final LoggerMode mode;
  const LogWriterDatabase(
      {required this.action,
      required this.storage,
      required this.tableId,
      required this.mode,
      required this.storageActionId});

  @override
  Future<void> write(LoggMessage msg) async {
    final msgStr = msg.toWriter();
    await action(StorageActionWrite(
        actionId: storageActionId,
        data: TableStructAStorageData(
            data: StringUtils.encode(msgStr),
            column: TableStructAStorageColums.write(
                storageId: msg.timestamp.millisecondsSinceEpoch),
            createdAt: msg.timestamp,
            encrypted: false),
        tableId: tableId,
        storage: storage));
  }

  @override
  Future<String?> readLogs() async {
    final buffer = StringBuffer();
    final rows = await action(StorageActionReadAll(
        actionId: storageActionId,
        query: TableStrucAQuery(
            column: TableStructAStorageColums.read(), encrypted: false),
        tableId: tableId,
        storage: storage));
    for (final i in rows) {
      final data = i.data;
      if (data == null) continue;
      buffer.writeln(StringUtils.decode(data));
    }
    return buffer.toString();
  }

  @override
  Future<void> clearLogs() async {
    await action(StorageActionRemove(
        actionId: storageActionId,
        query: TableStrucAQuery(column: TableStructAStorageColums.remove()),
        tableId: tableId,
        storage: storage));
  }

  @override
  void close() {}

  @override
  void init() {}
}
