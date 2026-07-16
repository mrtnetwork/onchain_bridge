import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/transport/authenticated/digest_authenticated.dart';
import 'package:on_chain_bridge/net_sdk/transport/core/transport.dart';
import 'package:on_chain_bridge/net_sdk/types/stream.dart';
import 'package:on_chain_bridge/platform_interface.dart';

abstract class HttpTransport implements ProtocolTransport {
  Future<Result<NetResponseHttp, NetSdkException>> get({
    required String url,
    required Duration timeout,
    Map<String, String> headers = const {},
    NetHttpRetryConfig? retryConfig,
  });
  Future<Result<NetResponseHttp, NetSdkException>> post({
    required String url,
    required Duration timeout,
    List<int>? body,
    Map<String, String> headers = const {},
    NetHttpRetryConfig? retryConfig,
  });

  Result<Stream<NetResponseHttp>, NetSdkException> stream({
    required String url,
    required Duration timeout,
    required HttpMethod method,
    List<int>? body,
    Map<String, String> headers = const {},
    NetHttpRetryConfig? retryConfig,
  });

  Future<Result<void, NetSdkException>> closeConnection(Duration timeout);
}

class DefaultHttpTransport implements HttpTransport {
  final HttpAuthenticated? _authenticated;
  final Transport _transport;
  DefaultHttpTransport(
      {required Transport transport, HttpAuthenticated? authenticated})
      : _authenticated = authenticated,
        _transport = transport;

  @override
  Future<Result<NetResponseHttp, NetSdkException>> get({
    required String url,
    required Duration timeout,
    Map<String, String> headers = const {},
    NetHttpRetryConfig? retryConfig,
  }) async {
    return await _send(
        url: url,
        method: HttpMethod.get,
        timeout: timeout,
        headers: headers,
        retryConfig: retryConfig);
  }

  @override
  Future<Result<NetResponseHttp, NetSdkException>> post({
    required String url,
    required Duration timeout,
    List<int>? body,
    Map<String, String> headers = const {},
    NetHttpRetryConfig? retryConfig,
  }) async {
    return await _send(
        url: url,
        method: HttpMethod.post,
        timeout: timeout,
        body: body,
        retryConfig: retryConfig,
        headers: headers);
  }

  Map<String, String> toHeaders(
      {required Uri uri,
      required HttpMethod method,
      Map<String, String> headers = const {}}) {
    return _authenticated?.toHeaders(headers) ?? headers;
  }

