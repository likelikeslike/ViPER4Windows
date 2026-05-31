import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:viper4windows/models/shared_params.dart';
import 'package:viper4windows/models/value_mappings.dart';
import 'package:viper4windows/services/bulk_data_service.dart';
import 'package:viper4windows/models/device_settings.dart';
import 'package:viper4windows/services/device_detection_service.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/profile_file_manager.dart';
import 'package:viper4windows/services/settings_service.dart';
import 'package:viper4windows/services/shared_memory_service.dart';

final _log = AppLogger('ViperState');

class ModeState {
  int mode = 0;

  int outputVolume = 11;
  int channelPan = 0;
  int limiter = 5;

  bool playbackGainEnabled = false;
  int playbackGainStrength = 0;
  int playbackGainMaxGain = 3;
  int playbackGainOutputThreshold = 3;

  bool fetCompressorEnabled = false;
  int fetCompressorThreshold = 100;
  int fetCompressorRatio = 100;
  bool fetCompressorAutoKnee = true;
  int fetCompressorKnee = 0;
  int fetCompressorKneeMulti = 0;
  bool fetCompressorAutoGain = true;
  int fetCompressorGain = 0;
  bool fetCompressorAutoAttack = true;
  int fetCompressorAttack = 20;
  int fetCompressorMaxAttack = 80;
  bool fetCompressorAutoRelease = true;
  int fetCompressorRelease = 50;
  int fetCompressorMaxRelease = 100;
  int fetCompressorCrest = 100;
  int fetCompressorAdapt = 50;
  bool fetCompressorNoClip = true;

  bool ddcEnabled = false;
  String ddcFilePath = '';

  bool spectrumExtensionEnabled = false;
  int spectrumExtensionBark = 9;
  int spectrumExtensionExciter = 0;

  bool equalizerEnabled = false;
  int equalizerBandCount = 10;
  List<double> equalizerBands = List.filled(10, 0.0);
  Map<int, List<double>> equalizerBandsMap = {10: List.filled(10, 0.0)};

  bool convolutionEnabled = false;
  String convolutionKernelPath = '';
  int convolutionCrossChannel = 0;

  bool fieldSurroundEnabled = false;
  int fieldSurroundWidening = 0;
  int fieldSurroundMidImage = 5;
  int fieldSurroundDepth = 0;

  bool diffSurroundEnabled = false;
  int diffSurroundDelay = 4;
  bool diffSurroundReverse = false;

  bool vheEnabled = false;
  int vheQuality = 0;

  bool reverberationEnabled = false;
  int reverberationRoomSize = 0;
  int reverberationRoomWidth = 0;
  int reverberationRoomDampening = 0;
  int reverberationWetSignal = 0;
  int reverberationDrySignal = 50;

  bool dynamicSystemEnabled = false;
  int dynamicSystemDevice = 0;
  int dynamicSystemStrength = 50;
  int dsXLow = 100;
  int dsXHigh = 5600;
  int dsYLow = 40;
  int dsYHigh = 80;
  int dsSideGainLow = 50;
  int dsSideGainHigh = 50;

  bool tubeSimulatorEnabled = false;

  bool viperBassEnabled = false;
  int viperBassMode = 0;
  int viperBassFrequency = 55;
  int viperBassGain = 0;
  bool viperBassAntiPop = true;

  bool viperBassMonoEnabled = false;
  int viperBassMonoMode = 0;
  int viperBassMonoFrequency = 55;
  int viperBassMonoGain = 0;
  bool viperBassMonoAntiPop = true;

  bool viperClarityEnabled = false;
  int viperClarityMode = 0;
  int viperClarityGain = 1;

  bool cureEnabled = false;
  int cureCrossfeedStrength = 0;

  bool analogXEnabled = false;
  int analogXMode = 0;

  bool speakerCorrectionEnabled = false;

  void copyFrom(ModeState other) {
    mode = other.mode;

    outputVolume = other.outputVolume;
    channelPan = other.channelPan;
    limiter = other.limiter;

    playbackGainEnabled = other.playbackGainEnabled;
    playbackGainStrength = other.playbackGainStrength;
    playbackGainMaxGain = other.playbackGainMaxGain;
    playbackGainOutputThreshold = other.playbackGainOutputThreshold;

    fetCompressorEnabled = other.fetCompressorEnabled;
    fetCompressorThreshold = other.fetCompressorThreshold;
    fetCompressorRatio = other.fetCompressorRatio;
    fetCompressorAutoKnee = other.fetCompressorAutoKnee;
    fetCompressorKnee = other.fetCompressorKnee;
    fetCompressorKneeMulti = other.fetCompressorKneeMulti;
    fetCompressorAutoGain = other.fetCompressorAutoGain;
    fetCompressorGain = other.fetCompressorGain;
    fetCompressorAutoAttack = other.fetCompressorAutoAttack;
    fetCompressorAttack = other.fetCompressorAttack;
    fetCompressorMaxAttack = other.fetCompressorMaxAttack;
    fetCompressorAutoRelease = other.fetCompressorAutoRelease;
    fetCompressorRelease = other.fetCompressorRelease;
    fetCompressorMaxRelease = other.fetCompressorMaxRelease;
    fetCompressorCrest = other.fetCompressorCrest;
    fetCompressorAdapt = other.fetCompressorAdapt;
    fetCompressorNoClip = other.fetCompressorNoClip;

    ddcEnabled = other.ddcEnabled;
    ddcFilePath = other.ddcFilePath;

    spectrumExtensionEnabled = other.spectrumExtensionEnabled;
    spectrumExtensionBark = other.spectrumExtensionBark;
    spectrumExtensionExciter = other.spectrumExtensionExciter;

    equalizerEnabled = other.equalizerEnabled;
    equalizerBandCount = other.equalizerBandCount;
    equalizerBands = List<double>.from(other.equalizerBands);
    equalizerBandsMap = other.equalizerBandsMap.map(
      (k, v) => MapEntry(k, List<double>.from(v)),
    );

    convolutionEnabled = other.convolutionEnabled;
    convolutionKernelPath = other.convolutionKernelPath;
    convolutionCrossChannel = other.convolutionCrossChannel;

    fieldSurroundEnabled = other.fieldSurroundEnabled;
    fieldSurroundWidening = other.fieldSurroundWidening;
    fieldSurroundMidImage = other.fieldSurroundMidImage;
    fieldSurroundDepth = other.fieldSurroundDepth;

    diffSurroundEnabled = other.diffSurroundEnabled;
    diffSurroundDelay = other.diffSurroundDelay;
    diffSurroundReverse = other.diffSurroundReverse;

    vheEnabled = other.vheEnabled;
    vheQuality = other.vheQuality;

    reverberationEnabled = other.reverberationEnabled;
    reverberationRoomSize = other.reverberationRoomSize;
    reverberationRoomWidth = other.reverberationRoomWidth;
    reverberationRoomDampening = other.reverberationRoomDampening;
    reverberationWetSignal = other.reverberationWetSignal;
    reverberationDrySignal = other.reverberationDrySignal;

    dynamicSystemEnabled = other.dynamicSystemEnabled;
    dynamicSystemDevice = other.dynamicSystemDevice;
    dynamicSystemStrength = other.dynamicSystemStrength;
    dsXLow = other.dsXLow;
    dsXHigh = other.dsXHigh;
    dsYLow = other.dsYLow;
    dsYHigh = other.dsYHigh;
    dsSideGainLow = other.dsSideGainLow;
    dsSideGainHigh = other.dsSideGainHigh;

    tubeSimulatorEnabled = other.tubeSimulatorEnabled;

    viperBassEnabled = other.viperBassEnabled;
    viperBassMode = other.viperBassMode;
    viperBassFrequency = other.viperBassFrequency;
    viperBassGain = other.viperBassGain;
    viperBassAntiPop = other.viperBassAntiPop;

    viperBassMonoEnabled = other.viperBassMonoEnabled;
    viperBassMonoMode = other.viperBassMonoMode;
    viperBassMonoFrequency = other.viperBassMonoFrequency;
    viperBassMonoGain = other.viperBassMonoGain;
    viperBassMonoAntiPop = other.viperBassMonoAntiPop;

    viperClarityEnabled = other.viperClarityEnabled;
    viperClarityMode = other.viperClarityMode;
    viperClarityGain = other.viperClarityGain;

    cureEnabled = other.cureEnabled;
    cureCrossfeedStrength = other.cureCrossfeedStrength;

    analogXEnabled = other.analogXEnabled;
    analogXMode = other.analogXMode;

    speakerCorrectionEnabled = other.speakerCorrectionEnabled;
  }

