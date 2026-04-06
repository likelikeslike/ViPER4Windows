import 'dart:typed_data';

import 'package:viper4windows/models/value_mappings.dart';
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

  static const vheEnabled = 292;
  static const vheQuality = 296;

  static const reverberationEnabled = 300;
  static const reverberationRoomSize = 304;
  static const reverberationRoomWidth = 308;
  static const reverberationRoomDampening = 312;
  static const reverberationWetSignal = 316;
  static const reverberationDrySignal = 320;

  static const dynamicSystemEnabled = 324;
  static const dynamicSystemXLow = 328;
  static const dynamicSystemXHigh = 332;
  static const dynamicSystemYLow = 336;
  static const dynamicSystemYHigh = 340;
  static const dynamicSystemSideGainLow = 344;
  static const dynamicSystemSideGainHigh = 348;
  static const dynamicSystemStrength = 352;

  static const tubeSimulatorEnabled = 356;

  static const viperBassEnabled = 360;
  static const viperBassMode = 364;
  static const viperBassFrequency = 368;
  static const viperBassGain = 372;
  static const viperBassAntiPop = 376;

  static const viperBassMonoEnabled = 380;
  static const viperBassMonoMode = 384;
  static const viperBassMonoFrequency = 388;
  static const viperBassMonoGain = 392;
  static const viperBassMonoAntiPop = 396;

  static const viperClarityEnabled = 400;
  static const viperClarityMode = 404;
  static const viperClarityGain = 408;

  static const cureEnabled = 412;
  static const cureCrossfeedStrength = 416;

  static const analogXEnabled = 420;
  static const analogXMode = 424;

  static const speakerCorrectionEnabled = 428;

  static const apoSampleRate = 432;
  static const apoProcessTimeMs = 436;

  static const uiWriteSize = 432;
  static const totalSize = 448;
}

class SharedParamsSerializer {
  SharedParamsSerializer._();

  static int _sequence = 0;

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

    _setU32(
      data,
      SharedParamsLayout.outputVolume,
      ValueMappings.safeIndex(
        ValueMappings.outputVolumeValues,
        state.outputVolume,
      ),
    );
    _setI32(data, SharedParamsLayout.channelPan, state.channelPan);
    _setU32(
      data,
      SharedParamsLayout.limiterThreshold,
      ValueMappings.safeIndex(ValueMappings.limiterValues, state.limiter),
    );

    _setU32(
      data,
      SharedParamsLayout.agcEnabled,
      state.playbackGainEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.agcStrength,
      ValueMappings.safeIndex(
        ValueMappings.agcRatioValues,
        state.playbackGainStrength,
      ),
    );
    _setU32(
      data,
      SharedParamsLayout.agcMaxGain,
      ValueMappings.safeIndex(
        ValueMappings.agcMaxGainValues,
        state.playbackGainMaxGain,
      ),
    );
    _setU32(
      data,
      SharedParamsLayout.agcThreshold,
      ValueMappings.safeIndex(
        ValueMappings.limiterValues,
        state.playbackGainOutputThreshold,
      ),
    );

    _setU32(
      data,
      SharedParamsLayout.fetCompressorEnabled,
      state.fetCompressorEnabled ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorThreshold,
      state.fetCompressorThreshold,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorRatio,
      state.fetCompressorRatio,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoKnee,
      state.fetCompressorAutoKnee ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorKnee,
      state.fetCompressorKnee,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorKneeMulti,
      state.fetCompressorKneeMulti,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoGain,
      state.fetCompressorAutoGain ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorGain,
      state.fetCompressorGain,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoAttack,
      state.fetCompressorAutoAttack ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorAttack,
      state.fetCompressorAttack,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorMaxAttack,
      state.fetCompressorMaxAttack,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorAutoRelease,
      state.fetCompressorAutoRelease ? 100 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorRelease,
      state.fetCompressorRelease,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorMaxRelease,
      state.fetCompressorMaxRelease,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorCrest,
      state.fetCompressorCrest,
    );
    _setI32(
      data,
      SharedParamsLayout.fetCompressorAdapt,
      state.fetCompressorAdapt,
    );
    _setU32(
      data,
      SharedParamsLayout.fetCompressorNoClip,
      state.fetCompressorNoClip ? 100 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.ddcEnabled,
      (state.ddcEnabled && state.ddcFilePath.isNotEmpty) ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.spectrumExtensionEnabled,
      state.spectrumExtensionEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.spectrumExtensionBark,
      ValueMappings.safeIndex(
        ValueMappings.vseBarkValues,
        state.spectrumExtensionBark,
      ),
    );
    _setI32(
      data,
      SharedParamsLayout.spectrumExtensionExciter,
      (state.spectrumExtensionExciter * 5.6).round(),
    );

