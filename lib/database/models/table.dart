import 'package:blockchain_utils/blockchain_utils.dart';

abstract class IDatabase {
  abstract final String dbName;
  const IDatabase();

  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params);
  Future<bool> remove(ITableRemove params);
  Future<bool> removeAll(List<ITableRemove> params);
  Future<bool> write(ITableInsertOrUpdate params);
  Future<List<DATA>> readAll<DATA extends ITableData>(ITableRead<DATA> params);
  Future<bool> writeAll(List<ITableInsertOrUpdate> params);
  Future<bool> drop(ITableDrop params);
}

class IDatabaseConfig with Equality {
  final String dbName;
  final String encryptionKey;
  IDatabaseConfig({required this.dbName, required this.encryptionKey});

  @override
  List get variabels => [dbName];
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

abstract class ITableStructOperation {
  final String tableName;
  final IDatabaseTableStruct struct;
  const ITableStructOperation({
    required this.tableName,
    required this.struct,
  });
}

abstract class ITableDrop extends ITableStructOperation {
  const ITableDrop({
    required super.tableName,
    required super.struct,
  });
}

abstract class ITableInsertOrUpdate extends ITableStructOperation {
  final List<int> data;
  ITableInsertOrUpdate(
      {required super.tableName,
      required super.struct,
      required List<int> data})
      : data = data.asImmutableBytes;
  ITableInsertOrUpdate copyWith({List<int>? data});
}

abstract class ITableRemove extends ITableStructOperation {
  const ITableRemove({
    required super.tableName,
    required super.struct,
  });
}

abstract class ITableRead<DATA extends ITableData>
    extends ITableStructOperation {
  const ITableRead({
    this.createdAtLt,
    this.createdAtGt,
    this.limit,
    this.offset,
    this.ordering = IDatabaseQueryOrdering.desc,
    required super.tableName,
    required super.struct,
  });
  final int? createdAtLt;
  final int? createdAtGt;
  final int? limit;
  final int? offset;
  final IDatabaseQueryOrdering ordering;
}

abstract class ITableData extends ITableStructOperation {
  final List<int> data;
  ITableData(
      {required super.tableName,
      required super.struct,
      required List<int> data})
      : data = data.asImmutableBytes;
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
    super.ordering = IDatabaseQueryOrdering.desc,
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
  const ITableRemoveStructA({
    required this.storage,
    this.storageId,
    this.key,
    this.keyA,
    required super.tableName,
  }) : super(struct: IDatabaseTableStruct.a);
}

class ITableDataStructA extends ITableData {
  final int id;
  final int storage;
  final int storageId;
  final String key;
  final String keyA;
  final int? createdAt;
  ITableDataStructA({
    required this.storage,
    required this.storageId,
    required this.id,
    this.createdAt,
    required this.key,
    required this.keyA,
    required super.data,
    required super.tableName,
  }) : super(struct: IDatabaseTableStruct.a);

  @override
  ITableDataStructA copyWith({
    List<int>? data,
    int? id,
    int? storage,
    int? storageId,
    String? key,
    String? keyA,
    int? createdAt,
  }) {
    return ITableDataStructA(
        storage: storage ?? this.storage,
        storageId: storageId ?? this.storageId,
        id: id ?? this.id,
        key: key ?? this.key,
        keyA: keyA ?? this.keyA,
        createdAt: createdAt ?? this.createdAt,
        data: data ?? this.data,
        tableName: tableName);
  }
}

class ITableInsertOrUpdateStructA extends ITableInsertOrUpdate {
  final int storage;
  final int storageId;
  final String? key;
  final String? keyA;

  ITableInsertOrUpdateStructA({
    required super.data,
    required this.storage,
    required this.storageId,
    this.key,
    this.keyA,
    required super.tableName,
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
  asc("ASC"),
  desc("DESC");

  const IDatabaseQueryOrdering(this.value);

  final String value;
}
