import 'dart:ffi';

typedef NetSdkDartCallbackC = Void Function(Pointer<Uint8>, Size length);
typedef NetSdkDartCallback = void Function(Pointer<Uint8>, int length);
typedef DartTransporterCreateC = Uint32 Function(
    Uint32, Pointer<Uint8>, Size length);
typedef DartTransporterCreate = int Function(int, Pointer<Uint8>, int length);
typedef DartTransportCreateInstanceC = Uint32 Function(
    Pointer<NativeFunction<NetSdkDartCallbackC>>, Pointer<Uint8>, Size length);
typedef DartTransportCreateInstance = int Function(
    Pointer<NativeFunction<NetSdkDartCallbackC>>, Pointer<Uint8>, int length);
typedef DartTransporterSendC = Uint8 Function(
    Uint32, Pointer<Uint8>, Size length);
typedef DartTransporterSend = int Function(int, Pointer<Uint8>, int length);
typedef DartTransporterClose = int Function(int, int);

typedef DartTransporterCloseInstanceC = Uint8 Function(Uint32);
typedef DartTransporterCloseInstance = int Function(int);

typedef DartTransporterFreePointerC = Uint8 Function(
    Pointer<Uint8>, Size length);
typedef DartTransporterFreePointer = int Function(Pointer<Uint8>, int length);
