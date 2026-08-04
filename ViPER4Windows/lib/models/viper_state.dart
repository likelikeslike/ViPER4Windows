import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:viper4windows/models/device_settings.dart';
import 'package:viper4windows/models/dynamic_system_preset.dart';
import 'package:viper4windows/models/param_ranges.dart';
import 'package:viper4windows/models/shared_params.dart';
import 'package:viper4windows/services/bulk_data_service.dart';
import 'package:viper4windows/services/device_detection_service.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/profile_file_manager.dart';
import 'package:viper4windows/services/settings_service.dart';
import 'package:viper4windows/services/shared_memory_service.dart';

final _log = AppLogger('ViperState');

class PlaybackGainControlState {
  bool enable = false;
  int strength = 100;
  int maxGain = 100;
  int outputThreshold = 100;

  void copyFrom(PlaybackGainControlState other) {
    enable = other.enable;
    strength = other.strength;
    maxGain = other.maxGain;
    outputThreshold = other.outputThreshold;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'strength': strength,
    'maxGain': maxGain,
    'outputThreshold': outputThreshold,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    strength = j['strength'] as int? ?? strength;
    maxGain = j['maxGain'] as int? ?? maxGain;
    outputThreshold = j['outputThreshold'] as int? ?? outputThreshold;
  }
}

class FetCompressorState {
  bool enable = false;
  int threshold = -18;
  int ratio = 100;
  bool kneeAuto = true;
  int knee = 0;
  int kneeMulti = 0;
  bool gainAuto = true;
  int gain = 0;
  bool attackAuto = true;
  int attack = 20;
  int maxAttack = 80;
  bool releaseAuto = true;
  int release = 50;
  int maxRelease = 100;
  int crest = 100;
  int adapt = 50;
  bool noClip = true;

  void copyFrom(FetCompressorState other) {
    enable = other.enable;
    threshold = other.threshold;
    ratio = other.ratio;
    kneeAuto = other.kneeAuto;
    knee = other.knee;
    kneeMulti = other.kneeMulti;
    gainAuto = other.gainAuto;
    gain = other.gain;
    attackAuto = other.attackAuto;
    attack = other.attack;
    maxAttack = other.maxAttack;
    releaseAuto = other.releaseAuto;
    release = other.release;
    maxRelease = other.maxRelease;
    crest = other.crest;
    adapt = other.adapt;
    noClip = other.noClip;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'threshold': threshold,
    'ratio': ratio,
    'kneeAuto': kneeAuto,
    'knee': knee,
    'kneeMulti': kneeMulti,
    'gainAuto': gainAuto,
    'gain': gain,
    'attackAuto': attackAuto,
    'attack': attack,
    'maxAttack': maxAttack,
    'releaseAuto': releaseAuto,
    'release': release,
    'maxRelease': maxRelease,
    'crest': crest,
    'adapt': adapt,
    'noClip': noClip,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    threshold = j['threshold'] as int? ?? threshold;
    ratio = j['ratio'] as int? ?? ratio;
    kneeAuto = j['kneeAuto'] as bool? ?? kneeAuto;
    knee = j['knee'] as int? ?? knee;
    kneeMulti = j['kneeMulti'] as int? ?? kneeMulti;
    gainAuto = j['gainAuto'] as bool? ?? gainAuto;
    gain = j['gain'] as int? ?? gain;
    attackAuto = j['attackAuto'] as bool? ?? attackAuto;
    attack = j['attack'] as int? ?? attack;
    maxAttack = j['maxAttack'] as int? ?? maxAttack;
    releaseAuto = j['releaseAuto'] as bool? ?? releaseAuto;
    release = j['release'] as int? ?? release;
    maxRelease = j['maxRelease'] as int? ?? maxRelease;
    crest = j['crest'] as int? ?? crest;
    adapt = j['adapt'] as int? ?? adapt;
    noClip = j['noClip'] as bool? ?? noClip;
  }
}

class DdcState {
  bool enable = false;
  String device = '';

  void copyFrom(DdcState other) {
    enable = other.enable;
    device = other.device;
  }

  Map<String, dynamic> toJson() => {'enable': enable, 'device': device};

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    device = j['device'] as String? ?? device;
  }
}

class SpectrumExtensionState {
  bool enable = false;
  int strength = 7600;
  int exciter = 0;

  void copyFrom(SpectrumExtensionState other) {
    enable = other.enable;
    strength = other.strength;
    exciter = other.exciter;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'strength': strength,
    'exciter': exciter,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    strength = j['strength'] as int? ?? strength;
    exciter = j['exciter'] as int? ?? exciter;
  }
}

class EqState {
  bool enable = false;
  int bandCount = 10;
  List<double> bands = List.filled(10, 0.0);
  Map<int, List<double>> bandsMap = {10: List.filled(10, 0.0)};

  void copyFrom(EqState other) {
    enable = other.enable;
    bandCount = other.bandCount;
    bands = List<double>.from(other.bands);
    bandsMap = other.bandsMap.map((k, v) => MapEntry(k, List<double>.from(v)));
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'bandCount': bandCount,
    'bands': bands,
    'presetId': null,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    bandCount = j['bandCount'] as int? ?? bandCount;
    if (j['bands'] is List) {
      bands = (j['bands'] as List).map((e) => (e as num).toDouble()).toList();
    }
  }
}

class ConvolverState {
  bool enable = false;
  String kernel = '';
  int crossChannel = 0;

  void copyFrom(ConvolverState other) {
    enable = other.enable;
    kernel = other.kernel;
    crossChannel = other.crossChannel;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'kernelFile': kernel,
    'crossChannel': crossChannel,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    kernel = j['kernelFile'] as String? ?? kernel;
    crossChannel = j['crossChannel'] as int? ?? crossChannel;
  }
}

class FieldSurroundState {
  bool enable = false;
  int widening = 0;
  int midImage = 5;
  int depth = 0;

  void copyFrom(FieldSurroundState other) {
    enable = other.enable;
    widening = other.widening;
    midImage = other.midImage;
    depth = other.depth;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'widening': widening,
    'midImage': midImage,
    'depth': depth,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    widening = j['widening'] as int? ?? widening;
    midImage = j['midImage'] as int? ?? midImage;
    depth = j['depth'] as int? ?? depth;
  }
}

class DiffSurroundState {
  bool enable = false;
  int delay = 5;
  bool reverse = false;
  int wetDryMix = 100;
  int lpCutoff = 0;

  void copyFrom(DiffSurroundState other) {
    enable = other.enable;
    delay = other.delay;
    reverse = other.reverse;
    wetDryMix = other.wetDryMix;
    lpCutoff = other.lpCutoff;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'delay': delay,
    'reverse': reverse,
    'wetDryMix': wetDryMix,
    'lpCutoff': lpCutoff,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    delay = j['delay'] as int? ?? delay;
    reverse = j['reverse'] as bool? ?? reverse;
    wetDryMix = j['wetDryMix'] as int? ?? wetDryMix;
    lpCutoff = j['lpCutoff'] as int? ?? lpCutoff;
  }
}

class HeadphoneSurroundState {
  bool enable = false;
  int quality = 0;

