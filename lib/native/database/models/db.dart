import 'dart:ffi';
import 'dart:typed_data';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/database/database.dart';
import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
import 'package:on_chain_bridge/native/database/models/table.dart';
import 'package:on_chain_bridge/native/database/types/types.dart';

class IDatabaseIo extends IDatabase {
  final SafeAtomicLock _lock = SafeAtomicLock();
  final Map<String, IDtabaseTableIo> _tables = {};
  IDatabaseIo(
      {required this.dbName, required this.dbPointer, required this.lib})
      : exec = lib
            .lookupFunction<Sqlite3ExecNative, Sqlite3ExecDart>('sqlite3_exec'),
        _sqlite3Close =
            lib.lookupFunction<Sqlite3CloseNative, Sqlite3CloseDart>(
                'sqlite3_close'),
        _sqlite3PrepareV2 =
            lib.lookupFunction<Sqlite3PrepareV2Native, Sqlite3PrepareV2Dart>(
                'sqlite3_prepare_v2'),
        _sqlite3BindText =
            lib.lookupFunction<Sqlite3BindTextNative, Sqlite3BindTextDart>(
                'sqlite3_bind_text'),
        _sqlite3BindInt64 =
            lib.lookupFunction<Sqlite3BindInt64Native, Sqlite3BindInt64Dart>(
                'sqlite3_bind_int64'),
        _sqlite3BindBlob =
            lib.lookupFunction<Sqlite3BindBlobNative, Sqlite3BindBlobDart>(
                'sqlite3_bind_blob'),
        sqlite3ColumnBlob =
            lib.lookupFunction<Sqlite3ColumnBlobNative, Sqlite3ColumnBlobDart>(
                'sqlite3_column_blob'),
        sqlite3ColumnType =
            lib.lookupFunction<Sqlite3ColumnTypeNative, Sqlite3ColumnTypeDart>(
                'sqlite3_column_type'),
        sqlite3ColumnBytes = lib.lookupFunction<Sqlite3ColumnBytesNative,
            Sqlite3ColumnBytesDart>('sqlite3_column_bytes'),
        _sqlite3Finalize =
            lib.lookupFunction<Sqlite3FinalizeNative, Sqlite3FinalizeDart>(
                'sqlite3_finalize'),
        _sqlite3ErrMsg =
            lib.lookupFunction<Sqlite3ErrMsgNative, Sqlite3ErrMsgDart>(
                'sqlite3_errmsg'),
        sqlite3ColumnInt64 = lib.lookupFunction<Sqlite3ColumnInt64Native,
            Sqlite3ColumnInt64Dart>('sqlite3_column_int64'),
        sqlite3ColumnText =
            lib.lookupFunction<Sqlite3ColumnTextNative, Sqlite3ColumnTextDart>(
                'sqlite3_column_text'),
        _sqlite3Step = lib
            .lookupFunction<Sqlite3StepNative, Sqlite3StepDart>('sqlite3_step'),
        _sqlite3BindNull =
            lib.lookupFunction<Sqlite3BindNullNative, Sqlite3BindNullDart>(
                'sqlite3_bind_null');
  final DynamicLibrary lib;
  @override
  final String dbName;
  final SafePointer<Pointer<Pointer<Void>>> dbPointer;
  Pointer<Void> get db => dbPointer.ptr.value;
  final Sqlite3ExecDart exec;
  final Sqlite3CloseDart _sqlite3Close;
  final Sqlite3PrepareV2Dart _sqlite3PrepareV2;
  final Sqlite3BindTextDart _sqlite3BindText;
  final Sqlite3BindInt64Dart _sqlite3BindInt64;
  final Sqlite3BindBlobDart _sqlite3BindBlob;
  final Sqlite3ColumnBlobDart sqlite3ColumnBlob;
  final Sqlite3ColumnTypeDart sqlite3ColumnType;
  final Sqlite3ColumnBytesDart sqlite3ColumnBytes;
  final Sqlite3FinalizeDart _sqlite3Finalize;
  final Sqlite3ErrMsgDart _sqlite3ErrMsg;
  final Sqlite3ColumnInt64Dart sqlite3ColumnInt64;
  final Sqlite3ColumnTextDart sqlite3ColumnText;
  final Sqlite3StepDart _sqlite3Step;
  final Sqlite3BindNullDart _sqlite3BindNull;
  // final Sqlite3BindNullNative _sqlite3BindNative;
  void closeDb() {
    final result = _sqlite3Close(db);
    if (result != IDatabaseSuccessCode.ok.code) {
      _throwLatestError(IDatabaseOperation.close);
    }
  }

  void _throwLatestError(IDatabaseOperation operation) {
    final errMsg = _sqlite3ErrMsg(db).cast<Utf8>().toDartString();
    throw IDatabaseException.unexpected(
        'database ${operation.name} operation failed: $errMsg');
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

  void bindNull({
    required Pointer<Void> stmt,
    required int index,
  }) {
    final rc = _sqlite3BindNull(stmt, index);
    if (rc != IDatabaseSuccessCode.ok.code) {
      _throwLatestError(IDatabaseOperation.bind);
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
        throw IDatabaseException.unexpected("Invalid table struct.");
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
    return await _lock.run(() async {
      final table = await _getOrCreateTable<DATA>(params);
      final data = await table.read(this, params);
      return data;
    });
  }

  @override
  Future<List<DATA>> readAll<DATA extends ITableData>(
      ITableRead<DATA> params) async {
    return await _lock.run(() async {
      final table = await _getOrCreateTable<DATA>(params);
      final data = await table.readAll(this, params);
      return data;
    });
  }

  @override
  Future<void> remove(ITableRemove params) async {
    return await _lock.run(() async {
      final table = await _getOrCreateTable(params);
      await table.remove(this, params);
    });
  }

  @override
  Future<void> write(ITableInsertOrUpdate params) async {
    return await _lock.run(() async {
      final table = await _getOrCreateTable(params);
      return await table.write(this, params);
    });
  }

  @override
  Future<void> writeAll(List<ITableInsertOrUpdate> params) async {
    if (params.isEmpty) return;
    return await _lock.run(() async {
      for (final i in params) {
        final table = await _getOrCreateTable(i);
        await table.write(this, i);
      }
    });
  }

  @override
  Future<void> removeAll(List<ITableRemove> params) async {
    if (params.isEmpty) return;
    return await _lock.run(() async {
      for (final i in params) {
        final table = await _getOrCreateTable(i);
        await table.remove(this, i);
      }
      return;
    });
  }

  @override
  Future<void> clearNullableColumn(ITableRemove params) async {
    return await _lock.run(() async {
      final table = await _getOrCreateTable(params);
      await table.clearNullableColumn(this, params);
    });
  }

  @override
  Future<void> drop(ITableDrop params) async {
    return await _lock.run(() async {
      final table = await _getOrCreateTable(params);
      await table.drop(this);
      _tables.remove(params.tableName);
    });
  }
}
