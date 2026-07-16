import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/serialization/src/exception.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

sealed class IDBAction<RESPONSE extends Object?> {
  final String tableId;
  const IDBAction({required this.tableId});
  Future<RESPONSE> excute(IDatabase db);
}

class IStorageEvent<RESPONSE extends Object?> with AppSerialization {
  final IStorageAction<RESPONSE> action;
  final RESPONSE response;
  const IStorageEvent({required this.action, required this.response});
  factory IStorageEvent.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionEvent,
        cborBytes: bytes,
        cborObject: obj);
    final action =
        IStorageAction<RESPONSE>.deserialize(obj: values.objectAt(0));
    return IStorageEvent(
        action: action, response: action.decodeResponse(values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionEvent;

  @override
  List<CborObject?> get serializationItems =>
      [action.toCbor(), action.encodeResponse(response)];
  String get tableId => action.tableId;
}

class ITableEvent<RESPONSE extends Object?> with AppSerialization {
  final ITableAction<RESPONSE> action;
  final RESPONSE response;
  const ITableEvent({required this.action, required this.response});
  factory ITableEvent.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionEvent,
        cborBytes: bytes,
        cborObject: obj);
    final action = ITableAction<RESPONSE>.deserialize(obj: values.objectAt(0));
    return ITableEvent(
        action: action, response: action.decodeResponse(values.objectAt(1)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionEvent;

  @override
  List<CborObject?> get serializationItems =>
      [action.toCbor(), action.encodeResponse(response)];
  String get tableId => action.tableId;
}

enum StorageActionOperation { write, read, remove, readAll, removeNullableData }

sealed class IStorageAction<RESPONSE extends Object?>
    extends IDBAction<RESPONSE> with AppSerialization {
  final int storage;
  final int actionId;

  StorageActionOperation get operation;

  ///
  const IStorageAction(
      {required super.tableId, required this.storage, required this.actionId});
  factory IStorageAction.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      OnChainBrdigeSerializationIdentifier.storageActionWrite,
      OnChainBrdigeSerializationIdentifier.storageActionRemove,
      OnChainBrdigeSerializationIdentifier.storageActionRead,
      OnChainBrdigeSerializationIdentifier.storageActionReadAll,
      OnChainBrdigeSerializationIdentifier.storageActionCleanNullableObject
    ], cborBytes: bytes, cborObject: obj);
    final tag = values.tag;
    final IStorageAction action = switch (values.identifier) {
      OnChainBrdigeSerializationIdentifier.storageActionWrite =>
        StorageActionWrite.deserialize(obj: tag),
      OnChainBrdigeSerializationIdentifier.storageActionRemove =>
        StorageActionRemove.deserialize(obj: tag),
      OnChainBrdigeSerializationIdentifier.storageActionRead =>
        StorageActionRead.deserialize(obj: tag),
      OnChainBrdigeSerializationIdentifier.storageActionReadAll =>
        StorageActionReadAll.deserialize(obj: tag),
      OnChainBrdigeSerializationIdentifier.storageActionCleanNullableObject =>
        StorageActionCleanNullableObject.deserialize(obj: tag),
      _ => throw OnChainSerializationException(
          reason: "Unknown storage action type.",
          details: {"identifier": values.identifier.toString()})
    };
    return action.cast();
  }

  T cast<T extends IStorageAction>() {
    if (this is! T) {
      throw IDatabaseException.unexpected(
          "Casting istorage failed. expected: $T action:$runtimeType");
    }
    return this as T;
  }

  CborObject encodeResponse(RESPONSE response);

  RESPONSE decodeResponse(CborObject encodedResponse);

  IStorageAction<RESPONSE> copyWith(
      {String? tableId, int? storage, int? actionId});
}

