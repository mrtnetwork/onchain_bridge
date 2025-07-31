import 'dart:ffi';
import 'package:on_chain_bridge/io/database/fifi/fifi.dart';

typedef Sqlite3OpenNative = Int32 Function(
    Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef Sqlite3OpenDart = int Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef Sqlite3ExecNative = Int32 Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Pointer<Utf8>>,
);
typedef Sqlite3ExecDart = int Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Pointer<Utf8>>,
);

typedef IDB = SafePointer<Pointer<Void>>;

typedef Sqlite3PrepareV2Native = Int32 Function(
  Pointer<Void>,
  Pointer<Utf8>,
  Int32,
  Pointer<Pointer<Void>>,
  Pointer<Pointer<Utf8>>,
);
typedef Sqlite3PrepareV2Dart = int Function(
  Pointer<Void>,
  Pointer<Utf8>,
  int,
  Pointer<Pointer<Void>>,
  Pointer<Pointer<Utf8>>,
);

typedef Sqlite3BindTextNative = Int32 Function(
    Pointer<Void>, Int32, Pointer<Utf8>, Int32, Pointer<Void>);
typedef Sqlite3BindTextDart = int Function(
    Pointer<Void>, int, Pointer<Utf8>, int, Pointer<Void>);

typedef Sqlite3BindBlobNative = Int32 Function(
    Pointer<Void>, Int32, Pointer<Void>, Int32, Pointer<Void>);
typedef Sqlite3BindBlobDart = int Function(
    Pointer<Void>, int, Pointer<Void>, int, Pointer<Void>);

typedef Sqlite3StepNative = Int32 Function(Pointer<Void>);
typedef Sqlite3StepDart = int Function(Pointer<Void>);

typedef Sqlite3ColumnBlobNative = Pointer<Void> Function(Pointer<Void>, Int32);
typedef Sqlite3ColumnBytesNative = Int32 Function(Pointer<Void>, Int32);
typedef Sqlite3ColumnBlobDart = Pointer<Void> Function(Pointer<Void>, int);
typedef Sqlite3ColumnBytesDart = int Function(Pointer<Void>, int);

typedef Sqlite3FinalizeNative = Int32 Function(Pointer<Void>);
typedef Sqlite3FinalizeDart = int Function(Pointer<Void>);
typedef Sqlite3ErrMsgNative = Pointer<Utf8> Function(Pointer<Void>);
typedef Sqlite3ErrMsgDart = Pointer<Utf8> Function(Pointer<Void>);

typedef Sqlite3BindNullNative = Int32 Function(Pointer<Void> stmt, Int32 index);

typedef Sqlite3BindNullDart = int Function(Pointer<Void> stmt, int index);

typedef Sqlite3BindInt64Native = Int32 Function(
    Pointer<Void> stmt, Int32 index, Int64 value);

typedef Sqlite3BindInt64Dart = int Function(
    Pointer<Void> stmt, int index, int value);
typedef Sqlite3BindIntNative = Int32 Function(
    Pointer<Void> stmt, Int32 index, Int32 value);

typedef Sqlite3BindIntDart = int Function(
    Pointer<Void> stmt, int index, int value);
typedef Sqlite3ColumnInt64Native = Int64 Function(Pointer<Void>, Int32);
typedef Sqlite3ColumnTextNative = Pointer<Utf8> Function(Pointer<Void>, Int32);

// Dart function typedefs
typedef Sqlite3ColumnInt64Dart = int Function(Pointer<Void>, int);
typedef Sqlite3ColumnTextDart = Pointer<Utf8> Function(Pointer<Void>, int);
typedef Sqlite3CloseNative = Int32 Function(Pointer<Void> db);
typedef Sqlite3CloseDart = int Function(Pointer<Void> db);
