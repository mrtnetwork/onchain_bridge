import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';

class NetSdkUtils {
  static NetAddressInfo? parseHostPort(String url, bool isTls) {
    if (url.trim().isEmpty) {
      return null;
    }
    int defaultPort = isTls ? 443 : 80;
    Uri? uri = Uri.tryParse(url);

    String host;
    int? port;

    if (uri != null && uri.host.isNotEmpty) {
      host = uri.host;
      port = uri.hasPort ? uri.port : null;
    } else {
      final parts = url.split(":");
      if (parts.length == 1) {
        host = parts[0];
      } else if (parts.length == 2) {
        host = parts[0];
        port = int.tryParse(parts[1]);
        if (port == null) return null;
      } else {
        return null;
      }
    }
    if (host.isEmpty) {
      return null;
    }
    port ??= defaultPort;

    if (port < 1 || port > BinaryOps.mask16) {
      return null;
    }
    final urlWithScheme = isTls ? "tls://$host:$port" : "tcp://$host:$port";
    return NetAddressInfo(
        host: host,
        port: port,
        url: urlWithScheme,
        isTls: isTls,
        uri: Uri.parse(urlWithScheme));
  }

  static NetAddressInfo? parseWebsocketUrl(String url) {
    if (url.trim().isEmpty) {
      return null;
    }
    Uri? uri = Uri.tryParse(url);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null || (scheme != "wss" && scheme != "ws")) {
      return null;
    }
    return NetAddressInfo(
        host: uri.host,
        port: uri.port,
        url: url,
        isTls: scheme == "wss",
        uri: uri);
  }

  static NetAddressInfo? parseHttpUrl(String url) {
    if (url.trim().isEmpty) {
      return null;
    }
    Uri? uri = Uri.tryParse(url);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null || (scheme != "http" && scheme != "https")) {
      return null;
    }
    return NetAddressInfo(
        host: uri.host,
        port: uri.port,
        url: url,
        isTls: scheme == "wss",
        uri: uri);
  }
}
