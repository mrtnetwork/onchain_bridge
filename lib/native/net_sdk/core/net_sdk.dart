import 'dart:async' show Completer, StreamController;
import 'dart:ffi';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart'
    show LockId, SafeAtomicLock;
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/native/database/fifi/fifi.dart';
import 'package:on_chain_bridge/native/net_sdk/constants/constants.dart';
import 'package:on_chain_bridge/native/net_sdk/types/ffi.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

Future<Result<INetSdk, NetResultStatus>> createSdk(NetSdkConfig config) async {
  if (config case NetSdkConfigNative nativeConf) {
    return NativeNetSdk.init(nativeConf);
  }
  return Err(NetResultStatus.invalidConfigParameters);
}

class NativeNetSdk extends INetSdk {
  final Map<int, Completer<NetResponseKind>> _requests = {};
  final List<int> _torTranspors = [];
  int _instanceId = -1;
  NativeCallable<NetSdkDartCallbackC>? _nativeCallable;
  int _requestId = 1;
  bool _torInited = false;
  final _lock = SafeAtomicLock();
  final DartTransporterCreate dartTransporterCreate;
  final DartTransportCreateInstance dartTransporterCreateInstance;
  final DartTransporterSend dartTransporterSend;
  final DartTransporterFreePointer dartTransporterFreeBytes;
  final DartTransporterCloseInstance dartTransporterCloseInstance;
  final StreamController<NetResponse> _controller =
      StreamController<NetResponse>.broadcast();
  bool _closed = false;

  NativeNetSdk.__(DynamicLibrary lib)
      : dartTransporterCreate =
            lib.lookupFunction<DartTransporterCreateC, DartTransporterCreate>(
                NetSdkRustIoConst.dartTransporterCreate),
        dartTransporterCreateInstance = lib.lookupFunction<
                DartTransportCreateInstanceC, DartTransportCreateInstance>(
            NetSdkRustIoConst.dartTransporterCreateInstance),
        dartTransporterSend =
            lib.lookupFunction<DartTransporterSendC, DartTransporterSend>(
                NetSdkRustIoConst.dartTransporterSend),
        dartTransporterFreeBytes = lib.lookupFunction<
                DartTransporterFreePointerC, DartTransporterFreePointer>(
            NetSdkRustIoConst.dartTransporterFreeBytes),
        dartTransporterCloseInstance = lib.lookupFunction<
                DartTransporterCloseInstanceC, DartTransporterCloseInstance>(
            NetSdkRustIoConst.dartTransporterCloseInstance);
  static Result<NativeNetSdk, NetResultStatus> init(NetSdkConfigNative config) {
    final lib = NativeNetSdk.__(DynamicLibrary.open(config.libUri));
    final nativeCallable =
        NativeCallable<NetSdkDartCallbackC>.listener(lib._callback);
    lib._nativeCallable = nativeCallable;
    final instanceConfig = config.config.toCbor().encode();
    final configPointer = instanceConfig.toNativePointer();
    try {
      final instanceId = lib.dartTransporterCreateInstance(
          nativeCallable.nativeFunction, configPointer, instanceConfig.length);
      final status = NetResultStatus.fromValueOrNull(instanceId);
      Logging.logData(
        mode: status == null ? LoggerMode.debug : LoggerMode.danger,
        fn: () => LogDataDefault(
            prefix: "netsdk",
            runtime: "NativeNetSdk",
            function: "init",
            message: status == null
                ? "New instance created $instanceId."
                : "Failed to create netsdk instance $instanceId/${config.config.instanceId}."),
      );

      if (status != null) {
        return Err(status);
      }
      lib._instanceId = instanceId;
      return Ok(lib);
    } finally {
      calloc.free(configPointer);
    }
  }

  NetResultStatus? _send(Pointer<Uint8> request, int length) {
    final result = dartTransporterSend(_instanceId, request, length);
    return NetResultStatus.fromValueOrNull(result);
  }

  int totalResponse = 0;
  void _callback(Pointer<Uint8> pResponse, int length) {
    assert(!pResponse.isNull() && length > 0);
    if (pResponse.isNull() || length == 0) return;
    try {
      final bytes = pResponse.asTypedList(length).clone();
      final response = NetResponse.deserialize(bytes: bytes);

      final request = _requests.remove(response.requestId);
      if (request != null) {
        request.complete(response.kind);
        return;
      }
      final kind = response.kind;
      switch (kind) {
        case NetResponseStreamData _:
        case NetResponseStreamClose _:
        case NetResponseStreamError _:
          _controller.add(response);

          break;
        default:
          break;
      }
    } finally {
      dartTransporterFreeBytes(pResponse, length);
    }
  }

  Future<Result<bool, NetResultStatus>> initTor(Duration timeout) async {
    if (_torInited) return Ok(true);
    return _lock.run(() async {
      final request = NetRequestInitTor();
      final respone =
          await sendRequest<NetResponseTorInited>(0, request, timeout);
      _torInited = respone.isOk;
      return respone.map((e) {
        if (e.inited) _torTranspors.clear();
        return e.inited;
      });
    }, lockId: LockId.two);
  }

