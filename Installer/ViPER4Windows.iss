#define MyAppName "ViPER4Windows"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "ViPER4Windows"
#define MyAppExeName "ViPER4Windows.exe"

[Setup]
AppId={{D7E3A1B2-5F4C-4D8E-9A6B-3C2D1E0F4A5B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\installer
OutputBaseFilename=ViPER4Windows_Setup
SetupIconFile=..\ViPER4Windows\assets\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
MinVersion=10.0.17763
AppMutex=Global\ViPER4Windows_SingleInstance
CloseApplications=force
RestartApplications=no
AlwaysRestart=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\screen_retriever_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\system_tray_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ViPER4Windows\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\ViPER4WindowsAPO\build\Release\ViPER4WindowsAPO.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace uninsrestartdelete

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{sys}\shutdown.exe"; Parameters: "/r /t 10 /c ""ViPER4Windows has been installed. Rebooting in 10 seconds to load the audio driver."""; Description: "Reboot now (required for audio driver)"; Flags: postinstall skipifsilent nowait

[Messages]
FinishedLabel=Setup has finished installing [name] on your computer.%n%nA reboot is required for the audio driver to load properly.

[Code]
const
  ViperClsid = '{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}';

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  Exec('taskkill', '/f /im ViPER4Windows.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := '';
end;

procedure RegisterAPODriver();
var
  DllPath, ApoRegPath, AudioPath: String;
begin
  DllPath := ExpandConstant('{app}\ViPER4WindowsAPO.dll');

  // COM class registration (InprocServer32)
  ApoRegPath := 'SOFTWARE\Classes\CLSID\' + ViperClsid + '\InprocServer32';
  RegWriteStringValue(HKLM, 'SOFTWARE\Classes\CLSID\' + ViperClsid, '', 'ViPER4Windows MFX');
  RegWriteStringValue(HKLM, ApoRegPath, '', DllPath);
  RegWriteStringValue(HKLM, ApoRegPath, 'ThreadingModel', 'Both');

  // APO metadata registration (AudioEngine)
  ApoRegPath := 'SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\' + ViperClsid;
  RegWriteStringValue(HKLM, ApoRegPath, 'FriendlyName', 'ViPER4Windows Audio Effect');
  RegWriteStringValue(HKLM, ApoRegPath, 'Copyright', 'ViPER4Windows');
  RegWriteDWordValue(HKLM, ApoRegPath, 'MajorVersion', 1);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MinorVersion', 0);
  RegWriteDWordValue(HKLM, ApoRegPath, 'Flags', 15);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MinInputConnections', 1);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MaxInputConnections', 1);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MinOutputConnections', 1);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MaxOutputConnections', 1);
  RegWriteDWordValue(HKLM, ApoRegPath, 'MaxInstances', $FFFFFFFF);
  RegWriteDWordValue(HKLM, ApoRegPath, 'NumAPOInterfaces', 1);
  RegWriteStringValue(HKLM, ApoRegPath, 'APOInterface0', '{FD7F2B29-24D0-4B5C-B177-592C39F9CA10}');

  // APO registration (Windows Audio subsystem)
  ApoRegPath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Audio\AudioProcessingObjects\' + ViperClsid;
  RegWriteDWordValue(HKLM, ApoRegPath, 'Flags', 15);

  // Disable protected audio for unsigned APO
  AudioPath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Audio';
  RegWriteDWordValue(HKLM, AudioPath, 'DisableProtectedAudioDG', 1);
end;

procedure UnregisterAPODriver();
var
  ApoRegPath, ScriptPath: String;
  ResultCode: Integer;
begin
  // Kill app if running
  Exec('taskkill', '/f /im ViPER4Windows.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  // Unregister ViPER from ALL audio endpoints via PowerShell
  ScriptPath := ExpandConstant('{tmp}\viper_unreg.ps1');
  SaveStringToFile(ScriptPath,
    '$viperClsid = "{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}"' + #13#10 +
    '$viperRegPath = "HKLM:\SOFTWARE\ViPER4Windows"' + #13#10 +
    '$renderPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render"' + #13#10 +
    'foreach ($ep in Get-ChildItem $renderPath -ErrorAction SilentlyContinue) {' + #13#10 +
    '    $fxPath = "$($ep.PSPath)\FxProperties"' + #13#10 +
    '    if (-not (Test-Path $fxPath)) { continue }' + #13#10 +
    '    $epId = $ep.PSChildName' + #13#10 +
    '    try {' + #13#10 +
    '        $fxRegPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\$epId\FxProperties"' + #13#10 +
    '        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($fxRegPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)' + #13#10 +
    '        if ($key) {' + #13#10 +
    '            $acl = $key.GetAccessControl()' + #13#10 +
    '            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")' + #13#10 +
    '            $acl.SetOwner($adminSid)' + #13#10 +
    '            $key.SetAccessControl($acl)' + #13#10 +
    '            $key.Close()' + #13#10 +
    '        }' + #13#10 +
    '        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($fxRegPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)' + #13#10 +
    '        if ($key) {' + #13#10 +
    '            $acl = $key.GetAccessControl()' + #13#10 +
    '            $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")' + #13#10 +
    '            $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")' + #13#10 +
    '            $rule1 = New-Object System.Security.AccessControl.RegistryAccessRule($systemSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")' + #13#10 +
    '            $rule2 = New-Object System.Security.AccessControl.RegistryAccessRule($adminSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")' + #13#10 +
    '            $acl.AddAccessRule($rule1)' + #13#10 +
    '            $acl.AddAccessRule($rule2)' + #13#10 +
    '            $key.SetAccessControl($acl)' + #13#10 +
    '            $key.Close()' + #13#10 +
    '        }' + #13#10 +
    '    } catch {}' + #13#10 +
    '    $origSFX = $null; $origComp = $null; $origSfxNew = $null; $origMfxNew = $null' + #13#10 +
    '    if (Test-Path $viperRegPath) {' + #13#10 +
    '        $vprops = Get-ItemProperty -Path $viperRegPath -ErrorAction SilentlyContinue' + #13#10 +
    '        $origSFX = $vprops."OrigSFX_$epId"' + #13#10 +
    '        $origComp = $vprops."OrigCompMFX_$epId"' + #13#10 +
    '        $origSfxNew = $vprops."OrigSFXNew_$epId"' + #13#10 +
    '        $origMfxNew = $vprops."OrigMFXNew_$epId"' + #13#10 +
    '    }' + #13#10 +
    '    $curSFX = (Get-ItemProperty -Path $fxPath -ErrorAction SilentlyContinue)."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5"' + #13#10 +
    '    if ($curSFX -eq $viperClsid) {' + #13#10 +
    '        if ($origSFX) { Set-ItemProperty -Path $fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Value $origSFX -Type String -Force }' + #13#10 +
    '        else { Remove-ItemProperty -Path $fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5" -Force -ErrorAction SilentlyContinue }' + #13#10 +
    '    }' + #13#10 +
    '    $curComp13 = (Get-ItemProperty -Path $fxPath -ErrorAction SilentlyContinue)."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13"' + #13#10 +
    '    if ($curComp13 -eq $viperClsid) { Remove-ItemProperty -Path $fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13" -Force -ErrorAction SilentlyContinue }' + #13#10 +
    '    $curComp14 = (Get-ItemProperty -Path $fxPath -ErrorAction SilentlyContinue)."{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14"' + #13#10 +
    '    if ($curComp14 -eq $viperClsid) {' + #13#10 +
    '        if ($origComp) { Set-ItemProperty -Path $fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Value $origComp -Type String -Force }' + #13#10 +
    '        else { Remove-ItemProperty -Path $fxPath -Name "{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14" -Force -ErrorAction SilentlyContinue }' + #13#10 +
    '    }' + #13#10 +
    '    $fxProps = Get-ItemProperty -Path $fxPath -ErrorAction SilentlyContinue' + #13#10 +
    '    $curSfxNew = $fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},6"' + #13#10 +
    '    $sfxHasViper = ($curSfxNew -is [array] -and $curSfxNew -contains $viperClsid) -or ($curSfxNew -eq $viperClsid)' + #13#10 +
    '    if ($sfxHasViper) {' + #13#10 +
    '        if ($origSfxNew) { $restored = $origSfxNew -split "\|"; Set-ItemProperty -Path $fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Value $restored -Type MultiString -Force }' + #13#10 +
    '        else { Remove-ItemProperty -Path $fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},6" -Force -ErrorAction SilentlyContinue }' + #13#10 +
    '    }' + #13#10 +
    '    $curMfxNew = $fxProps."{d3993a3f-99c2-4402-b5ec-a92a0367664b},7"' + #13#10 +
    '    $mfxHasViper = ($curMfxNew -is [array] -and $curMfxNew -contains $viperClsid) -or ($curMfxNew -eq $viperClsid)' + #13#10 +
    '    if ($mfxHasViper) {' + #13#10 +
    '        if ($origMfxNew) { $restored = $origMfxNew -split "\|"; Set-ItemProperty -Path $fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Value $restored -Type MultiString -Force }' + #13#10 +
    '        else { Remove-ItemProperty -Path $fxPath -Name "{d3993a3f-99c2-4402-b5ec-a92a0367664b},7" -Force -ErrorAction SilentlyContinue }' + #13#10 +
    '    }' + #13#10 +
    '    if (Test-Path $viperRegPath) {' + #13#10 +
    '        Remove-ItemProperty -Path $viperRegPath -Name "OrigSFX_$epId" -Force -ErrorAction SilentlyContinue' + #13#10 +
    '        Remove-ItemProperty -Path $viperRegPath -Name "OrigCompMFX_$epId" -Force -ErrorAction SilentlyContinue' + #13#10 +
    '        Remove-ItemProperty -Path $viperRegPath -Name "OrigSFXNew_$epId" -Force -ErrorAction SilentlyContinue' + #13#10 +
    '        Remove-ItemProperty -Path $viperRegPath -Name "OrigMFXNew_$epId" -Force -ErrorAction SilentlyContinue' + #13#10 +
    '    }' + #13#10 +
    '}' + #13#10 +
    'if (Test-Path $viperRegPath) { Remove-Item $viperRegPath -Force -ErrorAction SilentlyContinue }' + #13#10,
    False);
  Exec('powershell', '-NoProfile -ExecutionPolicy Bypass -File "' + ScriptPath + '"',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  DeleteFile(ScriptPath);

  // Remove COM CLSID registration
  ApoRegPath := 'SOFTWARE\Classes\CLSID\' + ViperClsid;
  if RegKeyExists(HKLM, ApoRegPath) then
    RegDeleteKeyIncludingSubkeys(HKLM, ApoRegPath);

  // Remove AudioEngine APO metadata
  ApoRegPath := 'SOFTWARE\Classes\AudioEngine\AudioProcessingObjects\' + ViperClsid;
  if RegKeyExists(HKLM, ApoRegPath) then
    RegDeleteKeyIncludingSubkeys(HKLM, ApoRegPath);

  // Remove Audio subsystem APO registration
  ApoRegPath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Audio\AudioProcessingObjects\' + ViperClsid;
  if RegKeyExists(HKLM, ApoRegPath) then
    RegDeleteKeyIncludingSubkeys(HKLM, ApoRegPath);

  // Remove DisableProtectedAudioDG
  RegDeleteValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Audio', 'DisableProtectedAudioDG');

  // sc.exe is non-interactive; net.exe prompts for confirmation when stopping
  // services with running dependents, which deadlocks under SW_HIDE.
  Exec('sc', 'stop Audiosrv', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(2000);
  Exec('sc', 'start Audiosrv', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    RegisterAPODriver();
end;

procedure RemoveAutostartShortcut();
var
  StartupVbs: String;
begin
  StartupVbs := ExpandConstant('{userappdata}\Microsoft\Windows\Start Menu\Programs\Startup\ViPER4Windows.vbs');
  if FileExists(StartupVbs) then
    DeleteFile(StartupVbs);
end;

procedure RemoveUserData();
var
  UserDir, ProgramDataDir: String;
begin
  UserDir := ExpandConstant('{userappdata}\ViPER4Windows');
  ProgramDataDir := ExpandConstant('{commonappdata}\ViPER4Windows');
  if DirExists(UserDir) then
    DelTree(UserDir, True, True, True);
  if DirExists(ProgramDataDir) then
    DelTree(ProgramDataDir, True, True, True);
end;

var
  RemoveUserDataChosen: Boolean;

function InitializeUninstall(): Boolean;
var
  Response: Integer;
  Labels: TArrayOfString;
begin
  SetArrayLength(Labels, 3);
  Labels[0] := 'Remove ViPER4Windows' + #13#10 +
               'Keep my settings, presets, profiles, and logs.';
  Labels[1] := 'Remove ViPER4Windows and my data' + #13#10 +
               'Also delete settings, presets, profiles, and logs.';
  Labels[2] := 'Cancel';
  Response := TaskDialogMsgBox(
    'Uninstall ViPER4Windows',
    'The audio driver registration and the autostart shortcut will be ' +
    'cleaned up automatically. Choose whether to also remove your saved ' +
    'settings, presets, profiles, and logs.',
    mbConfirmation,
    MB_YESNOCANCEL,
    Labels,
    0);
  case Response of
    IDYES:
      begin
        RemoveUserDataChosen := False;
        Result := True;
      end;
    IDNO:
      begin
        RemoveUserDataChosen := True;
        Result := True;
      end;
  else
    Result := False;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then begin
    UnregisterAPODriver();
    RemoveAutostartShortcut();
    if RemoveUserDataChosen then
      RemoveUserData();
  end;
end;
