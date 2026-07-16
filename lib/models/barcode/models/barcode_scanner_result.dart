import 'package:blockchain_utils/blockchain_utils.dart';

enum BarcodeScanerResultType {
  error,
  success,
  cancel;

  static BarcodeScanerResultType? fromName(String? type) {
    return values.firstWhereNullable((e) => e.name == type);
  }
}

class BarcodeScannerResult {
  final BarcodeScanerResultType type;
  final String? message;
  const BarcodeScannerResult({required this.type, required this.message});
  static BarcodeScannerResult? fromJson(Map<String, dynamic> json) {
    final type = BarcodeScanerResultType.fromName(json["type"]);
    if (type == null) return null;
    return BarcodeScannerResult(type: type, message: json["message"]);
  }
}
