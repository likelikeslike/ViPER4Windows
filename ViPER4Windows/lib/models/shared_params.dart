import 'dart:math';
import 'dart:typed_data';

import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/services/file_logger.dart';

class SharedParamsLayout {
  SharedParamsLayout._();

  static const version = 0;
  static const sequenceNumber = 4;
  static const masterEnabled = 8;
  static const fxType = 12;

  static const outputVolume = 16;
  static const channelPan = 20;
  static const limiterThreshold = 24;

  static const agcEnabled = 28;
  static const agcStrength = 32;
  static const agcMaxGain = 36;
  static const agcThreshold = 40;

  static const fetCompressorEnabled = 44;
  static const fetCompressorThreshold = 48;
  static const fetCompressorRatio = 52;
  static const fetCompressorAutoKnee = 56;
  static const fetCompressorKnee = 60;
  static const fetCompressorKneeMulti = 64;
  static const fetCompressorAutoGain = 68;
  static const fetCompressorGain = 72;
  static const fetCompressorAutoAttack = 76;
  static const fetCompressorAttack = 80;
  static const fetCompressorMaxAttack = 84;
  static const fetCompressorAutoRelease = 88;
  static const fetCompressorRelease = 92;
  static const fetCompressorMaxRelease = 96;
  static const fetCompressorCrest = 100;
  static const fetCompressorAdapt = 104;
  static const fetCompressorNoClip = 108;

  static const ddcEnabled = 112;

  static const spectrumExtensionEnabled = 116;
  static const spectrumExtensionBark = 120;
  static const spectrumExtensionExciter = 124;

  static const equalizerEnabled = 128;
  static const equalizerBandCount = 132;
  static const equalizerBands = 136;

  static const convolutionEnabled = 260;
  static const convolutionCrossChannel = 264;

  static const fieldSurroundEnabled = 268;
  static const fieldSurroundWidening = 272;
  static const fieldSurroundMidImage = 276;
  static const fieldSurroundDepth = 280;

  static const diffSurroundEnabled = 284;
  static const diffSurroundDelay = 288;
  static const diffSurroundReverse = 292;
  static const diffSurroundWetDryMix = 296;
  static const diffSurroundLpCutoff = 300;

  static const vheEnabled = 304;
  static const vheQuality = 308;

  static const reverberationEnabled = 312;
  static const reverberationRoomSize = 316;
  static const reverberationRoomWidth = 320;
  static const reverberationRoomDampening = 324;
  static const reverberationWetSignal = 328;
  static const reverberationDrySignal = 332;

  static const dynamicSystemEnabled = 336;
  static const dynamicSystemXLow = 340;
  static const dynamicSystemXHigh = 344;
  static const dynamicSystemYLow = 348;
  static const dynamicSystemYHigh = 352;
  static const dynamicSystemSideGainLow = 356;
  static const dynamicSystemSideGainHigh = 360;
  static const dynamicSystemStrength = 364;

  static const tubeSimulatorEnabled = 368;

  static const viperBassEnabled = 372;
  static const viperBassMode = 376;
  static const viperBassFrequency = 380;
  static const viperBassGain = 384;
  static const viperBassAntiPop = 388;

  static const viperBassMonoEnabled = 392;
  static const viperBassMonoMode = 396;
  static const viperBassMonoFrequency = 400;
  static const viperBassMonoGain = 404;
  static const viperBassMonoAntiPop = 408;

  static const viperClarityEnabled = 412;
  static const viperClarityMode = 416;
  static const viperClarityGain = 420;

  static const cureEnabled = 424;
  static const cureCrossfeedStrength = 428;

  static const analogXEnabled = 432;
  static const analogXMode = 436;

  static const speakerCorrectionEnabled = 440;

  static const mbcEnabled = 444;
  static const mbcBandCount = 448;
  static const mbcThresholds = 452;
  static const mbcRatios = 472;
  static const mbcKnees = 492;
  static const mbcAutoKnees = 512;
  static const mbcGains = 532;
  static const mbcAutoGains = 552;
  static const mbcAttacks = 572;
  static const mbcAutoAttacks = 592;
  static const mbcReleases = 612;
  static const mbcAutoReleases = 632;
  static const mbcKneeMultis = 652;
  static const mbcMaxAttacks = 672;
  static const mbcMaxReleases = 692;
  static const mbcCrests = 712;
  static const mbcAdapts = 732;
  static const mbcNoClips = 752;
  static const mbcBandEnables = 772;
  static const mbcCrossovers = 792;

  static const dynEqEnabled = 808;
  static const dynEqBandCount = 812;
  static const dynEqFreqs = 816;
  static const dynEqQs = 848;
  static const dynEqGains = 880;
  static const dynEqThresholds = 912;
  static const dynEqAttacks = 944;
  static const dynEqReleases = 976;
  static const dynEqFilterTypes = 1008;

  static const stereoImagerEnabled = 1040;
  static const stereoImagerLowWidth = 1044;
  static const stereoImagerMidWidth = 1048;
  static const stereoImagerHighWidth = 1052;
  static const stereoImagerLowCrossover = 1056;
  static const stereoImagerHighCrossover = 1060;

