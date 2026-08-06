import 'package:viper4windows/models/viper_state.dart';

class ControlDispatch {
  final ViperState state;

  ControlDispatch(this.state);

  List<String> dispatch(List<String> tokens) {
    if (tokens.isEmpty) return const ['ERR empty command'];
    switch (tokens.first) {
      case 'preset':
        return _preset(tokens.sublist(1));
      case 'master':
        return _master(tokens.sublist(1));
      case 'device':
        return _device(tokens.sublist(1));
      case 'status':
        return _status();
      default:
        return ['ERR unknown command: ${tokens.first}'];
    }
  }

  List<String> _preset(List<String> a) {
    if (a.isEmpty) return const ['ERR usage: preset <list|load|save|delete|rename|import>'];
    switch (a.first) {
      case 'list':
        state.refreshFileLists();
        final files = state.presetFiles;
        if (files.isEmpty) return const ['OK', '(no presets)'];
        return ['OK', ...files];
      case 'load':
        if (a.length < 2) return const ['ERR usage: preset load <name>'];
        final rc = state.loadPreset(a[1]);
        return rc == 0 ? ['OK loaded preset ${a[1]}'] : ['ERR preset not found or invalid: ${a[1]}'];
      case 'save':
        if (a.length < 2) return const ['ERR usage: preset save <name>'];
        state.savePreset(a[1]);
        return ['OK saved preset ${a[1]}'];
      case 'delete':
        if (a.length < 2) return const ['ERR usage: preset delete <name>'];
        if (!state.presetFiles.contains(a[1])) {
          return ['ERR preset not found: ${a[1]}'];
        }
        state.deletePreset(a[1]);
        return ['OK deleted preset ${a[1]}'];
      case 'rename':
        if (a.length < 3) return const ['ERR usage: preset rename <old> <new>'];
        if (!state.presetFiles.contains(a[1])) {
          return ['ERR preset not found: ${a[1]}'];
        }
        state.renamePreset(a[1], a[2]);
        return ['OK renamed preset ${a[1]} -> ${a[2]}'];
      case 'import':
        if (a.length < 2) return const ['ERR usage: preset import <path>'];
        final name = state.importPreset(a[1]);
        return name == null ? ['ERR import failed: ${a[1]}'] : ['OK imported preset $name'];
      default:
        return ['ERR unknown preset command: ${a.first}'];
    }
  }

  List<String> _master(List<String> a) {
    if (a.isEmpty) return ['OK', state.masterEnabled ? 'on' : 'off'];
    switch (a.first) {
      case 'on':
        state.masterEnabled = true;
        return const ['OK master=on'];
      case 'off':
        state.masterEnabled = false;
        return const ['OK master=off'];
      case 'toggle':
        state.masterEnabled = !state.masterEnabled;
        return ['OK master=${state.masterEnabled ? "on" : "off"}'];
      default:
        return ['ERR usage: master [on|off|toggle]'];
    }
  }

  List<String> _device(List<String> a) {
    if (a.isEmpty) return const ['ERR usage: device <current|list|show|delete>'];
    switch (a.first) {
      case 'current':
        return [
          'OK',
          'id=${state.currentDeviceId}',
          'name=${state.currentDeviceName}',
          'type=${state.isCurrentDeviceHeadphone ? "headphone" : "speaker"}',
        ];
      case 'list':
        final devices = state.deviceList;
        if (devices.isEmpty) return const ['OK', '(no devices)'];
        return [
          'OK',
          for (final d in devices)
            '${d['id']}  ${d['name']}  '
                '(${(d['isHeadphone'] as bool? ?? false) ? "headphone" : "speaker"})',
        ];
      case 'show':
        final id = a.length >= 2 ? a[1] : state.currentDeviceId;
        return _deviceShow(id);
      case 'delete':
        if (a.length < 2) return const ['ERR usage: device delete <id>'];
        final data = state.deviceSettings(a[1]);
        if (data == null) return ['ERR device not found: ${a[1]}'];
        state.deleteDeviceSettings(a[1]);
        return ['OK deleted device ${a[1]}'];
      default:
        return ['ERR unknown device command: ${a.first}'];
    }
  }

  List<String> _deviceShow(String id) {
    final data = state.deviceSettings(id);
    if (data == null) return ['ERR device not found: $id'];
    return [
      'OK',
      'id=${data['deviceId']}',
      'name=${data['deviceName']}',
      'type=${(data['isHeadphone'] as bool? ?? false) ? "headphone" : "speaker"}',
    ];
  }

  List<String> _status() {
    return [
      'OK',
      'master: ${state.masterEnabled ? "on" : "off"}',
      'driver installed: ${state.apoConnected ? "yes" : "no"}',
      'sample rate: ${state.apoSampleRate} Hz',
      'APO version: ${state.apoVersion.isEmpty ? "(unknown)" : state.apoVersion}',
      'APO arch: ${state.apoArch.isEmpty ? "(unknown)" : state.apoArch}',
      'device: ${state.currentDeviceName.isEmpty ? "(unknown)" : state.currentDeviceName} '
          '(${state.isCurrentDeviceHeadphone ? "headphone" : "speaker"})',
    ];
  }
}
