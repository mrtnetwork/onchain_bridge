import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';

import 'exception.dart';

enum DigestAuthHeadersAlg {
  md5(name: "MD5"),
  md5Sess(name: "MD5-sess"),
  sha256(name: "SHA-256"),
  sha256Sess(name: "SHA-256-sess"),
  sha512(name: "SHA-512"),
  sha512Sess(name: "SHA-512-sess"),
  sha512256(name: "SHA-512-256"),
  sha512256Sess(name: "SHA-512-256-sess");

  bool get sessionBased => name.endsWith("sess");

  final String name;
  const DigestAuthHeadersAlg({required this.name});
  static DigestAuthHeadersAlg fromName(String? name) {
    if (name == null) return DigestAuthHeadersAlg.md5;
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw HttpDigestAuthenticatedError.invalidOrUnsuportedDigestAuth);
  }

  List<int> hashBytes(List<int> input) {
    return switch (this) {
      DigestAuthHeadersAlg.md5 ||
      DigestAuthHeadersAlg.md5Sess =>
        MD5.hash(input),
      DigestAuthHeadersAlg.sha256 ||
      DigestAuthHeadersAlg.sha256Sess =>
        SHA256.hash(input),
      DigestAuthHeadersAlg.sha512 ||
      DigestAuthHeadersAlg.sha512Sess =>
        SHA512.hash(input),
      DigestAuthHeadersAlg.sha512256 ||
      DigestAuthHeadersAlg.sha512256Sess =>
        SHA512256.hash(input),
    };
  }

  String hashString(String input) {
    return BytesUtils.toHexString(hashBytes(StringUtils.encode(input)));
  }
}

enum DigestAuthQop {
  auth(name: "auth"),
  authInt(name: "auth-int");

  final String name;
  const DigestAuthQop({required this.name});
  static DigestAuthQop fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw HttpDigestAuthenticatedError.invalidOrUnsuportedDigestAuth);
  }
}

class DigestAuthHeaders {
  final String nonce;
  final DigestAuthQop? qop;
  final String realm;
  final DigestAuthHeadersAlg algorithm;
  final String? opaque;
  const DigestAuthHeaders(
      {required this.nonce,
      this.qop,
      required this.realm,
      required this.algorithm,
      required this.opaque});
  factory DigestAuthHeaders.fromJson(Map<String, dynamic> json) {
    return DigestAuthHeaders(
        nonce: json["nonce"],
        qop: json["qop"] == null ? null : DigestAuthQop.fromName(json["qop"]),
        realm: json["realm"],
        algorithm: DigestAuthHeadersAlg.fromName(json["algorithm"]),
        opaque: json["opaque"]);
  }
}

class DigestAuthenticatedUtils {
  static const int digestRetrAutheticatedStatusCode = 401;
  static const String digestAuthKey = "www-authenticate";
  static const String digestKey = "Digest ";
  static const String autorizationKey = "Authorization";

  static bool canUseAuthDigest(Map<String, String> headers) {
    return (headers[digestAuthKey]?.contains(digestKey) ?? false);
  }

  /// Generate Digest Authentication header
  static String generateDigestAuthHeader({
    required HttpDigestAuthenticated authenticated,
    required HttpMethod method,
    required Uri uri,
    required DigestAuthHeaders params,
    List<int>? body,
    int count = 1,
  }) {
    final realm = params.realm;
    final nonce = params.nonce;
    final qop = params.qop;
    final algorithm = params.algorithm;
    final path = uri.path;
    final cnonce = BytesUtils.toHexString(QuickCrypto.generateRandom(8));
    final nc = count.toRadixString(16).padLeft(8, '0');
    String ha1 = algorithm.hashString(
        '${authenticated.username}:$realm:${authenticated.password}');
    if (algorithm.sessionBased) {
      ha1 = algorithm.hashString('$ha1:$nonce:$cnonce');
    }
    final String ha2 = switch (qop) {
      DigestAuthQop.auth ||
      null =>
        algorithm.hashString('${method.name}:$path'),
      DigestAuthQop.authInt => algorithm.hashString(
          '${method.name}:$uri:${BytesUtils.toHexString(algorithm.hashBytes(body ?? []))}'),
    };

    final response = switch (qop) {
      DigestAuthQop.auth ||
      DigestAuthQop.authInt =>
        algorithm.hashString('$ha1:$nonce:$nc:$cnonce:${qop!.name}:$ha2'),
      null => algorithm.hashString('$ha1:$nonce:$ha2'),
    };
    String digest =
        'Digest username="${authenticated.username}", realm="$realm", nonce="$nonce", uri="$path", '
        'nc=$nc, cnonce="$cnonce", response="$response", algorithm=${algorithm.name}';
    if (qop != null) {
      digest += ', qop=${qop.name}';
    }
    if (params.opaque != null) {
      digest += ', opaque=${params.opaque}';
    }
    return digest;
  }

  static DigestAuthHeaders? getChallenges(Map<String, String> headers) {
    if (!canUseAuthDigest(headers)) return null;
    final challenges = parseDigestHeader(headers[digestAuthKey]!);
    if (challenges.isEmpty) {
      throw HttpDigestAuthenticatedError.invalidOrUnsuportedDigestAuth;
    }
    return challenges.first;
  }

  static Map<String, String> getDigestAuthenticatedHeader(
      {required HttpDigestAuthenticated authenticated,
      required DigestAuthHeaders params,
      required HttpMethod method,
      required Uri uri,
      required int count,
      List<int>? body}) {
    return {
      autorizationKey: generateDigestAuthHeader(
          authenticated: authenticated,
          method: method,
          uri: uri,
          params: params,
          body: body,
          count: count)
    };
  }

  static List<DigestAuthHeaders> parseDigestHeader(String header) {
    if (!header.contains(digestKey)) {
      throw HttpDigestAuthenticatedError.invalidOrUnsuportedDigestAuth;
    }
    final digestParts = header
        .split('Digest ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != ",")
        .toList();

    final List<DigestAuthHeaders> auth = [];
    for (final i in digestParts) {
      final challenge = i.split(',').map((e) => e.trim()).toList();
      final Map<String, dynamic> params = {};
      for (final part in challenge) {
        final match = RegExp(r'^(.*?)=(.*)$').firstMatch(part);
        if (match != null) {
          final key = match.group(1)!.trim();
          final value = match.group(2)!.replaceAll('"', '').trim();
          params[key] = value;
        }
      }
      try {
        final digestParams = DigestAuthHeaders.fromJson(params);
        auth.add(digestParams);
      } on HttpDigestAuthenticatedError catch (_) {}
    }

    return auth;
  }
}
