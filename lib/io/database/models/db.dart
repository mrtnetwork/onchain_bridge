import 'dart:ffi';
import 'dart:typed_data';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/io/database/fifi/fifi.dart';
import 'package:on_chain_bridge/io/database/models/table.dart';
import 'package:on_chain_bridge/io/database/types/types.dart';
import 'package:on_chain_bridge/synchronized/basic_lock.dart';

class IDatabaseIo extends IDatabase {
  final SynchronizedLock _lock = SynchronizedLock();
  final Map<String, IDtabaseTableIo> _tables = {};
  IDatabaseIo(
      {required this.dbName, required this.dbPointer, required this.lib});
  final DynamicLibrary lib;
  @override
  final String dbName;
  final SafePointer<Pointer<Pointer<Void>>> dbPointer;
  Pointer<Void> get db => dbPointer.ptr.value;

  late final exec = lib.lookupFunction<Sqlite3ExecNative, Sqlite3ExecDart>(
    'sqlite3_exec',
  );

  void closeDb() {
    final result = _sqlite3Close(db);
    if (result != IDatabaseSuccessCode.ok.code) {
      _throwLatestError(IDatabaseOperation.close);
    }
  }

  late final _sqlite3Close =
      lib.lookupFunction<Sqlite3CloseNative, Sqlite3CloseDart>('sqlite3_close');

  late final _sqlite3PrepareV2 =
      lib.lookupFunction<Sqlite3PrepareV2Native, Sqlite3PrepareV2Dart>(
    'sqlite3_prepare_v2',
  );
  late final _sqlite3BindText =
      lib.lookupFunction<Sqlite3BindTextNative, Sqlite3BindTextDart>(
    'sqlite3_bind_text',
  );
  late final _sqlite3BindInt64 =
      lib.lookupFunction<Sqlite3BindInt64Native, Sqlite3BindInt64Dart>(
    'sqlite3_bind_int64',
  );
  late final _sqlite3BindBlob =
      lib.lookupFunction<Sqlite3BindBlobNative, Sqlite3BindBlobDart>(
    'sqlite3_bind_blob',
  );

  late final sqlite3ColumnBlob =
      lib.lookupFunction<Sqlite3ColumnBlobNative, Sqlite3ColumnBlobDart>(
    'sqlite3_column_blob',
  );

  late final sqlite3ColumnBytes =
      lib.lookupFunction<Sqlite3ColumnBytesNative, Sqlite3ColumnBytesDart>(
    'sqlite3_column_bytes',
  );

  late final _sqlite3Finalize =
      lib.lookupFunction<Sqlite3FinalizeNative, Sqlite3FinalizeDart>(
    'sqlite3_finalize',
  );

  late final _sqlite3ErrMsg = lib
      .lookupFunction<Sqlite3ErrMsgNative, Sqlite3ErrMsgDart>('sqlite3_errmsg');

  late final sqlite3ColumnInt64 =
      lib.lookupFunction<Sqlite3ColumnInt64Native, Sqlite3ColumnInt64Dart>(
    'sqlite3_column_int64',
  );

  late final sqlite3ColumnText =
      lib.lookupFunction<Sqlite3ColumnTextNative, Sqlite3ColumnTextDart>(
    'sqlite3_column_text',
  );

  late final _sqlite3Step =
      lib.lookupFunction<Sqlite3StepNative, Sqlite3StepDart>('sqlite3_step');

  void _throwLatestError(IDatabaseOperation operation) {
    final errMsg = _sqlite3ErrMsg(db).cast<Utf8>().toDartString();
    throw IDatabaseException(
      'database ${operation.name} operation failed: $errMsg',
    );
  }

  T sqlite3Step<T>({
    required T Function(IDatabaseSuccessCode statusCode) onStep,
    required Pointer<Void> s,
    required IDatabaseOperation operation,
  }) {
    IDatabaseSuccessCode? statusCode;
    try {
      statusCode = IDatabaseSuccessCode.fromCode(_sqlite3Step(s));
      if (statusCode == null || !statusCode.isStepOk) {
        _throwLatestError(operation);
      }
      return onStep(statusCode!);
    } finally {
      if (operation != IDatabaseOperation.readAll ||
          (operation == IDatabaseOperation.readAll &&
              statusCode != IDatabaseSuccessCode.row)) {
        _sqlite3Finalize(s);
      }
    }
  }

