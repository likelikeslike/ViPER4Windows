import 'dart:convert';
import 'dart:io';

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
  static const _takeOwnershipAndGrant = r'''
    try {
        $fxRegPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\$epId\FxProperties"
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($fxRegPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
        if ($key) {
            $acl = $key.GetAccessControl()
            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            $acl.SetOwner($adminSid)
            $key.SetAccessControl($acl)
            $key.Close()
        }
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($fxRegPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
        if ($key) {
            $acl = $key.GetAccessControl()
            $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
            $rule1 = New-Object System.Security.AccessControl.RegistryAccessRule($systemSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $rule2 = New-Object System.Security.AccessControl.RegistryAccessRule($adminSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.AddAccessRule($rule1)
            $acl.AddAccessRule($rule2)
            $key.SetAccessControl($acl)
            $key.Close()
        }
    } catch {
        Write-Error "ACL failed for $epId : $_"
    }
''';

  Future<void> ensureProtectedAudioDGDisabled() async {
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
    final script =
        '''
\$renderPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\MMDevices\\Audio\\Render"
\$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"
\$viperRegPath = "HKLM:\\SOFTWARE\\ViPER4Windows"
New-Item -Path \$viperRegPath -Force -ErrorAction SilentlyContinue | Out-Null

\$apoRegPath = "HKLM:\\SOFTWARE\\Classes\\AudioEngine\\AudioProcessingObjects\\\$viperClsid"
New-Item -Path \$apoRegPath -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path \$apoRegPath -Name "FriendlyName" -Value "ViPER4Windows Audio Effect" -Type String -Force
Set-ItemProperty -Path \$apoRegPath -Name "Copyright" -Value "ViPER4Windows" -Type String -Force
Set-ItemProperty -Path \$apoRegPath -Name "MajorVersion" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MinorVersion" -Value 0 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "Flags" -Value 15 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MinInputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MaxInputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MinOutputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MaxOutputConnections" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "MaxInstances" -Value 0xFFFFFFFF -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "NumAPOInterfaces" -Value 1 -Type DWord -Force
Set-ItemProperty -Path \$apoRegPath -Name "APOInterface0" -Value "{FD7F2B29-24D0-4B5C-B177-592C39F9CA10}" -Type String -Force

\$count = 0
foreach (\$ep in Get-ChildItem \$renderPath) {
    \$props = Get-ItemProperty \$ep.PSPath -ErrorAction SilentlyContinue
    \$state = \$props.DeviceState
    if (\$state -ne 1 -and \$state -ne 8) { continue }
    \$fxPath = "\$(\$ep.PSPath)\\FxProperties"
    if (-not (Test-Path \$fxPath)) {
        New-Item -Path \$fxPath -Force | Out-Null
    }
    \$epId = \$ep.PSChildName

$_takeOwnershipAndGrant

    \$fxProps = Get-ItemProperty -Path \$fxPath -ErrorAction SilentlyContinue

    \$origSFX = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5"
    if (\$origSFX -and \$origSFX -ne \$viperClsid) {
        Set-ItemProperty -Path \$viperRegPath -Name "OrigSFX_\$epId" -Value \$origSFX -Type String -Force
    }
    \$origComp14 = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14"
    if (\$origComp14 -and \$origComp14 -ne \$viperClsid) {
        Set-ItemProperty -Path \$viperRegPath -Name "OrigCompMFX_\$epId" -Value \$origComp14 -Type String -Force
    }

    Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Value \$viperClsid -Type String -Force
    Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13" -Value \$viperClsid -Type String -Force
    Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Value \$viperClsid -Type String -Force

    \$hasNewStyle = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -or \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"
    if (\$hasNewStyle) {
        \$origSfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6"
        if (\$origSfxNew) {
            \$origStr = if (\$origSfxNew -is [array]) { \$origSfxNew -join "|" } else { [string]\$origSfxNew }
            if (\$origStr -notmatch [regex]::Escape(\$viperClsid)) {
                Set-ItemProperty -Path \$viperRegPath -Name "OrigSFXNew_\$epId" -Value \$origStr -Type String -Force
            }
        }
        \$origMfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"
        if (\$origMfxNew) {
            \$origStr = if (\$origMfxNew -is [array]) { \$origMfxNew -join "|" } else { [string]\$origMfxNew }
            if (\$origStr -notmatch [regex]::Escape(\$viperClsid)) {
                Set-ItemProperty -Path \$viperRegPath -Name "OrigMFXNew_\$epId" -Value \$origStr -Type String -Force
            }
        }
        Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Value @(\$viperClsid) -Type MultiString -Force
        Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Value @(\$viperClsid) -Type MultiString -Force
    }

    \$existingModes = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},5"
    if (-not \$existingModes) {
        Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},5" -Value @("{C18E2F7E-933D-4965-B7D1-1EEF228D2AF3}") -Type MultiString -Force
    }

    Remove-ItemProperty -Path \$fxPath -Name "{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5" -Force -ErrorAction SilentlyContinue

    \$count++
}

net stop Audiosrv >\$null 2>&1; Start-Sleep -Seconds 1; net start Audiosrv >\$null 2>&1
Write-Output \$count
''';
    final result = await _runPowerShell(script);
    final count = int.tryParse(result.trim()) ?? 0;
    return count > 0;
  }

  Future<bool> registerOnEndpoint(String endpointId) async {
    _log.info('Registering endpoint: $endpointId');
    final script =
        '''
\$renderPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\MMDevices\\Audio\\Render"
\$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"
\$viperRegPath = "HKLM:\\SOFTWARE\\ViPER4Windows"
\$epId = \$args[0]
\$fxPath = "\$renderPath\\\$epId\\FxProperties"

if (-not (Test-Path \$fxPath)) {
    New-Item -Path \$fxPath -Force | Out-Null
}

$_takeOwnershipAndGrant

\$fxProps = Get-ItemProperty -Path \$fxPath -ErrorAction SilentlyContinue

\$origSFX = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5"
if (\$origSFX -and \$origSFX -ne \$viperClsid) {
    Set-ItemProperty -Path \$viperRegPath -Name "OrigSFX_\$epId" -Value \$origSFX -Type String -Force
}
\$origComp14 = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14"
if (\$origComp14 -and \$origComp14 -ne \$viperClsid) {
    Set-ItemProperty -Path \$viperRegPath -Name "OrigCompMFX_\$epId" -Value \$origComp14 -Type String -Force
}

Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Value \$viperClsid -Type String -Force
Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13" -Value \$viperClsid -Type String -Force
Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Value \$viperClsid -Type String -Force

\$hasNewStyle = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -or \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"
if (\$hasNewStyle) {
    \$origSfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6"
    if (\$origSfxNew) {
        \$origStr = if (\$origSfxNew -is [array]) { \$origSfxNew -join "|" } else { [string]\$origSfxNew }
        if (\$origStr -notmatch [regex]::Escape(\$viperClsid)) {
            Set-ItemProperty -Path \$viperRegPath -Name "OrigSFXNew_\$epId" -Value \$origStr -Type String -Force
        }
    }
    \$origMfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"
    if (\$origMfxNew) {
        \$origStr = if (\$origMfxNew -is [array]) { \$origMfxNew -join "|" } else { [string]\$origMfxNew }
        if (\$origStr -notmatch [regex]::Escape(\$viperClsid)) {
            Set-ItemProperty -Path \$viperRegPath -Name "OrigMFXNew_\$epId" -Value \$origStr -Type String -Force
        }
    }
    Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Value @(\$viperClsid) -Type MultiString -Force
    Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Value @(\$viperClsid) -Type MultiString -Force
}

\$existingModes = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},5"
if (-not \$existingModes) {
    Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},5" -Value @("{C18E2F7E-933D-4965-B7D1-1EEF228D2AF3}") -Type MultiString -Force
}

Remove-ItemProperty -Path \$fxPath -Name "{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5" -Force -ErrorAction SilentlyContinue

net stop Audiosrv >\$null 2>&1; Start-Sleep -Seconds 1; net start Audiosrv >\$null 2>&1
Write-Output "OK"
''';
    final result = await _runPowerShell(script, args: [endpointId]);
    return result.trim() == 'OK';
  }

  Future<bool> unregisterEndpoint(String endpointId) async {
    _log.info('Unregistering endpoint: $endpointId');
    final script =
        '''
\$renderPath = "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\MMDevices\\Audio\\Render"
\$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"
\$viperRegPath = "HKLM:\\SOFTWARE\\ViPER4Windows"
\$epId = \$args[0]
\$fxPath = "\$renderPath\\\$epId\\FxProperties"

if (-not (Test-Path \$fxPath)) { Write-Output "OK"; exit }

$_takeOwnershipAndGrant

\$origSFX = \$null
\$origComp = \$null
\$origSfxNew = \$null
\$origMfxNew = \$null
if (Test-Path \$viperRegPath) {
    \$vprops = Get-ItemProperty -Path \$viperRegPath -ErrorAction SilentlyContinue
    \$origSFX = \$vprops."OrigSFX_\$epId"
    \$origComp = \$vprops."OrigCompMFX_\$epId"
    \$origSfxNew = \$vprops."OrigSFXNew_\$epId"
    \$origMfxNew = \$vprops."OrigMFXNew_\$epId"
}

\$fxProps = Get-ItemProperty -Path \$fxPath -ErrorAction SilentlyContinue

\$curSFX = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5"
if (\$curSFX -eq \$viperClsid) {
    if (\$origSFX) {
        Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Value \$origSFX -Type String -Force
    } else {
        Remove-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Force -ErrorAction SilentlyContinue
    }
}

\$curComp13 = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13"
if (\$curComp13 -eq \$viperClsid) {
    Remove-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13" -Force -ErrorAction SilentlyContinue
}

\$curComp14 = \$fxProps."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14"
if (\$curComp14 -eq \$viperClsid) {
    if (\$origComp) {
        Set-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Value \$origComp -Type String -Force
    } else {
        Remove-ItemProperty -Path \$fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Force -ErrorAction SilentlyContinue
    }
}

\$curSfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6"
\$sfxHasViper = (\$curSfxNew -is [array] -and \$curSfxNew -contains \$viperClsid) -or (\$curSfxNew -eq \$viperClsid)
if (\$sfxHasViper) {
    if (\$origSfxNew) {
        \$restored = \$origSfxNew -split '|'
        Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Value \$restored -Type MultiString -Force
    } else {
        Remove-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Force -ErrorAction SilentlyContinue
    }
}

\$curMfxNew = \$fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"
\$mfxHasViper = (\$curMfxNew -is [array] -and \$curMfxNew -contains \$viperClsid) -or (\$curMfxNew -eq \$viperClsid)
if (\$mfxHasViper) {
    if (\$origMfxNew) {
        \$restored = \$origMfxNew -split '|'
        Set-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Value \$restored -Type MultiString -Force
    } else {
        Remove-ItemProperty -Path \$fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path \$viperRegPath) {
    Remove-ItemProperty -Path \$viperRegPath -Name "OrigSFX_\$epId" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path \$viperRegPath -Name "OrigCompMFX_\$epId" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path \$viperRegPath -Name "OrigSFXNew_\$epId" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path \$viperRegPath -Name "OrigMFXNew_\$epId" -Force -ErrorAction SilentlyContinue
}

net stop Audiosrv >\$null 2>&1; Start-Sleep -Seconds 1; net start Audiosrv >\$null 2>&1
Write-Output "OK"
''';
    final result = await _runPowerShell(script, args: [endpointId]);
    return result.trim() == 'OK';
  }

  Future<String> _runPowerShell(String script, {List<String>? args}) async {
    final appData = Platform.environment['APPDATA'] ?? '';
    final scriptDir = '$appData\\ViPER4Windows';
    Directory(scriptDir).createSync(recursive: true);
    final scriptFile = File('$scriptDir\\apo_reg_script.ps1');
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
