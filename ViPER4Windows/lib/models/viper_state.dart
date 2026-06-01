import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:viper4windows/models/device_settings.dart';
import 'package:viper4windows/models/dynamic_system_preset.dart';
import 'package:viper4windows/models/shared_params.dart';
import 'package:viper4windows/services/bulk_data_service.dart';
import 'package:viper4windows/services/device_detection_service.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/profile_file_manager.dart';
import 'package:viper4windows/services/settings_service.dart';
import 'package:viper4windows/services/shared_memory_service.dart';

final _log = AppLogger('ViperState');

class AgcState {
  bool enabled = false;
  int strength = 50;
  int maxGain = 100;
  int outputThreshold = 100;

  void copyFrom(AgcState other) {
    enabled = other.enabled;
    strength = other.strength;
    maxGain = other.maxGain;
    outputThreshold = other.outputThreshold;
  }

  Map<String, dynamic> toJson() => {
    'playbackGainEnabled': enabled,
    'playbackGainStrength': strength,
    'playbackGainMaxGain': maxGain,
    'playbackGainOutputThreshold': outputThreshold,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['playbackGainEnabled'] as bool? ?? enabled;
    strength = j['playbackGainStrength'] as int? ?? strength;
    maxGain = j['playbackGainMaxGain'] as int? ?? maxGain;
    outputThreshold =
        j['playbackGainOutputThreshold'] as int? ?? outputThreshold;
  }
}

class FetState {
  bool enabled = false;
  int threshold = -18;
  int ratio = 100;
  bool autoKnee = true;
  int knee = 0;
  int kneeMulti = 0;
  bool autoGain = true;
  int gain = 0;
  bool autoAttack = true;
  int attack = 1;
  int maxAttack = 44;
  bool autoRelease = true;
  int release = 100;
  int maxRelease = 200;
  int crest = 100;
  int adapt = 50;
  bool noClip = true;

  void copyFrom(FetState other) {
    enabled = other.enabled;
    threshold = other.threshold;
    ratio = other.ratio;
    autoKnee = other.autoKnee;
    knee = other.knee;
    kneeMulti = other.kneeMulti;
    autoGain = other.autoGain;
    gain = other.gain;
    autoAttack = other.autoAttack;
    attack = other.attack;
    maxAttack = other.maxAttack;
    autoRelease = other.autoRelease;
    release = other.release;
    maxRelease = other.maxRelease;
    crest = other.crest;
    adapt = other.adapt;
    noClip = other.noClip;
  }

  Map<String, dynamic> toJson() => {
    'fetCompressorEnabled': enabled,
    'fetCompressorThreshold': threshold,
    'fetCompressorRatio': ratio,
    'fetCompressorAutoKnee': autoKnee,
    'fetCompressorKnee': knee,
    'fetCompressorKneeMulti': kneeMulti,
    'fetCompressorAutoGain': autoGain,
    'fetCompressorGain': gain,
    'fetCompressorAutoAttack': autoAttack,
    'fetCompressorAttack': attack,
    'fetCompressorMaxAttack': maxAttack,
    'fetCompressorAutoRelease': autoRelease,
    'fetCompressorRelease': release,
    'fetCompressorMaxRelease': maxRelease,
    'fetCompressorCrest': crest,
    'fetCompressorAdapt': adapt,
    'fetCompressorNoClip': noClip,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['fetCompressorEnabled'] as bool? ?? enabled;
    threshold = j['fetCompressorThreshold'] as int? ?? threshold;
    ratio = j['fetCompressorRatio'] as int? ?? ratio;
    autoKnee = j['fetCompressorAutoKnee'] as bool? ?? autoKnee;
    knee = j['fetCompressorKnee'] as int? ?? knee;
    kneeMulti = j['fetCompressorKneeMulti'] as int? ?? kneeMulti;
    autoGain = j['fetCompressorAutoGain'] as bool? ?? autoGain;
    gain = j['fetCompressorGain'] as int? ?? gain;
    autoAttack = j['fetCompressorAutoAttack'] as bool? ?? autoAttack;
    attack = j['fetCompressorAttack'] as int? ?? attack;
    maxAttack = j['fetCompressorMaxAttack'] as int? ?? maxAttack;
    autoRelease = j['fetCompressorAutoRelease'] as bool? ?? autoRelease;
    release = j['fetCompressorRelease'] as int? ?? release;
    maxRelease = j['fetCompressorMaxRelease'] as int? ?? maxRelease;
    crest = j['fetCompressorCrest'] as int? ?? crest;
    adapt = j['fetCompressorAdapt'] as int? ?? adapt;
    noClip = j['fetCompressorNoClip'] as bool? ?? noClip;
  }
}