  @override
  Future<Result<RESPONSE, NetResultStatus>>
      sendRequest<RESPONSE extends NetResponseKind>(
    int transportId,
    NetRequestKind<RESPONSE> request,
    Duration timeout,
  ) async {
    if (!_torInited &&
        request.type != NetRequestType.torInited &&
        _torTranspors.contains(transportId)) {
      final result = await initTor(timeout).timeout(
        timeout + const Duration(seconds: 1),
        onTimeout: () => Err(NetResultStatus.requestTimeout),
      );
      if (!result.isOk) {
        return Err(result.unwrapErr());
      }
    }
    var (NetResultStatus status, int id, Pointer<Uint8> pointer, int length) =
        await _lock.run(() {
      if (_closed) return (NetResultStatus.closed, 0, nullptr, 0);
      final id = _requestId++;
      final result = NetRequest(
          transportId: transportId, id: id, kind: request, timoutSecs: timeout);
      final toBytes = result.toCbor().encode();
      final pointer = toBytes.toNativePointer();
      final status = _send(pointer, toBytes.length);
      return (
        status ?? NetResultStatus.unknownResponse,
        id,
        pointer,
        toBytes.length
      );
    });
    Logging.error(
        fn: () => LogDataDefault(
              runtime: runtimeType,
              function: "sendRequest",
              message: "Request Status. transport: $transportId"
                  " status: $status"
                  " type: ${request.runtimeType}",
            ),
        when: () =>
            !status.isOk() && status != NetResultStatus.transportNotFound);

    if (!status.isOk()) {
      return Err(status);
    }
    try {
      final completer = Completer<NetResponseKind>();
      _requests[id] = completer;
      final response = await completer.future.timeout(
        timeout + const Duration(seconds: 1),
        onTimeout: () {
          Logging.error(
            fn: () => LogDataDefault(
                runtime: runtimeType,
                function: "sendRequest",
                message: "request timeout: ${request.runtimeType}"),
          );
          return NetResponseError(NetResultStatus.requestTimeout);
        },
      );
      switch (response) {
        case NetResponseError(:final error):
          return Err(error);
        default:
          final result = request.toResponse(response);
          return result;
      }
    } finally {
      if (!pointer.isNull()) {
        calloc.free(pointer);
        pointer = nullptr;
      }
    }
  }

  ({
    NetResultStatus status,
    int transportId,
  }) _createTransport(NetConfigRequest config) {
    final toBytes = config.toCbor().encode();
    final pointer = toBytes.toNativePointer();
    try {
      final result =
          dartTransporterCreate(_instanceId, pointer, toBytes.length);
      if (result > 256) {
        return (status: NetResultStatus.ok, transportId: result);
      }
      Logging.debug(
        fn: () => LogDataDefault(
            prefix: "netsdk",
            runtime: "NativeNetSdk",
            function: "_createTransport",
            message:
                "New transport created  instance: $_instanceId, protocol: ${config.protocol.name}, mode: ${config.mode.name}, id: $result"),
      );
      return (
        status: NetResultStatus.fromValueOrNull(result) ??
            NetResultStatus.unknownResponse,
        transportId: -1
      );
    } finally {
      calloc.free(pointer);
    }
  }

  @override
  Future<Result<Transport, NetResultStatus>> createTransport(
      NetConfigRequest config) async {
    return _lock.run(() {
      if (_closed) {
        return Err(NetResultStatus.closed);
      }
      final transport = _createTransport(config);

      if (!transport.status.isOk()) {
        Logging.danger(
          fn: () => LogDataDefault(
              prefix: "netsdk",
              runtime: "NativeNetSdk",
              function: "createTransport",
              message: "Create transport failed: ${transport.status}"),
        );
        return Err(transport.status);
      }
      int transportId = transport.transportId;
      if (!_torInited && config.mode.isTor) {
        _torTranspors.add(transportId);
      }
      final newTransport = Transport(
          lib: this,
          config: config,
          stream: _controller.stream.where((e) {
            return e.transportId == transportId;
          }).map((e) {
            return e.kind.cast<NetResponseStream>();
          }),
          transportId: transportId);
      return Ok(newTransport);
    });
  }

  @override
  List<NetMode> get modes => [NetMode.tor, NetMode.clearnet];

  @override
  Future<Result<void, NetResultStatus>> closeInstance() async {
    await _lock.run(() {
      final int instanceId = _instanceId;
      _closed = true;
      _instanceId = -1;
      final result = dartTransporterCloseInstance(instanceId);
      _nativeCallable?.close();
      _nativeCallable = null;

      final status = NetResultStatus.fromValueOrNull(result) ??
          NetResultStatus.unknownResponse;
      final requests = _requests.clone();
      for (final i in requests.values) {
        if (i.isCompleted) continue;
        i.complete(NetResponseError(NetResultStatus.connectionClosed));
      }
      _controller.close();
      Logging.logData(
        mode: status.isOk() ? LoggerMode.debug : LoggerMode.error,
        fn: () => LogDataDefault(
            runtime: runtimeType,
            function: "closeInstance",
            message: "instancee $instanceId closed statuc: $status."),
      );
    });
    return Ok(null);
  }

  @override
  NetApiTarget get target => NetApiTarget.rust;

  @override
  AppEnvironment get environment => AppEnvironment.native;
}
