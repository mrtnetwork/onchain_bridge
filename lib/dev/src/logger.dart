// ignore_for_file: avoid_print

import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logging.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';

enum LoggerMode implements Comparable<LoggerMode> {
  debug(1),
  info(2),
  error(3),
  danger(4);

  final int value;
  const LoggerMode(this.value);

  bool get isDebug => this == debug;

  @override
  int compareTo(LoggerMode other) {
    return index.compareTo(other.index);
  }

  bool operator >=(LoggerMode other) {
    return compareTo(other) >= 0;
  }

  bool operator <=(LoggerMode other) {
    return compareTo(other) <= 0;
  }

  bool operator <(LoggerMode other) {
    return compareTo(other) < 0;
  }

  static LoggerMode fromValue(int? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ItemNotFoundException(),
    );
  }
}

// enum _LogType { debug, info, error }

typedef LOGWHEN = bool Function();
typedef LOGDATA = Object? Function();

class LoggingConfig with AppSerialization {
  final LoggerMode mode;
  final LoggerMode netsdk;
  final LoggerMode libs;
  final bool printDebug;
  // bool get console => mode == LoggerMode.debug;
  final String? environment;
  const LoggingConfig(
      {required this.mode,
      this.environment,
      required this.netsdk,
      required this.libs,
      required this.printDebug});
  const LoggingConfig.debug(
      {this.mode = LoggerMode.debug,
      this.netsdk = LoggerMode.debug,
      this.environment,
      this.libs = LoggerMode.debug,
      required this.printDebug});
  factory LoggingConfig.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.loggingConfig,
        cborBytes: bytes,
        cborObject: object);
    return LoggingConfig(
        mode: LoggerMode.fromValue(values.rawValueAt(0)),
        netsdk: LoggerMode.fromValue(values.rawValueAt(1)),
        libs: LoggerMode.fromValue(values.rawValueAt(2)),
        environment: values.rawValueAt(3),
        printDebug: values.rawValueAt(4));
  }

  LoggingConfig copyWith({
    LoggerMode? mode,
    LoggerMode? netsdk,
    LoggerMode? libs,
    String? environment,
    bool? printDebug,
  }) {
    return LoggingConfig(
        mode: mode ?? this.mode,
        netsdk: netsdk ?? this.netsdk,
        libs: libs ?? this.libs,
        environment: environment ?? this.environment,
        printDebug: printDebug ?? this.printDebug);
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.loggingConfig;

  @override
  List<CborObject?> get serializationItems => [
        mode.value.toCbor(),
        netsdk.value.toCbor(),
        libs.value.toCbor(),
        environment?.toCbor(),
        printDebug.toCbor()
      ];
}

class Logging {
  static LoggingConfig _config = LoggingConfig.debug(printDebug: true);
  static LoggingConfig get config => _config;
  static LoggerMode get mode => _config.mode;
  static LogWriter? _writer;
  static LogWriter? get writer => _writer;
  static void init(LoggingConfig config, {LogWriter? writer}) {
    Logg.setTag(config.environment);
    _config = config;
    _writer?.close();
    _writer = writer;
    writer?.init();
  }

  static bool _allow(LoggerMode mode) {
    return mode >= Logging.mode;
  }

  static void logData(
      {required ILogData? Function() fn,
      required LoggerMode mode,
      LOGWHEN? when}) {
    if (!_allow(mode)) return;
    if (when != null && !when()) return;
    final message = fn();
    if (message == null) return;
    return _log(
        className: message.runtime,
        functionName: message.function,
        logType: mode,
        message: message.message,
        stackTrace: message.trace,
        prefix: message.prefix,
        data: () => message.data,
        when: null);
  }

  static void debug({required ILogData? Function() fn, LOGWHEN? when}) {
    return logData(fn: fn, mode: LoggerMode.debug, when: when);
  }

  static void info({required ILogData? Function() fn, LOGWHEN? when}) {
    return logData(fn: fn, mode: LoggerMode.info, when: when);
  }

  static void error({required ILogData? Function() fn, LOGWHEN? when}) {
    return logData(fn: fn, mode: LoggerMode.error, when: when);
  }

  static void danger({required ILogData? Function() fn, LOGWHEN? when}) {
    return logData(fn: fn, mode: LoggerMode.danger, when: when);
  }

