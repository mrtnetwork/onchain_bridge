import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/net_sdk/dart/http/core/http.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/net_sdk/types/request.dart';
import 'package:on_chain_bridge/net_sdk/types/response.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/web/api/window/fetch.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';

Future<Result<PlatformHttp, NetResultStatus>> httpClient(
        NetAddressInfo addr) async =>
    Ok(PlatformHttpWeb(addr));

class PlatformHttpWeb implements PlatformHttp {
  @override
  final NetAddressInfo addr;
  int _streamId = 0;

  PlatformHttpWeb(this.addr);

  Future<Response> _fetchOnce({
    required Uri url,
    required HttpMethod method,
    List<int>? body,
    Map<String, String>? headers,
  }) {
    return JSFetchApi.fetchOnce(
        url: url, method: method, body: body, headers: headers);
  }

  /// Retries a fetch call according to [config], mirroring the previous
  /// RetryClient behaviour (retry on configured status codes or on a
  /// network-level failure).
  Future<Response> _fetchWithRetry({
    required Uri url,
    required HttpMethod method,
    List<int>? body,
    Map<String, String>? headers,
    NetHttpRetryConfig? config,
  }) async {
    if (config == null) {
      return _fetchOnce(url: url, method: method, body: body, headers: headers);
    }

    int attempt = 0;
    while (true) {
      try {
        final response = await _fetchOnce(
            url: url, method: method, body: body, headers: headers);
        if (attempt >= config.maxRetry ||
            !config.retryStatus.contains(response.status)) {
          return response;
        }
      } catch (_) {
        if (attempt >= config.maxRetry) rethrow;
      }
      attempt++;
      await Future.delayed(config.retryDelay);
    }
  }

  List<NetHttpHeader> _headersToList(Headers headers) {
    final result = <NetHttpHeader>[];
    headers.forEach(
      (String value, String key, Headers parent) {
        result.add(NetHttpHeader(key: key, value: value));
      }.toJS,
    );
    return result;
  }

  @override
  Future<Result<NetResponseHttp, NetResultStatus>> send(
      {required Uri url,
      required HttpMethod method,
      List<int>? body,
      Map<String, String>? headers,
      NetHttpRetryConfig? retryConfig}) async {
    try {
      if (method == HttpMethod.closeConnection) {
        return Err(NetResultStatus.invalidRequestParameters);
      }

      final response = await _fetchWithRetry(
        url: url,
        method: method,
        body: body,
        headers: headers,
        config: retryConfig,
      );

      final bytes = await response.arrayBuffer_();

      return Ok(NetResponseHttp(
        statusCode: response.status,
        body: bytes.asUint8List(),
        headers: _headersToList(response.headers),
      ));
    } catch (_) {
      return Err(NetResultStatus.connectionError);
    }
  }

  @override
  void close() {
    // No persistent connection object to dispose of with fetch();
    // each call opens/closes its own request.
  }

  @override
  Future<Result<(NetResponseHttp, Stream<List<int>>?), NetResultStatus>>
      sendStream(
          {required Uri url,
          required HttpMethod method,
          List<int>? body,
          Map<String, String>? headers,
          NetHttpRetryConfig? retryConfig}) async {
    try {
      final response = await _fetchWithRetry(
        url: url,
        method: method,
        body: body,
        headers: headers,
        config: retryConfig,
      );

      final bool isSuccess = response.status >= 200 && response.status < 300;
      final int id = _streamId++;

      if (!isSuccess) {
        final bytes = await response.arrayBuffer_();
        final result = NetResponseHttp(
          streamId: id,
          statusCode: response.status,
          body: bytes.asUint8List(),
          headers: _headersToList(response.headers),
        );
        return Ok((result, null));
      }

      final result = NetResponseHttp(
        streamId: id,
        statusCode: response.status,
        body: const [],
        headers: _headersToList(response.headers),
      );

      final bodyStream = response.body;
      if (bodyStream == null) {
        return Ok((result, const Stream<List<int>>.empty()));
      }

      return Ok((result, _readBody(bodyStream)));
    } catch (_) {
      return Err(NetResultStatus.connectionError);
    }
  }

  Stream<List<int>> _readBody(ReadableStream stream) async* {
    final reader = stream.getReader();
    try {
      while (true) {
        final chunk = await reader.read().toDart;
        if (chunk.done) break;
        final value = chunk.value;
        if (value != null) {
          yield value.toDart;
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}

// class PlatformHttpWeb implements PlatformHttp {
//   final Client client;
//   @override
//   final NetAddressInfo addr;
//   int _streamId = 0;
//   PlatformHttpWeb._(this.client, this.addr);
//   factory PlatformHttpWeb(NetAddressInfo addr) {
//     return PlatformHttpWeb._(RetryClient(Client()), addr);
//   }
//   Client _client(NetHttpRetryConfig? config) {
//     if (config == null) {
//       return client;
//     }
//     return RetryClient(
//       client,
//       delay: (_) => config.retryDelay,
//       retries: config.maxRetry,
//       when: (response) => config.retryStatus.contains(response.statusCode),
//       whenError: (err, p1) => err is ClientException,
//     );
//   }

//   @override
//   Future<Result<NetResponseHttp, NetResultStatus>> send(
//       {required Uri url,
//       required HttpMethod method,
//       List<int>? body,
//       Map<String, String>? headers,
//       NetHttpRetryConfig? retryConfig}) async {
//     try {
//       if (method == HttpMethod.closeConnection) {
//         return Err(NetResultStatus.invalidRequestParameters);
//       }

//       final client = _client(retryConfig);
//       final response = await switch (method) {
//         HttpMethod.post => client.post(url, body: body, headers: headers),
//         HttpMethod.get => client.get(url, headers: headers),
//         HttpMethod.delete => client.delete(url, body: body, headers: headers),
//         HttpMethod.update => client.put(url, body: body, headers: headers),
//         HttpMethod.closeConnection =>
//           throw NetSdkException(NetResultStatus.invalidRequestParameters),
//       };
//       return Ok(NetResponseHttp(
//           statusCode: response.statusCode,
//           body: response.bodyBytes,
//           headers: response.headers.entries
//               .map((e) => NetHttpHeader(key: e.key, value: e.value))
//               .toList()));
//     } on ClientException {
//       return Err(NetResultStatus.connectionError);
//     }
//   }

//   @override
//   void close() {
//     client.close();
//   }

//   @override
//   Future<Result<(NetResponseHttp, Stream<List<int>>?), NetResultStatus>> sendStream(
//       {required Uri url,
//       required HttpMethod method,
//       List<int>? body,
//       Map<String, String>? headers,
//       NetHttpRetryConfig? retryConfig}) async {
//     try {
//       final client = _client(retryConfig);
//       final request = Request(method.name.toUpperCase(), url);

//       if (headers != null) {
//         request.headers.addAll(headers);
//       }

//       if (body != null) {
//         request.bodyBytes = body;
//       }

//       final response = await client.send(request);
//       bool isSuccess = response.statusCode >= 200 && response.statusCode < 300;
//       final int id = _streamId++;
//       final result = NetResponseHttp(
//           streamId: id,
//           statusCode: response.statusCode,
//           body: switch (isSuccess) {
//             false => await response.stream.toBytes(),
//             true => [],
//           },
//           headers: response.headers.entries
//               .map((e) => NetHttpHeader(key: e.key, value: e.value))
//               .toList());
//       if (!isSuccess) {
//         return Ok((result, null));
//       }

//       return Ok((result, response.stream));
//     } on ClientException {
//       return Err(NetResultStatus.connectionError);
//     }
//   }
// }
