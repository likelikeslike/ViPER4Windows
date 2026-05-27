import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:viper4windows/services/file_logger.dart';

class ApoEndpointInfo {
  final String id;
  final String name;
  final bool registered;

  ApoEndpointInfo({
    required this.id,
    required this.name,
    required this.registered,
  });
}

final _log = AppLogger('ApoReg');

class ApoRegistrationService {
  // Native channel that writes FxProperties values directly, taking ownership
  // of TrustedInstaller-owned keys when necessary. PowerShell cannot do this
  // reliably because Win11 24H2 restricts the privileges available to PS
  // children spawned from a Flutter process.
  static const _nativeChannel = MethodChannel('v4w/apo_registry');

  Future<void> ensureProtectedAudioDGDisabled() async {
    // This key is admin-writable even without take-ownership; keep PS.
    final script = r'''
$path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio"
$val = Get-ItemProperty -Path $path -Name "DisableProtectedAudioDG" -ErrorAction SilentlyContinue
if (-not $val -or $val.DisableProtectedAudioDG -ne 1) {
    Set-ItemProperty -Path $path -Name "DisableProtectedAudioDG" -Value 1 -Type DWord -Force
    Write-Output "FIXED"
} else {
    Write-Output "OK"
}
''';
    final result = await _runPowerShell(script);
    if (result.trim() == 'FIXED') {
      _log.info('DisableProtectedAudioDG was reset, re-applied');
    }
  }

  Future<List<ApoEndpointInfo>> listRenderEndpoints() async {
    // Read-only enumeration. PS is fine here; no ownership needed.
    final script = r'''
$renderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"
$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"
$results = @()
foreach ($ep in Get-ChildItem $renderPath) {
    $props = Get-ItemProperty $ep.PSPath -ErrorAction SilentlyContinue
    $state = $props.DeviceState
    if ($state -ne 1) { continue }
    $propPath = "$($ep.PSPath)\Properties"
    $epProps = Get-ItemProperty $propPath -ErrorAction SilentlyContinue
    $name = $epProps.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
    if (-not $name) { $name = $epProps.'{a45c254e-df1c-4efd-8020-67d146a850e0},2' }
    if (-not $name) { $name = "Unknown" }
    $fxPath = "$($ep.PSPath)\FxProperties"
    $registered = $false
    if (Test-Path $fxPath) {
        $fxProps = Get-ItemProperty $fxPath -ErrorAction SilentlyContinue
        $sfxOld = $fxProps.'{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5'
        $mfxOld = $fxProps.'{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14'
        $sfxNew = $fxProps.'{d3993a3f-99c2-4402-b5ec-a92a0367664b},6'
        $mfxNew = $fxProps.'{d3993a3f-99c2-4402-b5ec-a92a0367664b},7'
        if ($sfxOld -eq $viperClsid -or $mfxOld -eq $viperClsid) { $registered = $true }
        if ($sfxNew -is [array] -and $sfxNew -contains $viperClsid) { $registered = $true }
        if ($sfxNew -eq $viperClsid) { $registered = $true }
        if ($mfxNew -is [array] -and $mfxNew -contains $viperClsid) { $registered = $true }
        if ($mfxNew -eq $viperClsid) { $registered = $true }
    }
    $results += @{ id = $ep.PSChildName; name = $name; registered = $registered }
}
$results | ConvertTo-Json -Compress
''';
    final result = await _runPowerShell(script);
    if (result.isEmpty || result == 'null') return [];
    final decoded = jsonDecode(result);
    final list = decoded is List ? decoded : [decoded];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return ApoEndpointInfo(
        id: m['id'] as String,
        name: m['name'] as String,
        registered: m['registered'] as bool,
      );
    }).toList();
  }

  Future<bool> registerOnAllEndpoints() async {
    _log.info('Registering on all endpoints');
    // APO metadata keys live under HKLM\SOFTWARE\Classes - admin-writable, no
    // TrustedInstaller involvement. Keep PS for these.
    await _runPowerShell(r'''
$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"
$viperRegPath = "HKLM:\SOFTWARE\ViPER4Windows"
New-Item -Path $viperRegPath -Force -ErrorAction SilentlyContinue | Out-Null

$apoRegPath = "HKLM:\SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\$viperClsid"
New-Item -Path $apoRegPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path $apoRegPath -Name "FriendlyName" -Value "ViPER4Windows Audio Effect" -Type String -Force
Set-ItemProperty -Path $apoRegPath -Name "Copyright" -Value "ViPER4Windows" -Type String -Force
Set-ItemProperty -Path $apoRegPath -Name "MajorVersion" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MinorVersion" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "Flags" -Value 15 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MinInputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MaxInputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MinOutputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MaxOutputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "MaxInstances" -Value 0xFFFFFFFF -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "NumAPOInterfaces" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $apoRegPath -Name "APOInterface0" -Value "{FD7F2B29-24D0-4B5C-B177-592C39F9CA10}" -Type String -Force
''');

    final endpoints = await listRenderEndpoints();
    var count = 0;
    for (final ep in endpoints) {
      if (await registerOnEndpoint(ep.id)) {
        count++;
      }
    }
    await _restartAudioService();
    return count > 0;
  }

  Future<bool> registerOnEndpoint(String endpointId) async {
    _log.info('Registering endpoint: $endpointId');
    try {
      final ok = await _nativeChannel.invokeMethod<bool>('registerEndpoint', {
        'endpointId': endpointId,
      });
      if (ok == true) {
        await _restartAudioService();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      _log.error('registerEndpoint native failed: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<bool> unregisterEndpoint(String endpointId) async {
    _log.info('Unregistering endpoint: $endpointId');
    try {
      final ok = await _nativeChannel.invokeMethod<bool>('unregisterEndpoint', {
        'endpointId': endpointId,
      });
      if (ok == true) {
        await _restartAudioService();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      _log.error('unregisterEndpoint native failed: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<void> _restartAudioService() async {
    // sc.exe is non-interactive; net.exe blocks on the dependent-service
    // confirmation prompt when no console is attached.
    await Process.run('sc.exe', ['stop', 'Audiosrv']);
    await Future.delayed(const Duration(seconds: 2));
    await Process.run('sc.exe', ['start', 'Audiosrv']);
  }

  Future<String> _runPowerShell(String script, {List<String>? args}) async {
    final appData = Platform.environment['APPDATA'] ?? '';
    final scriptDir = '$appData\\ViPER4Windows';
    Directory(scriptDir).createSync(recursive: true);
    // Unique per-call name avoids "file not found" when concurrent callers
    // (list endpoints + DG check + register-all) share the same temp path.
    final tag = DateTime.now().microsecondsSinceEpoch;
    final scriptFile = File('$scriptDir\\apo_reg_$tag.ps1');
    scriptFile.writeAsStringSync(script);
    final psArgs = [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptFile.path,
      ...?args,
    ];
    final result = await Process.run(
      'powershell',
      psArgs,
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );
    try {
      scriptFile.deleteSync();
    } catch (_) {}
    final stderr = (result.stderr as String).trim();
    if (stderr.isNotEmpty) {
      _log.error('PowerShell stderr: $stderr');
    }
    return (result.stdout as String).trim();
  }
}