  Result<Uri, NetSdkException> toUri(String url) {
    final auth = _authenticated;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return Err(NetSdkException(NetResultStatus.invalidUrl));
    }
    return Ok(auth?.toUri(uri) ?? uri);
  }

  Future<Result<NetResponseHttp, NetSdkException>> _send(
      {required String url,
      required HttpMethod method,
      required Duration timeout,
      NetHttpRetryConfig? retryConfig,
      List<int>? body,
      Map<String, String> headers = const {}}) async {
    final uri = toUri(url);
    return uri.andThenAsync((uri) async {
      if (_transport.config.http.streaming) {
        return await _streamOnce(
            url: uri,
            method: method,
            timeout: timeout,
            body: body,
            headers: headers,
            retryConfig: retryConfig);
      }
      headers = toHeaders(headers: headers, method: method, uri: uri);
      final result = await _transport.sendRequest<NetResponseHttp>(
          NetRequestHttp(
              method: method,
              url: uri.toString(),
              body: body,
              retryConfig: retryConfig,
              headers: headers.entries
                  .map((e) => NetHttpHeader(key: e.key, value: e.value))
                  .toList()),
          timeout);
      return result.mapErr((e) => NetSdkException(e));
    });
  }

  @override
  Future<Result<NetResponseClose, NetSdkException>> close(
      {Duration? timeout}) async {
    final result = await _transport.closeTransport(timeout: timeout);
    return result.mapErr((e) => NetSdkException(e));
  }

  Future<
      Result<(Stream<List<int>>, NetResponseHttp),
          Result<NetResponseHttp, NetResultStatus>>> _stream(
      {required Uri url,
      required Duration timeout,
      required HttpMethod method,
      List<int>? body,
      Map<String, String> headers = const {},
      NetHttpRetryConfig? retryConfig}) async {
    headers = toHeaders(headers: headers, method: method, uri: url);

    if (!_transport.config.http.streaming) {
      return Err(Err(NetResultStatus.invalidRequestParameters));
    }
    int streamId = -1;
    final cachedController = CachedStreamController<NetResponseStream>(
      onCancel: () async {
        if (streamId.isNegative) return;
        _transport.sendRequest<NetResponseHttp>(
            NetRequestHttp(
                method: HttpMethod.closeConnection,
                url: url.toString(),
                body: body,
                retryConfig: retryConfig,
                streamId: streamId,
                headers: []),
            timeout);
      },
    );

    final listener = _transport.stream.listen((e) {
      cachedController.add(e);
    });
    final stream = await _transport.sendRequest<NetResponseHttp>(
        NetRequestHttp(
            method: method,
            url: url.toString(),
            body: body,
            retryConfig: retryConfig,
            headers: headers.entries
                .map((e) => NetHttpHeader(key: e.key, value: e.value))
                .toList()),
        timeout);
    final result = await stream
        .mapErr<Result<NetResponseHttp, NetResultStatus>>((e) => Err(e))
        .andThenAsync<(Stream<List<int>>, NetResponseHttp)>((response) async {
      if (!response.isSuccess) return Err(Ok(response));
      final id = response.streamId;
      if (id == null) {
        return Err(Err(NetResultStatus.unknownResponse));
      }
      streamId = id;
      Stream<List<int>> n() {
        return cachedController.stream
            .where((e) => e.id == response.streamId)
            .transform(StreamTransformer.fromHandlers(
          handleData: (event, sink) {
            switch (event) {
              case NetResponseStreamData data:
                sink.add(data.data);
                break;
              case NetResponseStreamClose():
                cachedController.close();
                break;
              case NetResponseStreamError error:
                sink.addError(NetSdkException(error.error));
                break;
            }
          },
        ));
      }

      return Ok<(Stream<List<int>>, NetResponseHttp),
          Result<NetResponseHttp, NetResultStatus>>((n(), response));
    });
    return result.mapErr((e) {
      listener.cancel();
      cachedController.close();
      return e;
    });
  }

  Future<Result<NetResponseHttp, NetSdkException>> _streamOnce(
      {required Uri url,
      required HttpMethod method,
      required Duration timeout,
      NetHttpRetryConfig? retryConfig,
      List<int>? body,
      Map<String, String> headers = const {}}) async {
    final result = await _stream(
        url: url,
        timeout: timeout,
        method: method,
        retryConfig: retryConfig,
        body: body,
        headers: headers);
    if (result.isErr) {
      final err = result.unwrapErr();
      if (err.isErr) {
        return Err(NetSdkException(err.unwrapErr()));
      }
      return Ok(err.unwrap());
    }
    final stream = result.unwrap();
    final Completer<Result<NetResponseHttp, NetSdkException>> completer =
        Completer();
    List<int> bytes = [];
    stream.$1.listen((event) {
      bytes.addAll(event);
    }, onDone: () {
      completer.complete(Ok(stream.$2.copyWith(body: bytes)));
    }, onError: (_) {
      completer
          .complete(Err(NetSdkException(NetResultStatus.connectionClosed)));
    }, cancelOnError: true);

    return await completer.future;
  }

  @override
  Result<Stream<NetResponseHttp>, NetSdkException> stream(
      {required String url,
      required Duration timeout,
      required HttpMethod method,
      List<int>? body,
      Map<String, String> headers = const {},
      NetHttpRetryConfig? retryConfig}) {
    if (method == HttpMethod.closeConnection) {
      return Err(NetSdkException(NetResultStatus.invalidRequestParameters));
    }
    final uri = toUri(url);
    CachedStreamController<NetResponseStream>? cachedStreamController;
    StreamSubscription<NetResponseStream>? subscription;
    return uri.map((uri) {
      headers = toHeaders(headers: headers, method: method, uri: uri);
      return () async* {
        int streamId = -1;
        try {
          cachedStreamController = CachedStreamController<NetResponseStream>(
            onCancel: () async {
              if (streamId.isNegative) return;
              _transport.sendRequest<NetResponseHttp>(
                  NetRequestHttp(
                      method: HttpMethod.closeConnection,
                      url: url.toString(),
                      body: body,
                      retryConfig: retryConfig,
                      streamId: streamId,
                      headers: []),
                  timeout);
            },
          );
          subscription = _transport.stream.listen((e) {
            cachedStreamController?.add(e);
          });
          final stream = await _transport.sendRequest<NetResponseHttp>(
              NetRequestHttp(
                  method: method,
                  url: url.toString(),
                  body: body,
                  retryConfig: retryConfig,
                  headers: headers.entries
                      .map((e) => NetHttpHeader(key: e.key, value: e.value))
                      .toList()),
              timeout);
          if (stream.isErr) {
            throw NetSdkException(stream.unwrapErr());
          }
          final response = stream.unwrap();
          yield response;
          if (!response.isSuccess) {
            return;
          }
          final id = response.streamId;
          if (id == null) {
            throw NetSdkException(NetResultStatus.unknownResponse);
          }
          streamId = id;
          await for (final event in cachedStreamController!.stream
              .where((e) => e.id == streamId)) {
            switch (event) {
              case NetResponseStreamData data:
                yield response.copyWith(body: data.data);
                break;
              case NetResponseStreamClose():
                return;
              case NetResponseStreamError error:
                throw NetSdkException(error.error, details: {
                  "code": error.code.toString(),
                  "message": error.message
                });
            }
          }
        } finally {
          subscription?.cancel();
          cachedStreamController?.close();
          cachedStreamController = null;
        }
      }();
    });
  }

  @override
  Future<Result<void, NetSdkException>> closeConnection(Duration timeout) {
    return _send(
        url: _transport.config.url,
        method: HttpMethod.closeConnection,
        timeout: timeout);
  }
}

