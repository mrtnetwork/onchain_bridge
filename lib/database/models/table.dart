import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/database/exception/exception.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

abstract class IDatabase {
  abstract final String dbName;
  const IDatabase();
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params);
  Future<void> remove(ITableRemove params);
  Future<void> removeAll(List<ITableRemove> params);
  Future<void> write(ITableInsertOrUpdate params);
  Future<List<DATA>> readAll<DATA extends ITableData>(ITableRead<DATA> params);
  Future<void> writeAll(List<ITableInsertOrUpdate> params);
  Future<void> drop(ITableDrop params);

  Future<void> clearNullableColumn(ITableRemove query);
}

class IDatabaseConfig with Equality {
  final String dbName;
  final String encryptionKey;
  IDatabaseConfig({required this.dbName, required this.encryptionKey});

  @override
  List get variables => [dbName];
}

enum IDatabaseTableStruct { a }

abstract class IDatabaseTable<
    DB extends IDatabase,
    W extends ITableInsertOrUpdate,
    DATA extends ITableData,
    R extends ITableRead<DATA>,
    RE extends ITableRemove,
    DR extends ITableDrop> {
  abstract final IDatabaseTableStruct struct;
  abstract final String tableName;
}

abstract class IDatabaseTableStructA<DB extends IDatabase>
    implements
        IDatabaseTable<DB, ITableInsertOrUpdateStructA, ITableDataStructA,
            ITableReadStructA, ITableRemoveStructA, ITableDropStructA> {}

sealed class ITableStructOperation {
  final String tableName;
  final IDatabaseTableStruct struct;
  const ITableStructOperation({
    required this.tableName,
    required this.struct,
  });

  T cast<T extends ITableStructOperation>() {
    if (this is! T) {
      throw IDatabaseException.unexpected("casting failed.");
    }
    return this as T;
  }
}

sealed class ITableDrop extends ITableStructOperation {
  const ITableDrop({
    required super.tableName,
    required super.struct,
  });
}

sealed class ITableInsertOrUpdate extends ITableStructOperation {
  final bool encrypted;
  ITableInsertOrUpdate({
    required super.tableName,
    required super.struct,
    this.encrypted = true,
  });
  ITableInsertOrUpdate copyWith({List<int>? data});

  List<int>? get data;
}

sealed class ITableRemove extends ITableStructOperation {
  const ITableRemove({
    required super.tableName,
    required super.struct,
  });
}

sealed class ITableRead<DATA extends ITableData> extends ITableStructOperation {
  const ITableRead({
    this.createdAtLt,
    this.createdAtGt,
    this.updatedAtGt,
    this.updatedAtLt,
    this.limit,
    this.offset,
    this.ordering = IDatabaseQueryOrdering.desc,
    required super.tableName,
    required super.struct,
    required this.encrypted,
  });
  final bool encrypted;
  final int? createdAtLt;
  final int? createdAtGt;
  final int? limit;
  final int? offset;
  final int? updatedAtLt;
  final int? updatedAtGt;
  final IDatabaseQueryOrdering ordering;
}

sealed class ITableData extends ITableStructOperation {
  final List<int>? data;
  ITableData(
      {required super.tableName,
      required super.struct,
      required List<int>? data})
      : data = data?.asImmutableBytes;
  ITableData copyWith({List<int>? data});
}

class ITableReadStructA extends ITableRead<ITableDataStructA> {
  final int? storage;
  final int? storageId;
  final String? key;
  final String? keyA;
  const ITableReadStructA({
    this.storage,
    this.storageId,
    this.key,
    this.keyA,
    super.createdAtLt,
    super.createdAtGt,
    super.limit,
    super.offset,
    super.updatedAtGt,
    super.updatedAtLt,
    super.ordering = IDatabaseQueryOrdering.desc,
    super.encrypted = true,
    required super.tableName,
  }) : super(struct: IDatabaseTableStruct.a);
  ITableReadStructA copyWith({
    int? storage,
    int? storageId,
    String? key,
    String? keyA,
    int? createdAtLt,
    int? createdAtGt,
    int? limit,
    int? offset,
    IDatabaseQueryOrdering? ordering,
  }) {
    return ITableReadStructA(
      storage: storage ?? this.storage,
      storageId: storageId ?? this.storageId,
      key: key ?? this.key,
      keyA: keyA ?? this.keyA,
      createdAtLt: createdAtLt ?? this.createdAtLt,
      createdAtGt: createdAtGt ?? this.createdAtGt,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      ordering: ordering ?? this.ordering,
      tableName: tableName,
    );
  }
}

class ITableRemoveStructA extends ITableRemove {
  final int storage;
  final int? storageId;
  final String? key;
  final String? keyA;
  final int? updatedAtLt;
  final int? updatedAtGt;
  final int? createdAtLt;
  final int? createdAtGt;

