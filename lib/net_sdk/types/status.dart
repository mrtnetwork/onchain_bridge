import 'package:blockchain_utils/helper/helper.dart';

enum NetResultStatus {
  // Success
  ok(100, "ok"),

  // General network errors
  invalidUrl(1, "invalid_url"),
  tlsError(2, "net_sdk_tls_handshake_failed"),
  connectionError(3, "net_sdk_network_connection_failed"),
  torNetError(4, "net_sdk_tor_connection_failed"),
  socketError(10, "net_sdk_socket_closed"),

  // HTTP / transport errors
  http2ConnectionFailed(13, "net_sdk_http2_connection_failed"),
  invalidRequestParameters(15, "net_sdk_invalid_request_parameters"),
  invalidConfigParameters(16, "net_sdk_invalid_config_parameters"),
  transportNotFound(17, "net_sdk_transport_not_found"),
  badHttpRequestHost(19, "request_host_does_not_match_connected_host"),

  requestTimeout(22, "net_sdk_request_timeout"),
  invalidTorConfig(23, "net_sdk_invalid_tor_config"),
  torInitializationFailed(24, "net_sdk_tor_initialization_failed"),
  torClientNotInitialized(26, "net_sdk_tor_client_not_initialized"),
  internalError(27, "net_sdk_internal_sdk_error"),
  instanceDoesNotExist(28, "net_sdk_sdk_not_initialized"),
  torConfigNotInitialized(29, "net_sdk_tor_config_not_initialized"),
  // Dart-specific SDK errors
  invalidSdkConfig(-1, "net_sdk_invalid_sdk_config"),
  unknownResponse(-2, "net_sdk_unknown_response"),
  unsupportedFeature(-7, "net_sdk_unsupported_feature"),
  closed(-4, "net_sdk_closed"),
  connectionClosed(-5, "net_sdk_connection_closed"),
  initializationFailed(-7, "net_sdk_sdk_initialization_failed"),
  parsingError(-8, "net_sdk_invalid_content_error");

  final int value;
  final String dsecription;
  const NetResultStatus(this.value, this.dsecription);

  static NetResultStatus? fromValueOrNull(int? value) {
    return values.firstWhereNullable((e) => e.value == value);
  }

  static NetResultStatus fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => NetResultStatus.unknownResponse,
    );
  }

  bool isDevError() {
    switch (this) {
      case NetResultStatus.ok:
      case NetResultStatus.invalidUrl:
      case NetResultStatus.tlsError:
      case NetResultStatus.connectionError:
      case NetResultStatus.torNetError:
      case NetResultStatus.socketError:
      case NetResultStatus.http2ConnectionFailed:
      case NetResultStatus.requestTimeout:
      case NetResultStatus.closed:
      case NetResultStatus.connectionClosed:
        return false;
      default:
        return true;
    }
  }

  bool isOk() {
    return this == NetResultStatus.ok;
  }
}