  static const lufsEnabled = 1064;
  static const lufsTarget = 1068;
  static const lufsMaxGain = 1072;
  static const lufsSpeed = 1076;

  static const psychoBassEnabled = 1080;
  static const psychoBassCutoff = 1084;
  static const psychoBassIntensity = 1088;
  static const psychoBassHarmonicOrder = 1092;
  static const psychoBassOriginalLevel = 1096;

  static const apoSampleRate = 1100;
  static const apoProcessTimeMs = 1104;
  static const apoVersionString = 1112;
  static const apoVersionStringLen = 32;
  static const apoArchString = 1144;
  static const apoArchStringLen = 16;

  static const uiWriteSize = 1100;
  static const totalSize = 1160;
}

class SharedParamsSerializer {
  SharedParamsSerializer._();

  static int _sequence = 0;

  static int _fetThresholdToRaw(int dB) => (dB / -60.0 * 100).round();
  static int _fetKneeToRaw(int dB) => (dB / 60.0 * 100).round();
  static int _fetGainToRaw(int dB) => (dB / 60.0 * 100).round();
  static int _fetAttackMsToRaw(int ms) {
    final t = ms / 1000.0;
    if (t <= 0) return 0;
    final v = (log(t) + 9.21034) / 7.600903;
    return (v * 100).round().clamp(0, 200);
  }

  static int _fetReleaseMsToRaw(int ms) {
    final t = ms / 1000.0;
    if (t <= 0) return 0;
    final v = (log(t) + 5.298317) / 5.991465;
    return (v * 100).round().clamp(0, 200);
  }

  static int _bassFrequencyToRaw(int value) => value + 15;
  static int _fieldSurroundWideningToRaw(int value) => value * 100;
  static int _fieldSurroundMidImageToRaw(int value) => value * 10 + 100;
  static int _fieldSurroundDepthToRaw(int value) => value * 75 + 200;
  static int _dynamicSystemStrengthToRaw(int value) => value * 20 + 100;
  static int _diffSurroundDelayToRaw(int ms) => ms * 100;
  static int _vseExciterToRaw(int value) => (value * 5.6).round();

