import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/core/core.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/api/window/fetch.dart';
import 'package:on_chain_bridge/web/net_sdk/module/module.dart';
import 'package:on_chain_bridge/web/net_sdk/helper/extensions.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';

@JS("createNetworkSdk")
external NetSdkWebModuleInterface _creaeteSdk();
Future<Result<INetSdk, NetResultStatus>> createSdk(NetSdkConfig config) async {
  if (config case NetSdkConfigWeb webConfig) {
    final module = (await importModule(webConfig.moduleUrl.toJS).toDart);
    switch (webConfig) {
      case NetSdkConfigWebWasm(:final info):
        final data = await JSFetchApi.fetchJsBuffer(info.wasmUrl).timeout(
          webConfig.timeout,
          onTimeout: () {
            return Err(NetResultStatus.requestTimeout);
          },
        );

        return data
            .mapErr((e) => NetResultStatus.invalidConfigParameters)
            .andThenAsync((bytes) async {
          if (info.target.isDart) {
            final compiledApp = await (module as NetSdkDartCompiledWasm)
                .instantiate(module.compile(bytes))
                .toDart;
            module.invoke(compiledApp);
            return Ok(WebNetSdk(_creaeteSdk(), NetApiTarget.dart));
          }
          (module as NetSdkWebRustCompiledGlue).initSync(bytes);
          final export = NetSdkWebModuleRustWasm(module, config.config);
          return Ok(WebNetSdk(
              createJSInteropWrapper(export) as NetSdkWebModuleInterface,
              NetApiTarget.rust));
        });
      case NetSdkConfigWebJsModule():
        return Ok(WebNetSdk(_creaeteSdk(), NetApiTarget.dart));
    }
  }
  return Err(NetResultStatus.invalidConfigParameters);
}

class WebNetSdk extends INetSdk {
  @override
  final NetApiTarget target;
  late final NetSdkWebModuleInterface _transport;
  final StreamController<NetResponse> _controller =
      StreamController<NetResponse>.broadcast();

  WebNetSdk(this._transport, this.target) {
    _transport.createTransport(_callback.toJS);
  }

  static Future<Result<WebNetSdk, NetResultStatus>> fromRustModule(
      NetSdkWebRustCompiledGlue module, NetCreateInstanceConfig config) async {
    final export = NetSdkWebModuleRustWasm(module, config);
    return Ok(WebNetSdk(
        createJSInteropWrapper(export) as NetSdkWebModuleInterface,
        NetApiTarget.rust));
  }

  static Future<Result<NetSdkWebModuleInterface, NetResultStatus>> dartWasm(
      NetSdkConfigWebWasm wasm) async {
    final module = (await importModule(wasm.info.moduleUrl.toJS).toDart
        as NetSdkDartCompiledWasm);
    final wasmBuffer =
        await JSFetchApi.fetchJsBuffer(wasm.info.wasmUrl).timeout(
      wasm.timeout,
      onTimeout: () {
        return Err(NetResultStatus.requestTimeout);
      },
    );

    if (wasmBuffer.isErr) {
      return Err(NetResultStatus.invalidSdkConfig);
    }
    final compiledApp =
        await module.instantiate(module.compile(wasmBuffer.unwrap())).toDart;
    module.invoke(compiledApp);
    return Ok(_creaeteSdk());
  }

  static Future<Result<NetSdkWebModuleInterface, NetResultStatus>> rustWasm(
      NetSdkConfigWebWasm wasm) async {
    final module = (await importModule(wasm.info.moduleUrl.toJS).toDart
        as NetSdkWebRustCompiledGlue);
    final wasmBytes = await JSFetchApi.fetchJsBuffer(wasm.info.wasmUrl).timeout(
      wasm.timeout,
      onTimeout: () {
        return Err(NetResultStatus.requestTimeout);
      },
    );
    if (!wasmBytes.isOk) {
      return Err(NetResultStatus.invalidSdkConfig);
    }
    module.initSync(wasmBytes.unwrap());
    final export = NetSdkWebModuleRustWasm(module, wasm.config);
    return Ok(createJSInteropWrapper(export) as NetSdkWebModuleInterface);
  }