class StorageActionWrite extends IStorageAction<void> {
  final TableStructAStorageData data;
  const StorageActionWrite(
      {required this.data,
      required super.tableId,
      required super.storage,
      required super.actionId});
  factory StorageActionWrite.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionWrite,
        cborBytes: bytes,
        cborObject: obj);
    return StorageActionWrite(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        data: TableStructAStorageData.deserialize(obj: values.objectAt(2)),
        actionId: values.rawValueAt(3));
  }

  @override
  Future<void> excute(IDatabase db) async {
    return await db.write(ITableInsertOrUpdateStructA(
        data: data.data,
        createdAt: data.createdAt,
        encrypted: data.encrypted,
        key: data.column.key,
        keyA: data.column.keyA,
        storage: storage,
        storageId: data.column.storageId ?? 0,
        tableName: tableId));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionWrite;

  @override
  List<CborObject?> get serializationItems =>
      [tableId.toCbor(), storage.toCbor(), data.toCbor(), actionId.toCbor()];

  @override
  CborObject<Object?> encodeResponse(void _) {
    return CborNullValue();
  }

  @override
  void decodeResponse(CborObject<Object?> encodedResponse) {
    encodedResponse.cast<CborNullValue>();
  }

  @override
  StorageActionWrite copyWith(
      {String? tableId,
      int? storage,
      TableStructAStorageData? data,
      int? actionId}) {
    return StorageActionWrite(
        data: data ?? this.data,
        tableId: tableId ?? this.tableId,
        storage: storage ?? this.storage,
        actionId: actionId ?? this.actionId);
  }

  @override
  StorageActionOperation get operation => StorageActionOperation.write;
}

class StorageActionRemove extends IStorageAction<void> {
  final TableStrucAQuery query;

  const StorageActionRemove({
    required this.query,
    required super.tableId,
    required super.storage,
    required super.actionId,
  });
  factory StorageActionRemove.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionRemove,
        cborBytes: bytes,
        cborObject: obj);
    return StorageActionRemove(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        query: TableStrucAQuery.deserialize(obj: values.objectAt(2)),
        actionId: values.rawValueAt(3));
  }
  @override
  Future<void> excute(IDatabase db) async {
    final item = ITableRemoveStructA(
        key: query.column.key,
        keyA: query.column.keyA,
        storage: storage,
        storageId: query.column.storageId,
        tableName: tableId,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt);
    return await db.remove(item);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionRemove;

  @override
  List<CborObject?> get serializationItems =>
      [tableId.toCbor(), storage.toCbor(), query.toCbor(), actionId.toCbor()];

  @override
  CborObject<Object?> encodeResponse(void _) {
    return CborNullValue();
  }

  @override
  void decodeResponse(CborObject<Object?> encodedResponse) {
    encodedResponse.cast<CborNullValue>();
  }

  @override
  StorageActionRemove copyWith(
      {String? tableId, int? storage, TableStrucAQuery? query, int? actionId}) {
    return StorageActionRemove(
        query: query ?? this.query,
        tableId: tableId ?? this.tableId,
        storage: storage ?? this.storage,
        actionId: actionId ?? this.actionId);
  }

  @override
  StorageActionOperation get operation => StorageActionOperation.remove;
}

class StorageActionCleanNullableObject extends IStorageAction<void> {
  final TableStrucAQuery query;

  const StorageActionCleanNullableObject({
    required this.query,
    required super.tableId,
    required super.storage,
    required super.actionId,
  });
  factory StorageActionCleanNullableObject.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier
            .storageActionCleanNullableObject,
        cborBytes: bytes,
        cborObject: obj);
    return StorageActionCleanNullableObject(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        query: TableStrucAQuery.deserialize(obj: values.objectAt(2)),
        actionId: values.rawValueAt(3));
  }
  @override
  Future<void> excute(IDatabase db) async {
    final item = ITableRemoveStructA(
        key: query.column.key,
        keyA: query.column.keyA,
        storage: storage,
        storageId: query.column.storageId,
        tableName: tableId,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt);
    return await db.clearNullableColumn(item);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionCleanNullableObject;

  @override
  List<CborObject?> get serializationItems =>
      [tableId.toCbor(), storage.toCbor(), query.toCbor(), actionId.toCbor()];

  @override
  CborObject<Object?> encodeResponse(void _) {
    return CborNullValue();
  }

  @override
  void decodeResponse(CborObject<Object?> encodedResponse) {
    encodedResponse.cast<CborNullValue>();
  }

  @override
  StorageActionCleanNullableObject copyWith(
      {String? tableId, int? storage, TableStrucAQuery? query, int? actionId}) {
    return StorageActionCleanNullableObject(
        query: query ?? this.query,
        tableId: tableId ?? this.tableId,
        storage: storage ?? this.storage,
        actionId: actionId ?? this.actionId);
  }

  @override
  StorageActionOperation get operation =>
      StorageActionOperation.removeNullableData;
}

