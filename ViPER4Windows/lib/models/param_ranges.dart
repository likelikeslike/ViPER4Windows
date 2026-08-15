class ParamRange {
  final num min;
  final num max;
  const ParamRange(this.min, this.max);
}

class ParamRanges {
  static const Map<String, ParamRange> ranges = {
    'masterLimiter.threshold': ParamRange(30, 100),
    'masterLimiter.outputVolume': ParamRange(1, 200),
    'masterLimiter.channelPan': ParamRange(-100, 100),
    'playbackGainControl.strength': ParamRange(50, 300),
    'playbackGainControl.maxGain': ParamRange(100, 1000),
    'playbackGainControl.outputThreshold': ParamRange(30, 100),
    'lufs.target': ParamRange(80, 240),
    'lufs.maxGain': ParamRange(0, 120),
    'lufs.speed': ParamRange(0, 2),
    'fetCompressor.threshold': ParamRange(-48, 0),
    'fetCompressor.ratio': ParamRange(0, 200),
    'fetCompressor.knee': ParamRange(0, 12),
    'fetCompressor.kneeMulti': ParamRange(0, 100),
    'fetCompressor.gain': ParamRange(0, 24),
    'fetCompressor.attack': ParamRange(1, 100),
    'fetCompressor.maxAttack': ParamRange(1, 100),
    'fetCompressor.release': ParamRange(5, 500),
    'fetCompressor.maxRelease': ParamRange(5, 500),
    'fetCompressor.crest': ParamRange(5, 300),
    'fetCompressor.adapt': ParamRange(0, 200),
    'multibandCompressor.crossovers': ParamRange(30, 16000),
    'multibandCompressor.thresholds': ParamRange(-48, 0),
    'multibandCompressor.ratios': ParamRange(0, 200),
    'multibandCompressor.gains': ParamRange(0, 24),
    'multibandCompressor.knees': ParamRange(0, 12),
    'multibandCompressor.kneeMultis': ParamRange(0, 100),
    'multibandCompressor.attacks': ParamRange(1, 100),
    'multibandCompressor.maxAttacks': ParamRange(1, 100),
    'multibandCompressor.releases': ParamRange(5, 500),
    'multibandCompressor.maxReleases': ParamRange(5, 500),
    'multibandCompressor.crests': ParamRange(5, 300),
    'multibandCompressor.adapts': ParamRange(0, 200),
    'spectrumExtension.strength': ParamRange(2200, 8200),
    'spectrumExtension.exciter': ParamRange(0, 100),
    'equalizer.bands': ParamRange(-12.0, 12.0),
    'dynamicEq.freqs': ParamRange(20, 20000),
    'dynamicEq.qs': ParamRange(50, 800),
    'dynamicEq.gains': ParamRange(-120, 120),
    'dynamicEq.thresholds': ParamRange(-800, 0),
    'dynamicEq.attacks': ParamRange(1, 100),
    'dynamicEq.releases': ParamRange(10, 500),
    'convolver.crossChannel': ParamRange(0, 100),
    'fieldSurround.widening': ParamRange(0, 8),
    'fieldSurround.midImage': ParamRange(0, 10),
    'fieldSurround.depth': ParamRange(0, 10),
    'diffSurround.delay': ParamRange(1, 20),
    'diffSurround.wetDryMix': ParamRange(0, 100),
    'diffSurround.lpCutoff': ParamRange(0, 20000),
    'stereoImager.lowWidth': ParamRange(0, 200),
    'stereoImager.midWidth': ParamRange(0, 200),
    'stereoImager.highWidth': ParamRange(0, 200),
    'stereoImager.lowCrossover': ParamRange(80, 400),
    'stereoImager.highCrossover': ParamRange(2000, 8000),
    'headphoneSurround.quality': ParamRange(0, 4),
    'reverb.roomSize': ParamRange(0, 10),
    'reverb.width': ParamRange(0, 10),
    'reverb.damp': ParamRange(0, 10),
    'reverb.wet': ParamRange(0, 100),
    'reverb.dry': ParamRange(0, 100),
    'dynamicSystem.strength': ParamRange(0, 100),
    'dynamicSystem.xLow': ParamRange(0, 2400),
    'dynamicSystem.xHigh': ParamRange(0, 12000),
    'dynamicSystem.yLow': ParamRange(0, 200),
    'dynamicSystem.yHigh': ParamRange(0, 300),
    'dynamicSystem.sideGainLow': ParamRange(0, 100),
    'dynamicSystem.sideGainHigh': ParamRange(0, 100),
    'psychoacousticBass.cutoff': ParamRange(60, 150),
    'psychoacousticBass.intensity': ParamRange(0, 100),
    'psychoacousticBass.harmonicOrder': ParamRange(2, 5),
    'psychoacousticBass.originalLevel': ParamRange(0, 100),
    'bass.frequency': ParamRange(0, 135),
    'bass.gain': ParamRange(50, 1000),
    'bassMono.frequency': ParamRange(0, 135),
    'bassMono.gain': ParamRange(50, 1000),
    'clarity.gain': ParamRange(0, 450),
  };

  static int clampInt(String group, String field, int value) {
    final r = ranges['$group.$field'];
    if (r == null) return value;
    return value.clamp(r.min.toInt(), r.max.toInt());
  }

  static List<int> clampIntList(String group, String field, List<int> values) {
    final r = ranges['$group.$field'];
    if (r == null) return values;
    final lo = r.min.toInt();
    final hi = r.max.toInt();
    return values.map((v) => v.clamp(lo, hi)).toList();
  }

  static List<double> clampDoubleList(
    String group,
    String field,
    List<double> values,
  ) {
    final r = ranges['$group.$field'];
    if (r == null) return values;
    final lo = r.min.toDouble();
    final hi = r.max.toDouble();
    return values.map((v) => v.clamp(lo, hi)).toList();
  }
}
