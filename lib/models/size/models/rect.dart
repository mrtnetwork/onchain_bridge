import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

class WidgetRect with AppSerialization {
  final double height;
  final double width;
  final double x;
  final double y;
  final double? devicePixelRatio;
  const WidgetRect(
      {required this.height,
      required this.width,
      required this.x,
      required this.y,
      this.devicePixelRatio});
  factory WidgetRect.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.widgetReact,
        cborBytes: bytes,
        cborObject: object);

    return WidgetRect(
        height: values.rawValueAt(0),
        width: values.rawValueAt(1),
        x: values.rawValueAt(2),
        y: values.rawValueAt(3),
        devicePixelRatio: values.rawValueAt(4));
  }

  WidgetRect copyWith(
      {double? height,
      double? width,
      double? x,
      double? y,
      double? devicePixelRatio}) {
    return WidgetRect(
        height: height ?? this.height,
        width: width ?? this.width,
        x: x ?? this.x,
        y: y ?? this.y,
        devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.widgetReact;

  @override
  List<CborObject?> get serializationItems => [
        CborFloatValue(height),
        CborFloatValue(width),
        CborFloatValue(x),
        CborFloatValue(y),
        switch (devicePixelRatio) {
          null => CborNullValue(),
          double v => CborFloatValue(v),
        }
      ];
}
