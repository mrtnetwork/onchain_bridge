import 'dart:io';
import 'package:on_chain_bridge/dev/src/logger.dart';

class LogWriterFile implements LogWriter {
  final String path;
  @override
  final LoggerMode mode;
  RandomAccessFile? _file;
  LogWriterFile(this.path, this.mode);
  @override
  void write(LoggMessage msg) {
    _file?.writeStringSync("${msg.toWriter()}\n");
  }

  File _getFiled() => File(path)..createSync(recursive: true);

  @override
  void init() {
    final file = _getFiled();
    _file = file.openSync(mode: FileMode.writeOnlyAppend);
    _file?.writeStringSync("Logging: ${DateTime.now()} \n");
  }

  @override
  void close() {
    _file?.closeSync();
    _file = null;
  }

  @override
  Future<String?> readLogs() async {
    try {
      _file?.flush();
      _file?.close();
      _file = null;
      return await _getFiled().readAsString();
    } finally {
      init();
    }
  }

  @override
  Future<void> clearLogs() async {
    try {
      _file?.flush();
      _file?.close();
      _file = null;
      await _getFiled().delete();
    } finally {
      init();
    }
  }
}
