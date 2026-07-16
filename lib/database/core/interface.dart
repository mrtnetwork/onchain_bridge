import 'dart:async';
import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

// enum InitializeDatabaseStatus {
//   init,
//   ready,
//   error;

//   bool get isReady => this == ready;
// }

abstract class IDatabaseApi {
  Stream<IStorageEvent> listenOnTable(
    String tableId, {
    List<OnChainBrdigeSerializationIdentifier> actions =
        OnChainBrdigeSerializationIdentifier.values,
  });
  Future<T> storageAction<T extends Object?>(IStorageAction<T> action);
  Future<T> tableAction<T extends Object?>(ITableAction<T> action);
}

abstract class DefaultDetabaseApi<IDB extends IDatabase>
    implements IDatabaseApi {
  DefaultDetabaseApi();
  Future<IDB> getDatabase();
  final StreamController<IStorageEvent> _controller =
      StreamController.broadcast();
  final Set<String> _tableIds = {};
  final Set<OnChainBrdigeSerializationIdentifier> _actions = {};
  @override
  Stream<IStorageEvent> listenOnTable(
    String tableId, {
    List<OnChainBrdigeSerializationIdentifier> actions =
        OnChainBrdigeSerializationIdentifier.values,
  }) {
    _actions.addAll(actions);
    _tableIds.add(tableId);
    return _controller.stream.where((e) =>
        actions.contains(e.action.serializationIdentifier) &&
        e.tableId == tableId);
  }

  void _emit<T>({required IStorageAction<T> action, required T response}) {
    if (_controller.hasListener &&
        _tableIds.contains(action.tableId) &&
        _actions.contains(action.serializationIdentifier)) {
      _controller.add(IStorageEvent(action: action, response: response));
    }
  }

  // /// database
  // Future<InitializeDatabaseStatus> openDatabase();

  @override
  Future<T> storageAction<T extends Object?>(IStorageAction<T> action) async {
    final database = await getDatabase();
    final response = await action.excute(database);
    try {
      return response;
    } finally {
      _emit<T>(action: action, response: response);
    }
  }

  @override
  Future<T> tableAction<T extends Object?>(ITableAction<T> action) async {
    final database = await getDatabase();
    return action.excute(database);
  }
}

abstract class PlatformStorage {
  Future<bool> hasStorage(String key);
  Future<Map<String, String>> readAllStorage({String? prefix});
  Future<Map<String, String>> readMultipleStorage(List<String> keys);
  Future<String?> readStorage(String key);
  Future<List<String>> readKeysStorage({String? prefix});
  Future<bool> removeAllStorage({String? prefix});
  Future<bool> removeMultipleStorage(List<String> keys);
  Future<bool> writeSecure(String key, String value);
  Future<bool> removeSecure(String key);
}
