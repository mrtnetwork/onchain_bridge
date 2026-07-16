import 'dart:async';
import 'dart:js_interop';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/core/default.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/net_sdk/helper/extensions.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';

@JS()
extension type NetSdkRustCompiledWasm(JSObject _) implements JSObject {
  @JS("initSync")
  external JSObject initSync(JSObject? obj);
}
@JS()
extension type NetSdkWebRustCompiledGlue(JSObject _)
    implements NetSdkRustCompiledWasm {
  @JS("DartTransporter.create")
  external NetSdkWebRustTransport createTransport(
      JSFunction fn, APPJSUint8Array cofnig);
}

abstract class NetSdkWebModule {
  void createTransport(JSFunction fn);
  JSPromise<ResultOrErrorJs<APPJSUint8Array, JSNumber>> sendRequest(
      APPJSUint8Array request);
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> createTransporter(
      APPJSUint8Array config);
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> closeTransport(
      JSNumber transportId);
  JSPromise<JSAny?> close();
}

@JSExport()
class NetSdkWebModuleRustWasm implements NetSdkWebModule {
  final NetSdkWebRustCompiledGlue module;
  final NetCreateInstanceConfig config;

  NetSdkWebRustTransport? _transport;
  NetSdkWebModuleRustWasm(this.module, this.config);
  @override
  @JSExport("init")
  void createTransport(JSFunction fn) {
    _transport = module.createTransport(
        fn, APPJSUint8Array.fromList(config.toCbor().encode()));
  }

  @override
  @JSExport("send_request")
  JSPromise<ResultOrErrorJs<APPJSUint8Array, JSNumber>> sendRequest(
      APPJSUint8Array request) {
    Future<ResultOrErrorJs<APPJSUint8Array, JSNumber>> msg() async {
      final transport = _transport;
      if (transport == null) return ErrJs(NetResultStatus.internalError.toJS);
      return transport.sendRequest(request).toDart;
    }

    return msg().toJS;
  }

  @override
  @JSExport("create_transporter")
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> createTransporter(
      APPJSUint8Array config) {
    Future<ResultOrErrorJs<JSNumber, JSNumber>> msg() async {
      final transport = _transport;
      if (transport == null) return ErrJs(NetResultStatus.internalError.toJS);
      final result = transport.createTransporter(config).toJS;
      return OkJs(result);
    }

    return msg().toJS;
  }

  @override
  @JSExport("close_transport")
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> closeTransport(
      JSNumber transportId) {
    Future<ResultOrErrorJs<JSNumber, JSNumber>> msg() async {
      final transport = _transport;
      if (transport == null) return ErrJs(NetResultStatus.internalError.toJS);
      final result = await transport.closeTransport(transportId).toDart;
      return OkJs(result);
    }

    return msg().toJS;
  }

  @override
  @JSExport("close")
  @override
  JSPromise<JSAny?> close() {
    Future<void> close() async {
      await _transport?.close().toDart;
      _transport = null;
    }

    return close().toJS;
  }
}

@JS()
extension type NetSdkWebModuleInterface(JSObject _) implements JSObject {
  @JS("send_request")
  external JSPromise<ResultOrErrorJs<APPJSUint8Array, JSNumber>> sendRequest(
      APPJSUint8Array request);
  @JS("close_transport")
  external JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> closeTransport(
      JSNumber transportId);
  @JS("create_transporter")
  external JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> createTransporter(
      APPJSUint8Array config);
  @JS("init")
  external void createTransport(JSFunction fn);
  @JS("close")
  external JSPromise<JSAny?> close();
}

@JS()
extension type NetSdkWebRustTransport(JSObject _) implements JSObject {
  @JS("create_transporter")
  external int createTransporter(APPJSUint8Array config);
  @JS("send_request")
  external JSPromise<ResultOrErrorJs<APPJSUint8Array, JSNumber>> sendRequest(
      APPJSUint8Array request);
  @JS("close_transport")
  external JSPromise<JSNumber> closeTransport(JSNumber transportId);
  @JS("close_all_transports")
  external JSPromise<JSNumber> close();
}

@JSExport()
class NetSdkWebModuleDefault implements NetSdkWebModule {
  final DefaultNetSdk sdk;
  NetSdkWebModuleDefault(this.sdk);
  JSFunction? _callback;
  final Map<int, StreamSubscription<NetResponseStream>> _subscribtions = {};

  @override
  @JSExport("init")
  void createTransport(JSFunction fn) {
    _callback = fn;
  }

  @override
  @JSExport("send_request")
  JSPromise<ResultOrErrorJs<APPJSUint8Array, JSNumber>> sendRequest(
      APPJSUint8Array request) {
    Future<ResultOrErrorJs<APPJSUint8Array, JSNumber>> msg() async {
      final bytes = request.toBytes();
      final netRequest = NetRequest.deserialize(bytes: bytes);
      final result = await sdk.sendRequest(
          netRequest.transportId, netRequest.kind, netRequest.timoutSecs);
      if (result.isOk) {
        return OkJs(JsUtils.toAppJsUint8Array(bytes));
      }
      return ErrJs(result.unwrapErr().toJS);
    }

    return msg().toJS;
  }

  @override
  @JSExport("create_transporter")
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> createTransporter(
      APPJSUint8Array payload) {
    Future<ResultOrErrorJs<JSNumber, JSNumber>> msg() async {
      final bytes = payload.toBytes();
      final config = NetConfigRequest.deserialize(bytes: bytes);
      final transport = await sdk.createTransport(config);
      return transport.toJS<JSNumber, JSNumber>(
          onResult: (e) {
            final sub = e.stream.listen((event) {
              final response = NetResponse(
                  transportId: e.transportId, requestId: 0, kind: event);
              final toBytes =
                  JsUtils.toAppJsUint8Array(response.toCbor().encode());
              _callback?.callAsFunction(null, toBytes);
            });
            _subscribtions[e.transportId] = sub;
            return e.transportId.toJS;
          },
          onErr: (e) => e.value.toJS);
    }

    return msg().toJS;
  }

  @override
  @JSExport("close_transport")
  JSPromise<ResultOrErrorJs<JSNumber, JSNumber>> closeTransport(
      JSNumber transportId) {
    Future<ResultOrErrorJs<JSNumber, JSNumber>> msg() async {
      final result = await sdk.sendRequest(
          transportId.toDartInt, NetRequestCloseTransport(), Duration.zero);
      if (result.isErr) {
        return ErrJs(result.unwrapErr().value.toJS);
      }
      return OkJs(NetResultStatus.ok.value.toJS);
    }

    final sub = _subscribtions.remove(transportId.toDartInt);
    sub?.cancel();
    return msg().toJS;
  }

  @override
  @JSExport("close")
  @override
  JSPromise<JSAny?> close() {
    return sdk.closeInstance().toJS;
  }
}
