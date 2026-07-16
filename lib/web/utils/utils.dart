import 'dart:js_interop';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart'
    show BigintUtils, StringUtils;
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';

class JsUtils {
  static JSUint8Array toJsUint8Array(List<int> bytes) {
    return Uint8List.fromList(toUint8Array(bytes)).toJS;
  }

  static APPJSUint8Array toAppJsUint8Array(List<int> bytes) {
    return APPJSUint8Array.fromList(bytes);
  }

  static JSArray<JSNumber> bytesToJsArray(List<int> bytes) {
    return bytes.map((e) => e.toJS).toList().toJS;
  }

  static Uint8List toUint8Array(List<int> bytes) {
    if (bytes is Uint8List) return bytes;
    return Uint8List.fromList(bytes);
  }

  static Object? _toEncodableObject(Object? p0) {
    if ((p0 as JSAny).isA<JSBigInt>()) {
      return p0.toString();
    }
    throw UnimplementedError();
  }

  static JSAny? convert(JSAny? k, JSAny? v) {
    if (v.isUndefinedOrNull) return null;
    if (v.isA<JSString>()) {
      return v;
    }
    if (v.isA<JSBigInt>()) {
      return v.toString().toJS;
    }
    if (v.isA<JSNumber>()) {
      return v;
    }
    if (v.isA<JSBoolean>()) {
      return v;
    }
    if (v.isA<JSUint8Array>()) {
      return v;
    }
    if (v.isA<JSArray>()) {
      return v;
    }
    if (v.isA<JSArrayBuffer>()) {
      return v;
    }
    if (v.typeofEquals("object")) {
      try {
        final toInt = List<int>.from(v.dartify() as List);
        return toInt.map((e) => e.toJS).toList().toJS;
      } catch (_) {}
    }
    return v;
  }

  static Map<String, dynamic>? toDartMap(JSAny? object) {
    if (object == null) return null;
    try {
      if (object.isA<JSString>()) {
        return StringUtils.toJson<Map<String, dynamic>>(
            (object as JSString).toDart);
      }
      try {
        final inDart = object.dartify();
        return StringUtils.toJson<Map<String, dynamic>>(
            StringUtils.fromJson(inDart!, toEncodable: _toEncodableObject));
      } catch (_) {}
      return StringUtils.toJson<Map<String, dynamic>>(
          jsJson.stringify(object, convert.toJS));
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>>? toListOfMap<T>(JSAny? object) {
    try {
      if (object == null) return null;
      if (object.isA<JSString>()) {
        return StringUtils.toJson<List>(object)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return StringUtils.toJson<List>(StringUtils.fromJson(object.dartify()!,
              toEncodable: _toEncodableObject))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static String toEthereumClientId(String clientId) {
    return "ETH_$clientId";
  }

  static String toWalletId(String clientId) {
    return "WALLET_$clientId";
  }

  static int convertInt53(JSInt58 int53) {
    BigInt low = BigInt.from(int53.low);
    BigInt high = BigInt.from(int53.high);
    final BigInt part = (high << 32);
    final BigInt int256 = part | (low & BigInt.from(0xFFFFFFFF));
    if (int53.unsigned) {
      return int256.toUnsigned(53).toInt();
    }

    return int256.toInt();
  }

  static BigInt? parseNumber(JSAny? object) {
    try {
      if (object.isUndefinedOrNull) return null;
      if (object.isA<JSNumber>()) {
        return BigInt.from((object as JSNumber).toDartInt);
      }
      if (object.isA<JSBigInt>()) {
        return BigintUtils.parse(object.toString());
      }
      if (object.isA<JSString>()) {
        return BigintUtils.parse((object as JSString).toDart);
      }
      final n = JSOBJ.as<JSInt58>(object: object, keys: JSInt58.properties);
      if (n != null) {
        return BigInt.from(convertInt53(n));
      }
      return BigintUtils.parse(object.toString());
    } catch (e) {
      return null;
    }
  }

  static JSArray<JSAny?>? asJSArray(JSAny? obj) {
    if (obj.isUndefinedOrNull) return <JSAny>[].toJS;
    List<JSAny?> messages = [];
    if (obj.isA<JSArray>()) {
      messages = (obj as JSArray<JSAny?>).toDart;
    } else {
      messages.add(obj);
    }
    return List<JSAny?>.from(messages).toJS;
  }

  static JSString? asJSString(JSString? obj) {
    if (obj.isUndefinedOrNull) return null;
    if (obj.isA<JSString>()) return obj;
    return null;
  }

  static List<int>? toDartBytes(JSAny? obj) {
    try {
      if (obj.isUndefinedOrNull) return null;
      if (obj.isA<JSUint8Array>()) return (obj as JSUint8Array).toDart;
      if (obj.isA<JSArray>()) {
        return (obj as JSArray)
            .toDart
            .cast<JSNumber>()
            .map((e) => e.toDartInt)
            .toList();
      }
      return (obj.dartify() as List?)?.cast<int>() ?? [];
    } catch (_) {}
    return null;
  }

  static JSAny? undefinedAsNull(JSAny? obj) {
    if (obj.isUndefinedOrNull) return null;
    return obj;
  }
}