  static ByteData serialize(ViperState state) {
    final data = ByteData(SharedParamsLayout.totalSize);
    _sequence++;

    _setU32(data, SharedParamsLayout.version, 1);
    _setU32(data, SharedParamsLayout.sequenceNumber, _sequence);

    _setU32(
      data,
      SharedParamsLayout.masterEnabled,
      state.masterEnabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.fxType, state.fxType);

    _setU32(data, SharedParamsLayout.outputVolume, state.active.out.volume);
    _setI32(data, SharedParamsLayout.channelPan, state.active.out.channelPan);
    _setU32(
      data,
      SharedParamsLayout.limiterThreshold,
      state.active.out.limiter,
    );

    _setU32(
      data,
      SharedParamsLayout.agcEnabled,
      state.active.agc.enabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.agcStrength, state.active.agc.strength);
    _setU32(data, SharedParamsLayout.agcMaxGain, state.active.agc.maxGain);
    _setU32(
      data,
      SharedParamsLayout.agcThreshold,
      state.active.agc.outputThreshold,
    );

    _setU32(
      data,
      SharedParamsLayout.fetCompressorEnabled,
      state.active.fet.enabled ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorThreshold,
      _fetThresholdToRaw(state.active.fet.threshold),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorRatio,
      state.active.fet.ratio,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoKnee,
      state.active.fet.autoKnee ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorKnee,
      _fetKneeToRaw(state.active.fet.knee),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorKneeMulti,
      state.active.fet.kneeMulti,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoGain,
      state.active.fet.autoGain ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorGain,
      _fetGainToRaw(state.active.fet.gain),
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoAttack,
      state.active.fet.autoAttack ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorAttack,
      _fetAttackMsToRaw(state.active.fet.attack),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorMaxAttack,
      _fetAttackMsToRaw(state.active.fet.maxAttack),
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoRelease,
      state.active.fet.autoRelease ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorRelease,
      _fetReleaseMsToRaw(state.active.fet.release),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorMaxRelease,
      _fetReleaseMsToRaw(state.active.fet.maxRelease),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorCrest,
      _fetReleaseMsToRaw(state.active.fet.crest),
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorAdapt,
      state.active.fet.adapt,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorNoClip,
      state.active.fet.noClip ? 100 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.ddcEnabled,
      (state.active.ddc.enabled && state.active.ddc.device.isNotEmpty) ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.spectrumExtensionEnabled,
      state.active.vse.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.spectrumExtensionBark,
      state.active.vse.strength,
    );
    _setI32(
      data,
      SharedParamsLayout.spectrumExtensionExciter,
      _vseExciterToRaw(state.active.vse.exciter),
    );

    _setU32(
      data,
      SharedParamsLayout.equalizerEnabled,
      state.active.eq.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.equalizerBandCount,
      state.active.eq.bandCount,
    );
    for (var i = 0; i < state.active.eq.bands.length && i < 31; i++) {
      _setI32(
        data,
        SharedParamsLayout.equalizerBands + i * 4,
        (state.active.eq.bands[i] * 100).round(),
      );
    }

    _setU32(
      data,
      SharedParamsLayout.convolutionEnabled,
      (state.active.convolver.enabled &&
              state.active.convolver.kernel.isNotEmpty)
          ? 1
          : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.convolutionCrossChannel,
      state.active.convolver.crossChannel,
    );

    _setU32(
      data,
      SharedParamsLayout.fieldSurroundEnabled,
      state.active.fieldSurround.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.fieldSurroundWidening,
      _fieldSurroundWideningToRaw(state.active.fieldSurround.widening),
    );
    _setI32(
      data,
      SharedParamsLayout.fieldSurroundMidImage,
      _fieldSurroundMidImageToRaw(state.active.fieldSurround.midImage),
    );
    _setI32(
      data,
      SharedParamsLayout.fieldSurroundDepth,
      _fieldSurroundDepthToRaw(state.active.fieldSurround.depth),
    );

    _setU32(
      data,
      SharedParamsLayout.diffSurroundEnabled,
      state.active.diffSurround.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.diffSurroundDelay,
      _diffSurroundDelayToRaw(state.active.diffSurround.delay),
    );
    _setU32(
      data,
      SharedParamsLayout.diffSurroundReverse,
      state.active.diffSurround.reverse ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.diffSurroundWetDryMix,
      state.active.diffSurround.wetDryMix,
    );
    _setI32(
      data,
      SharedParamsLayout.diffSurroundLpCutoff,
      state.active.diffSurround.lpCutoff,
    );

    _setU32(
      data,
      SharedParamsLayout.vheEnabled,
      state.active.vhe.enabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.vheQuality, state.active.vhe.quality);

    _setU32(
      data,
      SharedParamsLayout.reverberationEnabled,
      state.active.reverb.enabled ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomSize,
      state.active.reverb.roomSize * 10,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomWidth,
      state.active.reverb.width * 10,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomDampening,
      state.active.reverb.roomDampening,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationWetSignal,
      state.active.reverb.wet,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationDrySignal,
      state.active.reverb.dry,
    );

    _setU32(
      data,
      SharedParamsLayout.dynamicSystemEnabled,
      state.active.dynamicSystem.enabled ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemXLow,
      state.active.dynamicSystem.xLow,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemXHigh,
      state.active.dynamicSystem.xHigh,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemYLow,
      state.active.dynamicSystem.yLow,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemYHigh,
      state.active.dynamicSystem.yHigh,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemSideGainLow,
      state.active.dynamicSystem.sideGainLow,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemSideGainHigh,
      state.active.dynamicSystem.sideGainHigh,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemStrength,
      _dynamicSystemStrengthToRaw(state.active.dynamicSystem.strength),
    );

    _setU32(
      data,
      SharedParamsLayout.tubeSimulatorEnabled,
      state.active.tube.enabled ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperBassEnabled,
      state.active.bass.enabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.viperBassMode, state.active.bass.mode);
    _setU32(
      data,
      SharedParamsLayout.viperBassFrequency,
      _bassFrequencyToRaw(state.active.bass.frequency),
    );
    _setU32(data, SharedParamsLayout.viperBassGain, state.active.bass.gain);
    _setU32(
      data,
      SharedParamsLayout.viperBassAntiPop,
      state.active.bass.antiPop ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperBassMonoEnabled,
      state.active.bassMono.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoMode,
      state.active.bassMono.mode,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoFrequency,
      _bassFrequencyToRaw(state.active.bassMono.frequency),
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoGain,
      state.active.bassMono.gain,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoAntiPop,
      state.active.bassMono.antiPop ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperClarityEnabled,
      state.active.clarity.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.viperClarityMode,
      state.active.clarity.mode,
    );
    _setU32(
      data,
      SharedParamsLayout.viperClarityGain,
      state.active.clarity.gain,
    );

    _setU32(
      data,
      SharedParamsLayout.cureEnabled,
      state.active.cure.enabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.cureCrossfeedStrength,
      state.active.cure.strength,
    );

    _setU32(
      data,
      SharedParamsLayout.analogXEnabled,
      state.active.analog.enabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.analogXMode, state.active.analog.mode);

    _setU32(
      data,
      SharedParamsLayout.speakerCorrectionEnabled,
      state.active.speakerCorrection.enabled ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.mbcEnabled,
      state.active.mbc.enabled ? 100 : 0,
    );
    _setU32(data, SharedParamsLayout.mbcBandCount, 5);
    for (int i = 0; i < 5; i++) {
      _setI32(
        data,
        SharedParamsLayout.mbcThresholds + i * 4,
        _fetThresholdToRaw(state.active.mbc.thresholds[i]),
      );
      _setI32(
        data,
        SharedParamsLayout.mbcRatios + i * 4,
        state.active.mbc.ratios[i],
      );
      _setI32(
        data,
        SharedParamsLayout.mbcKnees + i * 4,
        _fetKneeToRaw(state.active.mbc.knees[i]),
      );
      _setU32(
        data,
        SharedParamsLayout.mbcAutoKnees + i * 4,
        state.active.mbc.autoKnees[i] ? 100 : 0,
      );
      _setI32(
        data,
        SharedParamsLayout.mbcGains + i * 4,
        _fetGainToRaw(state.active.mbc.gains[i]),
      );
      _setU32(
        data,
        SharedParamsLayout.mbcAutoGains + i * 4,
        state.active.mbc.autoGains[i] ? 100 : 0,
      );
      _setI32(
        data,
        SharedParamsLayout.mbcAttacks + i * 4,
        _fetAttackMsToRaw(state.active.mbc.attacks[i]),
      );
      _setU32(
        data,
        SharedParamsLayout.mbcAutoAttacks + i * 4,
        state.active.mbc.autoAttacks[i] ? 100 : 0,
      );
      _setI32(
        data,
        SharedParamsLayout.mbcReleases + i * 4,
        _fetReleaseMsToRaw(state.active.mbc.releases[i]),
      );
      _setU32(
        data,
        SharedParamsLayout.mbcAutoReleases + i * 4,
        state.active.mbc.autoReleases[i] ? 100 : 0,
      );
      _setI32(
        data,
        SharedParamsLayout.mbcKneeMultis + i * 4,
        state.active.mbc.kneeMultis[i],
      );
      _setI32(
        data,
        SharedParamsLayout.mbcMaxAttacks + i * 4,
        _fetAttackMsToRaw(state.active.mbc.maxAttacks[i]),
      );
      _setI32(
        data,
        SharedParamsLayout.mbcMaxReleases + i * 4,
        _fetReleaseMsToRaw(state.active.mbc.maxReleases[i]),
      );
      _setI32(
        data,
        SharedParamsLayout.mbcCrests + i * 4,
        _fetReleaseMsToRaw(state.active.mbc.crests[i]),
      );
      _setI32(
        data,
        SharedParamsLayout.mbcAdapts + i * 4,
        state.active.mbc.adapts[i],
      );
      _setU32(
        data,
        SharedParamsLayout.mbcNoClips + i * 4,
        state.active.mbc.noClips[i] ? 100 : 0,
      );
      _setU32(
        data,
        SharedParamsLayout.mbcBandEnables + i * 4,
        state.active.mbc.bandEnables[i] ? 100 : 0,
      );
    }
    for (int i = 0; i < 4; i++) {
      _setI32(
        data,
        SharedParamsLayout.mbcCrossovers + i * 4,
        state.active.mbc.crossovers[i],
      );
    }

    _setU32(
      data,
      SharedParamsLayout.dynEqEnabled,
      state.active.dynamicEq.enabled ? 100 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.dynEqBandCount,
      state.active.dynamicEq.bandCount,
    );
    for (int i = 0; i < 8; i++) {
      _setI32(
        data,
        SharedParamsLayout.dynEqFreqs + i * 4,
        state.active.dynamicEq.freqs[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqQs + i * 4,
        state.active.dynamicEq.qs[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqGains + i * 4,
        state.active.dynamicEq.gains[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqThresholds + i * 4,
        state.active.dynamicEq.thresholds[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqAttacks + i * 4,
        state.active.dynamicEq.attacks[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqReleases + i * 4,
        state.active.dynamicEq.releases[i],
      );
      _setI32(
        data,
        SharedParamsLayout.dynEqFilterTypes + i * 4,
        state.active.dynamicEq.filterTypes[i],
      );
    }

    _setU32(
      data,
      SharedParamsLayout.stereoImagerEnabled,
      state.active.stereoImager.enabled ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.stereoImagerLowWidth,
      state.active.stereoImager.lowWidth,
    );
    _setI32(
      data,
      SharedParamsLayout.stereoImagerMidWidth,
      state.active.stereoImager.midWidth,
    );
    _setI32(
      data,
      SharedParamsLayout.stereoImagerHighWidth,
      state.active.stereoImager.highWidth,
    );
    _setI32(
      data,
      SharedParamsLayout.stereoImagerLowCrossover,
      state.active.stereoImager.lowCrossover,
    );
    _setI32(
      data,
      SharedParamsLayout.stereoImagerHighCrossover,
      state.active.stereoImager.highCrossover,
    );

    _setU32(
      data,
      SharedParamsLayout.lufsEnabled,
      state.active.lufs.enabled ? 1 : 0,
    );
    _setI32(data, SharedParamsLayout.lufsTarget, state.active.lufs.target);
    _setI32(data, SharedParamsLayout.lufsMaxGain, state.active.lufs.maxGain);
    _setI32(data, SharedParamsLayout.lufsSpeed, state.active.lufs.speed);

    _setU32(
      data,
      SharedParamsLayout.psychoBassEnabled,
      state.active.psychoBass.enabled ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.psychoBassCutoff,
      state.active.psychoBass.cutoff,
    );
    _setI32(
      data,
      SharedParamsLayout.psychoBassIntensity,
      state.active.psychoBass.intensity,
    );
    _setI32(
      data,
      SharedParamsLayout.psychoBassHarmonicOrder,
      state.active.psychoBass.harmonicOrder,
    );
    _setI32(
      data,
      SharedParamsLayout.psychoBassOriginalLevel,
      state.active.psychoBass.originalLevel,
    );

    return data;
  }

  static void _setU32(ByteData data, int offset, int value) {
    data.setUint32(offset, value, Endian.little);
  }

  static void _setI32(ByteData data, int offset, int value) {
    data.setInt32(offset, value, Endian.little);
  }

  static final _log = AppLogger('ViperState');

  static void logParams(ByteData d) {
    int u(int o) => d.getUint32(o, Endian.little);
    int i(int o) => d.getInt32(o, Endian.little);

    final lines = <String>[];
    void p(String name, int offset, int value) {
      lines.add('$name @$offset = $value');
    }

    p(
      'master',
      SharedParamsLayout.masterEnabled,
      u(SharedParamsLayout.masterEnabled),
    );
    p('fxType', SharedParamsLayout.fxType, u(SharedParamsLayout.fxType));
    p(
      'outVol',
      SharedParamsLayout.outputVolume,
      u(SharedParamsLayout.outputVolume),
    );
    p(
      'outPan',
      SharedParamsLayout.channelPan,
      i(SharedParamsLayout.channelPan),
    );
    p(
      'limiter',
      SharedParamsLayout.limiterThreshold,
      u(SharedParamsLayout.limiterThreshold),
    );
    p('agcOn', SharedParamsLayout.agcEnabled, u(SharedParamsLayout.agcEnabled));
    p(
      'agcStr',
      SharedParamsLayout.agcStrength,
      u(SharedParamsLayout.agcStrength),
    );
    p(
      'agcMax',
      SharedParamsLayout.agcMaxGain,
      u(SharedParamsLayout.agcMaxGain),
    );
    p(
      'agcThr',
      SharedParamsLayout.agcThreshold,
      u(SharedParamsLayout.agcThreshold),
    );
    p(
      'fetOn',
      SharedParamsLayout.fetCompressorEnabled,
      u(SharedParamsLayout.fetCompressorEnabled),
    );
    p(
      'fetThr',
      SharedParamsLayout.fetCompressorThreshold,
      i(SharedParamsLayout.fetCompressorThreshold),
    );
    p(
      'fetRat',
      SharedParamsLayout.fetCompressorRatio,
      i(SharedParamsLayout.fetCompressorRatio),
    );
    p(
      'fetAKn',
      SharedParamsLayout.fetCompressorAutoKnee,
      u(SharedParamsLayout.fetCompressorAutoKnee),
    );
    p(
      'fetKn',
      SharedParamsLayout.fetCompressorKnee,
      i(SharedParamsLayout.fetCompressorKnee),
    );
    p(
      'fetKnM',
      SharedParamsLayout.fetCompressorKneeMulti,
      i(SharedParamsLayout.fetCompressorKneeMulti),
    );
    p(
      'fetAGn',
      SharedParamsLayout.fetCompressorAutoGain,
      u(SharedParamsLayout.fetCompressorAutoGain),
    );
    p(
      'fetGn',
      SharedParamsLayout.fetCompressorGain,
      i(SharedParamsLayout.fetCompressorGain),
    );
    p(
      'fetAAt',
      SharedParamsLayout.fetCompressorAutoAttack,
      u(SharedParamsLayout.fetCompressorAutoAttack),
    );
    p(
      'fetAt',
      SharedParamsLayout.fetCompressorAttack,
      i(SharedParamsLayout.fetCompressorAttack),
    );
    p(
      'fetMAt',
      SharedParamsLayout.fetCompressorMaxAttack,
      i(SharedParamsLayout.fetCompressorMaxAttack),
    );
    p(
      'fetARl',
      SharedParamsLayout.fetCompressorAutoRelease,
      u(SharedParamsLayout.fetCompressorAutoRelease),
    );
    p(
      'fetRl',
      SharedParamsLayout.fetCompressorRelease,
      i(SharedParamsLayout.fetCompressorRelease),
    );
    p(
      'fetMRl',
      SharedParamsLayout.fetCompressorMaxRelease,
      i(SharedParamsLayout.fetCompressorMaxRelease),
    );
    p(
      'fetCr',
      SharedParamsLayout.fetCompressorCrest,
      i(SharedParamsLayout.fetCompressorCrest),
    );
    p(
      'fetAd',
      SharedParamsLayout.fetCompressorAdapt,
      i(SharedParamsLayout.fetCompressorAdapt),
    );
    p(
      'fetNC',
      SharedParamsLayout.fetCompressorNoClip,
      u(SharedParamsLayout.fetCompressorNoClip),
    );
    p('ddcOn', SharedParamsLayout.ddcEnabled, u(SharedParamsLayout.ddcEnabled));
    p(
      'vseOn',
      SharedParamsLayout.spectrumExtensionEnabled,
      u(SharedParamsLayout.spectrumExtensionEnabled),
    );
    p(
      'vseBk',
      SharedParamsLayout.spectrumExtensionBark,
      u(SharedParamsLayout.spectrumExtensionBark),
    );
    p(
      'vseEx',
      SharedParamsLayout.spectrumExtensionExciter,
      i(SharedParamsLayout.spectrumExtensionExciter),
    );
    p(
      'eqOn',
      SharedParamsLayout.equalizerEnabled,
      u(SharedParamsLayout.equalizerEnabled),
    );
    final bc = u(SharedParamsLayout.equalizerBandCount);
    p('eqBC', SharedParamsLayout.equalizerBandCount, bc);
    for (var j = 0; j < bc && j < 31; j++) {
      p(
        'eq[$j]',
        SharedParamsLayout.equalizerBands + j * 4,
        i(SharedParamsLayout.equalizerBands + j * 4),
      );
    }
    p(
      'convOn',
      SharedParamsLayout.convolutionEnabled,
      u(SharedParamsLayout.convolutionEnabled),
    );
    p(
      'convXC',
      SharedParamsLayout.convolutionCrossChannel,
      i(SharedParamsLayout.convolutionCrossChannel),
    );
    p(
      'fsOn',
      SharedParamsLayout.fieldSurroundEnabled,
      u(SharedParamsLayout.fieldSurroundEnabled),
    );
    p(
      'fsWid',
      SharedParamsLayout.fieldSurroundWidening,
      u(SharedParamsLayout.fieldSurroundWidening),
    );
    p(
      'fsMid',
      SharedParamsLayout.fieldSurroundMidImage,
      i(SharedParamsLayout.fieldSurroundMidImage),
    );
    p(
      'fsDep',
      SharedParamsLayout.fieldSurroundDepth,
      i(SharedParamsLayout.fieldSurroundDepth),
    );
    p(
      'dsOn',
      SharedParamsLayout.diffSurroundEnabled,
      u(SharedParamsLayout.diffSurroundEnabled),
    );
    p(
      'dsDly',
      SharedParamsLayout.diffSurroundDelay,
      u(SharedParamsLayout.diffSurroundDelay),
    );
    p(
      'dsRev',
      SharedParamsLayout.diffSurroundReverse,
      u(SharedParamsLayout.diffSurroundReverse),
    );
    p(
      'dsWD',
      SharedParamsLayout.diffSurroundWetDryMix,
      i(SharedParamsLayout.diffSurroundWetDryMix),
    );
    p(
      'dsLP',
      SharedParamsLayout.diffSurroundLpCutoff,
      i(SharedParamsLayout.diffSurroundLpCutoff),
    );
    p('vheOn', SharedParamsLayout.vheEnabled, u(SharedParamsLayout.vheEnabled));
    p('vheQ', SharedParamsLayout.vheQuality, u(SharedParamsLayout.vheQuality));
    p(
      'rvbOn',
      SharedParamsLayout.reverberationEnabled,
      u(SharedParamsLayout.reverberationEnabled),
    );
    p(
      'rvbSz',
      SharedParamsLayout.reverberationRoomSize,
      i(SharedParamsLayout.reverberationRoomSize),
    );
    p(
      'rvbWd',
      SharedParamsLayout.reverberationRoomWidth,
      i(SharedParamsLayout.reverberationRoomWidth),
    );
    p(
      'rvbDp',
      SharedParamsLayout.reverberationRoomDampening,
      i(SharedParamsLayout.reverberationRoomDampening),
    );
    p(
      'rvbWt',
      SharedParamsLayout.reverberationWetSignal,
      i(SharedParamsLayout.reverberationWetSignal),
    );
    p(
      'rvbDr',
      SharedParamsLayout.reverberationDrySignal,
      i(SharedParamsLayout.reverberationDrySignal),
    );
    p(
      'dynOn',
      SharedParamsLayout.dynamicSystemEnabled,
      u(SharedParamsLayout.dynamicSystemEnabled),
    );
    p(
      'dynXL',
      SharedParamsLayout.dynamicSystemXLow,
      i(SharedParamsLayout.dynamicSystemXLow),
    );
    p(
      'dynXH',
      SharedParamsLayout.dynamicSystemXHigh,
      i(SharedParamsLayout.dynamicSystemXHigh),
    );
    p(
      'dynYL',
      SharedParamsLayout.dynamicSystemYLow,
      i(SharedParamsLayout.dynamicSystemYLow),
    );
    p(
      'dynYH',
      SharedParamsLayout.dynamicSystemYHigh,
      i(SharedParamsLayout.dynamicSystemYHigh),
    );
    p(
      'dynSL',
      SharedParamsLayout.dynamicSystemSideGainLow,
      i(SharedParamsLayout.dynamicSystemSideGainLow),
    );
    p(
      'dynSH',
      SharedParamsLayout.dynamicSystemSideGainHigh,
      i(SharedParamsLayout.dynamicSystemSideGainHigh),
    );
    p(
      'dynSt',
      SharedParamsLayout.dynamicSystemStrength,
      i(SharedParamsLayout.dynamicSystemStrength),
    );
    p(
      'tubeOn',
      SharedParamsLayout.tubeSimulatorEnabled,
      u(SharedParamsLayout.tubeSimulatorEnabled),
    );
    p(
      'basOn',
      SharedParamsLayout.viperBassEnabled,
      u(SharedParamsLayout.viperBassEnabled),
    );
    p(
      'basMd',
      SharedParamsLayout.viperBassMode,
      u(SharedParamsLayout.viperBassMode),
    );
    p(
      'basFq',
      SharedParamsLayout.viperBassFrequency,
      u(SharedParamsLayout.viperBassFrequency),
    );
    p(
      'basGn',
      SharedParamsLayout.viperBassGain,
      u(SharedParamsLayout.viperBassGain),
    );
    p(
      'basAP',
      SharedParamsLayout.viperBassAntiPop,
      u(SharedParamsLayout.viperBassAntiPop),
    );
    p(
      'bmOn',
      SharedParamsLayout.viperBassMonoEnabled,
      u(SharedParamsLayout.viperBassMonoEnabled),
    );
    p(
      'bmMd',
      SharedParamsLayout.viperBassMonoMode,
      u(SharedParamsLayout.viperBassMonoMode),
    );
    p(
      'bmFq',
      SharedParamsLayout.viperBassMonoFrequency,
      u(SharedParamsLayout.viperBassMonoFrequency),
    );
    p(
      'bmGn',
      SharedParamsLayout.viperBassMonoGain,
      u(SharedParamsLayout.viperBassMonoGain),
    );
    p(
      'bmAP',
      SharedParamsLayout.viperBassMonoAntiPop,
      u(SharedParamsLayout.viperBassMonoAntiPop),
    );
    p(
      'clrOn',
      SharedParamsLayout.viperClarityEnabled,
      u(SharedParamsLayout.viperClarityEnabled),
    );
    p(
      'clrMd',
      SharedParamsLayout.viperClarityMode,
      u(SharedParamsLayout.viperClarityMode),
    );
    p(
      'clrGn',
      SharedParamsLayout.viperClarityGain,
      u(SharedParamsLayout.viperClarityGain),
    );
    p(
      'curOn',
      SharedParamsLayout.cureEnabled,
      u(SharedParamsLayout.cureEnabled),
    );
    p(
      'curSt',
      SharedParamsLayout.cureCrossfeedStrength,
      u(SharedParamsLayout.cureCrossfeedStrength),
    );
    p(
      'axOn',
      SharedParamsLayout.analogXEnabled,
      u(SharedParamsLayout.analogXEnabled),
    );
    p(
      'axMd',
      SharedParamsLayout.analogXMode,
      u(SharedParamsLayout.analogXMode),
    );
    p(
      'spkOn',
      SharedParamsLayout.speakerCorrectionEnabled,
      u(SharedParamsLayout.speakerCorrectionEnabled),
    );
    p('mbcOn', SharedParamsLayout.mbcEnabled, u(SharedParamsLayout.mbcEnabled));
    p(
      'mbcBC',
      SharedParamsLayout.mbcBandCount,
      u(SharedParamsLayout.mbcBandCount),
    );
    for (var j = 0; j < 5; j++) {
      final s = 'mbc[$j]';
      p(
        '${s}thr',
        SharedParamsLayout.mbcThresholds + j * 4,
        i(SharedParamsLayout.mbcThresholds + j * 4),
      );
      p(
        '${s}rat',
        SharedParamsLayout.mbcRatios + j * 4,
        i(SharedParamsLayout.mbcRatios + j * 4),
      );
      p(
        '${s}kne',
        SharedParamsLayout.mbcKnees + j * 4,
        i(SharedParamsLayout.mbcKnees + j * 4),
      );
      p(
        '${s}akn',
        SharedParamsLayout.mbcAutoKnees + j * 4,
        u(SharedParamsLayout.mbcAutoKnees + j * 4),
      );
      p(
        '${s}gn',
        SharedParamsLayout.mbcGains + j * 4,
        i(SharedParamsLayout.mbcGains + j * 4),
      );
      p(
        '${s}agn',
        SharedParamsLayout.mbcAutoGains + j * 4,
        u(SharedParamsLayout.mbcAutoGains + j * 4),
      );
      p(
        '${s}at',
        SharedParamsLayout.mbcAttacks + j * 4,
        i(SharedParamsLayout.mbcAttacks + j * 4),
      );
      p(
        '${s}aat',
        SharedParamsLayout.mbcAutoAttacks + j * 4,
        u(SharedParamsLayout.mbcAutoAttacks + j * 4),
      );
      p(
        '${s}rl',
        SharedParamsLayout.mbcReleases + j * 4,
        i(SharedParamsLayout.mbcReleases + j * 4),
      );
      p(
        '${s}arl',
        SharedParamsLayout.mbcAutoReleases + j * 4,
        u(SharedParamsLayout.mbcAutoReleases + j * 4),
      );
      p(
        '${s}knM',
        SharedParamsLayout.mbcKneeMultis + j * 4,
        i(SharedParamsLayout.mbcKneeMultis + j * 4),
      );
      p(
        '${s}mAt',
        SharedParamsLayout.mbcMaxAttacks + j * 4,
        i(SharedParamsLayout.mbcMaxAttacks + j * 4),
      );
      p(
        '${s}mRl',
        SharedParamsLayout.mbcMaxReleases + j * 4,
        i(SharedParamsLayout.mbcMaxReleases + j * 4),
      );
      p(
        '${s}cr',
        SharedParamsLayout.mbcCrests + j * 4,
        i(SharedParamsLayout.mbcCrests + j * 4),
      );
      p(
        '${s}ad',
        SharedParamsLayout.mbcAdapts + j * 4,
        i(SharedParamsLayout.mbcAdapts + j * 4),
      );
      p(
        '${s}nc',
        SharedParamsLayout.mbcNoClips + j * 4,
        u(SharedParamsLayout.mbcNoClips + j * 4),
      );
      p(
        '${s}en',
        SharedParamsLayout.mbcBandEnables + j * 4,
        u(SharedParamsLayout.mbcBandEnables + j * 4),
      );
    }
    for (var j = 0; j < 4; j++) {
      p(
        'mbcXo[$j]',
        SharedParamsLayout.mbcCrossovers + j * 4,
        i(SharedParamsLayout.mbcCrossovers + j * 4),
      );
    }
    p(
      'deqOn',
      SharedParamsLayout.dynEqEnabled,
      u(SharedParamsLayout.dynEqEnabled),
    );
    final deqBc = u(SharedParamsLayout.dynEqBandCount);
    p('deqBC', SharedParamsLayout.dynEqBandCount, deqBc);
    for (var j = 0; j < 8; j++) {
      final s = 'deq[$j]';
      p(
        '${s}fq',
        SharedParamsLayout.dynEqFreqs + j * 4,
        i(SharedParamsLayout.dynEqFreqs + j * 4),
      );
      p(
        '${s}q',
        SharedParamsLayout.dynEqQs + j * 4,
        i(SharedParamsLayout.dynEqQs + j * 4),
      );
      p(
        '${s}gn',
        SharedParamsLayout.dynEqGains + j * 4,
        i(SharedParamsLayout.dynEqGains + j * 4),
      );
      p(
        '${s}th',
        SharedParamsLayout.dynEqThresholds + j * 4,
        i(SharedParamsLayout.dynEqThresholds + j * 4),
      );
      p(
        '${s}at',
        SharedParamsLayout.dynEqAttacks + j * 4,
        i(SharedParamsLayout.dynEqAttacks + j * 4),
      );
      p(
        '${s}rl',
        SharedParamsLayout.dynEqReleases + j * 4,
        i(SharedParamsLayout.dynEqReleases + j * 4),
      );
      p(
        '${s}ft',
        SharedParamsLayout.dynEqFilterTypes + j * 4,
        i(SharedParamsLayout.dynEqFilterTypes + j * 4),
      );
    }
    p(
      'siOn',
      SharedParamsLayout.stereoImagerEnabled,
      u(SharedParamsLayout.stereoImagerEnabled),
    );
    p(
      'siLW',
      SharedParamsLayout.stereoImagerLowWidth,
      i(SharedParamsLayout.stereoImagerLowWidth),
    );
    p(
      'siMW',
      SharedParamsLayout.stereoImagerMidWidth,
      i(SharedParamsLayout.stereoImagerMidWidth),
    );
    p(
      'siHW',
      SharedParamsLayout.stereoImagerHighWidth,
      i(SharedParamsLayout.stereoImagerHighWidth),
    );
    p(
      'siLX',
      SharedParamsLayout.stereoImagerLowCrossover,
      i(SharedParamsLayout.stereoImagerLowCrossover),
    );
    p(
      'siHX',
      SharedParamsLayout.stereoImagerHighCrossover,
      i(SharedParamsLayout.stereoImagerHighCrossover),
    );
    p(
      'lufsOn',
      SharedParamsLayout.lufsEnabled,
      u(SharedParamsLayout.lufsEnabled),
    );
    p(
      'lufsTg',
      SharedParamsLayout.lufsTarget,
      i(SharedParamsLayout.lufsTarget),
    );
    p(
      'lufsMG',
      SharedParamsLayout.lufsMaxGain,
      i(SharedParamsLayout.lufsMaxGain),
    );
    p('lufsSp', SharedParamsLayout.lufsSpeed, i(SharedParamsLayout.lufsSpeed));
    p(
      'pbOn',
      SharedParamsLayout.psychoBassEnabled,
      u(SharedParamsLayout.psychoBassEnabled),
    );
    p(
      'pbCut',
      SharedParamsLayout.psychoBassCutoff,
      i(SharedParamsLayout.psychoBassCutoff),
    );
    p(
      'pbInt',
      SharedParamsLayout.psychoBassIntensity,
      i(SharedParamsLayout.psychoBassIntensity),
    );
    p(
      'pbHar',
      SharedParamsLayout.psychoBassHarmonicOrder,
      i(SharedParamsLayout.psychoBassHarmonicOrder),
    );
    p(
      'pbOri',
      SharedParamsLayout.psychoBassOriginalLevel,
      i(SharedParamsLayout.psychoBassOriginalLevel),
    );
    _log.debugBatch(lines);
  }
}