  void copyFrom(HeadphoneSurroundState other) {
    enable = other.enable;
    quality = other.quality;
  }

  Map<String, dynamic> toJson() => {'enable': enable, 'quality': quality};

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    quality = j['quality'] as int? ?? quality;
  }
}

class ReverbState {
  bool enable = false;
  int roomSize = 0;
  int width = 0;
  int damp = 0;
  int wet = 0;
  int dry = 100;

  void copyFrom(ReverbState other) {
    enable = other.enable;
    roomSize = other.roomSize;
    width = other.width;
    damp = other.damp;
    wet = other.wet;
    dry = other.dry;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'roomSize': roomSize,
    'width': width,
    'damp': damp,
    'wet': wet,
    'dry': dry,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    roomSize = j['roomSize'] as int? ?? roomSize;
    width = j['width'] as int? ?? width;
    damp = j['damp'] as int? ?? damp;
    wet = j['wet'] as int? ?? wet;
    dry = j['dry'] as int? ?? dry;
  }
}

class DynamicSystemState {
  bool enable = false;
  int device = 0;
  int strength = 50;
  int xLow = 100;
  int xHigh = 5600;
  int yLow = 40;
  int yHigh = 80;
  int sideGainLow = 50;
  int sideGainHigh = 50;

  void copyFrom(DynamicSystemState other) {
    enable = other.enable;
    device = other.device;
    strength = other.strength;
    xLow = other.xLow;
    xHigh = other.xHigh;
    yLow = other.yLow;
    yHigh = other.yHigh;
    sideGainLow = other.sideGainLow;
    sideGainHigh = other.sideGainHigh;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'presetId': null,
    'device': device,
    'strength': strength,
    'xLow': xLow,
    'xHigh': xHigh,
    'yLow': yLow,
    'yHigh': yHigh,
    'sideGainLow': sideGainLow,
    'sideGainHigh': sideGainHigh,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    device = j['device'] as int? ?? device;
    strength = j['strength'] as int? ?? strength;
    xLow = j['xLow'] as int? ?? xLow;
    xHigh = j['xHigh'] as int? ?? xHigh;
    yLow = j['yLow'] as int? ?? yLow;
    yHigh = j['yHigh'] as int? ?? yHigh;
    sideGainLow = j['sideGainLow'] as int? ?? sideGainLow;
    sideGainHigh = j['sideGainHigh'] as int? ?? sideGainHigh;
  }
}

class BassState {
  bool enable = false;
  int mode = 0;
  int frequency = 55;
  int gain = 50;
  bool antiPop = false;

  void copyFrom(BassState other) {
    enable = other.enable;
    mode = other.mode;
    frequency = other.frequency;
    gain = other.gain;
    antiPop = other.antiPop;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'mode': mode,
    'frequency': frequency,
    'gain': gain,
    'antiPop': antiPop,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    mode = j['mode'] as int? ?? mode;
    frequency = j['frequency'] as int? ?? frequency;
    gain = j['gain'] as int? ?? gain;
    antiPop = j['antiPop'] as bool? ?? antiPop;
  }
}

class BassMonoState {
  bool enable = false;
  int mode = 0;
  int frequency = 55;
  int gain = 50;
  bool antiPop = false;

  void copyFrom(BassMonoState other) {
    enable = other.enable;
    mode = other.mode;
    frequency = other.frequency;
    gain = other.gain;
    antiPop = other.antiPop;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'mode': mode,
    'frequency': frequency,
    'gain': gain,
    'antiPop': antiPop,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    mode = j['mode'] as int? ?? mode;
    frequency = j['frequency'] as int? ?? frequency;
    gain = j['gain'] as int? ?? gain;
    antiPop = j['antiPop'] as bool? ?? antiPop;
  }
}

class ClarityState {
  bool enable = false;
  int mode = 0;
  int gain = 50;

  void copyFrom(ClarityState other) {
    enable = other.enable;
    mode = other.mode;
    gain = other.gain;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'mode': mode,
    'gain': gain,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    mode = j['mode'] as int? ?? mode;
    gain = j['gain'] as int? ?? gain;
  }
}

class CureState {
  bool enable = false;
  int strength = 0;

  void copyFrom(CureState other) {
    enable = other.enable;
    strength = other.strength;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'crossfeedPreset': strength,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    strength = j['crossfeedPreset'] as int? ?? strength;
  }
}

class AnalogXState {
  bool enable = false;
  int mode = 0;

  void copyFrom(AnalogXState other) {
    enable = other.enable;
    mode = other.mode;
  }

  Map<String, dynamic> toJson() => {'enable': enable, 'mode': mode};

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    mode = j['mode'] as int? ?? mode;
  }
}

class MultibandCompressorState {
  static const bandCount = 5;
  bool enable = false;
  List<int> thresholds = List.filled(5, -18);
  List<int> ratios = List.filled(5, 50);
  List<int> knees = List.filled(5, 0);
  List<bool> kneeAutos = List.filled(5, true);
  List<int> gains = List.filled(5, 0);
  List<bool> gainAutos = List.filled(5, true);
  List<int> attacks = List.filled(5, 1);
  List<bool> attackAutos = List.filled(5, true);
  List<int> releases = List.filled(5, 100);
  List<bool> releaseAutos = List.filled(5, true);
  List<int> kneeMultis = List.filled(5, 0);
  List<int> maxAttacks = List.filled(5, 44);
  List<int> maxReleases = List.filled(5, 200);
  List<int> crests = List.filled(5, 100);
  List<int> adapts = List.filled(5, 50);
  List<bool> noClips = List.filled(5, true);
  List<bool> bandEnables = List.filled(5, true);
  List<int> crossovers = [120, 500, 4000, 8000];