class StorageActionRead extends IStorageAction<ITableDataStructA?> {
  final TableStrucAQuery query;
  const StorageActionRead(
      {required this.query,
      required super.tableId,
      required super.storage,
      required super.actionId});

  factory StorageActionRead.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionRead,
        cborBytes: bytes,
        cborObject: obj);
    return StorageActionRead(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        query: TableStrucAQuery.deserialize(obj: values.objectAt(2)),
        actionId: values.rawValueAt(3));
  }
  @override
  Future<ITableDataStructA?> excute(IDatabase db) async {
    return await db.read(ITableReadStructA(
        tableName: tableId,
        storage: storage,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        encrypted: query.encrypted,
        key: query.column.key,
        keyA: query.column.keyA,
        limit: query.limit,
        offset: query.offset,
        ordering: query.ordering,
        storageId: query.column.storageId,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionRead;

  @override
  List<CborObject?> get serializationItems =>
      [tableId.toCbor(), storage.toCbor(), query.toCbor(), actionId.toCbor()];

  @override
  CborObject<Object?> encodeResponse(ITableDataStructA? response) {
    return response?.toCbor() ?? CborNullValue();
  }

  @override
  ITableDataStructA? decodeResponse(CborObject<Object?> encodedResponse) {
    return switch (encodedResponse) {
      CborNullValue _ => null,
      _ => ITableDataStructA.deserialize(obj: encodedResponse)
    };
  }

  @override
  StorageActionRead copyWith(
      {String? tableId,
      int? storage,
      TableStrucAQuery? query,
      bool? remove,
      int? actionId}) {
    return StorageActionRead(
        query: query ?? this.query,
        tableId: tableId ?? this.tableId,
        storage: storage ?? this.storage,
        actionId: actionId ?? this.actionId);
  }

  @override
  StorageActionOperation get operation => StorageActionOperation.read;
}

class StorageActionReadAll extends IStorageAction<List<ITableDataStructA>> {
  final TableStrucAQuery query;

  const StorageActionReadAll(
      {required this.query,
      required super.tableId,
      required super.storage,
      required super.actionId});
  factory StorageActionReadAll.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.storageActionReadAll,
        cborBytes: bytes,
        cborObject: obj);
    return StorageActionReadAll(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        query: TableStrucAQuery.deserialize(obj: values.objectAt(2)),
        actionId: values.rawValueAt(3));
  }
  @override
  Future<List<ITableDataStructA>> excute(IDatabase db) async {
    return await db.readAll(ITableReadStructA(
        tableName: tableId,
        storage: storage,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        encrypted: query.encrypted,
        key: query.column.key,
        keyA: query.column.keyA,
        limit: query.limit,
        offset: query.offset,
        ordering: query.ordering,
        storageId: query.column.storageId,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.storageActionReadAll;

  @override
  List<CborObject?> get serializationItems =>
      [tableId.toCbor(), storage.toCbor(), query.toCbor(), actionId.toCbor()];

  @override
  CborObject<Object?> encodeResponse(List<ITableDataStructA> response) {
    return AppSerialization.listFromObjects(
        response.map((e) => e.toCbor()).toList());
  }

  @override
  List<ITableDataStructA> decodeResponse(CborObject<Object?> encodedResponse) {
    return encodedResponse
        .cast<CborListValue>()
        .allObjectsAs<CborTagValue>()
        .map((e) => ITableDataStructA.deserialize(obj: e))
        .toList();
  }

  @override
  StorageActionReadAll copyWith(
      {String? tableId,
      int? storage,
      TableStrucAQuery? query,
      bool? remove,
      int? actionId}) {
    return StorageActionReadAll(
        query: query ?? this.query,
        tableId: tableId ?? this.tableId,
        storage: storage ?? this.storage,
        actionId: actionId ?? this.actionId);
  }

  @override
  StorageActionOperation get operation => StorageActionOperation.readAll;
}

/// table actions
sealed class ITableAction<RESPONSE extends Object?> extends IDBAction<RESPONSE>
    with AppSerialization {
  final int? storage;
  const ITableAction({required super.tableId, this.storage});
  factory ITableAction.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValueWithInfo(expectedTags: [
      OnChainBrdigeSerializationIdentifier.tableActionDrop,
      OnChainBrdigeSerializationIdentifier.tableActionReadAll,
    ], cborBytes: bytes, cborObject: obj);
    final tag = values.tag;
    final ITableAction action = switch (values.identifier) {
      OnChainBrdigeSerializationIdentifier.tableActionDrop =>
        TableActionDrop.deserialize(obj: tag),
      OnChainBrdigeSerializationIdentifier.tableActionReadAll =>
        TableActionReadAll.deserialize(obj: tag),
      _ => throw OnChainSerializationException(
          reason: "Unknown table action type.",
          details: {"identifier": values.identifier.toString()})
    };
    return action.cast();
  }

  CborObject encodeResponse(RESPONSE response);

  RESPONSE decodeResponse(CborObject encodedResponse);

  T cast<T extends ITableAction>() {
    if (this is! T) {
      throw IDatabaseException.unexpected(
          "Casting table action failed. expected: $T action:$runtimeType");
    }
    return this as T;
  }
}

class TableActionDrop extends ITableAction<void> {
  const TableActionDrop({required super.tableId});
  factory TableActionDrop.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.tableActionDrop,
        cborBytes: bytes,
        cborObject: obj);
    return TableActionDrop(tableId: values.rawValueAt(0));
  }
  @override
  Future<void> excute(IDatabase db) async {
    return await db.drop(ITableDropStructA(tableName: tableId));
  }

  @override
  void decodeResponse(CborObject<Object?> _) {}

  @override
  CborObject<Object?> encodeResponse(void response) {
    return CborNullValue();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableActionDrop;

  @override
  List<CborObject?> get serializationItems => [tableId.toCbor()];
}

class TableActionReadAll extends ITableAction<List<ITableDataStructA>> {
  final TableStrucAQuery query;
  const TableActionReadAll(
      {required this.query, required super.tableId, required super.storage});
  factory TableActionReadAll.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.tableActionReadAll,
        cborBytes: bytes,
        cborObject: obj);
    return TableActionReadAll(
        tableId: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        query: TableStrucAQuery.deserialize(obj: values.objectAt(2)));
  }

  @override
  Future<List<ITableDataStructA>> excute(IDatabase db) async {
    return await db.readAll(ITableReadStructA(
        tableName: tableId,
        storage: storage,
        createdAtGt: query.createdAtGt,
        createdAtLt: query.createdAtLt,
        encrypted: query.encrypted,
        key: query.column.key,
        keyA: query.column.keyA,
        limit: query.limit,
        offset: query.offset,
        ordering: query.ordering,
        storageId: query.column.storageId,
        updatedAtGt: query.updatedAtGt,
        updatedAtLt: query.updatedAtLt));
  }

  @override
  CborObject<Object?> encodeResponse(List<ITableDataStructA> response) {
    return AppSerialization.listFromObjects(
        response.map((e) => e.toCbor()).toList());
  }

  @override
  List<ITableDataStructA> decodeResponse(CborObject<Object?> encodedResponse) {
    return encodedResponse
        .cast<CborListValue>()
        .allObjectsAs<CborTagValue>()
        .map((e) => ITableDataStructA.deserialize(obj: e))
        .toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableActionReadAll;

  @override
  List<CborObject?> get serializationItems => [
        tableId.toCbor(),
        storage?.toCbor(),
        query.toCbor(),
      ];
}