  static LogMessageMessage? _ToMsg({
    String? className,
    String? functionName,
    required LoggerMode logType,
    Object? message,
    String? stackTrace,
    LOGWHEN? when,
    LOGDATA? data,
    String? prefix,
  }) {
    if (!_allow(logType)) return null;
    if (when != null && !when()) return null;
    String whereMsg = "";
    if (className != null || functionName != null) {
      whereMsg = "[";
      if (className != null) {
        whereMsg += className;
        if (functionName != null) whereMsg += ".";
      }
      if (functionName != null) {
        whereMsg += functionName;
      }
      whereMsg += "]";
    }
    String? msg;
    if (message != null) {
      if (message is List || message is Map) {
        msg = StringUtils.fromJson(message, toStringEncodable: true);
      } else {
        msg = message.toString();
      }
    }
    Object? msgData;
    if (data != null) {
      msgData = data();
    }

    final defaulmsg = LogMessageDefault(
        prefix: _logPrefix(logType, prefix: prefix),
        where: whereMsg,
        trace: stackTrace,
        data: msgData,
        logType: logType,
        msg: msg);
    return LogMessageMessage(
        consoleMsg: defaulmsg.toConsole(),
        writterMsg: defaulmsg.toWriter(),
        timestamp: defaulmsg.timestamp,
        logType: logType);
  }

  static LogMessageDefault toLogMessage({
    String? className,
    String? functionName,
    required LoggerMode logType,
    Object? message,
    String? stackTrace,
    LOGDATA? data,
    String? prefix,
  }) {
    String whereMsg = "";
    if (className != null || functionName != null) {
      whereMsg = "[";
      if (className != null) {
        whereMsg += className;
        if (functionName != null) whereMsg += ".";
      }
      if (functionName != null) {
        whereMsg += functionName;
      }
      whereMsg += "]";
    }
    String? msg;
    if (message != null) {
      if (message is List || message is Map) {
        msg = StringUtils.fromJson(message, toStringEncodable: true);
      } else {
        msg = message.toString();
      }
    }
    Object? msgData;
    if (data != null) {
      msgData = data();
    }

    return LogMessageDefault(
        prefix: _logPrefix(logType, prefix: prefix),
        where: whereMsg,
        trace: stackTrace.toString(),
        data: msgData,
        logType: logType,
        msg: msg);
  }

  static void logMessage(LogMessageMessage msg) {
    if (!_allow(msg.logType)) return;
    final consoleMessage = msg.toConsole();
    if (config.printDebug && consoleMessage != null) {
      switch (msg.logType) {
        case LoggerMode.debug:
          _debug(consoleMessage);
          break;
        case LoggerMode.info:
          _warning(consoleMessage);
          return;
        case LoggerMode.danger:
        case LoggerMode.error:
          _error(consoleMessage);
          break;
      }
    }
    _write(msg);
  }

  static void _log(
      {String? className,
      String? functionName,
      required LoggerMode logType,
      String? message,
      LOGDATA? data,
      String? stackTrace,
      LOGWHEN? when,
      String? prefix}) {
    final finalMessage = _ToMsg(
        logType: logType,
        className: className,
        functionName: functionName,
        prefix: prefix,
        message: message,
        stackTrace: stackTrace,
        data: data,
        when: when);
    if (finalMessage == null) return;
    final console = finalMessage.toConsole();
    if (config.printDebug && console != null) {
      switch (logType) {
        case LoggerMode.debug:
          _debug(console);
          break;
        case LoggerMode.info:
          _warning(console);
          return;
        case LoggerMode.error:
        case LoggerMode.danger:
          _error(console);
          break;
      }
    }
    _write(finalMessage);
  }

  static String _logPrefix(LoggerMode type, {String? prefix}) {
    String? environment = config.environment;
    String logPrefix = () {
      if (prefix != null) return '[$prefix]';
      switch (type) {
        case LoggerMode.debug:
          return '[DEBUG]';
        case LoggerMode.info:
          return '[INFO]';
        case LoggerMode.error:
          return '[ERROR]';
        case LoggerMode.danger:
          return '[DANGER]';
      }
    }();
    if (environment == null) return logPrefix;
    return "[$environment]$logPrefix";
  }

  static void _warning(String text) {
    const yellow = '\x1B[33m';
    const reset = '\x1B[0m';
    final coloredText =
        yellow + text.replaceAll('\n', '\x1B[0m\n\x1B[33m') + reset;
    print(coloredText);
  }

