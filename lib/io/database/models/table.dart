import 'dart:ffi';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/io/database/fifi/fifi.dart';
import 'package:on_chain_bridge/io/database/utils/statement_builder.dart';
import 'db.dart';

typedef IDATABASETABLEREAD<DATA extends ITableData> = IDtabaseTableIo<
    ITableInsertOrUpdate, DATA, ITableRead<DATA>, ITableRemove, ITableDrop>;

abstract class IDtabaseTableIo<
        W extends ITableInsertOrUpdate,
        DATA extends ITableData,
        R extends ITableRead<DATA>,
        RE extends ITableRemove,
        DR extends ITableDrop>
    implements IDatabaseTable<IDatabaseIo, W, DATA, R, RE, DR> {
  Future<DATA?> read(IDatabaseIo db, R query);
  Future<bool> remove(IDatabaseIo db, RE query);
  Future<bool> write(IDatabaseIo db, W data);
  Future<List<DATA>> readAll(IDatabaseIo db, R query);
  Future<bool> writeAll(IDatabaseIo db, List<W> data);
  Future<bool> removeAll(IDatabaseIo db, List<RE> queries);
  Future<bool> drop(IDatabaseIo db);
  String buildQueryStatement(R query);
  String buildCreateStatement();
  String buildInsertOrUpdateStatement(W query);
  String buildRemoveStatement(RE query);
  String buildDropTableStatement();
  DATA buildData({required IDatabaseIo db, required Pointer<Void> stmt});
  Future<void> create(IDatabaseIo db);
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
    data BLOB NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    UNIQUE(storage, storage_id, key, key_a)
  );
  ''';
  }

  @override
  String buildInsertOrUpdateStatement(ITableInsertOrUpdateStructA query) {
    return '''
INSERT INTO $tableName (
  storage,
  storage_id,
  key,
  key_a,
  data
) VALUES (?, ?, ?, ?, ?)
ON CONFLICT(storage, storage_id, key, key_a) DO UPDATE SET
  data = excluded.data;
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
      "created_at"
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
    builder.orderBy("created_at", query.ordering);
    builder.limit(query.limit);
    builder.offset(query.offset);
    return builder.build();
  }

  @override
  String buildRemoveStatement(ITableRemoveStructA query) {
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
    return builder.build();
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
    final dataPtr = db.sqlite3ColumnBlob(stmt, 5);
    final dataLen = db.sqlite3ColumnBytes(stmt, 5);
    final data = dataPtr.cast<Uint8>().asTypedList(dataLen).toList();
    final createdAt = db.sqlite3ColumnInt64(stmt, 6);
    return ITableDataStructA(
      storage: storage,
      storageId: storageId,
      id: id,
      key: key,
      keyA: keyA,
      data: data,
      createdAt: createdAt,
      tableName: tableName,
    );
  }

  @override
  Future<void> create(IDatabaseIo db) async {
    db.prepareV2(
      statement: buildCreateStatement(),
      stmt: (stmt) {
        db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.create,
          onStep: (statusCode) {},
        );
      },
    );
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
  Future<bool> remove(IDatabaseIo db, ITableRemoveStructA query) async {
    final statement = buildRemoveStatement(query);
    final args = <dynamic>[
      query.storage,
      query.storageId,
      query.key,
      query.keyA,
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
          onStep: (statusCode) {
            if (statusCode != IDatabaseSuccessCode.ok) {
              return false;
            }
            return true;
          },
        );
      },
      statement: statement,
    );
  }

  @override
  Future<bool> write(IDatabaseIo db, ITableInsertOrUpdateStructA data) async {
    return db.prepareV2(
      statement: buildInsertOrUpdateStatement(data),
      stmt: (stmt) {
        db.bindInt64(stmt: stmt, index: 1, value: data.storage);
        db.bindInt64(stmt: stmt, index: 2, value: data.storageId);
        db.bindTextTransient(stmt: stmt, index: 3, value: data.key ?? '');
        db.bindTextTransient(stmt: stmt, index: 4, value: data.keyA ?? '');
        db.bindBlobTransient(stmt: stmt, index: 5, value: data.data);
        return db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.insertOrUpdate,
          onStep: (stepCode) {
            return true;
          },
        );
      },
    );
  }

  @override
  Future<bool> writeAll(
    IDatabaseIo db,
    List<ITableInsertOrUpdateStructA> data,
  ) async {
    for (final i in data) {
      await write(db, i);
    }
    return true;
  }

  @override
  IDatabaseTableStruct get struct => IDatabaseTableStruct.a;

  @override
  Future<bool> removeAll(
      IDatabaseIo db, List<ITableRemoveStructA> queries) async {
    for (final i in queries) {
      await remove(db, i);
    }
    return true;
  }

  @override
  Future<bool> drop(IDatabaseIo db) async {
    final statement = buildDropTableStatement();
    return db.prepareV2(
      stmt: (stmt) {
        return db.sqlite3Step(
          s: stmt,
          operation: IDatabaseOperation.drop,
          onStep: (statusCode) {
            return true;
          },
        );
      },
      statement: statement,
    );
  }
}
