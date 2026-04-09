# ViPER4Windows

System-wide audio effects for Windows.

ViPER4Windows brings the legendary ViPER audio processing engine to Windows. It installs as a
Windows Audio Processing Object (APO) that hooks into the system audio pipeline, applies ViPER
effects in real-time on all audio output.

## Features

- FIR Equalizer with 10, 15, 25, or 31 bands
- ViPER Bass enhancement (Natural, Pure Bass, Subwoofer modes)
- ViPER Clarity (Natural, OZone, XHiFi modes)
- Tube Simulator and AnalogX warmth processing
- Spectrum Extension
- Field Surround with stereo widening, mid image, and depth control
- Differential Surround
- Headphone Surround+ (VHE) for virtual surround on headphones
- Reverberation with full room modeling
- FET Compressor
- Playback Gain Control (AGC)
- Auditory System Protection (CURe crossfeed)
- Speaker Optimization (speaker mode)
- ViPER-DDC device correction (.vdc profiles)
- Convolver with WAV/IRS impulse responses
- Dynamic System headphone compensation

## Requirements

- Windows 10 version 1809 or later (x64)
- Tested on Windows 10, theoretically supports Windows 11
- Visual Studio 2022 or later with C++ desktop workload (for building)
- Flutter SDK 3.11+ (for building the UI)
- Inno Setup 6 (for building the installer)

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

## Installation

- Download `ViPER4Windows_Setup.exe` from the [Releases](https://github.com/likelikeslike/ViPER4Windows/releases) page and install it
- A reboot is required after installation for the audio driver to load
- After reboot, open the app and register the audio endpoints on the Driver
Status page before using effects, a reboot may be required for registration to take effect

### Presets and Profiles

User data is stored in `%APPDATA%\ViPER4Windows\`. You can import and export:

- **Full presets** (JSON) capturing all effect settings at once
- **DDC profiles** (.vdc) for device-specific frequency correction
- **Convolver kernels** (WAV/IRS) for impulse response processing
- **EQ presets** and **Dynamic System presets** individually

Settings are saved automatically between sessions

## Uninstall

Run the uninstaller from Add/Remove Programs
The uninstaller removes all APO registrations, restores original audio endpoint settings,
and cleans up registry entries

Note that the data folder in `%APPDATA%\ViPER4Windows\` is not removed by the
uninstaller, you need to delete it manually

## Credits

- **ViPER4Android** by Zhuhang and ViPER520
- **ViPERDSP** reverse engineering by Martmists, Iscle, and likelikeslike ([ViPERDSP](https://github.com/likelikeslike/ViPERDSP))
