import 'package:on_chain_bridge/exception/exception.dart';

enum BarcodeScanerResultType {
  error,
  success,
  cancel;

  static BarcodeScanerResultType fromName(String? type) {
    return values.firstWhere((e) => e.name == type,
        orElse: () => throw const OnChainBridgeException(
            "Invalid barcode scanner result"));
  }
}

class BarcodeScannerResult {
  final BarcodeScanerResultType type;
  final String? message;
  const BarcodeScannerResult({required this.type, required this.message});
  factory BarcodeScannerResult.fromJson(Map<String, dynamic> json) {
    return BarcodeScannerResult(
        type: BarcodeScanerResultType.fromName(json["type"]),
        message: json["message"]);
  }
}
