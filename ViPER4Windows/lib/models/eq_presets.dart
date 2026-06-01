import 'package:viper4windows/l10n/app_localizations.dart';

class EqLabels {
  EqLabels._();

  // dart format off
  static const graph10 = ['31', '62', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];
  static const graph15 = ['25', '40', '63', '100', '160', '250', '400', '630', '1k', '1.6k', '2.5k', '4k', '6.3k', '10k', '16k'];
  static const graph25 = ['20', '31', '40', '50', '80', '100', '125', '160', '250', '315', '400', '500', '800', '1k', '1.25k', '1.6k', '2.5k', '3.15k', '4k', '5k', '8k', '10k', '12.5k', '16k', '20k'];
  static const graph31 = ['20', '25', '31', '40', '50', '63', '80', '100', '125', '160', '200', '250', '315', '400', '500', '630', '800', '1k', '1.25k', '1.6k', '2k', '2.5k', '3.15k', '4k', '5k', '6.3k', '8k', '10k', '12.5k', '16k', '20k'];

  static const full10 = ['31Hz', '62Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'];
  static const full15 = ['25Hz', '40Hz', '63Hz', '100Hz', '160Hz', '250Hz', '400Hz', '630Hz', '1kHz', '1.6kHz', '2.5kHz', '4kHz', '6.3kHz', '10kHz', '16kHz'];
  static const full25 = ['20Hz', '31Hz', '40Hz', '50Hz', '80Hz', '100Hz', '125Hz', '160Hz', '250Hz', '315Hz', '400Hz', '500Hz', '800Hz', '1kHz', '1.25kHz', '1.6kHz', '2.5kHz', '3.15kHz', '4kHz', '5kHz', '8kHz', '10kHz', '12.5kHz', '16kHz', '20kHz'];
  static const full31 = ['20Hz', '25Hz', '31Hz', '40Hz', '50Hz', '63Hz', '80Hz', '100Hz', '125Hz', '160Hz', '200Hz', '250Hz', '315Hz', '400Hz', '500Hz', '630Hz', '800Hz', '1kHz', '1.25kHz', '1.6kHz', '2kHz', '2.5kHz', '3.15kHz', '4kHz', '5kHz', '6.3kHz', '8kHz', '10kHz', '12.5kHz', '16kHz', '20kHz'];
  // dart format on

  static List<String> graphLabels(int count) {
    switch (count) {
      case 15:
        return graph15;
      case 25:
        return graph25;
      case 31:
        return graph31;
      default:
        return graph10;
    }
  }

  static List<String> fullLabels(int count) {
    switch (count) {
      case 15:
        return full15;
      case 25:
        return full25;
      case 31:
        return full31;
      default:
        return full10;
    }
  }

  static int labelStep(int count) {
    switch (count) {
      case 31:
        return 5;
      case 25:
        return 4;
      case 15:
        return 2;
      default:
        return 1;
    }
  }
}

class BuiltinEqPreset {
  final String Function(S) nameOf;
  final List<double> bands10;
  final List<double> bands15;
  final List<double> bands25;
  final List<double> bands31;

  const BuiltinEqPreset({
    required this.nameOf,
    required this.bands10,
    required this.bands15,
    required this.bands25,
    required this.bands31,
  });

  List<double> bandsFor(int count) {
    switch (count) {
      case 15:
        return bands15;
      case 25:
        return bands25;
      case 31:
        return bands31;
      default:
        return bands10;
    }
  }
}

class EqPresets {
  EqPresets._();

