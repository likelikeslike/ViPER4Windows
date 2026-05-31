import 'dart:convert';
import 'dart:io';

class DeviceInfo {
  final String id;
  final String name;
  final bool isHeadphone;

  DeviceInfo({required this.id, required this.name, required this.isHeadphone});

  static const defaultSpeaker = 'speaker';
  static const defaultWired = 'wired';
}

class DeviceSettingsManager {
  static String get _devicesDir {
    final appData = Platform.environment['APPDATA'] ?? '';
    return '$appData\\ViPER4Windows\\devices';
  }

  static void ensureDir() {
    Directory(_devicesDir).createSync(recursive: true);
  }

  static File _fileFor(String deviceId) {
    final safe = deviceId.replaceAll(RegExp(r'[{}]'), '');
    return File('$_devicesDir\\$safe.json');
  }

  static Map<String, dynamic>? loadDevice(String deviceId) {
    final f = _fileFor(deviceId);
    if (!f.existsSync()) return null;
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  static void saveDevice(
    String deviceId,
    String deviceName,
    bool isHeadphone,
    Map<String, dynamic> settings,
  ) {
    ensureDir();
    final data = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'isHeadphone': isHeadphone,
      'lastConnected': DateTime.now().millisecondsSinceEpoch,
      'settings': settings,
    };
    _fileFor(deviceId).writeAsStringSync(jsonEncode(data));
  }

  static List<Map<String, dynamic>> listDevices() {
    ensureDir();
    final dir = Directory(_devicesDir);
    final result = <Map<String, dynamic>>[];
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      try {
        result.add(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      } catch (_) {}
    }
    result.sort(
      (a, b) => (b['lastConnected'] as int? ?? 0).compareTo(
        a['lastConnected'] as int? ?? 0,
      ),
    );
    return result;
  }

  static void deleteDevice(String deviceId) {
    final f = _fileFor(deviceId);
    if (f.existsSync()) f.deleteSync();
  }

  static void renameDevice(String deviceId, String newName) {
    final data = loadDevice(deviceId);
    if (data == null) return;
    data['deviceName'] = newName;
    _fileFor(deviceId).writeAsStringSync(jsonEncode(data));
  }
}
