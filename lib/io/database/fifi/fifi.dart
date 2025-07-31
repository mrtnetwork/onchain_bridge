// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/database/database.dart';

typedef PosixCallocNative = Pointer Function(IntPtr num, IntPtr size);
typedef PosixFreeNative = Void Function(Pointer);
typedef WinCoTaskMemAllocNative = Pointer Function(NSize);
typedef WinCoTaskMemAlloc = Pointer Function(int);
typedef PosixMallocNative = Pointer Function(IntPtr);
typedef WinCoTaskMemFreeNative = Void Function(Pointer);
typedef WinCoTaskMemFree = void Function(Pointer);

final class Utf8 extends Opaque {}

@Native<PosixMallocNative>(symbol: 'malloc')
external Pointer posixMalloc(int size);
@Native<PosixCallocNative>(symbol: 'calloc')
external Pointer posixCalloc(int num, int size);
final Pointer<NativeFunction<PosixFreeNative>> posixFreePointer =
    Native.addressOf(posixFree);
const MallocAllocator malloc = MallocAllocator._();
const CallocAllocator calloc = CallocAllocator._();

final DynamicLibrary ole32lib = DynamicLibrary.open('ole32.dll');
final WinCoTaskMemAlloc winCoTaskMemAlloc =
    ole32lib.lookupFunction<WinCoTaskMemAllocNative, WinCoTaskMemAlloc>(
        'CoTaskMemAlloc');
final Pointer<NativeFunction<WinCoTaskMemFreeNative>> winCoTaskMemFreePointer =
    ole32lib.lookup('CoTaskMemFree');
final WinCoTaskMemFree winCoTaskMemFree = winCoTaskMemFreePointer.asFunction();
@Native<Void Function(Pointer)>(symbol: 'free')
external void posixFree(Pointer ptr);

@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.androidRiscv64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.fuchsiaRiscv64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.linuxRiscv32: Uint32(),
  Abi.linuxRiscv64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint64(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint64(),
})
final class NSize extends AbiSpecificInteger {
  const NSize();
}

final class MallocAllocator implements Allocator {
  const MallocAllocator._();
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result;
    if (Platform.isWindows) {
      result = winCoTaskMemAlloc(byteCount).cast();
    } else {
      result = posixMalloc(byteCount).cast();
    }
    if (result.address == 0) {
      throw IDatabaseException('Could not allocate $byteCount bytes.');
    }
    return result;
  }

  @override
  void free(Pointer pointer) {
    if (Platform.isWindows) {
      winCoTaskMemFree(pointer);
    } else {
      posixFree(pointer);
    }
  }

  Pointer<NativeFinalizerFunction> get nativeFree =>
      Platform.isWindows ? winCoTaskMemFreePointer : posixFreePointer;
}

final class CallocAllocator implements Allocator {
  const CallocAllocator._();

  void _fillMemory(Pointer destination, int length, int fill) {
    final ptr = destination.cast<Uint8>();
    for (var i = 0; i < length; i++) {
      ptr[i] = fill;
    }
  }

  void _zeroMemory(Pointer destination, int length) =>
      _fillMemory(destination, length, 0);

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result;
    if (Platform.isWindows) {
      result = winCoTaskMemAlloc(byteCount).cast();
    } else {
      result = posixCalloc(byteCount, 1).cast();
    }
    if (result.address == 0) {
      throw IDatabaseException('Could not allocate $byteCount bytes.');
    }
    if (Platform.isWindows) {
      _zeroMemory(result, byteCount);
    }
    return result;
  }

  @override
  void free(Pointer pointer) {
    if (Platform.isWindows) {
      winCoTaskMemFree(pointer);
    } else {
      posixFree(pointer);
    }
  }

  Pointer<NativeFinalizerFunction> get nativeFree =>
      Platform.isWindows ? winCoTaskMemFreePointer : posixFreePointer;
}

extension StringUtf8Pointer on String {
  SafePointer<Pointer<Utf8>> toNativeUtf8({Allocator allocator = malloc}) {
    final units = StringUtils.encode(this);
    final result = allocator<Uint8>(units.length + 1);
    final nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return SafePointer<Pointer<Utf8>>(result.cast());
  }
}

extension Utf8Pointer on Pointer<Utf8> {
  int get length {
    _ensureNotNullptr('length');
    final codeUnits = cast<Uint8>();
    return _length(codeUnits);
  }

  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    final codeUnits = cast<Uint8>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
    } else {
      length = _length(codeUnits);
    }
    return StringUtils.decode(codeUnits.asTypedList(length));
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw IDatabaseException(
        "Operation '$operation' not allowed on a 'nullptr'.",
      );
    }
  }
}

class SafePointer<T extends Pointer> {
  final T _ptr;
  T get ptr {
    assert(!_isFree);
    return _ptr;
  }

  bool _isFree = false;
  SafePointer(this._ptr);
  void free() {
    assert(!_isFree);
    if (_isFree) return;
    _isFree = true;
    calloc.free(_ptr);
  }
}