class DefaultHttpTransportWithDigestAuth extends DefaultHttpTransport {
  final HttpDigestAuthenticated _digestAuthenticated;
  DefaultHttpTransportWithDigestAuth(
      {required super.transport,
      required HttpAuthenticated super.authenticated,
      required HttpDigestAuthenticated digestAuthenticated})
      : _digestAuthenticated = digestAuthenticated;
  int _id = 1;
  DigestAuthHeaders? _challenge;
  final _lock = SafeAtomicLock();

  @override
  Map<String, String> toHeaders(
      {required Uri uri,
      required HttpMethod method,
      Map<String, String> headers = const {}}) {
    final challenge = _challenge;
    if (challenge != null) {
      final digestHeaders =
          DigestAuthenticatedUtils.getDigestAuthenticatedHeader(
              authenticated: _digestAuthenticated,
              params: challenge,
              method: method,
              uri: uri,
              count: _id);
      _id++;
      return {...digestHeaders, ...headers};
    }
    return super.toHeaders(headers: headers, method: method, uri: uri);
  }

  @override
  Future<Result<NetResponseHttp, NetSdkException>> _send(
      {required String url,
      required HttpMethod method,
      NetHttpRetryConfig? retryConfig,
      List<int>? body,
      required Duration timeout,
      Map<String, String> headers = const {}}) async {
    return _lock.run(() async {
      final response = await super._send(
          url: url,
          method: method,
          retryConfig: retryConfig,
          body: body,
          timeout: timeout,
          headers: headers);
      return response.andThenAsync((response) async {
        switch (response.statusCode) {
          case DigestAuthenticatedUtils.digestRetrAutheticatedStatusCode:
            final challenge = _challenge =
                DigestAuthenticatedUtils.getChallenges(response.headersMap());
            if (challenge != null) {
              _id = 1;
              final result = await super._send(
                  url: url,
                  method: method,
                  retryConfig: retryConfig,
                  body: body,
                  timeout: timeout,
                  headers: headers);
              return result;
            }
          default:
        }
        return Ok(response);
      });
    });
  }

  @override
  Future<
      Result<(Stream<List<int>>, NetResponseHttp),
          Result<NetResponseHttp, NetResultStatus>>> _stream(
      {required Uri url,
      required Duration timeout,
      required HttpMethod method,
      List<int>? body,
      Map<String, String> headers = const {},
      NetHttpRetryConfig? retryConfig}) async {
    final result = await super._stream(
      url: url,
      timeout: timeout,
      method: method,
      body: body,
      headers: headers,
      retryConfig: retryConfig,
    );
    if (result.isErr) {
      final err = result.unwrapErr();
      if (err.isErr) return Err(err);
      final response = err.unwrap();
      switch (response.statusCode) {
        case DigestAuthenticatedUtils.digestRetrAutheticatedStatusCode:
          _challenge =
              DigestAuthenticatedUtils.getChallenges(response.headersMap());
          if (_challenge != null) {
            _id = 1;
            return super._stream(
                url: url,
                method: method,
                retryConfig: retryConfig,
                body: body,
                timeout: timeout,
                headers: headers);
          }
          break;
        default:
      }
    }
    return result;
  }

  @override
  Result<Stream<NetResponseHttp>, NetSdkException> stream(
      {required String url,
      required Duration timeout,
      required HttpMethod method,
      List<int>? body,
      Map<String, String> headers = const {},
      NetHttpRetryConfig? retryConfig}) {
    if (method == HttpMethod.closeConnection) {
      return Err(NetSdkException(NetResultStatus.invalidRequestParameters));
    }
    final uri = toUri(url);
    return uri.andThen((uri) {
      headers = toHeaders(headers: headers, method: method, uri: uri);
      final stream = super.stream(
          url: url,
          timeout: timeout,
          method: method,
          body: body,
          headers: headers,
          retryConfig: retryConfig);
      if (stream.isErr) return Err(stream.unwrapErr());
      return Ok(() async* {
        await for (final i in stream.unwrap()) {
          if (!i.isSuccess) {
            switch (i.statusCode) {
              case DigestAuthenticatedUtils.digestRetrAutheticatedStatusCode:
                _challenge =
                    DigestAuthenticatedUtils.getChallenges(i.headersMap());
                if (_challenge != null) {
                  _id = 1;
                  final stream = super.stream(
                      url: url,
                      method: method,
                      retryConfig: retryConfig,
                      body: body,
                      timeout: timeout,
                      headers: headers);
                  if (stream.isErr) {
                    throw stream.unwrapErr();
                  }
                  await for (final i in stream.unwrap()) {
                    yield i;
                  }
                }
                break;
            }
          }
          yield i;
        }
      }());
    });
  }
}
