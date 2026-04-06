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
