import 'dart:js_interop';
import 'dart:typed_data';

import 'package:blockchain_utils/utils/types/result.dart';
import 'package:on_chain_bridge/dev/src/logging.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';

@JS("window")
external Window? get jsWindowOrNull;

@JS("fetch")
external JSPromise<Response> fetchWithOption(
    String resource, FetchOptions? options);

class JSFetchApi {
  static Headers _buildHeaders(Map<String, String>? headers) {
    final h = Headers();
    headers?.forEach((key, value) => h.append(key, value));
    return h;
  }

  static Future<Response> fetchOnce(
      {required Uri url,
      required HttpMethod method,
      List<int>? body,
      Map<String, String>? headers,
      AbortSignal? signal}) {
    final options = FetchOptions(
      signal: signal,
      method: method.name,
      headers: _buildHeaders(headers),
      body: (body != null) ? Uint8List.fromList(body).toJS : null,
    );
    Logg.error("befor send $body $method ${url.toString()}");
    final future = jsWindowOrNull?.fetchWithOption(url.toString(), options) ??
        fetchWithOption(url.toString(), options);

    return future.toDart;
  }

  static Future<Result<Response, void>> fetchResponse(String url,
      {List<int>? allowStatus,
      HttpMethod? method,
      Map<String, String>? headers,
      Object? body}) async {
    try {
      FetchOptions? buildOptions() {
        if (method == null && headers == null && body == null) {
          return null;
        }
        final option = FetchOptions();
        if (method != null) option.method = method.name.toJS;
        if (body != null) option.body = body.jsify();
        if (headers != null) option.headers = _buildHeaders(headers);
        return option;
      }

      final option = buildOptions();
      final future = jsWindowOrNull?.fetchWithOption(url, option) ??
          fetchWithOption(url, option);
      final result = await future.toDart;
      if (result.ok) {
        if (allowStatus == null || allowStatus.contains(result.status)) {
          return Ok(result);
        }
      }
    } catch (_) {}
    return Err(null);
  }

  static Future<Result<ByteBuffer, void>> fetchBuffer(String url,
      {List<int>? allowStatus,
      HttpMethod? method,
      Map<String, String>? headers,
      Object? body}) async {
    final result = await fetchResponse(url,
        allowStatus: allowStatus, method: method, headers: headers, body: body);
    try {
      if (result.isOk) {
        final buffer = await result.unwrap().arrayBuffer_();
        return Ok(buffer);
      }
    } catch (_) {}
    return Err(null);
  }

  static Future<Result<JSArrayBuffer, void>> fetchJsBuffer(String url,
      {List<int>? allowStatus,
      HttpMethod? method,
      Map<String, String>? headers,
      Object? body}) async {
    final result = await fetchResponse(url,
        allowStatus: allowStatus, method: method, body: body, headers: headers);
    try {
      if (result.isOk) {
        final data = await result.unwrap().arrayBuffer().toDart;
        return Ok(data);
      }
    } catch (_) {}
    return Err(null);
  }

  static Future<Result<String, void>> fetchText(String url,
      {List<int>? allowStatus,
      HttpMethod? method,
      Map<String, String>? headers,
      Object? body}) async {
    final result = await fetchResponse(url,
        allowStatus: allowStatus, method: method, body: body, headers: headers);
    try {
      if (result.isOk) {
        final data = await result.unwrap().text_();
        return Ok(data);
      }
    } catch (_) {}
    return Err(null);
  }
}
