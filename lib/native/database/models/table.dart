import 'dart:ffi';
import 'package:blockchain_utils/utils/json/extension/json.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/native/database/constants/constants.dart';
import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
import 'package:on_chain_bridge/native/database/types/types.dart';
import 'package:on_chain_bridge/native/database/utils/statement_builder.dart';
import 'db.dart';

typedef IDATABASETABLEREAD<DATA extends ITableData> = IDtabaseTableIo<
    ITableInsertOrUpdate, DATA, ITableRead<DATA>, ITableRemove, ITableDrop>;

sealed class IDtabaseTableIo<
        W extends ITableInsertOrUpdate,
        DATA extends ITableData,
        R extends ITableRead<DATA>,
        RE extends ITableRemove,
        DR extends ITableDrop>
    implements IDatabaseTable<IDatabaseIo, W, DATA, R, RE, DR> {
  Future<DATA?> read(IDatabaseIo db, R query);
  Future<void> remove(IDatabaseIo db, RE query);
  Future<void> removeAll(IDatabaseIo db, List<RE> queries);
  Future<void> write(IDatabaseIo db, W data);
  Future<List<DATA>> readAll(IDatabaseIo db, R query);
  Future<void> writeAll(IDatabaseIo db, List<W> data);

  Future<void> drop(IDatabaseIo db);
  String buildQueryStatement(R query);
  String buildCreateStatement();
  String buildInsertOrUpdateStatement();
  String buildRemoveStatement(RE query);
  String buildDropTableStatement();
  DATA buildData({required IDatabaseIo db, required Pointer<Void> stmt});
  Future<void> create(IDatabaseIo db);

  ///
  Future<void> removeData(IDatabaseIo db, RE query);
  Future<void> removeAllData(IDatabaseIo db, List<RE> queries);
  Future<void> clearNullableColumn(IDatabaseIo db, RE query);

  // String buildNullableStatement(RE query);
}

