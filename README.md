# ViPER4Windows

System-wide audio effects for Windows.

ViPER4Windows brings the ViPER audio processing engine to Windows. It installs as a
Windows Audio Processing Object (APO) that hooks into the system audio pipeline and applies
ViPER effects in real time to all audio output, with a modern Fluent UI front-end.

## Features

### Audio Effects

Effects are grouped by the page they live on in the UI:

- **Output**
  - Output Volume / Channel Pan / Master Limiter

- **Equalizer**
  - FIR Equalizer (10 / 15 / 25 / 31 bands) with importable/exportable EQ presets
  - Dynamic EQ (per-band threshold / attack / release)

- **Tone**
  - ViPER Bass (Natural / Pure Bass / Subwoofer) and Bass Mono
  - Psychoacoustic Bass Enhancement
  - ViPER Clarity (Natural / OZone / XHiFi)
  - Tube Simulator and AnalogX warmth
  - Spectrum Extension (VSE)

- **Spatial**
  - Field Surround (stereo widening, mid image, depth)
  - Differential Surround
  - Stereo Imager (3-band width control)
  - Headphone Surround+ (VHE) virtual surround for headphones
  - Reverberation with full room modeling
  - Auditory System Protection (CURe crossfeed)

- **Dynamics**
  - Playback Gain Control (AGC) and LUFS targeting
  - FET Compressor and Multiband Compressor (5-band)
  - Dynamic System headphone virtualization
  - Speaker Optimization (speaker-only)
  - ViPER-DDC device correction (.vdc profiles)
  - Convolver with WAV/IRS impulse responses

### App Features

- Fluent design UI with a system-tray icon
- Per-device profiles with automatic switching on output change
- Cross-platform preset format shared with ViPER4Android and ViPER4Mac
- Preset, DDC, convolver kernel, EQ, and Dynamic System import/export
- Command-line interface (`v4w-cli`)
- Optional start-at-boot
- In-app driver status and per-endpoint APO registration

## Requirements

- Windows 10 version 1809 or later (x64)
- Tested on Windows 10, theoretically supports Windows 11
- Visual Studio 2022 or later with C++ desktop workload (for building)
- Flutter SDK 3.11+ (for building the UI)
- Inno Setup 6 (for building the installer)

## Installation

1. Download `ViPER4Windows_Setup.exe` from the [Releases](https://github.com/likelikeslike/ViPER4Windows/releases) page and install it
2. Reboot — required for the audio driver to load
3. Open the app, go to the **Driver Status** page, and register the audio endpoints you want ViPER to process
4. A reboot may be required for registration to take effect
5. Tune your effects and enjoy

## Building

Ensure `MSBuild`, `flutter`, and `ISCC` are on your PATH, then:

```bash
git clone --recursive https://github.com/likelikeslike/ViPER4Windows.git
cd ViPER4Windows
make installer
```

Build individual components:

```bash
make driver              # APO DLL only
make app                 # Flutter UI only
make installer           # Full build: driver + app + installer
```

## Presets and Profiles

User data is stored in `%APPDATA%\ViPER4Windows\`. You can import and export:

- **Full presets** (JSON) capturing all effect settings at once
- **DDC profiles** (.vdc) for device-specific frequency correction
- **Convolver kernels** (WAV/IRS) for impulse response processing
- **EQ presets** and **Dynamic System presets** individually

Presets use the **v2 grouped-JSON format** (`schemaVersion: 2`) shared with ViPER4Android and
ViPER4Mac — a preset saved on one platform loads identically on the others.

```json
{
  "schemaVersion": 2,
  "name": "My Preset",
  "equalizer": { "enable": true, "bandCount": 10, "bands": [3.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0] },
  "bass": { "enable": true, "mode": 0, "frequency": 55, "gain": 60 },
  "ddc": { "enable": false, "device": "" }
}
```

A preset holds a single unified effect state; it no longer stores separate headphone and speaker
copies. State is applied to an output through the per-device profile system, and settings are saved automatically.

## Command-line interface

ViPER4Windows installs a command-line tool, `v4w-cli`, alongside the app. Enable the
"Add v4w-cli to PATH" option during installation to call it from any terminal.

`v4w-cli` controls the **running** app: commands are applied live, so loading a preset or toggling
master updates both the UI and the audio in real time. If the app is not running, the command prints an error and exits non-zero.

```text
v4w-cli preset list                 List saved presets
v4w-cli preset load <name>          Load a preset
v4w-cli preset save <name>          Save current settings as a preset
v4w-cli preset delete <name>        Delete a preset
v4w-cli preset rename <old> <new>   Rename a preset
v4w-cli preset import <path>        Import a preset .json file

v4w-cli master                      Show master on/off state
v4w-cli master on|off               Enable or disable all effects
v4w-cli master toggle               Flip the master state

v4w-cli device current              Show the current output device
v4w-cli device list                 List known devices
v4w-cli device show [id]            Show a device's id, name, and type
v4w-cli device delete <id>          Delete a device's saved settings

v4w-cli status                      Show master, driver, APO, and device status
v4w-cli help                        Show usage
```

## Per-Device Profiles

Each audio output device keeps its **own** full effect profile. When you switch outputs, the app
automatically loads the incoming device's profile, so your speakers and each pair of headphones
remember their own tuning.

### How a device is identified

The active output is detected from the Windows Core Audio API (the default render endpoint), and
each device is keyed by its endpoint ID. The device's form factor (from its Windows properties)
determines whether it is treated as **headphone** or **speaker**.

### When profiles are saved and loaded

- **On app background / close-to-tray / quit**: the current settings are saved to the active device's profile.
- **First time a device is seen**: a profile is created automatically from the current settings.

### Managing profiles

Open the **Devices** page (or use `v4w-cli device ...`) to manage saved profiles: view the current
device, list known devices, or delete a device's saved settings.

## Uninstall

Run the uninstaller from Add/Remove Programs. It removes all APO registrations, restores the
original audio endpoint effect chains and `DisableProtectedAudioDG` value, deletes the start-at-boot
shortcut, and cleans up registry entries.

The data folder in `%APPDATA%\ViPER4Windows\` is not removed automatically; delete it manually if
you want to clear your presets and profiles.

## Credits

- **ViPER4Android** by Zhuhang and ViPER520
- **ViPERDSP** reverse engineering by Martmists, Iscle, and likelikeslike ([ViPERDSP](https://github.com/likelikeslike/ViPERDSP))
