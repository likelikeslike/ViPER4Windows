import 'dart:io';

import 'package:viper4windows/services/file_logger.dart';

enum ProfileFileType { ddc, kernel, preset, eqPreset, dsPreset }

final _log = AppLogger('FileManager');

class ProfileFileManager {
  late final String _ddcDir;
  late final String _kernelDir;
  late final String _presetDir;
  late final String _eqPresetDir;
  late final String _dsPresetDir;

  ProfileFileManager() {
    final appData = Platform.environment['APPDATA'] ?? '';
    final baseDir = '$appData\\ViPER4Windows';
    _ddcDir = '$baseDir\\DDC';
    _kernelDir = '$baseDir\\Kernel';
    _presetDir = '$baseDir\\Preset';
    _eqPresetDir = '$baseDir\\EQPreset';
    _dsPresetDir = '$baseDir\\DynSysPreset';
    Directory(_ddcDir).createSync(recursive: true);
    Directory(_kernelDir).createSync(recursive: true);
    Directory(_presetDir).createSync(recursive: true);
    Directory(_eqPresetDir).createSync(recursive: true);
    Directory(_dsPresetDir).createSync(recursive: true);
  }

  String _dir(ProfileFileType type) {
    switch (type) {
      case ProfileFileType.ddc:
        return _ddcDir;
      case ProfileFileType.kernel:
        return _kernelDir;
      case ProfileFileType.preset:
        return _presetDir;
      case ProfileFileType.eqPreset:
        return _eqPresetDir;
      case ProfileFileType.dsPreset:
        return _dsPresetDir;
    }
  }

  Set<String> _extensions(ProfileFileType type) {
    switch (type) {
      case ProfileFileType.ddc:
        return {'vdc'};
      case ProfileFileType.kernel:
        return {'wav', 'irs'};
      case ProfileFileType.preset:
        return {'json'};
      case ProfileFileType.eqPreset:
        return {'json'};
      case ProfileFileType.dsPreset:
        return {'json'};
    }
  }

  String? importFile(String sourcePath, ProfileFileType type) {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) return null;
      final name = sourcePath.split(RegExp(r'[/\\]')).last;
      final dest = '${_dir(type)}\\$name';
      source.copySync(dest);
      return name;
    } catch (e) {
      _log.error('Import failed: $e');
    }
    return null;
  }

  List<String> listFiles(ProfileFileType type) {
    try {
      final dir = Directory(_dir(type));
      if (!dir.existsSync()) return [];
      final exts = _extensions(type);
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) {
            final ext = f.path.split('.').last.toLowerCase();
            return exts.contains(ext);
          })
          .map((f) => f.path.split(RegExp(r'[/\\]')).last)
          .toList();
      files.sort();
      return files;
    } catch (e) {
      _log.error('List files failed: $e');
      return [];
    }
  }

  String filePath(String name, ProfileFileType type) => '${_dir(type)}\\$name';

  void renameFile(String oldName, String newName, ProfileFileType type) {
    try {
      File(filePath(oldName, type)).renameSync(filePath(newName, type));
    } catch (e) {
      _log.error('Rename failed: $e');
    }
  }

  void deleteFile(String name, ProfileFileType type) {
    try {
      File(filePath(name, type)).deleteSync();
    } catch (e) {
      _log.error('Delete failed: $e');
    }
  }
}
