import 'dart:async';

typedef ONSTREAMCANCELED = FutureOr<void> Function();

class CachedStreamController<T> {
  List<T> _items = [];
  late final StreamController<T> controller;
  Stream<T> get stream => controller.stream;
  CachedStreamController({ONSTREAMCANCELED? onCancel, bool broadcast = false}) {
    controller = switch (broadcast) {
      false => StreamController<T>(
          onListen: _onListen,
          onCancel: onCancel,
        ),
      true => StreamController<T>.broadcast(
          onListen: _onListen,
          onCancel: onCancel,
        )
    };
  }

  void _onListen() {
    for (final i in _items) {
      controller.add(i);
    }
    _items = [];
  }

  void add(T data) {
    assert(!controller.isClosed);
    if (controller.isClosed) return;
    if (controller.hasListener) {
      controller.add(data);
    } else {
      _items.add(data);
    }
  }

  void addErr(Object error) {
    assert(!controller.isClosed);
    if (controller.isClosed) return;
    controller.addError(error);
  }

  void close() {
    controller.close();
    _items = [];
  }
}
