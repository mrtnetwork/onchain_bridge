import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';

class StraamBufferEncoder {
  final StreamEncoding encoding;
  StraamBufferEncoder(this.encoding);
  List<int> _buffer = [];

  List<int>? addBuffer(List<int> buffer) {
    switch (encoding) {
      case StreamEncoding.raw:
        return buffer;
      case StreamEncoding.map:
        _buffer = [..._buffer, ...buffer];
        final toJson = StringUtils.tryDecodeJson<Map<String, dynamic>>(_buffer);
        if (toJson != null) {
          try {
            return _buffer.clone();
          } finally {
            _buffer = [];
          }
        }
        break;
      case StreamEncoding.listOfMap:
        _buffer = [..._buffer, ...buffer];
        final toJson = StringUtils.tryDecodeJson<List>(_buffer);
        if (toJson != null) {
          try {
            return _buffer.clone();
          } finally {
            _buffer = [];
          }
        }
        break;
      case StreamEncoding.string:
        _buffer = [..._buffer, ...buffer];
        final str = StringUtils.tryDecode(_buffer);
        if (str != null) {
          try {
            return _buffer.clone();
          } finally {
            _buffer = [];
          }
        }
        break;
      case StreamEncoding.json:
        _buffer = [..._buffer, ...buffer];
        final toJson = StringUtils.tryDecodeJson(_buffer);
        if (toJson != null) {
          try {
            return _buffer.clone();
          } finally {
            _buffer = [];
          }
        }
        break;
    }
    return null;
  }
}