  static void _error(String text) {
    const red = '\x1B[31m';
    const reset = '\x1B[0m';
    final coloredText =
        red + text.replaceAll('\n', '\x1B[0m\n\x1B[31m') + reset;
    print(coloredText);
  }

  static void _debug(String text) {
    const green = '\x1B[32m';
    const reset = '\x1B[0m';
    final coloredText =
        green + text.replaceAll('\n', '\x1B[0m\n\x1B[32m') + reset;
    print(coloredText);
  }

  static Future<void> _write(LogMessageMessage msg) async {
    final writer = _writer;
    if (writer == null) return;
    if (msg.logType < writer.mode) {
      return;
    }
    try {
      await writer.write(msg);
    } catch (e, stackTrace) {
      final msg = _ToMsg(
          logType: LoggerMode.error,
          className: writer.runtimeType.toString(),
          functionName: "write",
          message: e.toString(),
          stackTrace: stackTrace.toString());
      if (msg == null) return;
      _error(msg.toConsole() ?? msg.toWriter());
    }
  }
}

abstract mixin class LogWriter {
  LoggerMode get mode;
  void init();
  FutureOr<void> write(LogMessageMessage msg);
  Future<String?> readLogs();
  Future<void> clearLogs();
  void close();
}

abstract class LoggMessage {
  String? toConsole();
  String toWriter();
  abstract final DateTime timestamp;
  abstract final LoggerMode logType;
}

abstract class ILogData {
  abstract final String? runtime;
  abstract final String? function;
  abstract final String? message;
  abstract final String? trace;
  abstract final Object? data;
  abstract final String? prefix;
}

class LogDataDefault implements ILogData {
  @override
  final String? runtime;
  @override
  final String? function;
  @override
  final String? message;
  @override
  final String? trace;
  @override
  final Object? data;

  @override
  final String? prefix;
  const LogDataDefault._(
      {this.runtime,
      this.function,
      this.message,
      this.trace,
      this.data,
      this.prefix});
  factory LogDataDefault(
      {Object? runtime,
      String? function,
      String? message,
      Object? data,
      String? trace,
      String? prefix}) {
    return LogDataDefault._(
        data: data,
        function: function,
        message: message,
        runtime: runtime?.toString(),
        trace: trace,
        prefix: prefix);
  }
}