    _setU32(
      data,
      SharedParamsLayout.equalizerEnabled,
      state.equalizerEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.equalizerBandCount,
      state.equalizerBandCount,
    );
    for (var i = 0; i < state.equalizerBands.length && i < 31; i++) {
      _setI32(
        data,
        SharedParamsLayout.equalizerBands + i * 4,
        (state.equalizerBands[i] * 100).round(),
      );
    }

    _setU32(
      data,
      SharedParamsLayout.convolutionEnabled,
      (state.convolutionEnabled && state.convolutionKernelPath.isNotEmpty)
          ? 1
          : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.convolutionCrossChannel,
      state.convolutionCrossChannel,
    );

    _setU32(
      data,
      SharedParamsLayout.fieldSurroundEnabled,
      state.fieldSurroundEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.fieldSurroundWidening,
      ValueMappings.safeIndex(
        ValueMappings.fieldSurroundWideningValues,
        state.fieldSurroundWidening,
      ),
    );
    _setI32(
      data,
      SharedParamsLayout.fieldSurroundMidImage,
      state.fieldSurroundMidImage * 10 + 100,
    );
    _setI32(
      data,
      SharedParamsLayout.fieldSurroundDepth,
      state.fieldSurroundDepth * 75 + 200,
    );

    _setU32(
      data,
      SharedParamsLayout.diffSurroundEnabled,
      state.diffSurroundEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.diffSurroundDelay,
      ValueMappings.safeIndex(
        ValueMappings.diffSurroundDelayValues,
        state.diffSurroundDelay,
      ),
    );

    _setU32(data, SharedParamsLayout.vheEnabled, state.vheEnabled ? 1 : 0);
    _setU32(data, SharedParamsLayout.vheQuality, state.vheQuality);

    _setU32(
      data,
      SharedParamsLayout.reverberationEnabled,
      state.reverberationEnabled ? 1 : 0,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomSize,
      state.reverberationRoomSize * 10,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomWidth,
      state.reverberationRoomWidth * 10,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationRoomDampening,
      state.reverberationRoomDampening,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationWetSignal,
      state.reverberationWetSignal,
    );
    _setI32(
      data,
      SharedParamsLayout.reverberationDrySignal,
      state.reverberationDrySignal,
    );