  Pointer<Void> _transient() => Pointer.fromAddress(-1);

  void bindTextTransient({
    required Pointer<Void> stmt,
    required int index,
    required String value,
  }) {
    final valueUtf8 = value.toNativeUtf8();
    try {
      final rc = _sqlite3BindText(
        stmt,
        index,
        valueUtf8.ptr,
        valueUtf8.ptr.length,
        _transient(),
      );
      if (rc != IDatabaseSuccessCode.ok.code) {
        _throwLatestError(IDatabaseOperation.bind);
      }
    } finally {
      valueUtf8.free();
    }
  }

  void bindBlobTransient({
    required Pointer<Void> stmt,
    required int index,
    required List<int> value,
  }) {
    final blob = Uint8List.fromList(value);
    final blobPtr = SafePointer(calloc<Uint8>(blob.length));
    try {
      blobPtr.ptr.asTypedList(blob.length).setAll(0, blob);
      final rc = _sqlite3BindBlob(
        stmt,
        index,
        blobPtr.ptr.cast<Void>(),
        blob.length,
        _transient(),
      );
      if (rc != IDatabaseSuccessCode.ok.code) {
        _throwLatestError(IDatabaseOperation.bind);
      }
    } finally {
      blobPtr.free();
    }
  }

  void bindInt64({
    required Pointer<Void> stmt,
    required int index,
    required int value,
  }) {
    final rc = _sqlite3BindInt64(stmt, index, value);
    if (rc != IDatabaseSuccessCode.ok.code) {
      _throwLatestError(IDatabaseOperation.bind);
    }
  }

  T prepareV2<T>({
    required T Function(Pointer<Void> stmt) stmt,
    required String statement,
  }) {
    final sqlUtf8 = statement.toNativeUtf8();
    final stmtPtr = SafePointer(calloc<Pointer<Void>>());
    try {
      final rc = _sqlite3PrepareV2(db, sqlUtf8.ptr, -1, stmtPtr.ptr, nullptr);
      if (rc != IDatabaseSuccessCode.ok.code) {
        _throwLatestError(IDatabaseOperation.bind);
      }
      return stmt(stmtPtr.ptr.value);
    } finally {
      sqlUtf8.free();
      stmtPtr.free();
    }
  }

  Future<IDATABASETABLEREAD<DATA>> _getOrCreateTable<DATA extends ITableData>(
      ITableStructOperation params) async {
    final t = _tables[params.tableName];
    if (t != null) {
      if (t.struct != params.struct) {
        throw IDatabaseException("Invalid table struct.");
      }
      return t as IDATABASETABLEREAD<DATA>;
    }
    final IDtabaseTableIo newTable = switch (params.struct) {
      IDatabaseTableStruct.a => IDatabaseTableIoStructA(params.tableName)
    };
    await newTable.create(this);
    _tables[params.tableName] = newTable;
    return newTable as IDATABASETABLEREAD<DATA>;
  }

  @override
  Future<DATA?> read<DATA extends ITableData>(ITableRead<DATA> params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable<DATA>(params);
      final data = await table.read(this, params);
      return data;
    });
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable<DATA>(params);
      final data = await table.readAll(this, params);
      return data;
    });
  }

  @override
  Future<bool> remove(ITableRemove params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      final data = await table.remove(this, params);
      return data;
    });
  }

  @override
  Future<bool> write(ITableInsertOrUpdate params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      return await table.write(this, params);
    });
  }

  @override
  Future<bool> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return false;
    return await _lock.synchronized(() async {
      for (final i in params) {
        final table = await _getOrCreateTable(i);
        await table.write(this, i);
      }
      return true;
    });
  }

  @override
  Future<bool> removeAll(List<ITableRemove> params) async {
    if (params.isEmpty) return false;
    return await _lock.synchronized(() async {
      for (final i in params) {
        final table = await _getOrCreateTable(i);
        await table.remove(this, i);
      }
      return true;
    });
  }

  @override
  Future<bool> drop(ITableDrop params) async {
    return await _lock.synchronized(() async {
      final table = await _getOrCreateTable(params);
      await table.drop(this);
      _tables.remove(params.tableName);
      return true;
    });
  }
}
