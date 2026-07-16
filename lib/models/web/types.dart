import 'package:blockchain_utils/helper/extensions/extensions.dart';

class WasmModuleInfo {
  final String moduleUrl;
  final String wasmUrl;
  final WasmModuleTarget target;
  const WasmModuleInfo(
      {required this.moduleUrl, required this.wasmUrl, required this.target});

  @override
  String toString() {
    return "WasmModuleInfo(moduleUrl:$moduleUrl, wasmUrl:$wasmUrl)";
  }
}

enum WasmModuleTarget {
  dart(1),
  rust(2);

  final int value;
  const WasmModuleTarget(this.value);
  bool get isDart => this == dart;
  bool get isRust => this == rust;
  static WasmModuleTarget? fromValue(int? value) {
    return values.firstWhereNullable((e) => e.value == value);
  }

  static WasmModuleTarget? fromName(String? name) {
    return values.firstWhereNullable((e) => e.name == name);
  }
}