  const ITableRemoveStructA({
    required this.storage,
    this.storageId,
    this.key,
    this.keyA,
    this.updatedAtGt,
    this.updatedAtLt,
    this.createdAtGt,
    this.createdAtLt,
    required super.tableName,
  }) : super(struct: IDatabaseTableStruct.a);
}

class ITableDataStructA extends ITableData with AppSerialization {
  final int id;
  final int storage;
  final int storageId;
  final String key;
  final String keyA;
  final int createdAt;
  final int updatedAt;
  ITableDataStructA({
    required this.storage,
    required this.storageId,
    required this.id,
    required this.key,
    required this.keyA,
    required super.data,
    required super.tableName,
    required this.createdAt,
    required this.updatedAt,
  }) : super(struct: IDatabaseTableStruct.a);
  factory ITableDataStructA.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.tableStructAData,
        cborBytes: bytes,
        cborObject: obj);
    return ITableDataStructA(
      id: values.rawValueAt(0),
      storage: values.rawValueAt(1),
      storageId: values.rawValueAt(2),
      key: values.rawValueAt(3),
      keyA: values.rawValueAt(4),
      data: values.rawValueAt(5),
      tableName: values.rawValueAt(6),
      createdAt: values.rawValueAt(7),
      updatedAt: values.rawValueAt(8),
    );
  }
  @override
  ITableDataStructA copyWith(
      {List<int>? data,
      int? id,
      int? storage,
      int? storageId,
      String? key,
      String? keyA,
      int? createdAt,
      int? updatedAt}) {
    return ITableDataStructA(
        storage: storage ?? this.storage,
        storageId: storageId ?? this.storageId,
        id: id ?? this.id,
        key: key ?? this.key,
        keyA: keyA ?? this.keyA,
        createdAt: createdAt ?? this.createdAt,
        data: data ?? this.data,
        tableName: tableName,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableStructAData;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        storage.toCbor(),
        storageId.toCbor(),
        key.toCbor(),
        keyA.toCbor(),
        AppSerialization.bytesToCbor(data),
        tableName.toCbor(),
        createdAt.toCbor(),
        updatedAt.toCbor(),
      ];

  ITableRemoveStructA toRemoveOperation() {
    return ITableRemoveStructA(
        storage: storage,
        tableName: tableName,
        storageId: storageId,
        key: key,
        keyA: keyA);
  }
}

class ITableInsertOrUpdateStructA extends ITableInsertOrUpdate {
  final int storage;
  final int storageId;
  final String? key;
  final String? keyA;
  final DateTime? createdAt;
  @override
  final List<int>? data;

  ITableInsertOrUpdateStructA({
    required this.data,
    required this.storage,
    required this.storageId,
    this.key,
    this.keyA,
    this.createdAt,
    required super.tableName,
    super.encrypted = true,
  }) : super(struct: IDatabaseTableStruct.a);
  @override
  ITableInsertOrUpdateStructA copyWith({
    List<int>? data,
    int? storage,
    int? storageId,
    String? key,
    String? keyA,
  }) {
    return ITableInsertOrUpdateStructA(
        data: data ?? this.data,
        storage: storage ?? this.storage,
        storageId: storageId ?? this.storageId,
        key: key ?? this.key,
        keyA: keyA ?? this.keyA,
        tableName: tableName);
  }
}

class ITableDropStructA extends ITableDrop {
  const ITableDropStructA({
    required super.tableName,
  }) : super(struct: IDatabaseTableStruct.a);
}

enum IDatabaseOperation {
  read,
  readAll,
  insertOrUpdate,
  delete,
  create,
  bind,
  drop,
  close,
}

enum IDatabaseSuccessCode {
  ok(0),
  done(101),
  row(100);

  bool get isStepOk => this == done || this == row;

  const IDatabaseSuccessCode(this.code);
  final int code;

  static IDatabaseSuccessCode? fromCode(int? code) {
    return values.firstWhereNullable((e) => e.code == code);
  }
}

enum IDatabaseQueryOrdering {
  asc("ASC", 0),
  desc("DESC", 1);

  const IDatabaseQueryOrdering(this.name, this.tag);

  final String name;
  final int tag;
  static IDatabaseQueryOrdering fromTag(int? tag) {
    return values.firstWhere(
      (e) => e.tag == tag,
      orElse: () => throw OnChainSerializationException(
          reason: "Invalid IDatabaseQueryOrdering tag",
          details: {"identifier": tag.toString()}),
    );
  }
}