  // dart format off
  static const List<BuiltinEqPreset> builtins = [
    BuiltinEqPreset(
      nameOf: _acoustic,
      bands10: [4.5, 4.5, 3.5, 1.2, 1.0, 0.5, 1.4, 1.75, 3.5, 2.5],
      bands15: [4.5, 4.5, 4.5, 4.0, 2.5, 1.0, 1.0, 1.0, 0.5, 1.0, 1.5, 2.0, 3.0, 3.0, 2.5],
      bands25: [4.5, 4.5, 4.5, 4.5, 4.0, 4.0, 3.5, 2.5, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.5, 1.5, 2.0, 2.5, 3.5, 3.0, 3.0, 2.5, 2.5],
      bands31: [4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.0, 4.0, 3.5, 2.5, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.5, 1.5, 1.5, 2.0, 2.5, 3.0, 3.5, 3.0, 3.0, 2.5, 2.5],
    ),
    BuiltinEqPreset(
      nameOf: _bassBooster,
      bands10: [6.0, 4.0, 2.0, 0, 0, 0, 0, 0, 0, 0],
      bands15: [6.0, 5.5, 4.0, 2.5, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands25: [6.0, 6.0, 5.5, 4.5, 3.5, 2.5, 2.0, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands31: [6.0, 6.0, 6.0, 5.5, 4.5, 4.0, 3.5, 2.5, 2.0, 1.5, 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    BuiltinEqPreset(
      nameOf: _bassReducer,
      bands10: [-6.0, -4.0, -2.0, 0, 0, 0, 0, 0, 0, 0],
      bands15: [-6.0, -5.5, -4.0, -2.5, -1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands25: [-6.0, -6.0, -5.5, -4.5, -3.5, -2.5, -2.0, -1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands31: [-6.0, -6.0, -6.0, -5.5, -4.5, -4.0, -3.5, -2.5, -2.0, -1.5, -0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    BuiltinEqPreset(
      nameOf: _classical,
      bands10: [0, 0, 0, 0, 0, 0, -3.0, -3.0, -3.0, -5.0],
      bands15: [0, 0, 0, 0, 0, 0, 0, 0, 0, -2.0, -3.0, -3.0, -3.0, -3.5, -5.0],
      bands25: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.5, -4.5, -5.0, -5.0],
      bands31: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.0, -3.5, -4.5, -5.0, -5.0],
    ),
    BuiltinEqPreset(
      nameOf: _deep,
      bands10: [3.0, 2.0, 1.0, 0.5, 0.5, 0, -1.0, -2.0, -3.0, -3.5],
      bands15: [3.0, 2.5, 2.0, 1.5, 1.0, 0.5, 0.5, 0.5, 0, -0.5, -1.5, -2.0, -2.5, -3.0, -3.5],
      bands25: [3.0, 3.0, 2.5, 2.5, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0, 0, -0.5, -0.5, -1.5, -1.5, -2.0, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5],
      bands31: [3.0, 3.0, 3.0, 2.5, 2.5, 2.0, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0, 0, -0.5, -0.5, -1.0, -1.5, -1.5, -2.0, -2.5, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5],
    ),
    BuiltinEqPreset(
      nameOf: _flat,
      bands10: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands15: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands25: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      bands31: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    BuiltinEqPreset(
      nameOf: _rnb,
      bands10: [3.0, 6.0, 4.0, 1.0, -1.0, -0.5, 1.0, 1.5, 2.5, 3.0],
      bands15: [3.0, 4.0, 6.0, 4.5, 3.0, 1.0, -0.5, -1.0, -0.5, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0],
      bands25: [3.0, 3.0, 4.0, 5.0, 5.5, 4.5, 4.0, 3.0, 1.0, 0.5, -0.5, -1.0, -0.5, -0.5, 0, 0.5, 1.0, 1.5, 1.5, 2.0, 2.5, 2.5, 3.0, 3.0, 3.0],
      bands31: [3.0, 3.0, 3.0, 4.0, 5.0, 6.0, 5.5, 4.5, 4.0, 3.0, 2.0, 1.0, 0.5, -0.5, -1.0, -1.0, -0.5, -0.5, 0, 0.5, 1.0, 1.0, 1.5, 1.5, 2.0, 2.0, 2.5, 2.5, 3.0, 3.0, 3.0],
    ),
    BuiltinEqPreset(
      nameOf: _rock,
      bands10: [4.0, 3.0, 1.0, 0, -0.5, 0, 1.5, 2.5, 3.5, 4.0],
      bands15: [4.0, 3.5, 3.0, 1.5, 0.5, 0, -0.5, -0.5, 0, 1.0, 2.0, 2.5, 3.0, 3.5, 4.0],
      bands25: [4.0, 4.0, 3.5, 3.5, 2.5, 1.5, 1.0, 0.5, 0, 0, -0.5, -0.5, 0, 0, 0.5, 1.0, 2.0, 2.0, 2.5, 3.0, 3.5, 3.5, 4.0, 4.0, 4.0],
      bands31: [4.0, 4.0, 4.0, 3.5, 3.5, 3.0, 2.5, 1.5, 1.0, 0.5, 0.5, 0, 0, -0.5, -0.5, -0.5, 0, 0, 0.5, 1.0, 1.5, 2.0, 2.0, 2.5, 3.0, 3.0, 3.5, 3.5, 4.0, 4.0, 4.0],
    ),
    BuiltinEqPreset(
      nameOf: _smallSpeakers,
      bands10: [3.0, 2.0, 1.5, 1.0, 0.5, -0.5, -1.5, -2.0, -3.0, -3.5],
      bands15: [3.0, 2.5, 2.0, 1.5, 1.5, 1.0, 0.5, 0, -0.5, -1.0, -1.5, -2.0, -2.5, -3.0, -3.5],
      bands25: [3.0, 3.0, 2.5, 2.5, 2.0, 1.5, 1.5, 1.5, 1.0, 1.0, 0.5, 0.5, 0, -0.5, -1.0, -1.0, -1.5, -2.0, -2.0, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5],
      bands31: [3.0, 3.0, 3.0, 2.5, 2.5, 2.0, 2.0, 1.5, 1.5, 1.5, 1.0, 1.0, 1.0, 0.5, 0.5, 0, 0, -0.5, -1.0, -1.0, -1.5, -1.5, -2.0, -2.0, -2.5, -2.5, -3.0, -3.0, -3.5, -3.5, -3.5],
    ),
    BuiltinEqPreset(
      nameOf: _trebleBooster,
      bands10: [0, 0, 0, 0, 0, 1.0, 2.0, 3.0, 4.0, 5.0],
      bands15: [0, 0, 0, 0, 0, 0, 0, 0.5, 1.0, 1.5, 2.5, 3.0, 3.5, 4.5, 5.0],
      bands25: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 1.0, 1.5, 1.5, 2.5, 2.5, 3.0, 3.5, 4.0, 4.5, 4.5, 5.0, 5.0],
      bands31: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 1.0, 1.5, 1.5, 2.0, 2.5, 2.5, 3.0, 3.5, 3.5, 4.0, 4.5, 4.5, 5.0, 5.0],
    ),
    BuiltinEqPreset(
      nameOf: _trebleReducer,
      bands10: [0, 0, 0, 0, 0, -1.0, -2.0, -3.0, -4.0, -5.0],
      bands15: [0, 0, 0, 0, 0, 0, 0, -0.5, -1.0, -1.5, -2.5, -3.0, -3.5, -4.5, -5.0],
      bands25: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.5, -1.0, -1.5, -1.5, -2.5, -2.5, -3.0, -3.5, -4.0, -4.5, -4.5, -5.0, -5.0],
      bands31: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.5, -0.5, -1.0, -1.5, -1.5, -2.0, -2.5, -2.5, -3.0, -3.5, -3.5, -4.0, -4.5, -4.5, -5.0, -5.0],
    ),
    BuiltinEqPreset(
      nameOf: _vocalBooster,
      bands10: [-1.0, -0.5, 0, 1.5, 3.0, 3.0, 2.0, 1.0, 0, -1.0],
      bands15: [-1.0, -1.0, -0.5, 0, 0.5, 1.5, 2.5, 3.0, 3.0, 2.5, 1.5, 1.0, 0.5, -0.5, -1.0],
      bands25: [-1.0, -1.0, -1.0, -0.5, -0.5, 0, 0, 0.5, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 2.5, 2.5, 1.5, 1.5, 1.0, 0.5, 0, -0.5, -0.5, -1.0, -1.0],
      bands31: [-1.0, -1.0, -1.0, -1.0, -0.5, -0.5, -0.5, 0, 0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.0, 3.0, 3.0, 2.5, 2.5, 2.0, 1.5, 1.5, 1.0, 0.5, 0.5, 0, -0.5, -0.5, -1.0, -1.0],
    ),
  ];
  // dart format on

  static List<List<double>> presetsForCount(int count) =>
      builtins.map((p) => p.bandsFor(count)).toList();
}

String _acoustic(S l) => l.eqPresetAcoustic;
String _bassBooster(S l) => l.eqPresetBassBooster;
String _bassReducer(S l) => l.eqPresetBassReducer;
String _classical(S l) => l.eqPresetClassical;
String _deep(S l) => l.eqPresetDeep;
String _flat(S l) => l.eqPresetFlat;
String _rnb(S l) => l.eqPresetRnb;
String _rock(S l) => l.eqPresetRock;
String _smallSpeakers(S l) => l.eqPresetSmallSpeakers;
String _trebleBooster(S l) => l.eqPresetTrebleBooster;
String _trebleReducer(S l) => l.eqPresetTrebleReducer;
String _vocalBooster(S l) => l.eqPresetVocalBooster;
