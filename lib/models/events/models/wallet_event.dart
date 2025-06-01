import 'package:on_chain_bridge/exception/exception.dart';

enum WalletEventTypes {
  message,
  exception,
  activation,
  tabId,
  ping,
  windowId,
  openExtension,
  background,
  close;

  static WalletEventTypes fromName(String name) {
    return values.firstWhere((e) => e.name == name,
        orElse: () =>
            throw OnChainBridgeException("Invalid wallet event type $name"));
  }
}

enum WalletEventTarget { wallet, background, external }

class WalletEvent {
  final WalletEventTarget target;
  final String clientId;
  final List<int> data;
  final String requestId;
  final WalletEventTypes type;
  final String? additional;
  final String? platform;

  WalletEvent copyWith({
    String? clientId,
    List<int>? data,
    String? requestId,
    WalletEventTypes? type,
    String? additional,
    String? platform,
    WalletEventTarget? target,
  }) {
    return WalletEvent(
        clientId: clientId ?? this.clientId,
        data: data ?? this.data,
        requestId: requestId ?? this.requestId,
        type: type ?? this.type,
        additional: additional ?? this.additional,
        platform: platform ?? this.platform,
        target: target ?? this.target);
  }

  WalletEvent(
      {this.clientId = "",
      List<int> data = const [],
      this.requestId = "",
      required this.target,
      required this.type,
      this.additional,
      this.platform})
      : data = List<int>.unmodifiable(data);
  factory WalletEvent.fromJson(
      Map<String, dynamic> json, WalletEventTarget target) {
    return WalletEvent(
        clientId: json["client_id"],
        data: List<int>.from(json["data"]),
        requestId: json["request_id"],
        type: WalletEventTypes.fromName(json["type"]),
        target: target,
        additional: json["additional"],
        platform: json["platform"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "client_id": clientId,
      "data": data,
      "request_id": requestId,
      "type": type.name,
      "additional": additional,
      "platform": platform,
      "target": target.name
    };
  }
}