  ModeState clone() {
    final c = ModeState();
    c.copyFrom(this);
    return c;
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,

    'outputVolume': outputVolume,
    'channelPan': channelPan,
    'limiter': limiter,

    'playbackGainEnabled': playbackGainEnabled,
    'playbackGainStrength': playbackGainStrength,
    'playbackGainMaxGain': playbackGainMaxGain,
    'playbackGainOutputThreshold': playbackGainOutputThreshold,

    'fetCompressorEnabled': fetCompressorEnabled,
    'fetCompressorThreshold': fetCompressorThreshold,
    'fetCompressorRatio': fetCompressorRatio,
    'fetCompressorAutoKnee': fetCompressorAutoKnee,
    'fetCompressorKnee': fetCompressorKnee,
    'fetCompressorKneeMulti': fetCompressorKneeMulti,
    'fetCompressorAutoGain': fetCompressorAutoGain,
    'fetCompressorGain': fetCompressorGain,
    'fetCompressorAutoAttack': fetCompressorAutoAttack,
    'fetCompressorAttack': fetCompressorAttack,
    'fetCompressorMaxAttack': fetCompressorMaxAttack,
    'fetCompressorAutoRelease': fetCompressorAutoRelease,
    'fetCompressorRelease': fetCompressorRelease,
    'fetCompressorMaxRelease': fetCompressorMaxRelease,
    'fetCompressorCrest': fetCompressorCrest,
    'fetCompressorAdapt': fetCompressorAdapt,
    'fetCompressorNoClip': fetCompressorNoClip,

    'ddcEnabled': ddcEnabled,
    'ddcFilePath': ddcFilePath,

    'spectrumExtensionEnabled': spectrumExtensionEnabled,
    'spectrumExtensionBark': spectrumExtensionBark,
    'spectrumExtensionExciter': spectrumExtensionExciter,

    'equalizerEnabled': equalizerEnabled,
    'equalizerBandCount': equalizerBandCount,
    'equalizerBands': equalizerBands,
    'equalizerBandsMap': equalizerBandsMap.map(
      (k, v) => MapEntry(k.toString(), v),
    ),

    'convolutionEnabled': convolutionEnabled,
    'convolutionKernelPath': convolutionKernelPath,
    'convolutionCrossChannel': convolutionCrossChannel,

    'fieldSurroundEnabled': fieldSurroundEnabled,
    'fieldSurroundWidening': fieldSurroundWidening,
    'fieldSurroundMidImage': fieldSurroundMidImage,
    'fieldSurroundDepth': fieldSurroundDepth,

    'diffSurroundEnabled': diffSurroundEnabled,
    'diffSurroundDelay': diffSurroundDelay,
    'diffSurroundReverse': diffSurroundReverse,

    'vheEnabled': vheEnabled,
    'vheQuality': vheQuality,

    'reverberationEnabled': reverberationEnabled,
    'reverberationRoomSize': reverberationRoomSize,
    'reverberationRoomWidth': reverberationRoomWidth,
    'reverberationRoomDampening': reverberationRoomDampening,
    'reverberationWetSignal': reverberationWetSignal,
    'reverberationDrySignal': reverberationDrySignal,

    'dynamicSystemEnabled': dynamicSystemEnabled,
    'dynamicSystemDevice': dynamicSystemDevice,
    'dynamicSystemStrength': dynamicSystemStrength,
    'dsXLow': dsXLow,
    'dsXHigh': dsXHigh,
    'dsYLow': dsYLow,
    'dsYHigh': dsYHigh,
    'dsSideGainLow': dsSideGainLow,
    'dsSideGainHigh': dsSideGainHigh,

    'tubeSimulatorEnabled': tubeSimulatorEnabled,

    'viperBassEnabled': viperBassEnabled,
    'viperBassMode': viperBassMode,
    'viperBassFrequency': viperBassFrequency,
    'viperBassGain': viperBassGain,
    'viperBassAntiPop': viperBassAntiPop,

    'viperBassMonoEnabled': viperBassMonoEnabled,
    'viperBassMonoMode': viperBassMonoMode,
    'viperBassMonoFrequency': viperBassMonoFrequency,
    'viperBassMonoGain': viperBassMonoGain,
    'viperBassMonoAntiPop': viperBassMonoAntiPop,

    'viperClarityEnabled': viperClarityEnabled,
    'viperClarityMode': viperClarityMode,
    'viperClarityGain': viperClarityGain,

    'cureEnabled': cureEnabled,
    'cureCrossfeedStrength': cureCrossfeedStrength,

    'analogXEnabled': analogXEnabled,
    'analogXMode': analogXMode,

    'speakerCorrectionEnabled': speakerCorrectionEnabled,
  };

