import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/clients/http.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/dart/types/types.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class HttpDartTransport implements ITransport, IHttpTransport {
  @override
  final NetConfig config;
  final HttpClient client;
  final DARTTRANSPORTCALLBACK callback;
  int _streamId = 0;
  HttpDartTransport._(
      {required this.config, required this.client, required this.callback});
  static Result<HttpDartTransport, NetResultStatus> create(
      {required NetConfig config, required DARTTRANSPORTCALLBACK callback}) {
    return Ok(HttpDartTransport._(
        config: config, client: HttpClient(config), callback: callback));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> doRequest(
      NetRequest data) async {
    final request = data.toHttpRequest();
    return request.andThenAsync((request) {
      if (config.http.streaming) {
        return sendStream(request);
      }
      return send(request);
    });
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> send(NetRequestHttp data) {
    return client.send(data.url, data.method,
        body: data.body,
        retryConfig: data.retryConfig,
        headers: Map<String, String>.fromEntries(
            data.headers.map((e) => MapEntry(e.key, e.value))));
  }

  @override
  Future<Result<NetResponseKind, NetResultStatus>> sendStream(
      NetRequestHttp data) async {
    final result = await client.sendStream(
        url: data.url,
        method: data.method,
        retryConfig: data.retryConfig,
        body: data.body,
        headers: Map<String, String>.fromEntries(
            data.headers.map((e) => MapEntry(e.key, e.value))));
    return result.andThenAsync((e) async {
      if (!e.$1.isSuccess) return Ok(e.$1);
      final stream = e.$2;
      if (stream == null) return Err(NetResultStatus.internalError);
      final id = _streamId++;
      stream.listen(
        (event) {
          callback(NetResponseStreamData(data: event, id: id));
        },
        cancelOnError: true,
        onDone: () {
          callback(NetResponseStreamClose(id: id));
        },
        onError: (_) {
          callback(NetResponseStreamError.error(
              id: id, error: NetResultStatus.internalError));
        },
      );
      return Ok(e.$1.copyWith(streamId: id));
    });
  }

  @override
  Future<void> close() async {
    await client.close();
  }
}