  void copyFrom(MultibandCompressorState other) {
    enable = other.enable;
    thresholds = List<int>.from(other.thresholds);
    ratios = List<int>.from(other.ratios);
    knees = List<int>.from(other.knees);
    kneeAutos = List<bool>.from(other.kneeAutos);
    gains = List<int>.from(other.gains);
    gainAutos = List<bool>.from(other.gainAutos);
    attacks = List<int>.from(other.attacks);
    attackAutos = List<bool>.from(other.attackAutos);
    releases = List<int>.from(other.releases);
    releaseAutos = List<bool>.from(other.releaseAutos);
    kneeMultis = List<int>.from(other.kneeMultis);
    maxAttacks = List<int>.from(other.maxAttacks);
    maxReleases = List<int>.from(other.maxReleases);
    crests = List<int>.from(other.crests);
    adapts = List<int>.from(other.adapts);
    noClips = List<bool>.from(other.noClips);
    bandEnables = List<bool>.from(other.bandEnables);
    crossovers = List<int>.from(other.crossovers);
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'bandEnables': bandEnables,
    'crossovers': crossovers,
    'thresholds': thresholds,
    'ratios': ratios,
    'gains': gains,
    'knees': knees,
    'kneeMultis': kneeMultis,
    'attacks': attacks,
    'maxAttacks': maxAttacks,
    'releases': releases,
    'maxReleases': maxReleases,
    'crests': crests,
    'adapts': adapts,
    'kneeAutos': kneeAutos,
    'gainAutos': gainAutos,
    'attackAutos': attackAutos,
    'releaseAutos': releaseAutos,
    'noClips': noClips,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    if (j['bandEnables'] is List) {
      bandEnables = (j['bandEnables'] as List).map((e) => e as bool).toList();
    }
    if (j['crossovers'] is List) {
      crossovers = (j['crossovers'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['thresholds'] is List) {
      thresholds = (j['thresholds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['ratios'] is List) {
      ratios = (j['ratios'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['gains'] is List) {
      gains = (j['gains'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['knees'] is List) {
      knees = (j['knees'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['kneeMultis'] is List) {
      kneeMultis = (j['kneeMultis'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['attacks'] is List) {
      attacks = (j['attacks'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['maxAttacks'] is List) {
      maxAttacks = (j['maxAttacks'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['releases'] is List) {
      releases = (j['releases'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['maxReleases'] is List) {
      maxReleases = (j['maxReleases'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['crests'] is List) {
      crests = (j['crests'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['adapts'] is List) {
      adapts = (j['adapts'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['kneeAutos'] is List) {
      kneeAutos = (j['kneeAutos'] as List).map((e) => e as bool).toList();
    }
    if (j['gainAutos'] is List) {
      gainAutos = (j['gainAutos'] as List).map((e) => e as bool).toList();
    }
    if (j['attackAutos'] is List) {
      attackAutos = (j['attackAutos'] as List).map((e) => e as bool).toList();
    }
    if (j['releaseAutos'] is List) {
      releaseAutos = (j['releaseAutos'] as List).map((e) => e as bool).toList();
    }
    if (j['noClips'] is List) {
      noClips = (j['noClips'] as List).map((e) => e as bool).toList();
    }
  }
}

class DynamicEqState {
  static const int capacity = 10;
  bool enable = false;
  int bandCount = 3;
  List<int> freqs = List<int>.filled(capacity, 60)
    ..[1] = 150
    ..[2] = 400;
  List<int> qs = List<int>.filled(capacity, 100)..[2] = 150;
  List<int> gains = List<int>.filled(capacity, 0);
  List<int> thresholds = List<int>.filled(capacity, -200);
  List<int> attacks = List<int>.filled(capacity, 10);
  List<int> releases = List<int>.filled(capacity, 100);
  List<int> filterTypes = List<int>.filled(capacity, 0);

  static List<int> _fit(List<dynamic> src, int fill) {
    final out = List<int>.filled(capacity, fill);
    for (var i = 0; i < src.length && i < capacity; i++) {
      out[i] = (src[i] as num).toInt();
    }
    return out;
  }

  void copyFrom(DynamicEqState other) {
    enable = other.enable;
    bandCount = other.bandCount;
    freqs = List<int>.from(other.freqs);
    qs = List<int>.from(other.qs);
    gains = List<int>.from(other.gains);
    thresholds = List<int>.from(other.thresholds);
    attacks = List<int>.from(other.attacks);
    releases = List<int>.from(other.releases);
    filterTypes = List<int>.from(other.filterTypes);
  }

  List<int> _active(List<int> src) =>
      src.take(bandCount.clamp(0, capacity)).toList();

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'bandCount': bandCount,
    'freqs': _active(freqs),
    'qs': _active(qs),
    'gains': _active(gains),
    'thresholds': _active(thresholds),
    'attacks': _active(attacks),
    'releases': _active(releases),
    'filterTypes': _active(filterTypes),
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    bandCount = j['bandCount'] as int? ?? bandCount;
    if (j['freqs'] is List) freqs = _fit(j['freqs'] as List, 60);
    if (j['qs'] is List) qs = _fit(j['qs'] as List, 100);
    if (j['gains'] is List) gains = _fit(j['gains'] as List, 0);
    if (j['thresholds'] is List) {
      thresholds = _fit(j['thresholds'] as List, -200);
    }
    if (j['attacks'] is List) attacks = _fit(j['attacks'] as List, 10);
    if (j['releases'] is List) releases = _fit(j['releases'] as List, 100);
    if (j['filterTypes'] is List) {
      filterTypes = _fit(j['filterTypes'] as List, 0);
    }
  }
}

class StereoImagerState {
  bool enable = false;
  int lowWidth = 100;
  int midWidth = 100;
  int highWidth = 100;
  int lowCrossover = 200;
  int highCrossover = 4000;

  void copyFrom(StereoImagerState other) {
    enable = other.enable;
    lowWidth = other.lowWidth;
    midWidth = other.midWidth;
    highWidth = other.highWidth;
    lowCrossover = other.lowCrossover;
    highCrossover = other.highCrossover;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'lowWidth': lowWidth,
    'midWidth': midWidth,
    'highWidth': highWidth,
    'lowCrossover': lowCrossover,
    'highCrossover': highCrossover,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    lowWidth = j['lowWidth'] as int? ?? lowWidth;
    midWidth = j['midWidth'] as int? ?? midWidth;
    highWidth = j['highWidth'] as int? ?? highWidth;
    lowCrossover = j['lowCrossover'] as int? ?? lowCrossover;
    highCrossover = j['highCrossover'] as int? ?? highCrossover;
  }
}

class LufsState {
  bool enable = false;
  int target = 140;
  int maxGain = 60;
  int speed = 1;

  void copyFrom(LufsState other) {
    enable = other.enable;
    target = other.target;
    maxGain = other.maxGain;
    speed = other.speed;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'target': target,
    'maxGain': maxGain,
    'speed': speed,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    target = j['target'] as int? ?? target;
    maxGain = j['maxGain'] as int? ?? maxGain;
    speed = j['speed'] as int? ?? speed;
  }
}

class PsychoacousticBassState {
  bool enable = false;
  int cutoff = 80;
  int intensity = 50;
  int harmonicOrder = 3;
  int originalLevel = 100;

  void copyFrom(PsychoacousticBassState other) {
    enable = other.enable;
    cutoff = other.cutoff;
    intensity = other.intensity;
    harmonicOrder = other.harmonicOrder;
    originalLevel = other.originalLevel;
  }

  Map<String, dynamic> toJson() => {
    'enable': enable,
    'cutoff': cutoff,
    'intensity': intensity,
    'harmonicOrder': harmonicOrder,
    'originalLevel': originalLevel,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
    cutoff = j['cutoff'] as int? ?? cutoff;
    intensity = j['intensity'] as int? ?? intensity;
    harmonicOrder = j['harmonicOrder'] as int? ?? harmonicOrder;
    originalLevel = j['originalLevel'] as int? ?? originalLevel;
  }
}

class TubeSimulatorState {
  bool enable = false;

  void copyFrom(TubeSimulatorState other) {
    enable = other.enable;
  }

  Map<String, dynamic> toJson() => {'enable': enable};

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
  }
}

class SpeakerCorrectionState {
  bool enable = false;

  void copyFrom(SpeakerCorrectionState other) {
    enable = other.enable;
  }

  Map<String, dynamic> toJson() => {'enable': enable};

  void loadFromJson(Map<String, dynamic> j) {
    enable = j['enable'] as bool? ?? enable;
  }
}

class OutputState {
  int volume = 100;
  int channelPan = 0;
  int limiter = 100;

  void copyFrom(OutputState other) {
    volume = other.volume;
    channelPan = other.channelPan;
    limiter = other.limiter;
  }

  Map<String, dynamic> toJson() => {
    'threshold': limiter,
    'outputVolume': volume,
    'channelPan': channelPan,
  };

  void loadFromJson(Map<String, dynamic> j) {
    limiter = j['threshold'] as int? ?? limiter;
    volume = j['outputVolume'] as int? ?? volume;
    channelPan = j['channelPan'] as int? ?? channelPan;
  }
}

class ModeState {
  final out = OutputState();
  final playbackGainControl = PlaybackGainControlState();
  final fetCompressor = FetCompressorState();
  final ddc = DdcState();
  final spectrumExtension = SpectrumExtensionState();
  final eq = EqState();
  final convolver = ConvolverState();
  final fieldSurround = FieldSurroundState();
  final diffSurround = DiffSurroundState();
  final headphoneSurround = HeadphoneSurroundState();
  final reverb = ReverbState();
  final dynamicSystem = DynamicSystemState();
  final tubeSimulator = TubeSimulatorState();
  final bass = BassState();
  final bassMono = BassMonoState();
  final clarity = ClarityState();
  final cure = CureState();
  final analogX = AnalogXState();
  final speakerCorrection = SpeakerCorrectionState();
  final multibandCompressor = MultibandCompressorState();
  final dynamicEq = DynamicEqState();
  final stereoImager = StereoImagerState();
  final lufs = LufsState();
  final psychoacousticBass = PsychoacousticBassState();

  void copyFrom(ModeState other) {
    out.copyFrom(other.out);
    playbackGainControl.copyFrom(other.playbackGainControl);
    fetCompressor.copyFrom(other.fetCompressor);
    ddc.copyFrom(other.ddc);
    spectrumExtension.copyFrom(other.spectrumExtension);
    eq.copyFrom(other.eq);
    convolver.copyFrom(other.convolver);
    fieldSurround.copyFrom(other.fieldSurround);
    diffSurround.copyFrom(other.diffSurround);
    headphoneSurround.copyFrom(other.headphoneSurround);
    reverb.copyFrom(other.reverb);
    dynamicSystem.copyFrom(other.dynamicSystem);
    tubeSimulator.copyFrom(other.tubeSimulator);
    bass.copyFrom(other.bass);
    bassMono.copyFrom(other.bassMono);
    clarity.copyFrom(other.clarity);
    cure.copyFrom(other.cure);
    analogX.copyFrom(other.analogX);
    speakerCorrection.copyFrom(other.speakerCorrection);
    multibandCompressor.copyFrom(other.multibandCompressor);
    dynamicEq.copyFrom(other.dynamicEq);
    stereoImager.copyFrom(other.stereoImager);
    lufs.copyFrom(other.lufs);
    psychoacousticBass.copyFrom(other.psychoacousticBass);
  }

  ModeState clone() {
    final c = ModeState();
    c.copyFrom(this);
    return c;
  }

  Map<String, dynamic> toJson() => {
    'masterLimiter': out.toJson(),
    'playbackGainControl': playbackGainControl.toJson(),
    'lufs': lufs.toJson(),
    'fetCompressor': fetCompressor.toJson(),
    'multibandCompressor': multibandCompressor.toJson(),
    'ddc': ddc.toJson(),
    'spectrumExtension': spectrumExtension.toJson(),
    'equalizer': eq.toJson(),
    'dynamicEq': dynamicEq.toJson(),
    'convolver': convolver.toJson(),
    'fieldSurround': fieldSurround.toJson(),
    'diffSurround': diffSurround.toJson(),
    'stereoImager': stereoImager.toJson(),
    'headphoneSurround': headphoneSurround.toJson(),
    'reverb': reverb.toJson(),
    'dynamicSystem': dynamicSystem.toJson(),
    'psychoacousticBass': psychoacousticBass.toJson(),
    'bass': bass.toJson(),
    'bassMono': bassMono.toJson(),
    'clarity': clarity.toJson(),
    'cure': cure.toJson(),
    'tubeSimulator': tubeSimulator.toJson(),
    'analogX': analogX.toJson(),
    'speakerCorrection': speakerCorrection.toJson(),
  };

  void loadFromJson(Map<String, dynamic> j) {
    final masterLimiter = j['masterLimiter'];
    if (masterLimiter is Map<String, dynamic>) out.loadFromJson(masterLimiter);
    final pgc = j['playbackGainControl'];
    if (pgc is Map<String, dynamic>) playbackGainControl.loadFromJson(pgc);
    final lufsObj = j['lufs'];
    if (lufsObj is Map<String, dynamic>) lufs.loadFromJson(lufsObj);
    final fet = j['fetCompressor'];
    if (fet is Map<String, dynamic>) fetCompressor.loadFromJson(fet);
    final mbc = j['multibandCompressor'];
    if (mbc is Map<String, dynamic>) multibandCompressor.loadFromJson(mbc);
    final ddcObj = j['ddc'];
    if (ddcObj is Map<String, dynamic>) ddc.loadFromJson(ddcObj);
    final vse = j['spectrumExtension'];
    if (vse is Map<String, dynamic>) spectrumExtension.loadFromJson(vse);
    final equalizer = j['equalizer'];
    if (equalizer is Map<String, dynamic>) eq.loadFromJson(equalizer);
    final deq = j['dynamicEq'];
    if (deq is Map<String, dynamic>) dynamicEq.loadFromJson(deq);
    final conv = j['convolver'];
    if (conv is Map<String, dynamic>) convolver.loadFromJson(conv);
    final fs = j['fieldSurround'];
    if (fs is Map<String, dynamic>) fieldSurround.loadFromJson(fs);
    final ds = j['diffSurround'];
    if (ds is Map<String, dynamic>) diffSurround.loadFromJson(ds);
    final si = j['stereoImager'];
    if (si is Map<String, dynamic>) stereoImager.loadFromJson(si);
    final vhe = j['headphoneSurround'];
    if (vhe is Map<String, dynamic>) headphoneSurround.loadFromJson(vhe);
    final rev = j['reverb'];
    if (rev is Map<String, dynamic>) reverb.loadFromJson(rev);
    final dynSys = j['dynamicSystem'];
    if (dynSys is Map<String, dynamic>) dynamicSystem.loadFromJson(dynSys);
    final pb = j['psychoacousticBass'];
    if (pb is Map<String, dynamic>) psychoacousticBass.loadFromJson(pb);
    final bassObj = j['bass'];
    if (bassObj is Map<String, dynamic>) bass.loadFromJson(bassObj);
    final bm = j['bassMono'];
    if (bm is Map<String, dynamic>) bassMono.loadFromJson(bm);
    final cl = j['clarity'];
    if (cl is Map<String, dynamic>) clarity.loadFromJson(cl);
    final cu = j['cure'];
    if (cu is Map<String, dynamic>) cure.loadFromJson(cu);
    final tube = j['tubeSimulator'];
    if (tube is Map<String, dynamic>) tubeSimulator.loadFromJson(tube);
    final ax = j['analogX'];
    if (ax is Map<String, dynamic>) analogX.loadFromJson(ax);
    final sc = j['speakerCorrection'];
    if (sc is Map<String, dynamic>) speakerCorrection.loadFromJson(sc);
    clampToRanges();
  }

  void clampToRanges() {
    out.limiter = ParamRanges.clampInt(
      'masterLimiter',
      'threshold',
      out.limiter,
    );
    out.volume = ParamRanges.clampInt(
      'masterLimiter',
      'outputVolume',
      out.volume,
    );
    out.channelPan = ParamRanges.clampInt(
      'masterLimiter',
      'channelPan',
      out.channelPan,
    );

    playbackGainControl.strength = ParamRanges.clampInt(
      'playbackGainControl',
      'strength',
      playbackGainControl.strength,
    );
    playbackGainControl.maxGain = ParamRanges.clampInt(
      'playbackGainControl',
      'maxGain',
      playbackGainControl.maxGain,
    );
    playbackGainControl.outputThreshold = ParamRanges.clampInt(
      'playbackGainControl',
      'outputThreshold',
      playbackGainControl.outputThreshold,
    );

    lufs.target = ParamRanges.clampInt('lufs', 'target', lufs.target);
    lufs.maxGain = ParamRanges.clampInt('lufs', 'maxGain', lufs.maxGain);
    lufs.speed = ParamRanges.clampInt('lufs', 'speed', lufs.speed);

    fetCompressor.threshold = ParamRanges.clampInt(
      'fetCompressor',
      'threshold',
      fetCompressor.threshold,
    );
    fetCompressor.ratio = ParamRanges.clampInt(
      'fetCompressor',
      'ratio',
      fetCompressor.ratio,
    );
    fetCompressor.knee = ParamRanges.clampInt(
      'fetCompressor',
      'knee',
      fetCompressor.knee,
    );
    fetCompressor.kneeMulti = ParamRanges.clampInt(
      'fetCompressor',
      'kneeMulti',
      fetCompressor.kneeMulti,
    );
    fetCompressor.gain = ParamRanges.clampInt(
      'fetCompressor',
      'gain',
      fetCompressor.gain,
    );
    fetCompressor.attack = ParamRanges.clampInt(
      'fetCompressor',
      'attack',
      fetCompressor.attack,
    );
    fetCompressor.maxAttack = ParamRanges.clampInt(
      'fetCompressor',
      'maxAttack',
      fetCompressor.maxAttack,
    );
    fetCompressor.release = ParamRanges.clampInt(
      'fetCompressor',
      'release',
      fetCompressor.release,
    );
    fetCompressor.maxRelease = ParamRanges.clampInt(
      'fetCompressor',
      'maxRelease',
      fetCompressor.maxRelease,
    );
    fetCompressor.crest = ParamRanges.clampInt(
      'fetCompressor',
      'crest',
      fetCompressor.crest,
    );
    fetCompressor.adapt = ParamRanges.clampInt(
      'fetCompressor',
      'adapt',
      fetCompressor.adapt,
    );

    multibandCompressor.crossovers = ParamRanges.clampIntList(
      'multibandCompressor',
      'crossovers',
      multibandCompressor.crossovers,
    );
    multibandCompressor.thresholds = ParamRanges.clampIntList(
      'multibandCompressor',
      'thresholds',
      multibandCompressor.thresholds,
    );
    multibandCompressor.ratios = ParamRanges.clampIntList(
      'multibandCompressor',
      'ratios',
      multibandCompressor.ratios,
    );
    multibandCompressor.gains = ParamRanges.clampIntList(
      'multibandCompressor',
      'gains',
      multibandCompressor.gains,
    );
    multibandCompressor.knees = ParamRanges.clampIntList(
      'multibandCompressor',
      'knees',
      multibandCompressor.knees,
    );
    multibandCompressor.kneeMultis = ParamRanges.clampIntList(
      'multibandCompressor',
      'kneeMultis',
      multibandCompressor.kneeMultis,
    );
    multibandCompressor.attacks = ParamRanges.clampIntList(
      'multibandCompressor',
      'attacks',
      multibandCompressor.attacks,
    );
    multibandCompressor.maxAttacks = ParamRanges.clampIntList(
      'multibandCompressor',
      'maxAttacks',
      multibandCompressor.maxAttacks,
    );
    multibandCompressor.releases = ParamRanges.clampIntList(
      'multibandCompressor',
      'releases',
      multibandCompressor.releases,
    );
    multibandCompressor.maxReleases = ParamRanges.clampIntList(
      'multibandCompressor',
      'maxReleases',
      multibandCompressor.maxReleases,
    );
    multibandCompressor.crests = ParamRanges.clampIntList(
      'multibandCompressor',
      'crests',
      multibandCompressor.crests,
    );
    multibandCompressor.adapts = ParamRanges.clampIntList(
      'multibandCompressor',
      'adapts',
      multibandCompressor.adapts,
    );

    spectrumExtension.strength = ParamRanges.clampInt(
      'spectrumExtension',
      'strength',
      spectrumExtension.strength,
    );
    spectrumExtension.exciter = ParamRanges.clampInt(
      'spectrumExtension',
      'exciter',
      spectrumExtension.exciter,
    );

    eq.bands = ParamRanges.clampDoubleList('equalizer', 'bands', eq.bands);

    dynamicEq.freqs = ParamRanges.clampIntList(
      'dynamicEq',
      'freqs',
      dynamicEq.freqs,
    );
    dynamicEq.qs = ParamRanges.clampIntList('dynamicEq', 'qs', dynamicEq.qs);
    dynamicEq.gains = ParamRanges.clampIntList(
      'dynamicEq',
      'gains',
      dynamicEq.gains,
    );
    dynamicEq.thresholds = ParamRanges.clampIntList(
      'dynamicEq',
      'thresholds',
      dynamicEq.thresholds,
    );
    dynamicEq.attacks = ParamRanges.clampIntList(
      'dynamicEq',
      'attacks',
      dynamicEq.attacks,
    );
    dynamicEq.releases = ParamRanges.clampIntList(
      'dynamicEq',
      'releases',
      dynamicEq.releases,
    );

    convolver.crossChannel = ParamRanges.clampInt(
      'convolver',
      'crossChannel',
      convolver.crossChannel,
    );

    fieldSurround.widening = ParamRanges.clampInt(
      'fieldSurround',
      'widening',
      fieldSurround.widening,
    );
    fieldSurround.midImage = ParamRanges.clampInt(
      'fieldSurround',
      'midImage',
      fieldSurround.midImage,
    );
    fieldSurround.depth = ParamRanges.clampInt(
      'fieldSurround',
      'depth',
      fieldSurround.depth,
    );

    diffSurround.delay = ParamRanges.clampInt(
      'diffSurround',
      'delay',
      diffSurround.delay,
    );
    diffSurround.wetDryMix = ParamRanges.clampInt(
      'diffSurround',
      'wetDryMix',
      diffSurround.wetDryMix,
    );
    diffSurround.lpCutoff = ParamRanges.clampInt(
      'diffSurround',
      'lpCutoff',
      diffSurround.lpCutoff,
    );

    stereoImager.lowWidth = ParamRanges.clampInt(
      'stereoImager',
      'lowWidth',
      stereoImager.lowWidth,
    );
    stereoImager.midWidth = ParamRanges.clampInt(
      'stereoImager',
      'midWidth',
      stereoImager.midWidth,
    );
    stereoImager.highWidth = ParamRanges.clampInt(
      'stereoImager',
      'highWidth',
      stereoImager.highWidth,
    );
    stereoImager.lowCrossover = ParamRanges.clampInt(
      'stereoImager',
      'lowCrossover',
      stereoImager.lowCrossover,
    );
    stereoImager.highCrossover = ParamRanges.clampInt(
      'stereoImager',
      'highCrossover',
      stereoImager.highCrossover,
    );

    headphoneSurround.quality = ParamRanges.clampInt(
      'headphoneSurround',
      'quality',
      headphoneSurround.quality,
    );

    reverb.roomSize = ParamRanges.clampInt(
      'reverb',
      'roomSize',
      reverb.roomSize,
    );
    reverb.width = ParamRanges.clampInt('reverb', 'width', reverb.width);
    reverb.damp = ParamRanges.clampInt('reverb', 'damp', reverb.damp);
    reverb.wet = ParamRanges.clampInt('reverb', 'wet', reverb.wet);
    reverb.dry = ParamRanges.clampInt('reverb', 'dry', reverb.dry);

    dynamicSystem.strength = ParamRanges.clampInt(
      'dynamicSystem',
      'strength',
      dynamicSystem.strength,
    );
    dynamicSystem.xLow = ParamRanges.clampInt(
      'dynamicSystem',
      'xLow',
      dynamicSystem.xLow,
    );
    dynamicSystem.xHigh = ParamRanges.clampInt(
      'dynamicSystem',
      'xHigh',
      dynamicSystem.xHigh,
    );
    dynamicSystem.yLow = ParamRanges.clampInt(
      'dynamicSystem',
      'yLow',
      dynamicSystem.yLow,
    );
    dynamicSystem.yHigh = ParamRanges.clampInt(
      'dynamicSystem',
      'yHigh',
      dynamicSystem.yHigh,
    );
    dynamicSystem.sideGainLow = ParamRanges.clampInt(
      'dynamicSystem',
      'sideGainLow',
      dynamicSystem.sideGainLow,
    );
    dynamicSystem.sideGainHigh = ParamRanges.clampInt(
      'dynamicSystem',
      'sideGainHigh',
      dynamicSystem.sideGainHigh,
    );

    psychoacousticBass.cutoff = ParamRanges.clampInt(
      'psychoacousticBass',
      'cutoff',
      psychoacousticBass.cutoff,
    );
    psychoacousticBass.intensity = ParamRanges.clampInt(
      'psychoacousticBass',
      'intensity',
      psychoacousticBass.intensity,
    );
    psychoacousticBass.harmonicOrder = ParamRanges.clampInt(
      'psychoacousticBass',
      'harmonicOrder',
      psychoacousticBass.harmonicOrder,
    );
    psychoacousticBass.originalLevel = ParamRanges.clampInt(
      'psychoacousticBass',
      'originalLevel',
      psychoacousticBass.originalLevel,
    );

    bass.frequency = ParamRanges.clampInt('bass', 'frequency', bass.frequency);
    bass.gain = ParamRanges.clampInt('bass', 'gain', bass.gain);
    bassMono.frequency = ParamRanges.clampInt(
      'bassMono',
      'frequency',
      bassMono.frequency,
    );
    bassMono.gain = ParamRanges.clampInt('bassMono', 'gain', bassMono.gain);

    clarity.gain = ParamRanges.clampInt('clarity', 'gain', clarity.gain);
  }
}

class ViperState extends ChangeNotifier {
  final SharedMemoryService _shm;
  final SettingsService _settings;
  Timer? _statusTimer;
  bool _pendingSave = false;
  bool _suppressPush = false;
  final DeviceDetectionService _deviceDetection = DeviceDetectionService();
  bool _isCurrentDeviceHeadphone = true;
  final ProfileFileManager _fileManager = ProfileFileManager();
  final BulkDataService _bulk = BulkDataService();
  List<String> _ddcFiles = [];
  List<String> _kernelFiles = [];
  List<String> _presetFiles = [];
  List<String> _eqPresetFiles = [];
  List<String> _dsPresetFiles = [];

  final ModeState _active = ModeState();

  bool _masterEnabled = true;
  String _currentDeviceId = '';
  String _currentDeviceName = '';

  bool _driverInstalled = false;
  bool _apoProcessing = false;
  int _apoSampleRate = 0;
  String _apoVersion = '';
  String _apoArch = '';
  int _lastProcessedFrames = 0;

  ViperState({
    required SharedMemoryService shm,
    required SettingsService settings,
  }) : _shm = shm,
       _settings = settings {
    _shm.open();
    _bulk.open();
    final device = _deviceDetection.detectActiveDevice();
    _isCurrentDeviceHeadphone = device.isHeadphone;
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
    _refreshDeviceAsync();
  }

  ModeState get active => _active;

  bool get masterEnabled => _masterEnabled;
  bool get isCurrentDeviceHeadphone => _isCurrentDeviceHeadphone;
  String get currentDeviceId => _currentDeviceId;
  String get currentDeviceName => _currentDeviceName;

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

  void update(void Function(ModeState s) mutate) {
    mutate(_active);
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

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

  void setDdcEnabled(bool v) {
    if (_active.ddc.enable == v) return;
    _active.ddc.enable = v;
    if (v && _active.ddc.device.isNotEmpty) {
      final path = _fileManager.filePath(
        _active.ddc.device,
        ProfileFileType.ddc,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadDdcFile(Uint8List.fromList(bytes));
        _log.info('DDC loaded: ${_active.ddc.device}');
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

  void setConvolverEnabled(bool v) {
    if (_active.convolver.enable == v) return;
    _active.convolver.enable = v;
    if (v && _active.convolver.kernel.isNotEmpty) {
      final path = _fileManager.filePath(
        _active.convolver.kernel,
        ProfileFileType.kernel,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadConvolverKernel(
          Uint8List.fromList(bytes),
          _active.convolver.kernel,
        );
        _log.info('Convolver loaded: ${_active.convolver.kernel}');
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

  void setDynamicSystemDevice(int v) {
    if (_active.dynamicSystem.device == v) return;
    _active.dynamicSystem.device = v;
    if (v >= 0 && v < DsDevices.builtins.length) {
      final d = DsDevices.builtins[v];
      _active.dynamicSystem.xLow = d.xLow;
      _active.dynamicSystem.xHigh = d.xHigh;
      _active.dynamicSystem.yLow = d.yLow;
      _active.dynamicSystem.yHigh = d.yHigh;
      _active.dynamicSystem.sideGainLow = d.sideGainLow;
      _active.dynamicSystem.sideGainHigh = d.sideGainHigh;
    }
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void setEQBandCount(int count) {
    if (count == _active.eq.bandCount) return;
    _log.info('EQ band count: ${_active.eq.bandCount} -> $count');
    _active.eq.bandsMap[_active.eq.bandCount] = List<double>.from(
      _active.eq.bands,
    );
    _active.eq.bandCount = count;
    _active.eq.bands = _active.eq.bandsMap[count] ?? List.filled(count, 0.0);
    _active.eq.bandsMap[count] = List<double>.from(_active.eq.bands);
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void sendEQBand(int index, double level) {
    if (index < 0 || index >= _active.eq.bands.length) return;
    _active.eq.bands[index] = level;
    _active.eq.bandsMap[_active.eq.bandCount] = List<double>.from(
      _active.eq.bands,
    );
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void addDynEqBand() {
    if (_active.dynamicEq.bandCount >= 10) return;
    final lastFreq = _active.dynamicEq.bandCount == 0
        ? 0
        : _active.dynamicEq.freqs[_active.dynamicEq.bandCount - 1];
    if (lastFreq >= 20000) return;
    _active.dynamicEq.bandCount++;
    final idx = _active.dynamicEq.bandCount - 1;
    final newFreq = lastFreq == 0 ? 1000 : (lastFreq * 2).clamp(0, 20000);
    _active.dynamicEq.freqs[idx] = newFreq;
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void removeDynEqBand(int band) {
    if (_active.dynamicEq.bandCount <= 1) return;
    for (int i = band; i < _active.dynamicEq.bandCount - 1; i++) {
      _active.dynamicEq.freqs[i] = _active.dynamicEq.freqs[i + 1];
      _active.dynamicEq.qs[i] = _active.dynamicEq.qs[i + 1];
      _active.dynamicEq.gains[i] = _active.dynamicEq.gains[i + 1];
      _active.dynamicEq.thresholds[i] = _active.dynamicEq.thresholds[i + 1];
      _active.dynamicEq.attacks[i] = _active.dynamicEq.attacks[i + 1];
      _active.dynamicEq.releases[i] = _active.dynamicEq.releases[i + 1];
      _active.dynamicEq.filterTypes[i] = _active.dynamicEq.filterTypes[i + 1];
    }
    _active.dynamicEq.bandCount--;
    notifyListeners();
    if (!_suppressPush) {
      pushParams();
      _scheduleSave();
    }
  }

  void pushParams() {
    if (_suppressPush) return;
    final data = SharedParamsSerializer.serialize(this);
    _shm.writeParams(data, masterEnabled: _masterEnabled);
  }

  void handleDeviceTypeChange(OutputDeviceType newType) {
    final newIsHeadphone = newType == OutputDeviceType.headphone;
    if (newIsHeadphone == _isCurrentDeviceHeadphone) return;
    _log.info(
      'Device class changed: ${_isCurrentDeviceHeadphone ? "headphone" : "speaker"} -> ${newIsHeadphone ? "headphone" : "speaker"}',
    );
    _isCurrentDeviceHeadphone = newIsHeadphone;
    notifyListeners();
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

    _apoProcessing =
        status.processedFrames > 0 &&
        status.processedFrames != _lastProcessedFrames;
    _lastProcessedFrames = status.processedFrames;

    _refreshDeviceAsync();

    if (_driverInstalled != wasInstalled ||
        _apoProcessing != wasProcessing ||
        _apoSampleRate != wasSampleRate ||
        _apoVersion != wasVersion) {
      notifyListeners();
    }
  }

  Future<void> _refreshDeviceAsync() async {
    final device = await _deviceDetection.detectActiveDeviceAsync();
    final detected = device.isHeadphone
        ? OutputDeviceType.headphone
        : OutputDeviceType.speaker;
    handleDeviceTypeChange(detected);

    if (device.id != _currentDeviceId && device.id.isNotEmpty) {
      _currentDeviceId = device.id;
      _currentDeviceName = device.name;
      _loadDeviceSettings(device.id, device.isHeadphone);
      _pendingSave = false;
    }
    notifyListeners();
  }

  bool _checkDriverInstalled() {
    return _checkDriverInstalledViaRegistry();
  }

  static final _advapi32 = DynamicLibrary.open('advapi32.dll');

  static final _regOpenKeyExW = _advapi32
      .lookupFunction<
        Int32 Function(
          IntPtr hKey,
          Pointer<Utf16> lpSubKey,
          Uint32 ulOptions,
          Uint32 samDesired,
          Pointer<IntPtr> phkResult,
        ),
        int Function(
          int hKey,
          Pointer<Utf16> lpSubKey,
          int ulOptions,
          int samDesired,
          Pointer<IntPtr> phkResult,
        )
      >('RegOpenKeyExW');

  static final _regQueryValueExW = _advapi32
      .lookupFunction<
        Int32 Function(
          IntPtr hKey,
          Pointer<Utf16> lpValueName,
          Pointer<Uint32> lpReserved,
          Pointer<Uint32> lpType,
          Pointer<Uint8> lpData,
          Pointer<Uint32> lpcbData,
        ),
        int Function(
          int hKey,
          Pointer<Utf16> lpValueName,
          Pointer<Uint32> lpReserved,
          Pointer<Uint32> lpType,
          Pointer<Uint8> lpData,
          Pointer<Uint32> lpcbData,
        )
      >('RegQueryValueExW');

  static final _regCloseKey = _advapi32
      .lookupFunction<Int32 Function(IntPtr hKey), int Function(int hKey)>(
        'RegCloseKey',
      );

  static bool _checkDriverInstalledViaRegistry() {
    const hklm = 0x80000002;
    const keyRead = 0x20019;

    final subKey =
        r'SOFTWARE\Classes\CLSID\{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}\InprocServer32'
            .toNativeUtf16();
    final phkResult = calloc<IntPtr>();
    final rc = _regOpenKeyExW(hklm, subKey, 0, keyRead, phkResult);
    calloc.free(subKey);

    if (rc != 0) {
      calloc.free(phkResult);
      return false;
    }

    final hKey = phkResult.value;
    calloc.free(phkResult);

    final valueName = ''.toNativeUtf16();
    final cbData = calloc<Uint32>();
    cbData.value = 0;
    final lpType = calloc<Uint32>();

    _regQueryValueExW(hKey, valueName, nullptr, lpType, nullptr, cbData);

    if (cbData.value == 0 || cbData.value > 2048) {
      calloc.free(valueName);
      calloc.free(cbData);
      calloc.free(lpType);
      _regCloseKey(hKey);
      return false;
    }

    final lpData = calloc<Uint8>(cbData.value);
    final rc2 = _regQueryValueExW(
      hKey,
      valueName,
      nullptr,
      lpType,
      lpData,
      cbData,
    );

    String dllPath = '';
    if (rc2 == 0) {
      final charCount = cbData.value ~/ 2;
      final chars = lpData.cast<Uint16>();
      final buf = <int>[];
      for (var i = 0; i < charCount; i++) {
        final c = chars[i];
        if (c == 0) break;
        buf.add(c);
      }
      dllPath = String.fromCharCodes(buf);
    }

    calloc.free(valueName);
    calloc.free(cbData);
    calloc.free(lpType);
    calloc.free(lpData);
    _regCloseKey(hKey);

    if (dllPath.isEmpty) return false;
    return File(dllPath).existsSync();
  }

  void _scheduleSave() {
    _pendingSave = true;
  }

  void saveIfDirty() {
    if (!_pendingSave) return;
    _pendingSave = false;
    saveSettingsSync();
  }

  Future<void> saveSettings() async {
    final data = <String, dynamic>{
      'schemaVersion': 2,
      'preset': _active.toJson(),
    };
    await _settings.save(data);
    _log.debug('Settings saved');
  }

  void saveSettingsSync() {
    _saveCurrentDeviceSettings();
    final data = <String, dynamic>{
      'schemaVersion': 2,
      'preset': _active.toJson(),
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
      update((s) => s.ddc.device = name);
      setDdcEnabled(true);
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
      update((s) => s.convolver.kernel = name);
      setConvolverEnabled(true);
      _log.info('Convolver loaded by name: $name');
    } catch (e) {
      _log.error('Convolver load failed: $e');
    }
  }

  void deleteDdc(String name) {
    _fileManager.deleteFile(name, ProfileFileType.ddc);
    if (_active.ddc.device == name) {
      update((s) => s.ddc.device = '');
      setDdcEnabled(false);
    }
    refreshFileLists();
  }

  void deleteKernel(String name) {
    _fileManager.deleteFile(name, ProfileFileType.kernel);
    if (_active.convolver.kernel == name) {
      update((s) => s.convolver.kernel = '');
      setConvolverEnabled(false);
    }
    refreshFileLists();
  }

  void savePreset(String name) {
    final body = <String, dynamic>{
      'schemaVersion': 2,
      'name': name,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    body.addAll(_active.toJson());
    final json = jsonEncode(body);
    final path = _fileManager.filePath('$name.json', ProfileFileType.preset);
    File(path).writeAsStringSync(json);
    _log.info('Preset saved: $name');
    refreshFileLists();
  }

  int loadPreset(String name) {
    final path = _fileManager.filePath('$name.json', ProfileFileType.preset);
    try {
      final json =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      _suppressPush = true;
      _active.loadFromJson(json);
      _suppressPush = false;
      _reloadActiveFiles();
      pushParams();
      _scheduleSave();
      notifyListeners();
      _log.info('Preset loaded: $name');
      return 0;
    } catch (e) {
      _log.error('Preset load failed: $e');
      return -1;
    }
  }

  void deletePreset(String name) {
    _fileManager.deleteFile('$name.json', ProfileFileType.preset);
    refreshFileLists();
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
      'bandCount': _active.eq.bandCount,
      'bands': List<double>.from(_active.eq.bands),
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
      if (bandCount != _active.eq.bandCount) return;
      final bands = (json['bands'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      _active.eq.bands = bands;
      _active.eq.bandsMap[_active.eq.bandCount] = List<double>.from(bands);
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
      'xLow': _active.dynamicSystem.xLow,
      'xHigh': _active.dynamicSystem.xHigh,
      'yLow': _active.dynamicSystem.yLow,
      'yHigh': _active.dynamicSystem.yHigh,
      'sideGainLow': _active.dynamicSystem.sideGainLow,
      'sideGainHigh': _active.dynamicSystem.sideGainHigh,
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
      _active.dynamicSystem.xLow =
          json['xLow'] as int? ?? _active.dynamicSystem.xLow;
      _active.dynamicSystem.xHigh =
          json['xHigh'] as int? ?? _active.dynamicSystem.xHigh;
      _active.dynamicSystem.yLow =
          json['yLow'] as int? ?? _active.dynamicSystem.yLow;
      _active.dynamicSystem.yHigh =
          json['yHigh'] as int? ?? _active.dynamicSystem.yHigh;
      _active.dynamicSystem.sideGainLow =
          json['sideGainLow'] as int? ?? _active.dynamicSystem.sideGainLow;
      _active.dynamicSystem.sideGainHigh =
          json['sideGainHigh'] as int? ?? _active.dynamicSystem.sideGainHigh;
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
        return (json['bandCount'] as int?) == _active.eq.bandCount;
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

    final preset = data['preset'];
    if (preset is Map<String, dynamic>) {
      _active.loadFromJson(preset);
    }

    _suppressPush = false;
    _ensureDeviceEntry(_currentDeviceId, _isCurrentDeviceHeadphone);
    _loadDeviceSettings(_currentDeviceId, _isCurrentDeviceHeadphone);
    _reloadActiveFiles();
    notifyListeners();
    _log.info('Settings restored');
  }

  void _saveCurrentDeviceSettings() {
    if (_currentDeviceId.isEmpty) return;
    DeviceSettingsManager.saveDevice(
      _currentDeviceId,
      _currentDeviceName,
      _isCurrentDeviceHeadphone,
      _active.toJson(),
    );
  }

  void _loadDeviceSettings(String deviceId, bool isHeadphone) {
    final data = DeviceSettingsManager.loadDevice(deviceId);
    if (data != null && data['settings'] != null) {
      final settings = data['settings'] as Map<String, dynamic>;
      _suppressPush = true;
      _active.loadFromJson(settings);
      _suppressPush = false;
      notifyListeners();
    } else {
      _ensureDeviceEntry(deviceId, isHeadphone);
    }
    pushParams();
    _scheduleSave();
  }

  void _ensureDeviceEntry(String deviceId, bool isHeadphone) {
    if (deviceId.isEmpty) return;
    if (DeviceSettingsManager.loadDevice(deviceId) != null) return;
    final source = _active;
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
    final isHp = data['isHeadphone'] as bool? ?? _isCurrentDeviceHeadphone;
    DeviceSettingsManager.saveDevice(
      deviceId,
      data['deviceName'] as String? ?? '',
      isHp,
      _active.toJson(),
    );
  }

  void loadDevicePreset(String deviceId) {
    final data = DeviceSettingsManager.loadDevice(deviceId);
    if (data == null) return;
    final settings = data['settings'] as Map<String, dynamic>?;
    if (settings == null) return;
    _suppressPush = true;
    _active.loadFromJson(settings);
    _suppressPush = false;
    pushParams();
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
    if (_active.ddc.device.isNotEmpty && _active.ddc.enable) {
      final path = _fileManager.filePath(
        _active.ddc.device,
        ProfileFileType.ddc,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadDdcFile(Uint8List.fromList(bytes));
        _log.info('DDC reloaded: ${_active.ddc.device}');
      } catch (e) {
        _log.error('DDC reload failed: $e');
      }
    }
    if (_active.convolver.kernel.isNotEmpty && _active.convolver.enable) {
      final path = _fileManager.filePath(
        _active.convolver.kernel,
        ProfileFileType.kernel,
      );
      try {
        final bytes = File(path).readAsBytesSync();
        _bulk.loadConvolverKernel(
          Uint8List.fromList(bytes),
          _active.convolver.kernel,
        );
        _log.info('Convolver reloaded: ${_active.convolver.kernel}');
      } catch (e) {
        _log.error('Convolver reload failed: $e');
      }
    }
  }

  @override
  @override
  void dispose() {
    _log.info('Disposing');
    _statusTimer?.cancel();
    saveSettingsSync();
    _deviceDetection.dispose();
    _bulk.close();
    _shm.close();
    FileLogger.shared.close();
    super.dispose();
  }
}
