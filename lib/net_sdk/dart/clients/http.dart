import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/dart/core/clients.dart';
import 'package:on_chain_bridge/net_sdk/dart/http/core/http.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';

class HttpClient implements IClient<PlatformHttp>, IHttpClient {
  final NetConfig config;
  PlatformHttp? _client;
  final _lock = SafeAtomicLock();
  HttpClient._(this.config);
  factory HttpClient(NetConfig config) {
    return HttpClient._(config);
  }
  @override
  Future<Result<PlatformHttp, NetResultStatus>> connect(
      {Duration? timeout, NetAddressInfo? url}) async {
    return _lock.run(() async {
      if (url != null && url != config.address) {
        return Err(NetResultStatus.badHttpRequestHost);
      }
      PlatformHttp? client = _client;
      NetAddressInfo? addr;
      if (client == null) {
        final connection = await PlatformHttp.create(addr ?? config.address);
        return connection.map((client) {
          _client = connection.unwrap();
          return client;
        });
      }

      return Ok(client);
    });
  }

  @override
  Future<Result<NetResponseHttp, NetResultStatus>> send(
    String url,
    HttpMethod method, {
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? retryConfig,
  }) async {
    if (method == HttpMethod.closeConnection) {
      final result = await close();
      return result
          .map((_) => NetResponseHttp(statusCode: 200, body: [], headers: []));
    }
    final addr = NetAddressInfo.http(url);
    if (addr == null) {
      return Err(NetResultStatus.invalidUrl);
    }
    final client = await connect(url: addr);
    return client.andThenAsync((client) async {
      return await client.send(
          url: addr.uri,
          method: method,
          body: body,
          headers: headers,
          retryConfig: retryConfig);
    });
  }

  @override
  Future<Result<(NetResponseHttp, Stream<List<int>>?), NetResultStatus>>
      sendStream({
    required String url,
    required HttpMethod method,
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? retryConfig,
  }) async {
    if (method == HttpMethod.closeConnection) {
      final result = await close();
      return result.map((_) =>
          (NetResponseHttp(statusCode: 200, body: [], headers: []), null));
    }
    final addr = NetAddressInfo.http(url);
    if (addr == null) {
      return Err(NetResultStatus.invalidUrl);
    }
    final client = await connect(url: addr);
    return client.andThenAsync((client) async {
      final result = await client.sendStream(
          url: addr.uri,
          method: method,
          body: body,
          headers: headers,
          retryConfig: retryConfig);
      return result;
    });
  }

  @override
  Future<Result<void, NetResultStatus>> close() async {
    await _lock.run(() {
      _client?.close();
      _client = null;
    });
    return Ok(null);
  }
}
