import 'dart:convert';
import 'dart:io';

import 'package:viper4windows/services/file_logger.dart';

final _log = AppLogger('Settings');

class SettingsService {
  late final String _settingsPath;

  SettingsService() {
    final appData = Platform.environment['APPDATA'] ?? '';
    final dir = Directory('$appData\\ViPER4Windows');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _settingsPath = '${dir.path}\\settings.json';
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await File(_settingsPath).writeAsString(json);
    } catch (e) {
      _log.error('Save failed: $e');
    }
  }

  void saveSync(Map<String, dynamic> data) {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(data);
      File(_settingsPath).writeAsStringSync(json);
    } catch (e) {
      _log.error('SaveSync failed: $e');
    }
  }

  Future<Map<String, dynamic>?> load() async {
    try {
      final file = File(_settingsPath);
      if (!await file.exists()) return null;
      final json = await file.readAsString();
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      _log.error('Load failed: $e');
      return null;
    }
  }
}