  void _callback(APPJSUint8Array? payload) {
    assert(payload != null, "Unexpected sdk response.");
    final bytes = payload?.toBytes();
    if (bytes != null) {
      final response = NetResponse.deserialize(bytes: bytes);
      final kind = response.kind;
      switch (kind) {
        case NetResponseClose():
          break;
        case NetResponseStreamData _:
        case NetResponseStreamClose _:
        case NetResponseStreamError _:
          _controller.add(response);
          break;
        default:
          assert(false, "invalid response");
          break;
      }
    }
  }

  @override
  Future<Result<RESPONSE, NetResultStatus>>
      sendRequest<RESPONSE extends NetResponseKind>(int transportId,
          NetRequestKind<RESPONSE> request, Duration timeout) async {
    switch (request) {
      case NetRequestCloseTransport():
        final result = await closeTransport(transportId).timeout(
          Duration(seconds: IntUtils.max(timeout.inSeconds, 1)),
          onTimeout: () {
            return Err(NetResultStatus.requestTimeout);
          },
        );
        return result.andThen((e) => request.toResponse(NetResponseClose()));
      default:
        break;
    }
    final dartRequest = NetRequest(
        transportId: transportId, id: 1, kind: request, timoutSecs: timeout);
    final result = await _transport
        .sendRequest(JsUtils.toAppJsUint8Array(dartRequest.toCbor().encode()))
        .toDart
        .timeout(
          timeout + const Duration(seconds: 1),
          onTimeout: () => ErrJs(NetResultStatus.requestTimeout.toJS),
        );

    final response = result.toDart(
        onResult: (ok) => NetResponse.deserialize(bytes: ok.toBytes()),
        onErr: (err) => NetResultStatus.fromValue(err.toDartInt),
        onInvalid: () => NetResultStatus.unknownResponse);
    if (response.isErr) {
      return Err(response.unwrapErr());
    }
    final dartResponse = response.unwrap();
    switch (dartResponse.kind) {
      case NetResponseError(:final error):
        return Err(error);
      default:
        return request.toResponse(dartResponse.kind);
    }
  }

  Future<
      ({
        NetResultStatus status,
        int transportId,
      })> _createTransport(NetConfigRequest config) async {
    final transport = (await _transport
        .createTransporter(JsUtils.toAppJsUint8Array(config.toCbor().encode()))
        .toDart
        .timeout(config.timeout,
            onTimeout: () => ErrJs(NetResultStatus.requestTimeout.toJS)));
    final result = transport
        .toDart(
          onResult: (ok) => ok.toDartInt,
          onErr: (err) => err.toDartInt,
          onInvalid: () => NetResultStatus.unknownResponse.value,
        )
        .fold(onOk: (value) => value, onErr: (error) => error);

    if (result > 256) {
      return (status: NetResultStatus.ok, transportId: result);
    }
    return (status: NetResultStatus.fromValue(result), transportId: -1);
  }

  @override
  Future<Result<Transport, NetResultStatus>> createTransport(
      NetConfigRequest config) async {
    final transport = await _createTransport(config);
    if (!transport.status.isOk()) {
      return Err(transport.status);
    }
    int transportId = transport.transportId;
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
  }

  Future<Result<NetResultStatus, NetResultStatus>> closeTransport(
      int transportId) async {
    final result = await _transport.closeTransport(transportId.toJS).toDart;
    return result.toDart(
        onResult: (ok) => NetResultStatus.fromValue(ok.toDartInt),
        onErr: (err) => NetResultStatus.fromValue(err.toDartInt),
        onInvalid: () => NetResultStatus.unknownResponse);
  }

  @override
  List<NetMode> get modes => [NetMode.clearnet];

  @override
  Future<Result<void, NetResultStatus>> closeInstance() async {
    await _transport.close().toDart.catchError((e) => null);
    return Ok(null);
  }

  @override
  AppEnvironment get environment => AppEnvironment.web;
}