class DdcState {
  bool enabled = false;
  String device = '';

  void copyFrom(DdcState other) {
    enabled = other.enabled;
    device = other.device;
  }

  Map<String, dynamic> toJson() => {
    'ddcEnabled': enabled,
    'ddcFilePath': device,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['ddcEnabled'] as bool? ?? enabled;
    device = j['ddcFilePath'] as String? ?? device;
  }
}

class VseState {
  bool enabled = false;
  int strength = 7600;
  int exciter = 0;

  void copyFrom(VseState other) {
    enabled = other.enabled;
    strength = other.strength;
    exciter = other.exciter;
  }

  Map<String, dynamic> toJson() => {
    'spectrumExtensionEnabled': enabled,
    'spectrumExtensionBark': strength,
    'spectrumExtensionExciter': exciter,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['spectrumExtensionEnabled'] as bool? ?? enabled;
    strength = j['spectrumExtensionBark'] as int? ?? strength;
    exciter = j['spectrumExtensionExciter'] as int? ?? exciter;
  }
}

class EqState {
  bool enabled = false;
  int bandCount = 10;
  List<double> bands = List.filled(10, 0.0);
  Map<int, List<double>> bandsMap = {10: List.filled(10, 0.0)};

  void copyFrom(EqState other) {
    enabled = other.enabled;
    bandCount = other.bandCount;
    bands = List<double>.from(other.bands);
    bandsMap = other.bandsMap.map((k, v) => MapEntry(k, List<double>.from(v)));
  }

