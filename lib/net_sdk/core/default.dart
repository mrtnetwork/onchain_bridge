import 'dart:async';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/dart/transport/grpc.dart';
import 'package:on_chain_bridge/net_sdk/dart/transport/http.dart';
import 'package:on_chain_bridge/net_sdk/dart/transport/socket.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'core.dart';

/// Only sypported on web environment
class DefaultNetSdk implements INetSdk {
  @override
  final AppEnvironment environment;
  DefaultNetSdk(this.environment);
  int _latestTransportId = 257;
  final Map<int, ITransport> _transport = {};
  final StreamController<NetResponse> _controller =
      StreamController<NetResponse>.broadcast();
  int _requestId = 1;
  final _lock = SafeAtomicLock();
  void _callBack(int id, NetResponseKind response) {
    _controller.add(NetResponse(transportId: id, requestId: 0, kind: response));
  }

  Future<Result<void, NetResultStatus>> closeTransport(int transportId) async {
    final transport = _transport.remove(transportId);
    await transport?.close();
    return Ok(null);
  }

  @override
  Future<Result<Transport, NetResultStatus>> createTransport(
      NetConfigRequest config) async {
    final configRequest = config.toConfig();
    if (configRequest.isErr) {
      return Err(configRequest.unwrapErr());
    }
    int id = _latestTransportId++;
    final c = configRequest.unwrap();
    void callBack(NetResponseKind response) {
      _callBack(id, response);
    }

    final transport = switch (config.protocol) {
      NetProtocol.http =>
        HttpDartTransport.create(config: c, callback: callBack),
      NetProtocol.grpc =>
        GrpcDartTransport.create(config: c, callback: callBack),
      _ => SocketDartTransport.create(config: c, callback: callBack)
    };
    if (transport.isErr) {
      return Err(configRequest.unwrapErr());
    }
    _transport[id] = transport.unwrap();

    return Ok(Transport(
        lib: this,
        config: config,
        stream: _controller.stream
            .where((e) => e.transportId == id)
            .map((e) => e.kind.cast<NetResponseStream>()),
        transportId: id));
  }

  @override
  Future<Result<RESPONSE, NetResultStatus>>
      sendRequest<RESPONSE extends NetResponseKind>(
          int transportId, NetRequestKind<RESPONSE> request, Duration timeout,
          {bool isDynamicRequest = false}) async {
    switch (request) {
      case NetRequestCloseTransport():
        await closeTransport(transportId).timeout(
          timeout,
          onTimeout: () => Err(NetResultStatus.requestTimeout),
        );
        return request.toResponse(NetResponseClose());
      default:
        break;
    }
    final int id = await _lock.run(() {
      return _requestId++;
    });
    final result = NetRequest(
        transportId: transportId, id: id, kind: request, timoutSecs: timeout);
    final transport = _transport[transportId];
    if (transport == null) {
      return Err(NetResultStatus.transportNotFound);
    }
    final response = await transport.doRequest(result).timeout(
          timeout,
          onTimeout: () => Err(NetResultStatus.requestTimeout),
        );
    if (response.isErr) {
      return Err(response.unwrapErr());
    }
    switch (response) {
      case NetResponseError(:final error):
        return Err(error);
      default:
        return request.toResponse(response.unwrap());
    }
  }

  @override
  List<NetMode> get modes => [NetMode.clearnet];

  @override
  Future<Result<void, NetResultStatus>> closeInstance() async {
    _controller.close();
    return Ok(null);
  }

  @override
  NetApiTarget get target => NetApiTarget.dart;
}