class IDatabaseTableIoStructA
    implements
        IDatabaseTableStructA<IDatabaseIo>,
        IDtabaseTableIo<ITableInsertOrUpdateStructA, ITableDataStructA,
            ITableReadStructA, ITableRemoveStructA, ITableDropStructA> {
  @override
  final String tableName;
  const IDatabaseTableIoStructA(this.tableName);

  @override
  String buildDropTableStatement() {
    return "DROP TABLE $tableName";
  }

  @override
  String buildCreateStatement() {
    return '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    storage INTEGER NOT NULL,
    storage_id INTEGER NOT NULL,
    key TEXT NOT NULL,
    key_a TEXT NOT NULL,
    data BLOB,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL DEFAULT 0,
    UNIQUE(storage, storage_id, key, key_a)
  );
  ''';
  }

  @override
  String buildInsertOrUpdateStatement() {
    return '''
INSERT INTO $tableName (
  storage,
  storage_id,
  key,
  key_a,
  data,
  created_at,
  updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(storage, storage_id, key, key_a) DO UPDATE SET
  data = excluded.data,
  updated_at = excluded.updated_at;
  ''';
  }

  @override
  String buildQueryStatement(ITableReadStructA query) {
    final builder = StatementBuilder.select(columns: [
      "id",
      "storage",
      "storage_id",
      "key",
      "key_a",
      "data",
      "created_at",
      "updated_at"
    ], tableName: tableName);
    if (query.storage != null) {
      builder.and('storage');
    }
    if (query.storageId != null) {
      builder.and('storage_id');
    }
    if (query.key != null) {
      builder.and('key');
    }
    if (query.keyA != null) {
      builder.and('key_a');
    }
    if (query.createdAtLt != null) {
      builder.lt("created_at");
    }
    if (query.createdAtGt != null) {
      builder.gt("created_at");
    }
    if (query.updatedAtLt != null) {
      builder.lt("updated_at");
    }
    if (query.updatedAtGt != null) {
      builder.gt("updated_at");
    }
    builder.orderBy("created_at", query.ordering);
    builder.limit(query.limit);
    builder.offset(query.offset);
    return builder.build();
  }

  @override
  String buildRemoveStatement(ITableRemoveStructA query,
      {bool clearNullData = false}) {
    final builder = StatementBuilder.delete(tableName: tableName);
    builder.and("storage");
    if (query.storageId != null) {
      builder.and("storage_id");
    }
    if (query.key != null) {
      builder.and("key");
    }
    if (query.keyA != null) {
      builder.and("key_a");
    }

    if (query.updatedAtGt != null) {
      builder.gt("updated_at");
    }
    if (query.updatedAtLt != null) {
      builder.lt("updated_at");
    }
    if (query.createdAtGt != null) {
      builder.gt("created_at");
    }
    if (query.createdAtLt != null) {
      builder.lt("created_at");
    }
    if (clearNullData) builder.isNull("data");
    return builder.build();
  }

  @override
  Future<void> clearNullableColumn(
      IDatabaseIo db, ITableRemoveStructA query) async {
    return remove(db, query, clearNullData: true);
  }

  @override
  ITableDataStructA buildData({
    required IDatabaseIo db,
    required Pointer<Void> stmt,
  }) {
    final id = db.sqlite3ColumnInt64(stmt, 0);
    final storage = db.sqlite3ColumnInt64(stmt, 1);
    final storageId = db.sqlite3ColumnInt64(stmt, 2);
    final keyPtr = db.sqlite3ColumnText(stmt, 3);
    final key = keyPtr.cast<Utf8>().toDartString();
    final keyAPtr = db.sqlite3ColumnText(stmt, 4);
    final keyA = keyAPtr.cast<Utf8>().toDartString();

    List<int>? bytes;
    if (db.sqlite3ColumnType(stmt, 5) != IDatabaseIoConstants.sqlliteNull) {
      final dataPtr = db.sqlite3ColumnBlob(stmt, 5);
      final dataLen = db.sqlite3ColumnBytes(stmt, 5);
      bytes = dataPtr.cast<Uint8>().asTypedList(dataLen).toList();
    }

    final createdAt = db.sqlite3ColumnInt64(stmt, 6);
    final updateAt = db.sqlite3ColumnInt64(stmt, 7);
    return ITableDataStructA(
        storage: storage,
        storageId: storageId,
        id: id,
        key: key,
        keyA: keyA,
        data: bytes,
        createdAt: createdAt,
        tableName: tableName,
        updatedAt: updateAt);
  }

  @override
  Future<void> create(IDatabaseIo db) async {
    db.prepareV2(
      statement: buildCreateStatement(),
      stmt: (stmt) {
        db.sqlite3Step(
            s: stmt,
            operation: IDatabaseOperation.create,
            onStep: (statusCode) {});
      },
    );
  }

  Map<String, dynamic> buildDataAsMap({
    required IDatabaseIo db,
    required Pointer<Void> stmt,
    required List<String> columnNames,
  }) {
    final Map<String, dynamic> dataMap = {};

    for (int i = 0; i < columnNames.length; i++) {
      final columnName = columnNames[i];
      final columnType = db.sqlite3ColumnType(stmt, i);
      dynamic columnValue;

      switch (columnType) {
        case IDatabaseIoConstants.sqlliteNull:
          columnValue = null;
          break;
        case IDatabaseIoConstants.sqlliteInteger:
          columnValue = db.sqlite3ColumnInt64(stmt, i);
          break;
        case IDatabaseIoConstants.sqlliteText:
          final textPtr = db.sqlite3ColumnText(stmt, i);
          columnValue = textPtr.cast<Utf8>().toDartString();
          break;
        case IDatabaseIoConstants.sqlliteBlob:
          final blobPtr = db.sqlite3ColumnBlob(stmt, i);
          final blobLen = db.sqlite3ColumnBytes(stmt, i);
          columnValue = blobPtr.cast<Uint8>().asTypedList(blobLen).toList();
          break;
        default:
          columnValue = null;
          break;
      }
      dataMap[columnName] = columnValue;
    }

    return dataMap;
  }

  Future<List<SqlliteColumnInfo>> tableColumeInfo(
    IDatabaseIo db,
  ) async {
    final data = await _readAll(
        db: db,
        columnNames: ["cid", "name", "type"],
        statement: "PRAGMA table_info($tableName)");
    return data
        .map((e) => SqlliteColumnInfo(
            cid: e.valueAsInt("cid"),
            name: e.valueAsString("name"),
            type: e.valueAsString("type")))
        .toList();
  }

  @override
  Future<ITableDataStructA?> read(
    IDatabaseIo db,
    ITableReadStructA query,
  ) async {
    final statement = buildQueryStatement(query.copyWith(limit: 1));
    final args = <dynamic>[
      query.storage,
      query.storageId,
      query.key,
      query.keyA,
      query.createdAtLt,
      query.createdAtGt,
    ];
    return db.prepareV2(
      stmt: (stmt) {
        int index = 1;
        for (final arg in args) {
          if (arg is int) {
            db.bindInt64(stmt: stmt, index: index, value: arg);
          } else if (arg is String) {
            db.bindTextTransient(stmt: stmt, index: index, value: arg);
          } else {
            assert(arg == null, "unknow type");
            continue;
          }
          index++;
        }
        return db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.read,
          onStep: (statusCode) {
            if (statusCode == IDatabaseSuccessCode.row) {
              final data = buildData(db: db, stmt: stmt);
              return data;
            }
            return null;
          },
        );
      },
      statement: statement,
    );
  }

  Future<List<Map<String, dynamic>>> _readAll({
    required IDatabaseIo db,
    required List<String> columnNames,
    required String statement,
  }) async {
    return db.prepareV2(
      stmt: (stmt) {
        List<Map<String, dynamic>> results = [];
        while (true) {
          final stepRc = db.sqlite3Step(
            operation: IDatabaseOperation.readAll,
            s: stmt,
            onStep: (statusCode) {
              if (statusCode == IDatabaseSuccessCode.row) {
                return buildDataAsMap(
                    db: db, stmt: stmt, columnNames: columnNames);
              }
              return null;
            },
          );
          if (stepRc == null) break;
          results.add(stepRc);
        }
        return results;
      },
      statement: statement,
    );
  }

  @override
  Future<List<ITableDataStructA>> readAll(
    IDatabaseIo db,
    ITableReadStructA query,
  ) async {
    final statement = buildQueryStatement(query.copyWith());
    final args = <dynamic>[
      query.storage,
      query.storageId,
      query.key,
      query.keyA,
      query.createdAtLt,
      query.createdAtGt,
    ];
    return db.prepareV2(
      stmt: (stmt) {
        int index = 1;
        for (final arg in args) {
          if (arg is int) {
            db.bindInt64(stmt: stmt, index: index, value: arg);
          } else if (arg is String) {
            db.bindTextTransient(stmt: stmt, index: index, value: arg);
          } else {
            assert(arg == null, "unknow type");
            continue;
          }
          index++;
        }
        List<ITableDataStructA> results = [];
        while (true) {
          final stepRc = db.sqlite3Step(
            operation: IDatabaseOperation.readAll,
            s: stmt,
            onStep: (statusCode) {
              if (statusCode == IDatabaseSuccessCode.row) {
                return buildData(db: db, stmt: stmt);
              }
              return null;
            },
          );
          if (stepRc == null) break;
          results.add(stepRc);
        }
        return results;
      },
      statement: statement,
    );
  }

  @override
  Future<void> remove(IDatabaseIo db, ITableRemoveStructA query,
      {bool clearNullData = false}) async {
    final statement = buildRemoveStatement(query, clearNullData: clearNullData);
    final args = <dynamic>[
      query.storage,
      query.storageId,
      query.key,
      query.keyA,
      query.updatedAtGt,
      query.updatedAtLt,
      query.createdAtGt,
      query.createdAtLt
    ];
    return db.prepareV2(
        stmt: (stmt) {
          int index = 1;
          for (final arg in args) {
            if (arg is int) {
              db.bindInt64(stmt: stmt, index: index, value: arg);
            } else if (arg is String) {
              db.bindTextTransient(stmt: stmt, index: index, value: arg);
            } else {
              assert(arg == null, "unknow type");
              continue;
            }
            index++;
          }
          return db.sqlite3Step(
            s: stmt,
            operation: IDatabaseOperation.delete,
            onStep: (statusCode) {},
          );
        },
        statement: statement);
  }

  Future<void> _write({
    required IDatabaseIo db,
    required int storage,
    required int storageId,
    String? key,
    String? keyA,
    DateTime? createdAt,
    List<int>? data,
  }) async {
    return db.prepareV2(
      statement: buildInsertOrUpdateStatement(),
      stmt: (stmt) {
        db.bindInt64(stmt: stmt, index: 1, value: storage);
        db.bindInt64(stmt: stmt, index: 2, value: storageId);
        db.bindTextTransient(stmt: stmt, index: 3, value: key ?? '');
        db.bindTextTransient(stmt: stmt, index: 4, value: keyA ?? '');
        if (data != null) {
          db.bindBlobTransient(stmt: stmt, index: 5, value: data);
        } else {
          db.bindNull(stmt: stmt, index: 5);
        }
        db.bindInt64(
            stmt: stmt,
            index: 6,
            value: IDatabaseUtils.createOrConvertDateTimeSecound(createdAt));
        db.bindInt64(
            stmt: stmt,
            index: 7,
            value: IDatabaseUtils.createOrConvertDateTimeSecound());
        return db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.insertOrUpdate,
          onStep: (stepCode) {},
        );
      },
    );
  }

  @override
  Future<void> write(IDatabaseIo db, ITableInsertOrUpdateStructA data) async {
    return _write(
        db: db,
        storage: data.storage,
        storageId: data.storageId,
        data: data.data,
        createdAt: data.createdAt,
        key: data.key,
        keyA: data.keyA);
  }

  @override
  Future<void> writeAll(
    IDatabaseIo db,
    List<ITableInsertOrUpdateStructA> data,
  ) async {
    for (final i in data) {
      await write(db, i);
    }
  }

  @override
  IDatabaseTableStruct get struct => IDatabaseTableStruct.a;

  @override
  Future<void> removeAll(
      IDatabaseIo db, List<ITableRemoveStructA> queries) async {
    for (final i in queries) {
      await remove(db, i);
    }
  }

  @override
  Future<void> drop(IDatabaseIo db) async {
    final statement = buildDropTableStatement();
    return db.prepareV2(
      stmt: (stmt) {
        return db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.drop,
          onStep: (statusCode) {},
        );
      },
      statement: statement,
    );
  }

  @override
  Future<void> removeAllData(
      IDatabaseIo db, List<ITableRemoveStructA> queries) async {
    for (final i in queries) {
      await removeData(db, i);
    }
  }

  @override
  Future<void> removeData(IDatabaseIo db, ITableRemoveStructA query) async {
    final data = await readAll(
        db,
        ITableReadStructA(
          tableName: tableName,
          storage: query.storage,
          storageId: query.storageId,
          key: query.key,
          keyA: query.keyA,
        ));
    for (final i in data) {
      await _write(
          db: db,
          storage: i.storage,
          storageId: i.storageId,
          data: null,
          key: i.key,
          keyA: i.keyA);
    }
  }
}
