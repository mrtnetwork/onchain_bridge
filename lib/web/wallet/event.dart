import 'dart:js_interop';
import 'package:on_chain_bridge/models/events/models/wallet_event.dart';
import 'package:on_chain_bridge/web/api/api.dart';

@JS()
extension type JSWalletEvent._(JSObject o) implements JSOBJ {
  external factory JSWalletEvent(
      {JSArray<JSNumber>? data,
      String? type,
      String? additional,
      String? platform,
      required String? target});

  external String? get target;
  external String? get type;
  @JS("client_id")
  external set clientId(String? clientId);
  @JS("client_id")
  external String? get clientId;
  @JS("request_id")
  external set requestId(String? requestId);
  @JS("request_id")
  external String? get requestId;
  external String? get platform;
  external JSArray<JSNumber>? get data;
  external String? get additional;
  external set additional(String? additional);
  List<int> get data_ => List<int>.from(data!.toDart);
  Map<String, dynamic> toJson() {
    return {
      "id": clientId,
      "data": data_,
      "additional": additional,
      "request_id": requestId,
      "type": type,
      "platform": platform,
      "target": target,
    };
  }

  WalletEvent? toEvent() {
    try {
      return WalletEvent(
          clientId: clientId!,
          data: data_,
          requestId: requestId!,
          type: WalletEventTypes.fromName(type!),
          additional: additional,
          platform: platform,
          target: WalletEventTarget.values.firstWhere((e) => e.name == target));
    } catch (e) {
      return null;
    }
  }
}

extension ToJsEvent on WalletEvent {
  JSWalletEvent toJsEvent() {
    return JSWalletEvent(
        data: data.map((e) => e.toJS).toList().toJS,
        type: type.name,
        additional: additional,
        platform: platform,
        target: target.name)
      ..clientId = clientId
      ..requestId = requestId;
  }
}
