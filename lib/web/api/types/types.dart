import 'dart:js_interop';
import 'package:blockchain_utils/utils/types/result.dart';

@JS()
extension type JSInt58(JSObject _) implements JSAny {
  external int get low;
  external int get high;
  external bool get unsigned;
  static const List<String> properties = ['low', 'high', 'unsigned'];
}

@JS()
extension type NetSdkDartCompiledWasm(JSObject _) implements JSObject {
  external JSPromise<JSAny> compile(JSAny buffer);
  external JSPromise<JSAny> instantiate(JSAny compiledApp);
  external void invoke(JSAny moduleInstance);
}
@JS()
extension type ResultOrErrorJs<T extends JSAny?, E extends JSAny>.__(JSObject _)
    implements JSAny {
  external T get ok;
  external E get err;
  @JS("ok")
  external T? get okNullable;
  @JS("err")
  external E? get errNullable;
  bool isValid() {
    if (errNullable.isDefinedAndNotNull) return okNullable.isUndefinedOrNull;
    return true;
  }
}
@JS()
extension type ErrJs<T extends JSAny?, E extends JSAny>.__(JSObject _)
    implements ResultOrErrorJs<T, E> {
  external factory ErrJs._({E? err});
  factory ErrJs(E? err) => ErrJs<T, E>._(err: err);
}
@JS()
extension type OkJs<T extends JSAny?, E extends JSAny>.__(JSObject _)
    implements ResultOrErrorJs<T, E> {
  external factory OkJs._({T? ok});
  factory OkJs(T? ok) => OkJs<T, E>._(ok: ok);
}

extension JSRESULT<T, E> on Result<T, E> {
  ResultOrErrorJs<TJS, EJS> toJS<TJS extends JSAny?, EJS extends JSAny>({
    required TJS Function(T ok) onResult,
    required EJS Function(E err) onErr,
  }) {
    if (isErr) return ErrJs<TJS, EJS>(onErr(unwrapErr()));
    return OkJs<TJS, EJS>(onResult(unwrap()));
  }
}

@JS('ArrayBuffer')
extension type APPJSArrayBuffer._(JSObject obj) implements JSObject {
  APPJSUint8Array toUint8Array() {
    return APPJSUint8Array(this);
  }
}

@JS("Uint8Array")
extension type APPJSUint8Array._(JSAny _) implements JSAny {
  external APPJSUint8Array(
      [APPJSArrayBuffer buffer, int byteOffset, int length]);
  external static APPJSUint8Array from(JSAny? v);
  external APPJSUint8Array slice();
  external APPJSArrayBuffer get buffer;

  factory APPJSUint8Array.fromList(List<int> bytes) {
    JSUint8Array();
    return APPJSUint8Array.from(bytes.jsify());
  }
  List<int> toBytes() {
    return (dartify() as List?)?.cast<int>() ?? [];
  }
}

extension DARTRESULT<T extends JSAny?, E extends JSAny>
    on ResultOrErrorJs<T, E>? {
  Result<TD, ED> toDart<TD extends Object?, ED extends Object>({
    required TD Function(T ok) onResult,
    required ED Function(E err) onErr,
    required ED Function() onInvalid,
  }) {
    final result = this;
    if (result.isUndefinedOrNull || result == null) return Err(onInvalid());
    if (!result.isValid()) return Err(onInvalid());
    try {
      if (result.errNullable.isDefinedAndNotNull) {
        return Err(onErr(result.err));
      }
      return Ok(onResult(result.ok));
    } catch (_) {
      return Err(onInvalid());
    }
  }
}
