import 'dart:io';

class FileLogger {
  static final FileLogger shared = FileLogger._();

  static const int _maxFileSize = 2 * 1024 * 1024;
  late final String _logPath;
  late final String _oldLogPath;

  FileLogger._() {
    final appData = Platform.environment['APPDATA'] ?? '';
    final logDir = Directory('$appData\\ViPER4Windows');
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }
    _logPath = '${logDir.path}\\viper.log';
    _oldLogPath = '${logDir.path}\\viper.old.log';
  }

  void _rotateIfNeeded() {
    final file = File(_logPath);
    if (!file.existsSync()) return;
    if (file.lengthSync() <= _maxFileSize) return;

    final oldFile = File(_oldLogPath);
    if (oldFile.existsSync()) {
      oldFile.deleteSync();
    }
    file.renameSync(_oldLogPath);
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
  static String _pad3(int n) => n.toString().padLeft(3, '0');

  void log(String level, String category, String message) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${_pad2(now.month)}-${_pad2(now.day)} '
        '${_pad2(now.hour)}:${_pad2(now.minute)}:${_pad2(now.second)}.${_pad3(now.millisecond)}';
    final line = '$timestamp [$category][$level] $message\n';
    _rotateIfNeeded();
    File(_logPath).writeAsStringSync(line, mode: FileMode.append);
  }

  void logBatch(String level, String category, List<String> messages) {
    if (messages.isEmpty) return;
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${_pad2(now.month)}-${_pad2(now.day)} '
        '${_pad2(now.hour)}:${_pad2(now.minute)}:${_pad2(now.second)}.${_pad3(now.millisecond)}';
    final buf = StringBuffer();
    for (final msg in messages) {
      buf.write('$timestamp [$category][$level] $msg\n');
    }
    _rotateIfNeeded();
    File(_logPath).writeAsStringSync(buf.toString(), mode: FileMode.append);
  }

  void flush() {}

  void close() {}
}

class AppLogger {
  final String category;

  const AppLogger(this.category);

  void debug(String message) =>
      FileLogger.shared.log('DEBUG', category, message);

  void debugBatch(List<String> messages) =>
      FileLogger.shared.logBatch('DEBUG', category, messages);

  void info(String message) => FileLogger.shared.log('INFO', category, message);

  void warning(String message) =>
      FileLogger.shared.log('WARN', category, message);

  void error(String message) =>
      FileLogger.shared.log('ERROR', category, message);
}
