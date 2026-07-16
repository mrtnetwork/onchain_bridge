import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

abstract class IBuffer {
  List<int> toBytes();
  factory IBuffer.binary(List<int> data) => BufferBinary(data);
  factory IBuffer.string(String data,
          {StringEncoding encoding = StringEncoding.utf8}) =>
      BufferString(data, encoding: encoding);
}

class BufferBinary implements IBuffer {
  final List<int> data;
  const BufferBinary(this.data);
  factory BufferBinary.immutable(List<int> bytes) {
    return BufferBinary(bytes.asImmutableBytes);
  }

  @override
  List<int> toBytes() {
    return data;
  }
}

class BufferString implements IBuffer {
  final String data;
  final StringEncoding encoding;
  const BufferString(this.data, {this.encoding = StringEncoding.utf8});

  @override
  List<int> toBytes() {
    return StringUtils.encode(data, encoding: encoding);
  }
}