class TableStructAStorageColums with AppSerialization {
  final String? key;
  final String? keyA;
  final int? storageId;
  const TableStructAStorageColums._({this.key, this.keyA, this.storageId});
  factory TableStructAStorageColums.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.tableStructAStorageColumn,
        cborBytes: bytes,
        cborObject: obj);
    return TableStructAStorageColums._(
        key: values.rawValueAt(0),
        keyA: values.rawValueAt(1),
        storageId: values.rawValueAt(2));
  }
  const TableStructAStorageColums.write(
      {this.key, this.keyA, required int this.storageId});
  const TableStructAStorageColums.remove({this.key, this.keyA, this.storageId});
  const TableStructAStorageColums.read({this.key, this.keyA, this.storageId});

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableStructAStorageColumn;

  @override
  List<CborObject?> get serializationItems =>
      [key?.toCbor(), keyA?.toCbor(), storageId?.toCbor()];
}

class TableStructAStorageData with AppSerialization {
  final List<int>? data;
  final TableStructAStorageColums column;

  final DateTime? createdAt;

  final bool encrypted;

  TableStructAStorageData({
    required this.data,
    required this.column,
    this.createdAt,
    this.encrypted = true,
  }) : super();
  factory TableStructAStorageData.deserialize(
      {List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier:
            OnChainBrdigeSerializationIdentifier.tableStructAStorageData,
        cborBytes: bytes,
        cborObject: obj);
    return TableStructAStorageData(
      data: values.rawValueAt(0),
      column: TableStructAStorageColums.deserialize(obj: values.objectAt(1)),
      createdAt: values.rawValueAt(2),
      encrypted: values.rawValueAt(3),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableStructAStorageData;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.bytesToCbor(data),
        column.toCbor(),
        createdAt?.toCbor(),
        encrypted.toCbor()
      ];
}

class TableStrucAQuery with AppSerialization {
  final TableStructAStorageColums column;
  final bool encrypted;
  final int? createdAtLt;
  final int? createdAtGt;
  final int? limit;
  final int? offset;
  final int? updatedAtLt;
  final int? updatedAtGt;
  final IDatabaseQueryOrdering ordering;
  const TableStrucAQuery(
      {required this.column,
      this.encrypted = true,
      this.createdAtLt,
      this.createdAtGt,
      this.limit,
      this.offset,
      this.updatedAtLt,
      this.updatedAtGt,
      this.ordering = IDatabaseQueryOrdering.desc});
  factory TableStrucAQuery.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.tableStructARead,
        cborBytes: bytes,
        cborObject: obj);
    return TableStrucAQuery(
        column: TableStructAStorageColums.deserialize(obj: values.objectAt(0)),
        createdAtLt: values.rawValueAt(1),
        createdAtGt: values.rawValueAt(2),
        limit: values.rawValueAt(3),
        offset: values.rawValueAt(4),
        ordering: IDatabaseQueryOrdering.fromTag(values.rawValueAt(5)),
        encrypted: values.rawValueAt(6),
        updatedAtGt: values.rawValueAt(7),
        updatedAtLt: values.rawValueAt(8));
  }
  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableStructARead;

  @override
  List<CborObject?> get serializationItems => [
        column.toCbor(),
        createdAtLt?.toCbor(),
        createdAtGt?.toCbor(),
        limit?.toCbor(),
        offset?.toCbor(),
        ordering.tag.toCbor(),
        encrypted.toCbor(),
        updatedAtGt?.toCbor(),
        updatedAtLt?.toCbor()
      ];
}

class TableStructAColums with AppSerialization, Equality {
  final int storage;
  final int storageId;
  final String key;
  final String keyA;

  final String tableName;
  final bool encrypted;
  const TableStructAColums({
    required this.tableName,
    required this.storage,
    required this.storageId,
    this.key = "",
    this.keyA = "",
    this.encrypted = true,
  });
  factory TableStructAColums.deserialize({List<int>? bytes, CborObject? obj}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.tableStructAColumn,
        cborBytes: bytes,
        cborObject: obj);
    return TableStructAColums(
        tableName: values.rawValueAt(0),
        storage: values.rawValueAt(1),
        storageId: values.rawValueAt(2),
        key: values.rawValueAt(3),
        keyA: values.rawValueAt(4),
        encrypted: values.rawValueAt(5));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.tableStructAColumn;

  @override
  List<CborObject?> get serializationItems => [
        tableName.toCbor(),
        storage.toCbor(),
        storageId.toCbor(),
        key.toCbor(),
        keyA.toCbor(),
        encrypted.toCbor()
      ];

  TableStructAStorageColums toStorageColumns() {
    return TableStructAStorageColums._(
        key: key, keyA: keyA, storageId: storageId);
  }

  @override
  List<dynamic> get variables => [storage, storageId, key, keyA, tableName];

  String get identifier => "${tableName}_${storage}_${storageId}_${key}_$keyA";
}