class LogMessageDefault implements LoggMessage {
  final String prefix;
  final String? where;
  final String? msg;
  final String? trace;
  @override
  final LoggerMode logType;
  @override
  final DateTime timestamp;
  final Object? data;
  LogMessageDefault(
      {required this.prefix,
      required this.where,
      required this.trace,
      required this.msg,
      required this.logType,
      required this.data,
      DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
  factory LogMessageDefault.debug(
      {Object? runtime,
      String? functionName,
      String? msg,
      LOGDATA? data,
      String? stackTrace}) {
    return Logging.toLogMessage(
        logType: LoggerMode.debug,
        className: runtime?.toString(),
        functionName: functionName,
        message: msg,
        stackTrace: stackTrace,
        data: data);
  }
  factory LogMessageDefault.from(
      {required LoggerMode logType,
      Object? runtime,
      String? functionName,
      String? msg,
      LOGDATA? data,
      String? stackTrace}) {
    return Logging.toLogMessage(
        logType: logType,
        className: runtime?.toString(),
        functionName: functionName,
        message: msg,
        stackTrace: stackTrace,
        data: data);
  }
  factory LogMessageDefault.danger(
      {Object? runtime,
      String? functionName,
      String? msg,
      LOGDATA? data,
      String? stackTrace}) {
    return Logging.toLogMessage(
        logType: LoggerMode.danger,
        className: runtime?.toString(),
        functionName: functionName,
        message: msg,
        stackTrace: stackTrace,
        data: data);
  }
  factory LogMessageDefault.error(
      {Object? runtime,
      String? functionName,
      String? msg,
      LOGDATA? data,
      String? stackTrace}) {
    return Logging.toLogMessage(
        logType: LoggerMode.error,
        className: runtime?.toString(),
        functionName: functionName,
        message: msg,
        stackTrace: stackTrace,
        data: data);
  }
  factory LogMessageDefault.info(
      {Object? runtime,
      String? functionName,
      String? msg,
      LOGDATA? data,
      String? stackTrace}) {
    return Logging.toLogMessage(
        logType: LoggerMode.info,
        className: runtime?.toString(),
        functionName: functionName,
        message: msg,
        stackTrace: stackTrace,
        data: data);
  }

  String? _data() {
    final data = this.data;
    if (data == null) return null;
    if (data is String) return data;
    if (data is List<int> && BytesUtils.areBytesValid(data)) {
      return BytesUtils.toHexString(data, prefix: "0x");
    }
    return StringUtils.tryFromJson(data) ?? data.toString();
  }

  @override
  String toConsole() {
    final buffer = StringBuffer()..write(prefix);
    if (where != null) {
      buffer.write(" $where");
    }
    final msg = this.msg;
    if (msg != null) {
      buffer.write(" $msg");
    }
    final stackTrace = trace;

    if (stackTrace != null) {
      final List<String> error = stackTrace
          .toString()
          .split("\n")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (error.isNotEmpty) {
        buffer.writeln(" trance:");
        for (final i in error) {
          buffer.writeln(i);
        }
      }
    }
    final data = _data();
    if (data != null) {
      buffer.writeln(" data: $data");
    }
    return buffer.toString();
  }

  @override
  String toWriter() {
    final buffer = StringBuffer()..write(prefix);
    buffer.write(" [$timestamp] ");
    if (where != null) {
      buffer.write(where);
    }
    if (msg != null) {
      buffer.write(" $msg");
    }
    final stackTrace = trace;

    if (stackTrace != null) {
      final List<String> error = stackTrace
          .toString()
          .split("\n")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (error.isNotEmpty) {
        buffer.writeln(" trance:");
        for (final i in error) {
          buffer.writeln(i);
        }
      }
    }
    final data = _data();
    if (data != null) {
      buffer.writeln(" data: $data");
    }
    return buffer.toString();
  }
}

class LogWriterDefault implements LogWriter {
  final List<LogMessageMessage> _cachedMessage = [];
  late final StreamController<LogMessageMessage> _controller =
      StreamController()
        ..onListen = () {
          for (final m in _cachedMessage) {
            _controller.add(m);
          }
          _cachedMessage.clear();
        };

  @override
  final LoggerMode mode;
  final bool withConsoleMessage;
  LogWriterDefault(this.mode, {this.withConsoleMessage = true});
  @override
  Future<void> clearLogs() async {}

  @override
  void close() {
    _controller.close();
  }

  @override
  void init() {}

  @override
  Future<String?> readLogs() async => null;

  @override
  FutureOr<void> write(LogMessageMessage msg) async {
    if (!withConsoleMessage) {
      msg = msg.withoutConsoleMessage();
    }

    if (_controller.hasListener) {
      _controller.add(msg);
    } else {
      _cachedMessage.add(msg);
    }
  }

  Stream<LogMessageMessage> get stream => _controller.stream;
}

class LogMessageMessage with AppSerialization implements LoggMessage {
  final String? consoleMsg;
  final String writterMsg;
  @override
  final DateTime timestamp;
  @override
  final LoggerMode logType;
  const LogMessageMessage(
      {required this.consoleMsg,
      required this.writterMsg,
      required this.timestamp,
      required this.logType});
  factory LogMessageMessage.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: OnChainBrdigeSerializationIdentifier.logMessage,
        cborBytes: bytes,
        cborObject: object);
    return LogMessageMessage(
        consoleMsg: values.rawValueAt(0),
        writterMsg: values.rawValueAt(1),
        timestamp: values.rawValueAt(2),
        logType: LoggerMode.fromValue(values.rawValueAt(3)));
  }

  LogMessageMessage withoutConsoleMessage() {
    if (consoleMsg == null) return this;
    return LogMessageMessage(
        consoleMsg: null,
        writterMsg: writterMsg,
        timestamp: timestamp,
        logType: logType);
  }

  @override
  String? toConsole() {
    return consoleMsg;
  }

  @override
  String toWriter() {
    return writterMsg;
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      OnChainBrdigeSerializationIdentifier.logMessage;

  @override
  List<CborObject?> get serializationItems => [
        consoleMsg?.toCbor(),
        writterMsg.toCbor(),
        CborEpochIntValue(timestamp),
        logType.value.toCbor()
      ];
}