  Map<String, dynamic> toJson() => {
    'equalizerEnabled': enabled,
    'equalizerBandCount': bandCount,
    'equalizerBands': bands,
    'equalizerBandsMap': bandsMap.map((k, v) => MapEntry(k.toString(), v)),
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['equalizerEnabled'] as bool? ?? enabled;
    bandCount = j['equalizerBandCount'] as int? ?? bandCount;
    if (j['equalizerBands'] is List) {
      bands = (j['equalizerBands'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }
    if (j['equalizerBandsMap'] is Map) {
      bandsMap = (j['equalizerBandsMap'] as Map).map(
        (k, v) => MapEntry(
          int.parse(k.toString()),
          (v as List).map((e) => (e as num).toDouble()).toList(),
        ),
      );
    }
  }
}

class ConvolverState {
  bool enabled = false;
  String kernel = '';
  int crossChannel = 0;

  void copyFrom(ConvolverState other) {
    enabled = other.enabled;
    kernel = other.kernel;
    crossChannel = other.crossChannel;
  }

  Map<String, dynamic> toJson() => {
    'convolutionEnabled': enabled,
    'convolutionKernelPath': kernel,
    'convolutionCrossChannel': crossChannel,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['convolutionEnabled'] as bool? ?? enabled;
    kernel = j['convolutionKernelPath'] as String? ?? kernel;
    crossChannel = j['convolutionCrossChannel'] as int? ?? crossChannel;
  }
}

class FieldSurroundState {
  bool enabled = false;
  int widening = 0;
  int midImage = 5;
  int depth = 0;

  void copyFrom(FieldSurroundState other) {
    enabled = other.enabled;
    widening = other.widening;
    midImage = other.midImage;
    depth = other.depth;
  }

  Map<String, dynamic> toJson() => {
    'fieldSurroundEnabled': enabled,
    'fieldSurroundWidening': widening,
    'fieldSurroundMidImage': midImage,
    'fieldSurroundDepth': depth,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['fieldSurroundEnabled'] as bool? ?? enabled;
    widening = j['fieldSurroundWidening'] as int? ?? widening;
    midImage = j['fieldSurroundMidImage'] as int? ?? midImage;
    depth = j['fieldSurroundDepth'] as int? ?? depth;
  }
}

class DiffSurroundState {
  bool enabled = false;
  int delay = 5;
  bool reverse = false;
  int wetDryMix = 100;
  int lpCutoff = 0;

  void copyFrom(DiffSurroundState other) {
    enabled = other.enabled;
    delay = other.delay;
    reverse = other.reverse;
    wetDryMix = other.wetDryMix;
    lpCutoff = other.lpCutoff;
  }

  Map<String, dynamic> toJson() => {
    'diffSurroundEnabled': enabled,
    'diffSurroundDelay': delay,
    'diffSurroundReverse': reverse,
    'diffSurroundWetDryMix': wetDryMix,
    'diffSurroundLpCutoff': lpCutoff,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['diffSurroundEnabled'] as bool? ?? enabled;
    delay = j['diffSurroundDelay'] as int? ?? delay;
    reverse = j['diffSurroundReverse'] as bool? ?? reverse;
    wetDryMix = j['diffSurroundWetDryMix'] as int? ?? wetDryMix;
    lpCutoff = j['diffSurroundLpCutoff'] as int? ?? lpCutoff;
  }
}

class VheState {
  bool enabled = false;
  int quality = 0;

  void copyFrom(VheState other) {
    enabled = other.enabled;
    quality = other.quality;
  }

  Map<String, dynamic> toJson() => {
    'vheEnabled': enabled,
    'vheQuality': quality,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['vheEnabled'] as bool? ?? enabled;
    quality = j['vheQuality'] as int? ?? quality;
  }
}

class ReverbState {
  bool enabled = false;
  int roomSize = 0;
  int width = 0;
  int roomDampening = 0;
  int wet = 0;
  int dry = 50;

  void copyFrom(ReverbState other) {
    enabled = other.enabled;
    roomSize = other.roomSize;
    width = other.width;
    roomDampening = other.roomDampening;
    wet = other.wet;
    dry = other.dry;
  }

  Map<String, dynamic> toJson() => {
    'reverberationEnabled': enabled,
    'reverberationRoomSize': roomSize,
    'reverberationRoomWidth': width,
    'reverberationRoomDampening': roomDampening,
    'reverberationWetSignal': wet,
    'reverberationDrySignal': dry,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['reverberationEnabled'] as bool? ?? enabled;
    roomSize = j['reverberationRoomSize'] as int? ?? roomSize;
    width = j['reverberationRoomWidth'] as int? ?? width;
    roomDampening = j['reverberationRoomDampening'] as int? ?? roomDampening;
    wet = j['reverberationWetSignal'] as int? ?? wet;
    dry = j['reverberationDrySignal'] as int? ?? dry;
  }
}

class DynamicSystemState {
  bool enabled = false;
  int device = 0;
  int strength = 50;
  int xLow = 100;
  int xHigh = 5600;
  int yLow = 40;
  int yHigh = 80;
  int sideGainLow = 50;
  int sideGainHigh = 50;

  void copyFrom(DynamicSystemState other) {
    enabled = other.enabled;
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
    'dynamicSystemEnabled': enabled,
    'dynamicSystemDevice': device,
    'dynamicSystemStrength': strength,
    'dsXLow': xLow,
    'dsXHigh': xHigh,
    'dsYLow': yLow,
    'dsYHigh': yHigh,
    'dsSideGainLow': sideGainLow,
    'dsSideGainHigh': sideGainHigh,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['dynamicSystemEnabled'] as bool? ?? enabled;
    device = j['dynamicSystemDevice'] as int? ?? device;
    strength = j['dynamicSystemStrength'] as int? ?? strength;
    xLow = j['dsXLow'] as int? ?? xLow;
    xHigh = j['dsXHigh'] as int? ?? xHigh;
    yLow = j['dsYLow'] as int? ?? yLow;
    yHigh = j['dsYHigh'] as int? ?? yHigh;
    sideGainLow = j['dsSideGainLow'] as int? ?? sideGainLow;
    sideGainHigh = j['dsSideGainHigh'] as int? ?? sideGainHigh;
  }
}

class BassState {
  bool enabled = false;
  int mode = 0;
  int frequency = 55;
  int gain = 50;
  bool antiPop = true;

  void copyFrom(BassState other) {
    enabled = other.enabled;
    mode = other.mode;
    frequency = other.frequency;
    gain = other.gain;
    antiPop = other.antiPop;
  }

  Map<String, dynamic> toJson() => {
    'viperBassEnabled': enabled,
    'viperBassMode': mode,
    'viperBassFrequency': frequency,
    'viperBassGain': gain,
    'viperBassAntiPop': antiPop,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['viperBassEnabled'] as bool? ?? enabled;
    mode = j['viperBassMode'] as int? ?? mode;
    frequency = j['viperBassFrequency'] as int? ?? frequency;
    gain = j['viperBassGain'] as int? ?? gain;
    antiPop = j['viperBassAntiPop'] as bool? ?? antiPop;
  }
}

class BassMonoState {
  bool enabled = false;
  int mode = 0;
  int frequency = 55;
  int gain = 50;
  bool antiPop = true;

  void copyFrom(BassMonoState other) {
    enabled = other.enabled;
    mode = other.mode;
    frequency = other.frequency;
    gain = other.gain;
    antiPop = other.antiPop;
  }

  Map<String, dynamic> toJson() => {
    'viperBassMonoEnabled': enabled,
    'viperBassMonoMode': mode,
    'viperBassMonoFrequency': frequency,
    'viperBassMonoGain': gain,
    'viperBassMonoAntiPop': antiPop,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['viperBassMonoEnabled'] as bool? ?? enabled;
    mode = j['viperBassMonoMode'] as int? ?? mode;
    frequency = j['viperBassMonoFrequency'] as int? ?? frequency;
    gain = j['viperBassMonoGain'] as int? ?? gain;
    antiPop = j['viperBassMonoAntiPop'] as bool? ?? antiPop;
  }
}

class ClarityState {
  bool enabled = false;
  int mode = 0;
  int gain = 50;

  void copyFrom(ClarityState other) {
    enabled = other.enabled;
    mode = other.mode;
    gain = other.gain;
  }

  Map<String, dynamic> toJson() => {
    'viperClarityEnabled': enabled,
    'viperClarityMode': mode,
    'viperClarityGain': gain,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['viperClarityEnabled'] as bool? ?? enabled;
    mode = j['viperClarityMode'] as int? ?? mode;
    gain = j['viperClarityGain'] as int? ?? gain;
  }
}

class CureState {
  bool enabled = false;
  int strength = 0;

  void copyFrom(CureState other) {
    enabled = other.enabled;
    strength = other.strength;
  }

  Map<String, dynamic> toJson() => {
    'cureEnabled': enabled,
    'cureCrossfeedStrength': strength,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['cureEnabled'] as bool? ?? enabled;
    strength = j['cureCrossfeedStrength'] as int? ?? strength;
  }
}

class AnalogXState {
  bool enabled = false;
  int mode = 0;

  void copyFrom(AnalogXState other) {
    enabled = other.enabled;
    mode = other.mode;
  }

  Map<String, dynamic> toJson() => {
    'analogXEnabled': enabled,
    'analogXMode': mode,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['analogXEnabled'] as bool? ?? enabled;
    mode = j['analogXMode'] as int? ?? mode;
  }
}

class MultibandCompressorState {
  static const bandCount = 5;
  bool enabled = false;
  List<int> thresholds = List.filled(5, -18);
  List<int> ratios = List.filled(5, 50);
  List<int> knees = List.filled(5, 0);
  List<bool> autoKnees = List.filled(5, true);
  List<int> gains = List.filled(5, 24);
  List<bool> autoGains = List.filled(5, true);
  List<int> attacks = List.filled(5, 1);
  List<bool> autoAttacks = List.filled(5, true);
  List<int> releases = List.filled(5, 100);
  List<bool> autoReleases = List.filled(5, true);
  List<int> kneeMultis = List.filled(5, 0);
  List<int> maxAttacks = List.filled(5, 44);
  List<int> maxReleases = List.filled(5, 200);
  List<int> crests = List.filled(5, 100);
  List<int> adapts = List.filled(5, 50);
  List<bool> noClips = List.filled(5, true);
  List<bool> bandEnables = List.filled(5, true);
  List<int> crossovers = [120, 500, 4000, 8000];

  void copyFrom(MultibandCompressorState other) {
    enabled = other.enabled;
    thresholds = List<int>.from(other.thresholds);
    ratios = List<int>.from(other.ratios);
    knees = List<int>.from(other.knees);
    autoKnees = List<bool>.from(other.autoKnees);
    gains = List<int>.from(other.gains);
    autoGains = List<bool>.from(other.autoGains);
    attacks = List<int>.from(other.attacks);
    autoAttacks = List<bool>.from(other.autoAttacks);
    releases = List<int>.from(other.releases);
    autoReleases = List<bool>.from(other.autoReleases);
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
    'mbcEnabled': enabled,
    'mbcThresholds': thresholds,
    'mbcRatios': ratios,
    'mbcKnees': knees,
    'mbcAutoKnees': autoKnees,
    'mbcGains': gains,
    'mbcAutoGains': autoGains,
    'mbcAttacks': attacks,
    'mbcAutoAttacks': autoAttacks,
    'mbcReleases': releases,
    'mbcAutoReleases': autoReleases,
    'mbcKneeMultis': kneeMultis,
    'mbcMaxAttacks': maxAttacks,
    'mbcMaxReleases': maxReleases,
    'mbcCrests': crests,
    'mbcAdapts': adapts,
    'mbcNoClips': noClips,
    'mbcBandEnables': bandEnables,
    'mbcCrossovers': crossovers,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['mbcEnabled'] as bool? ?? enabled;
    if (j['mbcThresholds'] is List) {
      thresholds = (j['mbcThresholds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcRatios'] is List) {
      ratios = (j['mbcRatios'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['mbcKnees'] is List) {
      knees = (j['mbcKnees'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['mbcAutoKnees'] is List) {
      autoKnees = (j['mbcAutoKnees'] as List).map((e) => e as bool).toList();
    }
    if (j['mbcGains'] is List) {
      gains = (j['mbcGains'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['mbcAutoGains'] is List) {
      autoGains = (j['mbcAutoGains'] as List).map((e) => e as bool).toList();
    }
    if (j['mbcAttacks'] is List) {
      attacks = (j['mbcAttacks'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcAutoAttacks'] is List) {
      autoAttacks = (j['mbcAutoAttacks'] as List)
          .map((e) => e as bool)
          .toList();
    }
    if (j['mbcReleases'] is List) {
      releases = (j['mbcReleases'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcAutoReleases'] is List) {
      autoReleases = (j['mbcAutoReleases'] as List)
          .map((e) => e as bool)
          .toList();
    }
    if (j['mbcKneeMultis'] is List) {
      kneeMultis = (j['mbcKneeMultis'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcMaxAttacks'] is List) {
      maxAttacks = (j['mbcMaxAttacks'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcMaxReleases'] is List) {
      maxReleases = (j['mbcMaxReleases'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['mbcCrests'] is List) {
      crests = (j['mbcCrests'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['mbcAdapts'] is List) {
      adapts = (j['mbcAdapts'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['mbcNoClips'] is List) {
      noClips = (j['mbcNoClips'] as List).map((e) => e as bool).toList();
    }
    if (j['mbcBandEnables'] is List) {
      bandEnables = (j['mbcBandEnables'] as List)
          .map((e) => e as bool)
          .toList();
    }
    if (j['mbcCrossovers'] is List) {
      crossovers = (j['mbcCrossovers'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
  }
}

class DynamicEqState {
  bool enabled = false;
  int bandCount = 3;
  List<int> freqs = [60, 150, 400, 1000, 2500, 5000, 8000, 12000];
  List<int> qs = [100, 100, 150, 150, 150, 200, 200, 200];
  List<int> gains = List.filled(8, 0);
  List<int> thresholds = [-300, -300, -250, -250, -200, -200, -200, -200];
  List<int> attacks = List.filled(8, 10);
  List<int> releases = List.filled(8, 100);
  List<int> filterTypes = List.filled(8, 0);

  void copyFrom(DynamicEqState other) {
    enabled = other.enabled;
    bandCount = other.bandCount;
    freqs = List<int>.from(other.freqs);
    qs = List<int>.from(other.qs);
    gains = List<int>.from(other.gains);
    thresholds = List<int>.from(other.thresholds);
    attacks = List<int>.from(other.attacks);
    releases = List<int>.from(other.releases);
    filterTypes = List<int>.from(other.filterTypes);
  }

  Map<String, dynamic> toJson() => {
    'dynEqEnabled': enabled,
    'dynEqBandCount': bandCount,
    'dynEqFreqs': freqs,
    'dynEqQs': qs,
    'dynEqGains': gains,
    'dynEqThresholds': thresholds,
    'dynEqAttacks': attacks,
    'dynEqReleases': releases,
    'dynEqFilterTypes': filterTypes,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['dynEqEnabled'] as bool? ?? enabled;
    bandCount = j['dynEqBandCount'] as int? ?? bandCount;
    if (j['dynEqFreqs'] is List) {
      freqs = (j['dynEqFreqs'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['dynEqQs'] is List) {
      qs = (j['dynEqQs'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['dynEqGains'] is List) {
      gains = (j['dynEqGains'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (j['dynEqThresholds'] is List) {
      thresholds = (j['dynEqThresholds'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['dynEqAttacks'] is List) {
      attacks = (j['dynEqAttacks'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['dynEqReleases'] is List) {
      releases = (j['dynEqReleases'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
    if (j['dynEqFilterTypes'] is List) {
      filterTypes = (j['dynEqFilterTypes'] as List)
          .map((e) => (e as num).toInt())
          .toList();
    }
  }
}

class StereoImagerState {
  bool enabled = false;
  int lowWidth = 100;
  int midWidth = 100;
  int highWidth = 100;
  int lowCrossover = 200;
  int highCrossover = 4000;

  void copyFrom(StereoImagerState other) {
    enabled = other.enabled;
    lowWidth = other.lowWidth;
    midWidth = other.midWidth;
    highWidth = other.highWidth;
    lowCrossover = other.lowCrossover;
    highCrossover = other.highCrossover;
  }

  Map<String, dynamic> toJson() => {
    'stereoImagerEnabled': enabled,
    'stereoImagerLowWidth': lowWidth,
    'stereoImagerMidWidth': midWidth,
    'stereoImagerHighWidth': highWidth,
    'stereoImagerLowCrossover': lowCrossover,
    'stereoImagerHighCrossover': highCrossover,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['stereoImagerEnabled'] as bool? ?? enabled;
    lowWidth = j['stereoImagerLowWidth'] as int? ?? lowWidth;
    midWidth = j['stereoImagerMidWidth'] as int? ?? midWidth;
    highWidth = j['stereoImagerHighWidth'] as int? ?? highWidth;
    lowCrossover = j['stereoImagerLowCrossover'] as int? ?? lowCrossover;
    highCrossover = j['stereoImagerHighCrossover'] as int? ?? highCrossover;
  }
}

class LufsState {
  bool enabled = false;
  int target = 140;
  int maxGain = 60;
  int speed = 1;

  void copyFrom(LufsState other) {
    enabled = other.enabled;
    target = other.target;
    maxGain = other.maxGain;
    speed = other.speed;
  }

  Map<String, dynamic> toJson() => {
    'lufsEnabled': enabled,
    'lufsTarget': target,
    'lufsMaxGain': maxGain,
    'lufsSpeed': speed,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['lufsEnabled'] as bool? ?? enabled;
    target = j['lufsTarget'] as int? ?? target;
    maxGain = j['lufsMaxGain'] as int? ?? maxGain;
    speed = j['lufsSpeed'] as int? ?? speed;
  }
}

class PsychoBassState {
  bool enabled = false;
  int cutoff = 80;
  int intensity = 50;
  int harmonicOrder = 3;
  int originalLevel = 100;

  void copyFrom(PsychoBassState other) {
    enabled = other.enabled;
    cutoff = other.cutoff;
    intensity = other.intensity;
    harmonicOrder = other.harmonicOrder;
    originalLevel = other.originalLevel;
  }

  Map<String, dynamic> toJson() => {
    'psychoBassEnabled': enabled,
    'psychoBassCutoff': cutoff,
    'psychoBassIntensity': intensity,
    'psychoBassHarmonicOrder': harmonicOrder,
    'psychoBassOriginalLevel': originalLevel,
  };

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['psychoBassEnabled'] as bool? ?? enabled;
    cutoff = j['psychoBassCutoff'] as int? ?? cutoff;
    intensity = j['psychoBassIntensity'] as int? ?? intensity;
    harmonicOrder = j['psychoBassHarmonicOrder'] as int? ?? harmonicOrder;
    originalLevel = j['psychoBassOriginalLevel'] as int? ?? originalLevel;
  }
}

class TubeSimulatorState {
  bool enabled = false;

  void copyFrom(TubeSimulatorState other) {
    enabled = other.enabled;
  }

  Map<String, dynamic> toJson() => {'tubeSimulatorEnabled': enabled};

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['tubeSimulatorEnabled'] as bool? ?? enabled;
  }
}

class SpeakerCorrectionState {
  bool enabled = false;

  void copyFrom(SpeakerCorrectionState other) {
    enabled = other.enabled;
  }

  Map<String, dynamic> toJson() => {'speakerCorrectionEnabled': enabled};

  void loadFromJson(Map<String, dynamic> j) {
    enabled = j['speakerCorrectionEnabled'] as bool? ?? enabled;
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
    'outputVolume': volume,
    'channelPan': channelPan,
    'limiter': limiter,
  };

  void loadFromJson(Map<String, dynamic> j) {
    volume = j['outputVolume'] as int? ?? volume;
    channelPan = j['channelPan'] as int? ?? channelPan;
    limiter = j['limiter'] as int? ?? limiter;
  }
}

class ModeState {
  int mode = 0;
  final out = OutputState();
  final agc = AgcState();
  final fet = FetState();
  final ddc = DdcState();
  final vse = VseState();
  final eq = EqState();
  final convolver = ConvolverState();
  final fieldSurround = FieldSurroundState();
  final diffSurround = DiffSurroundState();
  final vhe = VheState();
  final reverb = ReverbState();
  final dynamicSystem = DynamicSystemState();
  final tube = TubeSimulatorState();
  final bass = BassState();
  final bassMono = BassMonoState();
  final clarity = ClarityState();
  final cure = CureState();
  final analog = AnalogXState();
  final speakerCorrection = SpeakerCorrectionState();
  final mbc = MultibandCompressorState();
  final dynamicEq = DynamicEqState();
  final stereoImager = StereoImagerState();
  final lufs = LufsState();
  final psychoBass = PsychoBassState();

  void copyFrom(ModeState other) {
    mode = other.mode;
    out.copyFrom(other.out);
    agc.copyFrom(other.agc);
    fet.copyFrom(other.fet);
    ddc.copyFrom(other.ddc);
    vse.copyFrom(other.vse);
    eq.copyFrom(other.eq);
    convolver.copyFrom(other.convolver);
    fieldSurround.copyFrom(other.fieldSurround);
    diffSurround.copyFrom(other.diffSurround);
    vhe.copyFrom(other.vhe);
    reverb.copyFrom(other.reverb);
    dynamicSystem.copyFrom(other.dynamicSystem);
    tube.copyFrom(other.tube);
    bass.copyFrom(other.bass);
    bassMono.copyFrom(other.bassMono);
    clarity.copyFrom(other.clarity);
    cure.copyFrom(other.cure);
    analog.copyFrom(other.analog);
    speakerCorrection.copyFrom(other.speakerCorrection);
    mbc.copyFrom(other.mbc);
    dynamicEq.copyFrom(other.dynamicEq);
    stereoImager.copyFrom(other.stereoImager);
    lufs.copyFrom(other.lufs);
    psychoBass.copyFrom(other.psychoBass);
  }

  ModeState clone() {
    final c = ModeState();
    c.copyFrom(this);
    return c;
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    ...out.toJson(),
    ...agc.toJson(),
    ...fet.toJson(),
    ...ddc.toJson(),
    ...vse.toJson(),
    ...eq.toJson(),
    ...convolver.toJson(),
    ...fieldSurround.toJson(),
    ...diffSurround.toJson(),
    ...vhe.toJson(),
    ...reverb.toJson(),
    ...dynamicSystem.toJson(),
    ...tube.toJson(),
    ...bass.toJson(),
    ...bassMono.toJson(),
    ...clarity.toJson(),
    ...cure.toJson(),
    ...analog.toJson(),
    ...speakerCorrection.toJson(),
    ...mbc.toJson(),
    ...dynamicEq.toJson(),
    ...stereoImager.toJson(),
    ...lufs.toJson(),
    ...psychoBass.toJson(),
  };

  void loadFromJson(Map<String, dynamic> j) {
    mode = j['mode'] as int? ?? mode;
    out.loadFromJson(j);
    agc.loadFromJson(j);
    fet.loadFromJson(j);
    ddc.loadFromJson(j);
    vse.loadFromJson(j);
    eq.loadFromJson(j);
    convolver.loadFromJson(j);
    fieldSurround.loadFromJson(j);
    diffSurround.loadFromJson(j);
    vhe.loadFromJson(j);
    reverb.loadFromJson(j);
    dynamicSystem.loadFromJson(j);
    tube.loadFromJson(j);
    speakerCorrection.loadFromJson(j);
    bass.loadFromJson(j);
    bassMono.loadFromJson(j);
    clarity.loadFromJson(j);
    cure.loadFromJson(j);
    analog.loadFromJson(j);
    mbc.loadFromJson(j);
    dynamicEq.loadFromJson(j);
    stereoImager.loadFromJson(j);
    lufs.loadFromJson(j);
    psychoBass.loadFromJson(j);
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
  int _lastProcessedFrames = 0;

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

  ModeState get active => _active;

  bool get masterEnabled => _masterEnabled;
  int get fxType => _fxType;
  int get activeDeviceType => _activeDeviceType;
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

  void setDdcEnabled(bool v) {
    if (_active.ddc.enabled == v) return;
    _active.ddc.enabled = v;
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
    if (_active.convolver.enabled == v) return;
    _active.convolver.enabled = v;
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
    if (_active.dynamicEq.bandCount >= 8) return;
    final lastFreq = _active.dynamicEq.bandCount == 0
        ? 20
        : _active.dynamicEq.freqs[_active.dynamicEq.bandCount - 1];
    if (lastFreq >= 20000) return;
    _active.dynamicEq.bandCount++;
    _active.dynamicEq.freqs[_active.dynamicEq.bandCount - 1] = (lastFreq + 1000)
        .clamp(lastFreq + 5, 20000);
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

    _apoProcessing =
        status.processedFrames > 0 &&
        status.processedFrames != _lastProcessedFrames;
    _lastProcessedFrames = status.processedFrames;

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
    if (_active.ddc.device.isNotEmpty && _active.ddc.enabled) {
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
    if (_active.convolver.kernel.isNotEmpty && _active.convolver.enabled) {
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
    _saveTimer?.cancel();
    saveSettingsSync();
    _deviceDetection.dispose();
    _bulk.close();
    _shm.close();
    FileLogger.shared.close();
    super.dispose();
  }
}