    _setU32(
      data,
      SharedParamsLayout.dynamicSystemEnabled,
      state.dynamicSystemEnabled ? 1 : 0,
    );
    _setI32(data, SharedParamsLayout.dynamicSystemXLow, state.dsXLow);
    _setI32(data, SharedParamsLayout.dynamicSystemXHigh, state.dsXHigh);
    _setI32(data, SharedParamsLayout.dynamicSystemYLow, state.dsYLow);
    _setI32(data, SharedParamsLayout.dynamicSystemYHigh, state.dsYHigh);
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemSideGainLow,
      state.dsSideGainLow,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemSideGainHigh,
      state.dsSideGainHigh,
    );
    _setI32(
      data,
      SharedParamsLayout.dynamicSystemStrength,
      state.dynamicSystemStrength * 20 + 100,
    );

    _setU32(
      data,
      SharedParamsLayout.tubeSimulatorEnabled,
      state.tubeSimulatorEnabled ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperBassEnabled,
      state.viperBassEnabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.viperBassMode, state.viperBassMode);
    _setU32(
      data,
      SharedParamsLayout.viperBassFrequency,
      state.viperBassFrequency + 15,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassGain,
      state.viperBassGain * 50 + 50,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassAntiPop,
      state.viperBassAntiPop ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperBassMonoEnabled,
      state.viperBassMonoEnabled ? 1 : 0,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoMode,
      state.viperBassMonoMode,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoFrequency,
      state.viperBassMonoFrequency + 15,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoGain,
      state.viperBassMonoGain * 50 + 50,
    );
    _setU32(
      data,
      SharedParamsLayout.viperBassMonoAntiPop,
      state.viperBassMonoAntiPop ? 1 : 0,
    );

    _setU32(
      data,
      SharedParamsLayout.viperClarityEnabled,
      state.viperClarityEnabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.viperClarityMode, state.viperClarityMode);
    _setU32(
      data,
      SharedParamsLayout.viperClarityGain,
      state.viperClarityGain * 50,
    );

    _setU32(data, SharedParamsLayout.cureEnabled, state.cureEnabled ? 1 : 0);
    _setU32(
      data,
      SharedParamsLayout.cureCrossfeedStrength,
      state.cureCrossfeedStrength,
    );

    _setU32(
      data,
      SharedParamsLayout.analogXEnabled,
      state.analogXEnabled ? 1 : 0,
    );
    _setU32(data, SharedParamsLayout.analogXMode, state.analogXMode);

    _setU32(
      data,
      SharedParamsLayout.speakerCorrectionEnabled,
      state.speakerCorrectionEnabled ? 1 : 0,
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
    void p(int offset, dynamic v1, [int v2 = 0, int v3 = 0, int v4 = 0]) {
      lines.add('DSP param=$offset v1=$v1 v2=$v2 v3=$v3 v4=$v4');
    }

    p(8, u(8));
    p(12, u(12));
    p(16, u(16));
    p(20, i(20));
    p(24, u(24));
    p(28, u(28));
    p(32, u(32));
    p(36, u(36));
    p(40, u(40));
    p(44, u(44));
    p(48, i(48));
    p(52, i(52));
    p(56, u(56));
    p(60, i(60));
    p(64, i(64));
    p(68, u(68));
    p(72, i(72));
    p(76, u(76));
    p(80, i(80));
    p(84, i(84));
    p(88, u(88));
    p(92, i(92));
    p(96, i(96));
    p(100, i(100));
    p(104, i(104));
    p(108, u(108));
    p(112, u(112));
    p(116, u(116));
    p(120, u(120));
    p(124, i(124));
    p(128, u(128));
    p(132, u(132));
    final bc = u(132);
    for (var j = 0; j < bc; j++) {
      p(136 + j * 4, i(136 + j * 4));
    }
    p(260, u(260));
    p(264, i(264));
    p(268, u(268));
    p(272, u(272));
    p(276, i(276));
    p(280, i(280));
    p(284, u(284));
    p(288, u(288));
    p(292, u(292));
    p(296, u(296));
    p(300, u(300));
    p(304, i(304));
    p(308, i(308));
    p(312, i(312));
    p(316, i(316));
    p(320, i(320));
    p(324, u(324));
    p(328, i(328));
    p(332, i(332));
    p(336, i(336));
    p(340, i(340));
    p(344, i(344));
    p(348, i(348));
    p(352, i(352));
    p(356, u(356));
    p(360, u(360));
    p(364, u(364));
    p(368, u(368));
    p(372, u(372));
    p(376, u(376));
    p(380, u(380));
    p(384, u(384));
    p(388, u(388));
    p(392, u(392));
    p(396, u(396));
    p(400, u(400));
    p(404, u(404));
    p(408, u(408));
    p(412, u(412));
    p(416, u(416));
    p(420, u(420));
    p(424, u(424));
    p(428, u(428));
    _log.debugBatch(lines);
  }
}
