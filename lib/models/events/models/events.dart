import 'package:on_chain_bridge/exception/exception.dart';

enum AppNativeEventType {
  internet,
  deeplink;

  static AppNativeEventType fromName(String? name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw OnChainBridgeException("Invalid app native event."));
  }
}

abstract final class AppNativeEvent {
  final AppNativeEventType type;
  const AppNativeEvent(this.type);
  factory AppNativeEvent.fromJson(Map<String, dynamic> json) {
    final type = AppNativeEventType.fromName(json["type"]);
    return switch (type) {
      AppNativeEventType.internet => AppNativeEventConnection.fromJson(json),
      AppNativeEventType.deeplink => AppNativeEventDeeplink.fromJson(json),
    };
  }
}

final class AppNativeEventConnection extends AppNativeEvent {
  const AppNativeEventConnection(this.isOnline)
      : super(AppNativeEventType.internet);
  factory AppNativeEventConnection.fromJson(Map<String, dynamic> json) {
    return AppNativeEventConnection(json["value"]);
  }
  final bool isOnline;
}

final class AppNativeEventDeeplink extends AppNativeEvent {
  const AppNativeEventDeeplink(this.url) : super(AppNativeEventType.deeplink);
  final String url;
  factory AppNativeEventDeeplink.fromJson(Map<String, dynamic> json) {
    return AppNativeEventDeeplink(json["value"]);
  }
}