  void loadFromJson(Map<String, dynamic> j) {
    mode = j['mode'] as int? ?? mode;
    outputVolume = j['outputVolume'] as int? ?? outputVolume;
    channelPan = j['channelPan'] as int? ?? channelPan;
    limiter = j['limiter'] as int? ?? limiter;
    playbackGainEnabled =
        j['playbackGainEnabled'] as bool? ?? playbackGainEnabled;
    playbackGainStrength =
        j['playbackGainStrength'] as int? ?? playbackGainStrength;
    playbackGainMaxGain =
        j['playbackGainMaxGain'] as int? ?? playbackGainMaxGain;
    playbackGainOutputThreshold =
        j['playbackGainOutputThreshold'] as int? ?? playbackGainOutputThreshold;
    fetCompressorEnabled =
        j['fetCompressorEnabled'] as bool? ?? fetCompressorEnabled;
    fetCompressorThreshold =
        j['fetCompressorThreshold'] as int? ?? fetCompressorThreshold;
    fetCompressorRatio = j['fetCompressorRatio'] as int? ?? fetCompressorRatio;
    fetCompressorAutoKnee =
        j['fetCompressorAutoKnee'] as bool? ?? fetCompressorAutoKnee;
    fetCompressorKnee = j['fetCompressorKnee'] as int? ?? fetCompressorKnee;
    fetCompressorKneeMulti =
        j['fetCompressorKneeMulti'] as int? ?? fetCompressorKneeMulti;
    fetCompressorAutoGain =
        j['fetCompressorAutoGain'] as bool? ?? fetCompressorAutoGain;
    fetCompressorGain = j['fetCompressorGain'] as int? ?? fetCompressorGain;
    fetCompressorAutoAttack =
        j['fetCompressorAutoAttack'] as bool? ?? fetCompressorAutoAttack;
    fetCompressorAttack =
        j['fetCompressorAttack'] as int? ?? fetCompressorAttack;
    fetCompressorMaxAttack =
        j['fetCompressorMaxAttack'] as int? ?? fetCompressorMaxAttack;
    fetCompressorAutoRelease =
        j['fetCompressorAutoRelease'] as bool? ?? fetCompressorAutoRelease;
    fetCompressorRelease =
        j['fetCompressorRelease'] as int? ?? fetCompressorRelease;
    fetCompressorMaxRelease =
        j['fetCompressorMaxRelease'] as int? ?? fetCompressorMaxRelease;
    fetCompressorCrest = j['fetCompressorCrest'] as int? ?? fetCompressorCrest;
    fetCompressorAdapt = j['fetCompressorAdapt'] as int? ?? fetCompressorAdapt;
    fetCompressorNoClip =
        j['fetCompressorNoClip'] as bool? ?? fetCompressorNoClip;
    ddcEnabled = j['ddcEnabled'] as bool? ?? ddcEnabled;
    ddcFilePath = j['ddcFilePath'] as String? ?? ddcFilePath;
    spectrumExtensionEnabled =
        j['spectrumExtensionEnabled'] as bool? ?? spectrumExtensionEnabled;
    spectrumExtensionBark =
        j['spectrumExtensionBark'] as int? ?? spectrumExtensionBark;
    spectrumExtensionExciter =
        j['spectrumExtensionExciter'] as int? ?? spectrumExtensionExciter;
    equalizerEnabled = j['equalizerEnabled'] as bool? ?? equalizerEnabled;
    equalizerBandCount = j['equalizerBandCount'] as int? ?? equalizerBandCount;
    if (j['equalizerBands'] is List) {
      equalizerBands = (j['equalizerBands'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }
    if (j['equalizerBandsMap'] is Map) {
      equalizerBandsMap = (j['equalizerBandsMap'] as Map).map(
        (k, v) => MapEntry(
          int.parse(k.toString()),
          (v as List).map((e) => (e as num).toDouble()).toList(),
        ),
      );
    }
    convolutionEnabled = j['convolutionEnabled'] as bool? ?? convolutionEnabled;
    convolutionKernelPath =
        j['convolutionKernelPath'] as String? ?? convolutionKernelPath;
    convolutionCrossChannel =
        j['convolutionCrossChannel'] as int? ?? convolutionCrossChannel;
    fieldSurroundEnabled =
        j['fieldSurroundEnabled'] as bool? ?? fieldSurroundEnabled;
    fieldSurroundWidening =
        j['fieldSurroundWidening'] as int? ?? fieldSurroundWidening;
    fieldSurroundMidImage =
        j['fieldSurroundMidImage'] as int? ?? fieldSurroundMidImage;
    fieldSurroundDepth = j['fieldSurroundDepth'] as int? ?? fieldSurroundDepth;
    diffSurroundEnabled =
        j['diffSurroundEnabled'] as bool? ?? diffSurroundEnabled;
    diffSurroundDelay = j['diffSurroundDelay'] as int? ?? diffSurroundDelay;
    diffSurroundReverse =
        j['diffSurroundReverse'] as bool? ?? diffSurroundReverse;
    vheEnabled = j['vheEnabled'] as bool? ?? vheEnabled;
    vheQuality = j['vheQuality'] as int? ?? vheQuality;
    reverberationEnabled =
        j['reverberationEnabled'] as bool? ?? reverberationEnabled;
    reverberationRoomSize =
        j['reverberationRoomSize'] as int? ?? reverberationRoomSize;
    reverberationRoomWidth =
        j['reverberationRoomWidth'] as int? ?? reverberationRoomWidth;
    reverberationRoomDampening =
        j['reverberationRoomDampening'] as int? ?? reverberationRoomDampening;
    reverberationWetSignal =
        j['reverberationWetSignal'] as int? ?? reverberationWetSignal;
    reverberationDrySignal =
        j['reverberationDrySignal'] as int? ?? reverberationDrySignal;
    dynamicSystemEnabled =
        j['dynamicSystemEnabled'] as bool? ?? dynamicSystemEnabled;
    dynamicSystemDevice =
        j['dynamicSystemDevice'] as int? ?? dynamicSystemDevice;
    dynamicSystemStrength =
        j['dynamicSystemStrength'] as int? ?? dynamicSystemStrength;
    dsXLow = j['dsXLow'] as int? ?? dsXLow;
    dsXHigh = j['dsXHigh'] as int? ?? dsXHigh;
    dsYLow = j['dsYLow'] as int? ?? dsYLow;
    dsYHigh = j['dsYHigh'] as int? ?? dsYHigh;
    dsSideGainLow = j['dsSideGainLow'] as int? ?? dsSideGainLow;
    dsSideGainHigh = j['dsSideGainHigh'] as int? ?? dsSideGainHigh;
    tubeSimulatorEnabled =
        j['tubeSimulatorEnabled'] as bool? ?? tubeSimulatorEnabled;
    viperBassEnabled = j['viperBassEnabled'] as bool? ?? viperBassEnabled;
    viperBassMode = j['viperBassMode'] as int? ?? viperBassMode;
    viperBassFrequency = j['viperBassFrequency'] as int? ?? viperBassFrequency;
    viperBassGain = j['viperBassGain'] as int? ?? viperBassGain;
    viperBassAntiPop = j['viperBassAntiPop'] as bool? ?? viperBassAntiPop;
    viperBassMonoEnabled =
        j['viperBassMonoEnabled'] as bool? ?? viperBassMonoEnabled;
    viperBassMonoMode = j['viperBassMonoMode'] as int? ?? viperBassMonoMode;
    viperBassMonoFrequency =
        j['viperBassMonoFrequency'] as int? ?? viperBassMonoFrequency;
    viperBassMonoGain = j['viperBassMonoGain'] as int? ?? viperBassMonoGain;
    viperBassMonoAntiPop =
        j['viperBassMonoAntiPop'] as bool? ?? viperBassMonoAntiPop;
    viperClarityEnabled =
        j['viperClarityEnabled'] as bool? ?? viperClarityEnabled;
    viperClarityMode = j['viperClarityMode'] as int? ?? viperClarityMode;
    viperClarityGain = j['viperClarityGain'] as int? ?? viperClarityGain;
    cureEnabled = j['cureEnabled'] as bool? ?? cureEnabled;
    cureCrossfeedStrength =
        j['cureCrossfeedStrength'] as int? ?? cureCrossfeedStrength;
    analogXEnabled = j['analogXEnabled'] as bool? ?? analogXEnabled;
    analogXMode = j['analogXMode'] as int? ?? analogXMode;
    speakerCorrectionEnabled =
        j['speakerCorrectionEnabled'] as bool? ?? speakerCorrectionEnabled;
  }
}

class ViperState extends ChangeNotifier {
  final SharedMemoryService _shm;
  final SettingsService _settings;
  Timer? _statusTimer;
  Timer? _saveTimer;
  bool _suppressPush = false;
  final DeviceDetectionService _deviceDetection = DeviceDetectionService();
  int _activeDeviceType = 0;
  final ProfileFileManager _fileManager = ProfileFileManager();
  final BulkDataService _bulk = BulkDataService();
  List<String> _ddcFiles = [];
  List<String> _kernelFiles = [];
  List<String> _presetFiles = [];
  List<String> _eqPresetFiles = [];
  List<String> _dsPresetFiles = [];

  final ModeState _headphoneState = ModeState();
  final ModeState _speakerState = ModeState();
  final ModeState _active = ModeState();

  bool _masterEnabled = true;
  int _fxType = 0;
  String _currentDeviceId = '';
  String _currentDeviceName = '';

  bool _driverInstalled = false;
  bool _apoProcessing = false;
  int _apoSampleRate = 0;
  String _apoVersion = '';
  String _apoArch = '';

  ViperState({
    required SharedMemoryService shm,
    required SettingsService settings,
  }) : _shm = shm,
       _settings = settings {
    _shm.open();
    _bulk.open();
    final device = _deviceDetection.detectActiveDevice();
    _activeDeviceType = device.isHeadphone ? 0 : 1;
    _fxType = _activeDeviceType;
    _currentDeviceId = device.id;
    _currentDeviceName = device.name;
    _log.info(
      'Init: device=${device.isHeadphone ? "headphone" : "speaker"}, name=${device.name}',
    );
    refreshFileLists();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshApoStatus(),
    );
    _refreshApoStatus();
  }

  bool get masterEnabled => _masterEnabled;
  int get fxType => _fxType;
  int get activeDeviceType => _activeDeviceType;
  String get currentDeviceId => _currentDeviceId;
  String get currentDeviceName => _currentDeviceName;

  int get outputVolume => _active.outputVolume;
  int get channelPan => _active.channelPan;
  int get limiter => _active.limiter;

  bool get playbackGainEnabled => _active.playbackGainEnabled;
  int get playbackGainStrength => _active.playbackGainStrength;
  int get playbackGainMaxGain => _active.playbackGainMaxGain;
  int get playbackGainOutputThreshold => _active.playbackGainOutputThreshold;

  bool get fetCompressorEnabled => _active.fetCompressorEnabled;
  int get fetCompressorThreshold => _active.fetCompressorThreshold;
  int get fetCompressorRatio => _active.fetCompressorRatio;
  bool get fetCompressorAutoKnee => _active.fetCompressorAutoKnee;
  int get fetCompressorKnee => _active.fetCompressorKnee;
  int get fetCompressorKneeMulti => _active.fetCompressorKneeMulti;
  bool get fetCompressorAutoGain => _active.fetCompressorAutoGain;
  int get fetCompressorGain => _active.fetCompressorGain;
  bool get fetCompressorAutoAttack => _active.fetCompressorAutoAttack;
  int get fetCompressorAttack => _active.fetCompressorAttack;
  int get fetCompressorMaxAttack => _active.fetCompressorMaxAttack;
  bool get fetCompressorAutoRelease => _active.fetCompressorAutoRelease;
  int get fetCompressorRelease => _active.fetCompressorRelease;
  int get fetCompressorMaxRelease => _active.fetCompressorMaxRelease;
  int get fetCompressorCrest => _active.fetCompressorCrest;
  int get fetCompressorAdapt => _active.fetCompressorAdapt;
  bool get fetCompressorNoClip => _active.fetCompressorNoClip;

  bool get ddcEnabled => _active.ddcEnabled;
  String get ddcFilePath => _active.ddcFilePath;

  bool get spectrumExtensionEnabled => _active.spectrumExtensionEnabled;
  int get spectrumExtensionBark => _active.spectrumExtensionBark;
  int get spectrumExtensionExciter => _active.spectrumExtensionExciter;

  bool get equalizerEnabled => _active.equalizerEnabled;
  int get equalizerBandCount => _active.equalizerBandCount;
  List<double> get equalizerBands => _active.equalizerBands;
  Map<int, List<double>> get equalizerBandsMap => _active.equalizerBandsMap;

  bool get convolutionEnabled => _active.convolutionEnabled;
  String get convolutionKernelPath => _active.convolutionKernelPath;
  int get convolutionCrossChannel => _active.convolutionCrossChannel;

  bool get fieldSurroundEnabled => _active.fieldSurroundEnabled;
  int get fieldSurroundWidening => _active.fieldSurroundWidening;
  int get fieldSurroundMidImage => _active.fieldSurroundMidImage;
  int get fieldSurroundDepth => _active.fieldSurroundDepth;

  bool get diffSurroundEnabled => _active.diffSurroundEnabled;
  int get diffSurroundDelay => _active.diffSurroundDelay;
  bool get diffSurroundReverse => _active.diffSurroundReverse;

  bool get vheEnabled => _active.vheEnabled;
  int get vheQuality => _active.vheQuality;

  bool get reverberationEnabled => _active.reverberationEnabled;
  int get reverberationRoomSize => _active.reverberationRoomSize;
  int get reverberationRoomWidth => _active.reverberationRoomWidth;
  int get reverberationRoomDampening => _active.reverberationRoomDampening;
  int get reverberationWetSignal => _active.reverberationWetSignal;
  int get reverberationDrySignal => _active.reverberationDrySignal;

  bool get dynamicSystemEnabled => _active.dynamicSystemEnabled;
  int get dynamicSystemDevice => _active.dynamicSystemDevice;
  int get dynamicSystemStrength => _active.dynamicSystemStrength;
  int get dsXLow => _active.dsXLow;
  int get dsXHigh => _active.dsXHigh;
  int get dsYLow => _active.dsYLow;
  int get dsYHigh => _active.dsYHigh;
  int get dsSideGainLow => _active.dsSideGainLow;
  int get dsSideGainHigh => _active.dsSideGainHigh;

  bool get tubeSimulatorEnabled => _active.tubeSimulatorEnabled;

  bool get viperBassEnabled => _active.viperBassEnabled;
  int get viperBassMode => _active.viperBassMode;
  int get viperBassFrequency => _active.viperBassFrequency;
  int get viperBassGain => _active.viperBassGain;
  bool get viperBassAntiPop => _active.viperBassAntiPop;

  bool get viperBassMonoEnabled => _active.viperBassMonoEnabled;
  int get viperBassMonoMode => _active.viperBassMonoMode;
  int get viperBassMonoFrequency => _active.viperBassMonoFrequency;
  int get viperBassMonoGain => _active.viperBassMonoGain;
  bool get viperBassMonoAntiPop => _active.viperBassMonoAntiPop;

  bool get viperClarityEnabled => _active.viperClarityEnabled;
  int get viperClarityMode => _active.viperClarityMode;
  int get viperClarityGain => _active.viperClarityGain;

  bool get cureEnabled => _active.cureEnabled;
  int get cureCrossfeedStrength => _active.cureCrossfeedStrength;

  bool get analogXEnabled => _active.analogXEnabled;
  int get analogXMode => _active.analogXMode;

  bool get speakerCorrectionEnabled => _active.speakerCorrectionEnabled;

  bool get apoConnected => _driverInstalled;
  bool get apoProcessing => _apoProcessing;
  int get apoSampleRate => _apoSampleRate;
  String get apoVersion => _apoVersion;
  String get apoArch => _apoArch;
  List<String> get ddcFiles => _ddcFiles;
  List<String> get kernelFiles => _kernelFiles;
  List<String> get presetFiles => _presetFiles;
  List<String> get eqPresetFiles => _eqPresetFiles;
  List<String> get dsPresetFiles => _dsPresetFiles;

  set masterEnabled(bool v) {
    if (_masterEnabled == v) return;
    _log.info('Master ${v ? "enabled" : "disabled"}');
    _masterEnabled = v;
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set outputVolume(int v) =>
      _set(() => _active.outputVolume = v, _active.outputVolume != v);
  set channelPan(int v) =>
      _set(() => _active.channelPan = v, _active.channelPan != v);
  set limiter(int v) => _set(() => _active.limiter = v, _active.limiter != v);

  set playbackGainEnabled(bool v) => _set(
    () => _active.playbackGainEnabled = v,
    _active.playbackGainEnabled != v,
  );
  set playbackGainStrength(int v) => _set(
    () => _active.playbackGainStrength = v,
    _active.playbackGainStrength != v,
  );
  set playbackGainMaxGain(int v) => _set(
    () => _active.playbackGainMaxGain = v,
    _active.playbackGainMaxGain != v,
  );
  set playbackGainOutputThreshold(int v) => _set(
    () => _active.playbackGainOutputThreshold = v,
    _active.playbackGainOutputThreshold != v,
  );

  set fetCompressorEnabled(bool v) => _set(
    () => _active.fetCompressorEnabled = v,
    _active.fetCompressorEnabled != v,
  );
  set fetCompressorThreshold(int v) => _set(
    () => _active.fetCompressorThreshold = v,
    _active.fetCompressorThreshold != v,
  );
  set fetCompressorRatio(int v) => _set(
    () => _active.fetCompressorRatio = v,
    _active.fetCompressorRatio != v,
  );
  set fetCompressorAutoKnee(bool v) => _set(
    () => _active.fetCompressorAutoKnee = v,
    _active.fetCompressorAutoKnee != v,
  );
  set fetCompressorKnee(int v) =>
      _set(() => _active.fetCompressorKnee = v, _active.fetCompressorKnee != v);
  set fetCompressorKneeMulti(int v) => _set(
    () => _active.fetCompressorKneeMulti = v,
    _active.fetCompressorKneeMulti != v,
  );
  set fetCompressorAutoGain(bool v) => _set(
    () => _active.fetCompressorAutoGain = v,
    _active.fetCompressorAutoGain != v,
  );
  set fetCompressorGain(int v) =>
      _set(() => _active.fetCompressorGain = v, _active.fetCompressorGain != v);
  set fetCompressorAutoAttack(bool v) => _set(
    () => _active.fetCompressorAutoAttack = v,
    _active.fetCompressorAutoAttack != v,
  );
  set fetCompressorAttack(int v) => _set(
    () => _active.fetCompressorAttack = v,
    _active.fetCompressorAttack != v,
  );
  set fetCompressorMaxAttack(int v) => _set(
    () => _active.fetCompressorMaxAttack = v,
    _active.fetCompressorMaxAttack != v,
  );
  set fetCompressorAutoRelease(bool v) => _set(
    () => _active.fetCompressorAutoRelease = v,
    _active.fetCompressorAutoRelease != v,
  );
  set fetCompressorRelease(int v) => _set(
    () => _active.fetCompressorRelease = v,
    _active.fetCompressorRelease != v,
  );
  set fetCompressorMaxRelease(int v) => _set(
    () => _active.fetCompressorMaxRelease = v,
    _active.fetCompressorMaxRelease != v,
  );
  set fetCompressorCrest(int v) => _set(
    () => _active.fetCompressorCrest = v,
    _active.fetCompressorCrest != v,
  );
  set fetCompressorAdapt(int v) => _set(
    () => _active.fetCompressorAdapt = v,
    _active.fetCompressorAdapt != v,
  );
  set fetCompressorNoClip(bool v) => _set(
    () => _active.fetCompressorNoClip = v,
    _active.fetCompressorNoClip != v,
  );

  set ddcEnabled(bool v) {
    if (_active.ddcEnabled == v) return;
    _active.ddcEnabled = v;
    if (v && _active.ddcFilePath.isNotEmpty) {
      final path = _fileManager.filePath(
        _active.ddcFilePath,
        ProfileFileType.ddc,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadDdcFile(Uint8List.fromList(bytes));
        _log.info('DDC loaded: ${_active.ddcFilePath}');
      } catch (e) {
        _log.error('DDC load failed: $e');
      }
    }
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set ddcFilePath(String v) =>
      _set(() => _active.ddcFilePath = v, _active.ddcFilePath != v);

  set spectrumExtensionEnabled(bool v) => _set(
    () => _active.spectrumExtensionEnabled = v,
    _active.spectrumExtensionEnabled != v,
  );
  set spectrumExtensionBark(int v) => _set(
    () => _active.spectrumExtensionBark = v,
    _active.spectrumExtensionBark != v,
  );
  set spectrumExtensionExciter(int v) => _set(
    () => _active.spectrumExtensionExciter = v,
    _active.spectrumExtensionExciter != v,
  );

  set equalizerEnabled(bool v) =>
      _set(() => _active.equalizerEnabled = v, _active.equalizerEnabled != v);
  set equalizerBandCount(int v) => _set(
    () => _active.equalizerBandCount = v,
    _active.equalizerBandCount != v,
  );

  set equalizerBands(List<double> v) {
    _active.equalizerBands = v;
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set convolutionEnabled(bool v) {
    if (_active.convolutionEnabled == v) return;
    _active.convolutionEnabled = v;
    if (v && _active.convolutionKernelPath.isNotEmpty) {
      final path = _fileManager.filePath(
        _active.convolutionKernelPath,
        ProfileFileType.kernel,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadConvolverKernel(
          Uint8List.fromList(bytes),
          _active.convolutionKernelPath,
        );
        _log.info('Convolver loaded: ${_active.convolutionKernelPath}');
      } catch (e) {
        _log.error('Convolver load failed: $e');
      }
    }
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set convolutionKernelPath(String v) => _set(
    () => _active.convolutionKernelPath = v,
    _active.convolutionKernelPath != v,
  );
  set convolutionCrossChannel(int v) => _set(
    () => _active.convolutionCrossChannel = v,
    _active.convolutionCrossChannel != v,
  );

  set fieldSurroundEnabled(bool v) => _set(
    () => _active.fieldSurroundEnabled = v,
    _active.fieldSurroundEnabled != v,
  );
  set fieldSurroundWidening(int v) => _set(
    () => _active.fieldSurroundWidening = v,
    _active.fieldSurroundWidening != v,
  );
  set fieldSurroundMidImage(int v) => _set(
    () => _active.fieldSurroundMidImage = v,
    _active.fieldSurroundMidImage != v,
  );
  set fieldSurroundDepth(int v) => _set(
    () => _active.fieldSurroundDepth = v,
    _active.fieldSurroundDepth != v,
  );

  set diffSurroundEnabled(bool v) => _set(
    () => _active.diffSurroundEnabled = v,
    _active.diffSurroundEnabled != v,
  );
  set diffSurroundDelay(int v) =>
      _set(() => _active.diffSurroundDelay = v, _active.diffSurroundDelay != v);
  set diffSurroundReverse(bool v) => _set(
    () => _active.diffSurroundReverse = v,
    _active.diffSurroundReverse != v,
  );

  set vheEnabled(bool v) =>
      _set(() => _active.vheEnabled = v, _active.vheEnabled != v);
  set vheQuality(int v) =>
      _set(() => _active.vheQuality = v, _active.vheQuality != v);

  set reverberationEnabled(bool v) => _set(
    () => _active.reverberationEnabled = v,
    _active.reverberationEnabled != v,
  );
  set reverberationRoomSize(int v) => _set(
    () => _active.reverberationRoomSize = v,
    _active.reverberationRoomSize != v,
  );
  set reverberationRoomWidth(int v) => _set(
    () => _active.reverberationRoomWidth = v,
    _active.reverberationRoomWidth != v,
  );
  set reverberationRoomDampening(int v) => _set(
    () => _active.reverberationRoomDampening = v,
    _active.reverberationRoomDampening != v,
  );
  set reverberationWetSignal(int v) => _set(
    () => _active.reverberationWetSignal = v,
    _active.reverberationWetSignal != v,
  );
  set reverberationDrySignal(int v) => _set(
    () => _active.reverberationDrySignal = v,
    _active.reverberationDrySignal != v,
  );

  set dynamicSystemEnabled(bool v) => _set(
    () => _active.dynamicSystemEnabled = v,
    _active.dynamicSystemEnabled != v,
  );
  set dynamicSystemDevice(int v) {
    if (_active.dynamicSystemDevice == v) return;
    _active.dynamicSystemDevice = v;
    if (v >= 0 && v < ValueMappings.dynamicSystemDevices.length) {
      final parts = ValueMappings.dynamicSystemDevices[v].$2.split(';');
      if (parts.length == 6) {
        _active.dsXLow = int.parse(parts[0]);
        _active.dsXHigh = int.parse(parts[1]);
        _active.dsYLow = int.parse(parts[2]);
        _active.dsYHigh = int.parse(parts[3]);
        _active.dsSideGainLow = int.parse(parts[4]);
        _active.dsSideGainHigh = int.parse(parts[5]);
      }
    }
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set dynamicSystemStrength(int v) => _set(
    () => _active.dynamicSystemStrength = v,
    _active.dynamicSystemStrength != v,
  );
  set dsXLow(int v) => _set(() => _active.dsXLow = v, _active.dsXLow != v);
  set dsXHigh(int v) => _set(() => _active.dsXHigh = v, _active.dsXHigh != v);
  set dsYLow(int v) => _set(() => _active.dsYLow = v, _active.dsYLow != v);
  set dsYHigh(int v) => _set(() => _active.dsYHigh = v, _active.dsYHigh != v);
  set dsSideGainLow(int v) =>
      _set(() => _active.dsSideGainLow = v, _active.dsSideGainLow != v);
  set dsSideGainHigh(int v) =>
      _set(() => _active.dsSideGainHigh = v, _active.dsSideGainHigh != v);

  set tubeSimulatorEnabled(bool v) => _set(
    () => _active.tubeSimulatorEnabled = v,
    _active.tubeSimulatorEnabled != v,
  );

  set viperBassEnabled(bool v) =>
      _set(() => _active.viperBassEnabled = v, _active.viperBassEnabled != v);
  set viperBassMode(int v) =>
      _set(() => _active.viperBassMode = v, _active.viperBassMode != v);
  set viperBassFrequency(int v) => _set(
    () => _active.viperBassFrequency = v,
    _active.viperBassFrequency != v,
  );
  set viperBassGain(int v) =>
      _set(() => _active.viperBassGain = v, _active.viperBassGain != v);
  set viperBassAntiPop(bool v) =>
      _set(() => _active.viperBassAntiPop = v, _active.viperBassAntiPop != v);

  set viperBassMonoEnabled(bool v) => _set(
    () => _active.viperBassMonoEnabled = v,
    _active.viperBassMonoEnabled != v,
  );
  set viperBassMonoMode(int v) =>
      _set(() => _active.viperBassMonoMode = v, _active.viperBassMonoMode != v);
  set viperBassMonoFrequency(int v) => _set(
    () => _active.viperBassMonoFrequency = v,
    _active.viperBassMonoFrequency != v,
  );
  set viperBassMonoGain(int v) =>
      _set(() => _active.viperBassMonoGain = v, _active.viperBassMonoGain != v);
  set viperBassMonoAntiPop(bool v) => _set(
    () => _active.viperBassMonoAntiPop = v,
    _active.viperBassMonoAntiPop != v,
  );

  set viperClarityEnabled(bool v) => _set(
    () => _active.viperClarityEnabled = v,
    _active.viperClarityEnabled != v,
  );
  set viperClarityMode(int v) =>
      _set(() => _active.viperClarityMode = v, _active.viperClarityMode != v);
  set viperClarityGain(int v) =>
      _set(() => _active.viperClarityGain = v, _active.viperClarityGain != v);

  set cureEnabled(bool v) =>
      _set(() => _active.cureEnabled = v, _active.cureEnabled != v);
  set cureCrossfeedStrength(int v) => _set(
    () => _active.cureCrossfeedStrength = v,
    _active.cureCrossfeedStrength != v,
  );

  set analogXEnabled(bool v) =>
      _set(() => _active.analogXEnabled = v, _active.analogXEnabled != v);
  set analogXMode(int v) =>
      _set(() => _active.analogXMode = v, _active.analogXMode != v);

  set speakerCorrectionEnabled(bool v) => _set(
    () => _active.speakerCorrectionEnabled = v,
    _active.speakerCorrectionEnabled != v,
  );

  void setEqualizerBand(int index, double value) {
    if (index < 0 || index >= _active.equalizerBands.length) return;
    if (_active.equalizerBands[index] == value) return;
    _active.equalizerBands[index] = value;
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void setEQBandCount(int count) {
    if (count == _active.equalizerBandCount) return;
    _log.info('EQ band count: ${_active.equalizerBandCount} -> $count');
    _active.equalizerBandsMap[_active.equalizerBandCount] = List<double>.from(
      _active.equalizerBands,
    );
    _active.equalizerBandCount = count;
    _active.equalizerBands =
        _active.equalizerBandsMap[count] ?? List.filled(count, 0.0);
    _active.equalizerBandsMap[count] = List<double>.from(
      _active.equalizerBands,
    );
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void sendEQBand(int index, double level) {
    if (index < 0 || index >= _active.equalizerBands.length) return;
    _active.equalizerBands[index] = level;
    _active.equalizerBandsMap[_active.equalizerBandCount] = List<double>.from(
      _active.equalizerBands,
    );
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  set fxType(int value) {
    if (_fxType == value) return;
    _log.info('FX type: $_fxType -> $value');
    _saveActiveToMode();
    _fxType = value;
    notifyListeners();
    final mode = _fxType == 0 ? _headphoneState : _speakerState;
    _loadModeToActive(mode);
    pushParams();
    _scheduleSave();
  }

  void _set(VoidCallback apply, bool changed) {
    if (!changed) return;
    apply();
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void _saveActiveToMode() {
    final slot = _fxType == 0 ? _headphoneState : _speakerState;
    slot.copyFrom(_active);
  }

  void _loadModeToActive(ModeState mode) {
    _suppressPush = true;
    _active.copyFrom(mode);
    _suppressPush = false;
    notifyListeners();
  }

  void pushParams() {
    if (_suppressPush) return;
    if (_fxType != _activeDeviceType) return;
    final data = SharedParamsSerializer.serialize(this);
    _shm.writeParams(data);
    SharedParamsSerializer.logParams(data);
  }

  void handleDeviceTypeChange(OutputDeviceType newType) {
    final newFxType = newType == OutputDeviceType.headphone ? 0 : 1;
    if (newFxType == _activeDeviceType) return;
    _log.info(
      'Device changed: ${_activeDeviceType == 0 ? "headphone" : "speaker"} -> ${newFxType == 0 ? "headphone" : "speaker"}',
    );
    _saveActiveToMode();
    _activeDeviceType = newFxType;
    _fxType = newFxType;
    final source = _fxType == 0 ? _headphoneState : _speakerState;
    _loadModeToActive(source);
    pushParams();
    _scheduleSave();
  }

  void _refreshApoStatus() {
    final status = _shm.readApoStatus();
    final wasInstalled = _driverInstalled;
    final wasProcessing = _apoProcessing;
    final wasSampleRate = _apoSampleRate;
    final wasVersion = _apoVersion;

    _driverInstalled = _checkDriverInstalled();
    _apoSampleRate = status.sampleRate;
    _apoVersion = status.version;
    _apoArch = status.arch;

    if (status.processTimeMs == 0) {
      _apoProcessing = status.sampleRate > 0;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      _apoProcessing =
          now >= status.processTimeMs && (now - status.processTimeMs) < 5000;
    }

    final device = _deviceDetection.detectActiveDevice();
    final detected = device.isHeadphone
        ? OutputDeviceType.headphone
        : OutputDeviceType.speaker;
    handleDeviceTypeChange(detected);

    if (device.id != _currentDeviceId && device.id.isNotEmpty) {
      _saveCurrentDeviceSettings();
      _currentDeviceId = device.id;
      _currentDeviceName = device.name;
      _loadDeviceSettings(device.id, device.isHeadphone);
    }

    if (_driverInstalled != wasInstalled ||
        _apoProcessing != wasProcessing ||
        _apoSampleRate != wasSampleRate ||
        _apoVersion != wasVersion) {
      notifyListeners();
    }
  }

  bool _checkDriverInstalled() {
    try {
      final result = Process.runSync('reg', [
        'query',
        r'HKLM\SOFTWARE\Classes\CLSID\{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}\InprocServer32',
        '/ve',
      ]);
      if (result.exitCode != 0) return false;
      final output = result.stdout as String;
      final match = RegExp(r'REG_SZ\s+(.+)').firstMatch(output);
      if (match == null) return false;
      final dllPath = match.group(1)!.trim();
      return File(dllPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      saveSettings();
    });
  }

  Future<void> saveSettings() async {
    _saveActiveToMode();
    final data = <String, dynamic>{
      'masterEnabled': _masterEnabled,
      'fxType': _fxType,
      'headphonePreset': _headphoneState.toJson(),
      'speakerPreset': _speakerState.toJson(),
    };
    await _settings.save(data);
    _log.debug('Settings saved');
  }

  void saveSettingsSync() {
    _saveActiveToMode();
    _saveCurrentDeviceSettings();
    final data = <String, dynamic>{
      'masterEnabled': _masterEnabled,
      'fxType': _fxType,
      'headphonePreset': _headphoneState.toJson(),
      'speakerPreset': _speakerState.toJson(),
    };
    _settings.saveSync(data);
  }

  void refreshFileLists() {
    _ddcFiles = _fileManager.listFiles(ProfileFileType.ddc);
    _kernelFiles = _fileManager.listFiles(ProfileFileType.kernel);
    _presetFiles = _fileManager
        .listFiles(ProfileFileType.preset)
        .map((f) => f.replaceAll('.json', ''))
        .toList();
    _eqPresetFiles = _fileManager
        .listFiles(ProfileFileType.eqPreset)
        .map((f) => f.replaceAll('.json', ''))
        .toList();
    _dsPresetFiles = _fileManager
        .listFiles(ProfileFileType.dsPreset)
        .map((f) => f.replaceAll('.json', ''))
        .toList();
    notifyListeners();
  }

  void importDdc(String sourcePath) {
    final name = _fileManager.importFile(sourcePath, ProfileFileType.ddc);
    if (name == null) return;
    refreshFileLists();
    loadDdcByName(name);
  }

  void importKernel(String sourcePath) {
    final name = _fileManager.importFile(sourcePath, ProfileFileType.kernel);
    if (name == null) return;
    refreshFileLists();
    loadKernelByName(name);
  }

  void loadDdcByName(String name) {
    final path = _fileManager.filePath(name, ProfileFileType.ddc);
    try {
      final bytes = File(path).readAsBytesSync();
      _bulk.loadDdcFile(Uint8List.fromList(bytes));
      ddcFilePath = name;
      ddcEnabled = true;
      _log.info('DDC loaded by name: $name');
    } catch (e) {
      _log.error('DDC load failed: $e');
    }
  }

  void loadKernelByName(String name) {
    final path = _fileManager.filePath(name, ProfileFileType.kernel);
    try {
      final bytes = File(path).readAsBytesSync();
      _bulk.loadConvolverKernel(Uint8List.fromList(bytes), name);
      convolutionKernelPath = name;
      convolutionEnabled = true;
      _log.info('Convolver loaded by name: $name');
    } catch (e) {
      _log.error('Convolver load failed: $e');
    }
  }

  void deleteDdc(String name) {
    _fileManager.deleteFile(name, ProfileFileType.ddc);
    if (_active.ddcFilePath == name) {
      ddcFilePath = '';
      ddcEnabled = false;
    }
    refreshFileLists();
  }

  void deleteKernel(String name) {
    _fileManager.deleteFile(name, ProfileFileType.kernel);
    if (_active.convolutionKernelPath == name) {
      convolutionKernelPath = '';
      convolutionEnabled = false;
    }
    refreshFileLists();
  }

  void savePreset(String name) {
    _saveActiveToMode();
    final current = (_fxType == 0 ? _headphoneState : _speakerState).clone();
    current.mode = _fxType;
    final json = jsonEncode(current.toJson());
    final path = _fileManager.filePath('$name.json', ProfileFileType.preset);
    File(path).writeAsStringSync(json);
    _log.info('Preset saved: $name (mode=$_fxType)');
    refreshFileLists();
  }

  int loadPreset(String name) {
    final path = _fileManager.filePath('$name.json', ProfileFileType.preset);
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final preset = ModeState();
      preset.loadFromJson(json);
      final targetSpk = preset.mode == 1;
      if (targetSpk) {
        _speakerState.loadFromJson(json);
      } else {
        _headphoneState.loadFromJson(json);
      }
      final viewingTarget =
          (targetSpk && _fxType == 1) || (!targetSpk && _fxType == 0);
      if (viewingTarget) {
        final source = targetSpk ? _speakerState : _headphoneState;
        _loadModeToActive(source);
        _reloadActiveFiles();
      }
      final activeTarget =
          (targetSpk && _activeDeviceType == 1) ||
          (!targetSpk && _activeDeviceType == 0);
      if (activeTarget) {
        pushParams();
      }
      _scheduleSave();
      _log.info(
        'Preset loaded: $name -> ${targetSpk ? "speaker" : "headphone"}',
      );
      return targetSpk ? 1 : 0;
    } catch (e) {
      _log.error('Preset load failed: $e');
      return -1;
    }
  }

  void deletePreset(String name) {
    _fileManager.deleteFile('$name.json', ProfileFileType.preset);
    refreshFileLists();
  }

  bool presetIsHeadphone(String name) {
    final path = _fileManager.filePath('$name.json', ProfileFileType.preset);
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      return (json['mode'] as int? ?? 0) == 0;
    } catch (_) {
      return true;
    }
  }

  void renamePreset(String oldName, String newName) {
    _fileManager.renameFile(
      '$oldName.json',
      '$newName.json',
      ProfileFileType.preset,
    );
    refreshFileLists();
  }

  void saveEqPreset(String name) {
    final preset = {
      'name': name,
      'bandCount': _active.equalizerBandCount,
      'bands': List<double>.from(_active.equalizerBands),
    };
    final path = _fileManager.filePath('$name.json', ProfileFileType.eqPreset);
    File(path).writeAsStringSync(jsonEncode(preset));
    refreshFileLists();
  }

  void loadEqPreset(String name) {
    final path = _fileManager.filePath('$name.json', ProfileFileType.eqPreset);
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final bandCount = json['bandCount'] as int? ?? 10;
      if (bandCount != _active.equalizerBandCount) return;
      final bands = (json['bands'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      _active.equalizerBands = bands;
      _active.equalizerBandsMap[_active.equalizerBandCount] = List<double>.from(
        bands,
      );
      notifyListeners();
      if (!_suppressPush) {
        pushParams();
        _scheduleSave();
      }
    } catch (e) {
      _log.error('EQ preset load failed: $e');
    }
  }

  void deleteEqPreset(String name) {
    _fileManager.deleteFile('$name.json', ProfileFileType.eqPreset);
    refreshFileLists();
  }

  void saveDsPreset(String name) {
    final preset = {
      'name': name,
      'xLow': _active.dsXLow,
      'xHigh': _active.dsXHigh,
      'yLow': _active.dsYLow,
      'yHigh': _active.dsYHigh,
      'sideGainLow': _active.dsSideGainLow,
      'sideGainHigh': _active.dsSideGainHigh,
    };
    final path = _fileManager.filePath('$name.json', ProfileFileType.dsPreset);
    File(path).writeAsStringSync(jsonEncode(preset));
    refreshFileLists();
  }

  void loadDsPreset(String name) {
    final path = _fileManager.filePath('$name.json', ProfileFileType.dsPreset);
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      _active.dsXLow = json['xLow'] as int? ?? _active.dsXLow;
      _active.dsXHigh = json['xHigh'] as int? ?? _active.dsXHigh;
      _active.dsYLow = json['yLow'] as int? ?? _active.dsYLow;
      _active.dsYHigh = json['yHigh'] as int? ?? _active.dsYHigh;
      _active.dsSideGainLow =
          json['sideGainLow'] as int? ?? _active.dsSideGainLow;
      _active.dsSideGainHigh =
          json['sideGainHigh'] as int? ?? _active.dsSideGainHigh;
      notifyListeners();
      if (!_suppressPush) {
        pushParams();
        _scheduleSave();
      }
    } catch (e) {
      _log.error('DS preset load failed: $e');
    }
  }

  void deleteDsPreset(String name) {
    _fileManager.deleteFile('$name.json', ProfileFileType.dsPreset);
    refreshFileLists();
  }

  List<String> eqPresetsForCurrentBandCount() {
    return _eqPresetFiles.where((name) {
      try {
        final path = _fileManager.filePath(
          '$name.json',
          ProfileFileType.eqPreset,
        );
        final json =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        return (json['bandCount'] as int?) == _active.equalizerBandCount;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  String? importPreset(String sourcePath) {
    final name = _fileManager.importFile(sourcePath, ProfileFileType.preset);
    if (name == null) return null;
    refreshFileLists();
    return name.replaceAll('.json', '');
  }

  Future<void> loadSettings() async {
    final data = await _settings.load();
    if (data == null) {
      _log.info('No saved settings found');
      return;
    }

    _suppressPush = true;
    _masterEnabled = data['masterEnabled'] as bool? ?? _masterEnabled;
    _fxType = _activeDeviceType;

    if (data['headphonePreset'] is Map<String, dynamic>) {
      _headphoneState.loadFromJson(
        data['headphonePreset'] as Map<String, dynamic>,
      );
    }
    if (data['speakerPreset'] is Map<String, dynamic>) {
      _speakerState.loadFromJson(data['speakerPreset'] as Map<String, dynamic>);
    }

    final activeMode = _fxType == 0 ? _headphoneState : _speakerState;
    _loadModeToActive(activeMode);
    _suppressPush = false;
    _ensureDeviceEntry(_currentDeviceId, _activeDeviceType == 0);
    _loadDeviceSettings(_currentDeviceId, _activeDeviceType == 0);
    _reloadActiveFiles();
    _log.info('Settings restored');
  }

  void _saveCurrentDeviceSettings() {
    if (_currentDeviceId.isEmpty) return;
    _saveActiveToMode();
    final isSpk = _activeDeviceType == 1;
    final source = isSpk ? _speakerState : _headphoneState;
    DeviceSettingsManager.saveDevice(
      _currentDeviceId,
      _currentDeviceName,
      !isSpk,
      source.toJson(),
    );
  }

  void _loadDeviceSettings(String deviceId, bool isHeadphone) {
    final data = DeviceSettingsManager.loadDevice(deviceId);
    if (data != null && data['settings'] != null) {
      final settings = data['settings'] as Map<String, dynamic>;
      final target = isHeadphone ? _headphoneState : _speakerState;
      target.loadFromJson(settings);
      _loadModeToActive(target);
    } else {
      _ensureDeviceEntry(deviceId, isHeadphone);
    }
    pushParams();
    _scheduleSave();
  }

  void _ensureDeviceEntry(String deviceId, bool isHeadphone) {
    if (deviceId.isEmpty) return;
    if (DeviceSettingsManager.loadDevice(deviceId) != null) return;
    final source = isHeadphone ? _headphoneState : _speakerState;
    DeviceSettingsManager.saveDevice(
      deviceId,
      _currentDeviceName,
      isHeadphone,
      source.toJson(),
    );
  }

  void saveDevicePreset(String deviceId) {
    final data = DeviceSettingsManager.loadDevice(deviceId);
    if (data == null) return;
    final isSpk = !(data['isHeadphone'] as bool? ?? true);
    final source = isSpk ? _speakerState : _headphoneState;
    DeviceSettingsManager.saveDevice(
      deviceId,
      data['deviceName'] as String? ?? '',
      !isSpk,
      source.toJson(),
    );
  }

  void loadDevicePreset(String deviceId) {
    final data = DeviceSettingsManager.loadDevice(deviceId);
    if (data == null) return;
    final isHp = data['isHeadphone'] as bool? ?? true;
    final settings = data['settings'] as Map<String, dynamic>?;
    if (settings == null) return;
    final target = isHp ? _headphoneState : _speakerState;
    target.loadFromJson(settings);
    if ((isHp && _activeDeviceType == 0) || (!isHp && _activeDeviceType == 1)) {
      _loadModeToActive(target);
      pushParams();
    }
    _scheduleSave();
    notifyListeners();
  }

  void renameDevice(String deviceId, String newName) {
    DeviceSettingsManager.renameDevice(deviceId, newName);
    if (deviceId == _currentDeviceId) {
      _currentDeviceName = newName;
    }
    notifyListeners();
  }

  void deleteDevice(String deviceId) {
    DeviceSettingsManager.deleteDevice(deviceId);
    notifyListeners();
  }

  List<Map<String, dynamic>> get deviceList =>
      DeviceSettingsManager.listDevices();

  void _reloadActiveFiles() {
    if (_active.ddcFilePath.isNotEmpty && _active.ddcEnabled) {
      final path = _fileManager.filePath(
        _active.ddcFilePath,
        ProfileFileType.ddc,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadDdcFile(Uint8List.fromList(bytes));
        _log.info('DDC reloaded: ${_active.ddcFilePath}');
      } catch (e) {
        _log.error('DDC reload failed: $e');
      }
    }
    if (_active.convolutionKernelPath.isNotEmpty &&
        _active.convolutionEnabled) {
      final path = _fileManager.filePath(
        _active.convolutionKernelPath,
        ProfileFileType.kernel,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadConvolverKernel(
          Uint8List.fromList(bytes),
          _active.convolutionKernelPath,
        );
        _log.info('Convolver reloaded: ${_active.convolutionKernelPath}');
      } catch (e) {
        _log.error('Convolver reload failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _log.info('Disposing');
    _statusTimer?.cancel();
    _saveTimer?.cancel();
    _saveActiveToMode();
    final data = <String, dynamic>{
      'masterEnabled': _masterEnabled,
      'fxType': _fxType,
      'headphonePreset': _headphoneState.toJson(),
      'speakerPreset': _speakerState.toJson(),
    };
    _settings.saveSync(data);
    _deviceDetection.dispose();
    _bulk.close();
    _shm.close();
    FileLogger.shared.close();
    super.dispose();
  }
}
