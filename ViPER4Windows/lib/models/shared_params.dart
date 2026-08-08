import 'dart:math';
import 'dart:typed_data';

import 'package:viper4windows/models/viper_params_layout.dart';
import 'package:viper4windows/models/viper_state.dart';

class SharedParamsSerializer {
  SharedParamsSerializer._();

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

  static int _bassFrequencyToRaw(int v) => v + 15;
  static int _vseExciterToRaw(int v) => (v * 5.6).round();
  static int _dynamicSystemStrengthToRaw(int v) => v * 20 + 100;
  static int _fieldSurroundMidImageToRaw(int v) => v * 10 + 100;
  static int _fieldSurroundDepthToRaw(int v) => v * 75 + 200;
  static int _reverbRoomSizeToRaw(int v) => v * 10;
  static int _reverbWidthToRaw(int v) => v * 10;
  static int _reverbDampToRaw(int v) => v * 10;

  static ByteData serialize(ViperState state) {
    final data = ByteData(ViperParamsLayout.SIZE);
    final s = state.active;
    const le = Endian.little;

    // Master Limiter
    final ml = ViperParamsLayout.masterLimiter;
    data.setFloat32(
      ml + MasterLimiterLayout.threshold,
      s.out.limiter / 100.0,
      le,
    );
    data.setFloat32(
      ml + MasterLimiterLayout.outputVolume,
      s.out.volume / 100.0,
      le,
    );
    data.setFloat32(
      ml + MasterLimiterLayout.channelPan,
      s.out.channelPan / 100.0,
      le,
    );

    // Playback Gain Control
    final pgc = ViperParamsLayout.playbackGainControl;
    data.setUint8(
      pgc + PlaybackGainControlLayout.enable,
      s.playbackGainControl.enable ? 1 : 0,
    );
    data.setFloat32(
      pgc + PlaybackGainControlLayout.strength,
      s.playbackGainControl.strength / 100.0,
      le,
    );
    data.setFloat32(
      pgc + PlaybackGainControlLayout.maxGain,
      s.playbackGainControl.maxGain / 100.0,
      le,
    );
    data.setFloat32(
      pgc + PlaybackGainControlLayout.outputThreshold,
      s.playbackGainControl.outputThreshold / 100.0,
      le,
    );

    // LUFS Targeting
    final lufs = ViperParamsLayout.lufs;
    data.setUint8(lufs + LufsLayout.enable, s.lufs.enable ? 1 : 0);
    data.setFloat32(lufs + LufsLayout.target, s.lufs.target / -10.0, le);
    data.setFloat32(lufs + LufsLayout.maxGain, s.lufs.maxGain / 10.0, le);
    data.setInt32(lufs + LufsLayout.speed, s.lufs.speed, le);

    // FET Compressor
    final fetCompressor = ViperParamsLayout.fetCompressor;
    data.setUint8(
      fetCompressor + FetCompressorLayout.enable,
      s.fetCompressor.enable ? 1 : 0,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.threshold,
      _fetThresholdToRaw(s.fetCompressor.threshold) / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.ratio,
      s.fetCompressor.ratio / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.knee,
      _fetKneeToRaw(s.fetCompressor.knee) / 100.0,
      le,
    );
    data.setUint8(
      fetCompressor + FetCompressorLayout.kneeAuto,
      s.fetCompressor.kneeAuto ? 1 : 0,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.gain,
      _fetGainToRaw(s.fetCompressor.gain) / 100.0,
      le,
    );
    data.setUint8(
      fetCompressor + FetCompressorLayout.gainAuto,
      s.fetCompressor.gainAuto ? 1 : 0,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.attack,
      _fetAttackMsToRaw(s.fetCompressor.attack) / 100.0,
      le,
    );
    data.setUint8(
      fetCompressor + FetCompressorLayout.attackAuto,
      s.fetCompressor.attackAuto ? 1 : 0,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.release,
      _fetReleaseMsToRaw(s.fetCompressor.release) / 100.0,
      le,
    );
    data.setUint8(
      fetCompressor + FetCompressorLayout.releaseAuto,
      s.fetCompressor.releaseAuto ? 1 : 0,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.kneeMulti,
      s.fetCompressor.kneeMulti / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.maxAttack,
      _fetAttackMsToRaw(s.fetCompressor.maxAttack) / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.maxRelease,
      _fetReleaseMsToRaw(s.fetCompressor.maxRelease) / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.crest,
      _fetReleaseMsToRaw(s.fetCompressor.crest) / 100.0,
      le,
    );
    data.setFloat32(
      fetCompressor + FetCompressorLayout.adapt,
      s.fetCompressor.adapt / 100.0,
      le,
    );
    data.setUint8(
      fetCompressor + FetCompressorLayout.noClip,
      s.fetCompressor.noClip ? 1 : 0,
    );

    // Bass
    final bass = ViperParamsLayout.bass;
    data.setUint8(bass + BassLayout.enable, s.bass.enable ? 1 : 0);
    data.setInt32(bass + BassLayout.mode, s.bass.mode, le);
    data.setUint32(
      bass + BassLayout.frequency,
      _bassFrequencyToRaw(s.bass.frequency),
      le,
    );
    data.setFloat32(bass + BassLayout.gain, s.bass.gain / 100.0, le);
    data.setUint8(bass + BassLayout.antiPop, s.bass.antiPop ? 1 : 0);

    // BassMono
    final bassMono = ViperParamsLayout.bassMono;
    data.setUint8(bassMono + BassMonoLayout.enable, s.bassMono.enable ? 1 : 0);
    data.setInt32(bassMono + BassMonoLayout.mode, s.bassMono.mode, le);
    data.setUint32(
      bassMono + BassMonoLayout.frequency,
      _bassFrequencyToRaw(s.bassMono.frequency),
      le,
    );
    data.setFloat32(
      bassMono + BassMonoLayout.gain,
      s.bassMono.gain / 100.0,
      le,
    );
    data.setUint8(
      bassMono + BassMonoLayout.antiPop,
      s.bassMono.antiPop ? 1 : 0,
    );

    // Psychoacoustic Bass
    final psy = ViperParamsLayout.psychoacousticBass;
    data.setUint8(
      psy + PsychoacousticBassLayout.enable,
      s.psychoacousticBass.enable ? 1 : 0,
    );
    data.setUint32(
      psy + PsychoacousticBassLayout.cutoff,
      s.psychoacousticBass.cutoff,
      le,
    );
    data.setUint32(
      psy + PsychoacousticBassLayout.intensity,
      s.psychoacousticBass.intensity,
      le,
    );
    data.setUint32(
      psy + PsychoacousticBassLayout.harmonicOrder,
      s.psychoacousticBass.harmonicOrder,
      le,
    );
    data.setUint32(
      psy + PsychoacousticBassLayout.originalLevel,
      s.psychoacousticBass.originalLevel,
      le,
    );

    // Spectrum Extension
    final se = ViperParamsLayout.spectrumExtension;
    data.setUint8(
      se + SpectrumExtensionLayout.enable,
      s.spectrumExtension.enable ? 1 : 0,
    );
    data.setInt32(
      se + SpectrumExtensionLayout.strength,
      s.spectrumExtension.strength,
      le,
    );
    data.setFloat32(
      se + SpectrumExtensionLayout.exciter,
      _vseExciterToRaw(s.spectrumExtension.exciter) / 100.0,
      le,
    );

    // Equalizer
    final eq = ViperParamsLayout.equalizer;
    data.setUint8(eq + EqualizerLayout.enable, s.eq.enable ? 1 : 0);
    data.setUint32(eq + EqualizerLayout.bandCount, s.eq.bandCount, le);
    final eqBandsBase = eq + EqualizerLayout.bandLevels;
    final eqLen = min(s.eq.bands.length, EqualizerLayout.bandLevelsLen);
    for (var i = 0; i < eqLen; i++) {
      data.setFloat32(eqBandsBase + i * 4, s.eq.bands[i], le);
    }

    // Convolver
    final conv = ViperParamsLayout.convolver;
    data.setUint8(conv + ConvolverLayout.enable, s.convolver.enable ? 1 : 0);
    data.setFloat32(
      conv + ConvolverLayout.crossChannel,
      s.convolver.crossChannel / 100.0,
      le,
    );

    // DDC
    final ddc = ViperParamsLayout.ddc;
    data.setUint8(ddc + DdcLayout.enable, s.ddc.enable ? 1 : 0);

    // Field Surround
    final fs = ViperParamsLayout.fieldSurround;
    data.setUint8(
      fs + FieldSurroundLayout.enable,
      s.fieldSurround.enable ? 1 : 0,
    );
    data.setFloat32(
      fs + FieldSurroundLayout.widening,
      s.fieldSurround.widening.toDouble(),
      le,
    );
    data.setFloat32(
      fs + FieldSurroundLayout.midImage,
      _fieldSurroundMidImageToRaw(s.fieldSurround.midImage) / 100.0,
      le,
    );
    data.setInt16(
      fs + FieldSurroundLayout.depth,
      _fieldSurroundDepthToRaw(s.fieldSurround.depth),
      le,
    );

    // Diff Surround
    final ds = ViperParamsLayout.diffSurround;
    data.setUint8(
      ds + DiffSurroundLayout.enable,
      s.diffSurround.enable ? 1 : 0,
    );
    data.setFloat32(
      ds + DiffSurroundLayout.delay,
      s.diffSurround.delay.toDouble(),
      le,
    );
    data.setUint8(
      ds + DiffSurroundLayout.reverse,
      s.diffSurround.reverse ? 1 : 0,
    );
    data.setFloat32(
      ds + DiffSurroundLayout.wetDryMix,
      s.diffSurround.wetDryMix / 100.0,
      le,
    );
    data.setFloat32(
      ds + DiffSurroundLayout.lpCutoff,
      s.diffSurround.lpCutoff.toDouble(),
      le,
    );

    // Stereo Imager
    final si = ViperParamsLayout.stereoImager;
    data.setUint8(
      si + StereoImagerLayout.enable,
      s.stereoImager.enable ? 1 : 0,
    );
    data.setFloat32(
      si + StereoImagerLayout.lowWidth,
      s.stereoImager.lowWidth.toDouble(),
      le,
    );
    data.setFloat32(
      si + StereoImagerLayout.midWidth,
      s.stereoImager.midWidth.toDouble(),
      le,
    );
    data.setFloat32(
      si + StereoImagerLayout.highWidth,
      s.stereoImager.highWidth.toDouble(),
      le,
    );
    data.setFloat32(
      si + StereoImagerLayout.lowCrossover,
      s.stereoImager.lowCrossover.toDouble(),
      le,
    );
    data.setFloat32(
      si + StereoImagerLayout.highCrossover,
      s.stereoImager.highCrossover.toDouble(),
      le,
    );

    // Headphone Surround (was VHE)
    final hs = ViperParamsLayout.headphoneSurround;
    data.setUint8(
      hs + HeadphoneSurroundLayout.enable,
      s.headphoneSurround.enable ? 1 : 0,
    );
    data.setInt32(
      hs + HeadphoneSurroundLayout.quality,
      s.headphoneSurround.quality,
      le,
    );

    // Reverb
    final rvb = ViperParamsLayout.reverb;
    data.setUint8(rvb + ReverbLayout.enable, s.reverb.enable ? 1 : 0);
    data.setFloat32(
      rvb + ReverbLayout.roomSize,
      _reverbRoomSizeToRaw(s.reverb.roomSize) / 100.0,
      le,
    );
    data.setFloat32(
      rvb + ReverbLayout.width,
      _reverbWidthToRaw(s.reverb.width) / 100.0,
      le,
    );
    data.setFloat32(
      rvb + ReverbLayout.damp,
      _reverbDampToRaw(s.reverb.damp) / 100.0,
      le,
    );
    data.setFloat32(rvb + ReverbLayout.wet, s.reverb.wet / 100.0, le);
    data.setFloat32(rvb + ReverbLayout.dry, s.reverb.dry / 100.0, le);

    // Dynamic System
    final dyn = ViperParamsLayout.dynamicSystem;
    data.setUint8(
      dyn + DynamicSystemLayout.enable,
      s.dynamicSystem.enable ? 1 : 0,
    );
    data.setInt32(
      dyn + DynamicSystemLayout.xCoeffLow,
      s.dynamicSystem.xLow,
      le,
    );
    data.setInt32(
      dyn + DynamicSystemLayout.xCoeffHigh,
      s.dynamicSystem.xHigh,
      le,
    );
    data.setInt32(
      dyn + DynamicSystemLayout.yCoeffLow,
      s.dynamicSystem.yLow,
      le,
    );
    data.setInt32(
      dyn + DynamicSystemLayout.yCoeffHigh,
      s.dynamicSystem.yHigh,
      le,
    );
    data.setFloat32(
      dyn + DynamicSystemLayout.sideGainLow,
      s.dynamicSystem.sideGainLow / 100.0,
      le,
    );
    data.setFloat32(
      dyn + DynamicSystemLayout.sideGainHigh,
      s.dynamicSystem.sideGainHigh / 100.0,
      le,
    );
    data.setFloat32(
      dyn + DynamicSystemLayout.strength,
      _dynamicSystemStrengthToRaw(s.dynamicSystem.strength) / 100.0,
      le,
    );

    // Clarity
    final cla = ViperParamsLayout.clarity;
    data.setUint8(cla + ClarityLayout.enable, s.clarity.enable ? 1 : 0);
    data.setInt32(cla + ClarityLayout.mode, s.clarity.mode, le);
    data.setFloat32(cla + ClarityLayout.gain, s.clarity.gain / 100.0, le);

    // Cure
    final cure = ViperParamsLayout.cure;
    data.setUint8(cure + CureLayout.enable, s.cure.enable ? 1 : 0);
    data.setInt32(cure + CureLayout.crossfeedPreset, s.cure.strength, le);

    // Tube Simulator
    final tubeSimulator = ViperParamsLayout.tubeSimulator;
    data.setUint8(
      tubeSimulator + TubeSimulatorLayout.enable,
      s.tubeSimulator.enable ? 1 : 0,
    );

    // AnalogX
    final ax = ViperParamsLayout.analogX;
    data.setUint8(ax + AnalogXLayout.enable, s.analogX.enable ? 1 : 0);
    data.setInt32(ax + AnalogXLayout.mode, s.analogX.mode, le);

    // Speaker Correction
    final sc = ViperParamsLayout.speakerCorrection;
    data.setUint8(
      sc + SpeakerCorrectionLayout.enable,
      s.speakerCorrection.enable ? 1 : 0,
    );

    // Multiband Compressor
    final multibandCompressor = ViperParamsLayout.multibandCompressor;
    data.setUint8(
      multibandCompressor + MultibandCompressorLayout.enable,
      s.multibandCompressor.enable ? 1 : 0,
    );
    final mbcBandCount = s.multibandCompressor.crossovers.length + 1;
    data.setUint32(
      multibandCompressor + MultibandCompressorLayout.bandCount,
      mbcBandCount,
      le,
    );
    final crossBase =
        multibandCompressor + MultibandCompressorLayout.crossoverFrequencies;
    final crossLen = min(
      s.multibandCompressor.crossovers.length,
      MultibandCompressorLayout.crossoverFrequenciesLen,
    );
    for (var i = 0; i < crossLen; i++) {
      data.setFloat32(
        crossBase + i * 4,
        s.multibandCompressor.crossovers[i].toDouble(),
        le,
      );
    }
    final bandsBase = multibandCompressor + MultibandCompressorLayout.bands;
    final bandStride = MultibandCompressorBandLayout.SIZE;
    final mbcLen = min(
      s.multibandCompressor.bandEnables.length,
      MultibandCompressorLayout.bandsLen,
    );
    for (var i = 0; i < mbcLen; i++) {
      final b = bandsBase + i * bandStride;
      data.setUint8(
        b + MultibandCompressorBandLayout.enable,
        s.multibandCompressor.bandEnables[i] ? 1 : 0,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.threshold,
        _fetThresholdToRaw(s.multibandCompressor.thresholds[i]) / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.ratio,
        s.multibandCompressor.ratios[i] / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.knee,
        _fetKneeToRaw(s.multibandCompressor.knees[i]) / 100.0,
        le,
      );
      data.setUint8(
        b + MultibandCompressorBandLayout.kneeAuto,
        s.multibandCompressor.kneeAutos[i] ? 1 : 0,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.gain,
        _fetGainToRaw(s.multibandCompressor.gains[i]) / 100.0,
        le,
      );
      data.setUint8(
        b + MultibandCompressorBandLayout.gainAuto,
        s.multibandCompressor.gainAutos[i] ? 1 : 0,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.attack,
        _fetAttackMsToRaw(s.multibandCompressor.attacks[i]) / 100.0,
        le,
      );
      data.setUint8(
        b + MultibandCompressorBandLayout.attackAuto,
        s.multibandCompressor.attackAutos[i] ? 1 : 0,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.release,
        _fetReleaseMsToRaw(s.multibandCompressor.releases[i]) / 100.0,
        le,
      );
      data.setUint8(
        b + MultibandCompressorBandLayout.releaseAuto,
        s.multibandCompressor.releaseAutos[i] ? 1 : 0,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.kneeMulti,
        s.multibandCompressor.kneeMultis[i] / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.maxAttack,
        _fetAttackMsToRaw(s.multibandCompressor.maxAttacks[i]) / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.maxRelease,
        _fetReleaseMsToRaw(s.multibandCompressor.maxReleases[i]) / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.crest,
        _fetReleaseMsToRaw(s.multibandCompressor.crests[i]) / 100.0,
        le,
      );
      data.setFloat32(
        b + MultibandCompressorBandLayout.adapt,
        s.multibandCompressor.adapts[i] / 100.0,
        le,
      );
      data.setUint8(
        b + MultibandCompressorBandLayout.noClip,
        s.multibandCompressor.noClips[i] ? 1 : 0,
      );
    }

    // Dynamic EQ
    final deq = ViperParamsLayout.dynamicEq;
    data.setUint8(deq + DynamicEqLayout.enable, s.dynamicEq.enable ? 1 : 0);
    data.setUint32(deq + DynamicEqLayout.bandCount, s.dynamicEq.bandCount, le);
    final deqBandsBase = deq + DynamicEqLayout.bands;
    final deqStride = DynamicEqBandLayout.SIZE;
    final deqLen = min(s.dynamicEq.bandCount, DynamicEqLayout.bandsLen);
    for (var i = 0; i < deqLen; i++) {
      final b = deqBandsBase + i * deqStride;
      data.setFloat32(
        b + DynamicEqBandLayout.frequency,
        s.dynamicEq.freqs[i].toDouble(),
        le,
      );
      data.setFloat32(b + DynamicEqBandLayout.q, s.dynamicEq.qs[i] / 100.0, le);
      data.setFloat32(
        b + DynamicEqBandLayout.gain,
        s.dynamicEq.gains[i] / 10.0,
        le,
      );
      data.setFloat32(
        b + DynamicEqBandLayout.threshold,
        s.dynamicEq.thresholds[i] / 10.0,
        le,
      );
      data.setFloat32(
        b + DynamicEqBandLayout.attack,
        s.dynamicEq.attacks[i].toDouble(),
        le,
      );
      data.setFloat32(
        b + DynamicEqBandLayout.release,
        s.dynamicEq.releases[i].toDouble(),
        le,
      );
      data.setInt32(
        b + DynamicEqBandLayout.filterType,
        s.dynamicEq.filterTypes[i],
        le,
      );
    }

    return data;
  }
}
