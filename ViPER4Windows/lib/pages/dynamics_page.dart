import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/dynamic_system_preset.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/effect_card.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

double _rawToDb(double raw) => raw > 0 ? 20.0 * log(raw / 100.0) / ln10 : -99.9;
double _dbToRaw(double db) => (pow(10, db / 20.0) * 100).roundToDouble();

class DynamicsPage extends StatefulWidget {
  const DynamicsPage({super.key});

  @override
  State<DynamicsPage> createState() => _DynamicsPageState();
}

class _DynamicsPageState extends State<DynamicsPage> {
  final TextEditingController _dsPresetNameController = TextEditingController();
  int _selectedDsPreset = 0;
  int _mbcSelectedBand = 0;

  @override
  void dispose() {
    _dsPresetNameController.dispose();
    super.dispose();
  }

  void _editDs(ViperState state, void Function(DynamicSystemState) update) {
    state.update((s) => update(s.dynamicSystem));
    if (_selectedDsPreset != -1) setState(() => _selectedDsPreset = -1);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pageDynamics,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildDynamicSystem(state, l),
        _buildFetCompressor(state, l),
        _buildMbc(state, l),
        _buildPlaybackGain(state, l),
        _buildLufs(state, l),
        _buildDdc(context, state, l),
        _buildConvolver(context, state, l),
        _buildSpeakerOptimization(state, l),
      ],
    );
  }

  Widget _buildDynamicSystem(ViperState state, S l) {
    final userPresets = state.dsPresetFiles;
    final items = <ComboBoxItem<int>>[
      ...List.generate(
        DsDevices.builtins.length,
        (i) => ComboBoxItem<int>(
          value: i,
          child: Text(
            DsDevices.builtins[i].nameOf(l),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
      ...List.generate(userPresets.length, (i) {
        return ComboBoxItem<int>(
          value: 1000 + i,
          child: Text(
            userPresets[i],
            style: TextStyle(fontSize: 12, color: AppColors.accent),
          ),
        );
      }),
    ];

    return EffectCard(
      title: l.dynamicSystem,
      masterEnabled: state.masterEnabled,
      enabled: state.active.dynamicSystem.enable,
      onToggle: (v) => state.update((s) => s.dynamicSystem.enable = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.preset,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: _selectedDsPreset == -1 ? null : _selectedDsPreset,
                  placeholder: Text(
                    l.custom,
                    style: const TextStyle(fontSize: 12),
                  ),
                  items: items,
                  onChanged: (v) {
                    if (v == null) return;
                    if (v >= 1000) {
                      final idx = v - 1000;
                      if (idx < userPresets.length) {
                        state.loadDsPreset(userPresets[idx]);
                        setState(() => _selectedDsPreset = v);
                      }
                    } else {
                      state.setDynamicSystemDevice(v);
                      setState(() => _selectedDsPreset = v);
                    }
                  },
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.save, size: 14),
                onPressed: () => _showDsSaveDialog(context, state, l),
              ),
              if (_selectedDsPreset >= 1000)
                IconButton(
                  icon: Icon(FluentIcons.delete, size: 14, color: Colors.red),
                  onPressed: () {
                    final idx = _selectedDsPreset - 1000;
                    if (idx < userPresets.length) {
                      state.deleteDsPreset(userPresets[idx]);
                      setState(() => _selectedDsPreset = -1);
                    }
                  },
                ),
            ],
          ),
          LabeledSlider(
            label: l.strength,
            value: state.active.dynamicSystem.strength.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.strength = v.round()),
          ),
          LabeledSlider(
            label: l.xLowFreq,
            value: state.active.dynamicSystem.xLow.toDouble(),
            min: 0,
            max: 2400,
            divisions: 480,
            valueFormatter: (v) => '${v.round()} Hz',
            unit: 'Hz',
            onChanged: (v) => _editDs(state, (d) => d.xLow = v.round()),
          ),
          LabeledSlider(
            label: l.xHighFreq,
            value: state.active.dynamicSystem.xHigh.toDouble(),
            min: 0,
            max: 12000,
            divisions: 2400,
            valueFormatter: (v) => '${v.round()} Hz',
            unit: 'Hz',
            onChanged: (v) => _editDs(state, (d) => d.xHigh = v.round()),
          ),
          LabeledSlider(
            label: l.yLowFreq,
            value: state.active.dynamicSystem.yLow.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()} Hz',
            unit: 'Hz',
            onChanged: (v) => _editDs(state, (d) => d.yLow = v.round()),
          ),
          LabeledSlider(
            label: l.yHighFreq,
            value: state.active.dynamicSystem.yHigh.toDouble(),
            min: 0,
            max: 300,
            divisions: 60,
            valueFormatter: (v) => '${v.round()} Hz',
            unit: 'Hz',
            onChanged: (v) => _editDs(state, (d) => d.yHigh = v.round()),
          ),
          LabeledSlider(
            label: l.sideGainLow,
            value: state.active.dynamicSystem.sideGainLow.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) => _editDs(state, (d) => d.sideGainLow = v.round()),
          ),
          LabeledSlider(
            label: l.sideGainHigh,
            value: state.active.dynamicSystem.sideGainHigh.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) => _editDs(state, (d) => d.sideGainHigh = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildFetCompressor(ViperState state, S l) {
    return EffectCard(
      title: l.fetCompressor,
      masterEnabled: state.masterEnabled,
      enabled: state.active.fetCompressor.enable,
      onToggle: (v) => state.update((s) => s.fetCompressor.enable = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.threshold,
            value: state.active.fetCompressor.threshold.toDouble(),
            min: -48,
            max: 0,
            divisions: 48,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.threshold = v.round()),
          ),
          LabeledSlider(
            label: l.ratio,
            value: state.active.fetCompressor.ratio.toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => (v / 100).toStringAsFixed(1),
            toDisplay: (v) => v / 100,
            fromDisplay: (v) => v * 100,
            decimals: 1,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.ratio = v.round()),
          ),
          _buildAutoToggle(
            l.autoKnee,
            state.active.fetCompressor.kneeAuto,
            (v) => state.update((s) => s.fetCompressor.kneeAuto = v),
          ),
          LabeledSlider(
            label: l.knee,
            value: state.active.fetCompressor.knee.toDouble(),
            min: 0,
            max: 12,
            divisions: 12,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            enabled: !state.active.fetCompressor.kneeAuto,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.knee = v.round()),
          ),
          LabeledSlider(
            label: l.kneeMulti,
            value: state.active.fetCompressor.kneeMulti.toDouble(),
            min: 0,
            max: 100,
            valueFormatter: (v) => '${(v / 100 * 4).toStringAsFixed(1)}x',
            toDisplay: (v) => v / 100 * 4,
            fromDisplay: (v) => v / 4 * 100,
            unit: 'x',
            decimals: 1,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.kneeMulti = v.round()),
          ),
          _buildAutoToggle(
            l.autoGain,
            state.active.fetCompressor.gainAuto,
            (v) => state.update((s) => s.fetCompressor.gainAuto = v),
          ),
          LabeledSlider(
            label: l.gain,
            value: state.active.fetCompressor.gain.toDouble(),
            min: 0,
            max: 24,
            divisions: 24,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            enabled: !state.active.fetCompressor.gainAuto,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.gain = v.round()),
          ),
          _buildAutoToggle(
            l.autoAttack,
            state.active.fetCompressor.attackAuto,
            (v) => state.update((s) => s.fetCompressor.attackAuto = v),
          ),
          LabeledSlider(
            label: l.attack,
            value: state.active.fetCompressor.attack.toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            enabled: !state.active.fetCompressor.attackAuto,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.attack = v.round()),
          ),
          LabeledSlider(
            label: l.maxAttack,
            value: state.active.fetCompressor.maxAttack.toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.maxAttack = v.round()),
          ),
          _buildAutoToggle(
            l.autoRelease,
            state.active.fetCompressor.releaseAuto,
            (v) => state.update((s) => s.fetCompressor.releaseAuto = v),
          ),
          LabeledSlider(
            label: l.release,
            value: state.active.fetCompressor.release.toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            enabled: !state.active.fetCompressor.releaseAuto,
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.release = v.round()),
          ),
          LabeledSlider(
            label: l.maxRelease,
            value: state.active.fetCompressor.maxRelease.toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.maxRelease = v.round()),
          ),
          LabeledSlider(
            label: l.crest,
            value: state.active.fetCompressor.crest.toDouble(),
            min: 5,
            max: 300,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.crest = v.round()),
          ),
          LabeledSlider(
            label: l.adapt,
            value: state.active.fetCompressor.adapt.toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) =>
                state.update((s) => s.fetCompressor.adapt = v.round()),
          ),
          _buildAutoToggle(
            l.noClip,
            state.active.fetCompressor.noClip,
            (v) => state.update((s) => s.fetCompressor.noClip = v),
          ),
        ],
      ),
    );
  }

  static const _mbcBandNames = ['Sub', 'Low', 'Mid', 'Pres', 'Air'];

  Widget _buildMbc(ViperState state, S l) {
    final band = _mbcSelectedBand;
    return EffectCard(
      title: l.multibandCompressor,
      masterEnabled: state.masterEnabled,
      enabled: state.active.multibandCompressor.enable,
      onToggle: (v) => state.update((s) => s.multibandCompressor.enable = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final selected = i == band;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ToggleButton(
                  checked: selected,
                  onChanged: (_) => setState(() => _mbcSelectedBand = i),
                  style: ToggleButtonThemeData(
                    checkedButtonStyle: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.accent,
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: AppColors.accent, width: 1),
                        ),
                      ),
                    ),
                    uncheckedButtonStyle: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.cardBorder.withValues(alpha: 0.3),
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        AppColors.subtitleText,
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    _mbcBandNames[i],
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final lowFreq = band == 0
                  ? 20
                  : state.active.multibandCompressor.crossovers[band - 1];
              final highFreq = band < 4
                  ? state.active.multibandCompressor.crossovers[band]
                  : 20000;
              return Text(
                '$lowFreq - ${band < 4 ? "$highFreq" : "20000+"} Hz',
                style: TextStyle(fontSize: 11, color: AppColors.subtitleText),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildAutoToggle(
            l.bandEnabled,
            state.active.multibandCompressor.bandEnables[band],
            (v) => state.update(
              (s) => s.multibandCompressor.bandEnables[band] = v,
            ),
          ),
          LabeledSlider(
            label: l.threshold,
            value: state.active.multibandCompressor.thresholds[band].toDouble(),
            min: -48,
            max: 0,
            divisions: 48,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.thresholds[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.ratio,
            value: state.active.multibandCompressor.ratios[band].toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => (v / 100).toStringAsFixed(1),
            toDisplay: (v) => v / 100,
            fromDisplay: (v) => v * 100,
            decimals: 1,
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.ratios[band] = v.round(),
            ),
          ),
          _buildAutoToggle(
            l.autoKnee,
            state.active.multibandCompressor.kneeAutos[band],
            (v) =>
                state.update((s) => s.multibandCompressor.kneeAutos[band] = v),
          ),
          LabeledSlider(
            label: l.knee,
            value: state.active.multibandCompressor.knees[band].toDouble(),
            min: 0,
            max: 12,
            divisions: 12,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            enabled: !state.active.multibandCompressor.kneeAutos[band],
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.knees[band] = v.round(),
            ),
          ),
          _buildAutoToggle(
            l.autoGain,
            state.active.multibandCompressor.gainAutos[band],
            (v) =>
                state.update((s) => s.multibandCompressor.gainAutos[band] = v),
          ),
          LabeledSlider(
            label: l.gain,
            value: state.active.multibandCompressor.gains[band].toDouble(),
            min: 0,
            max: 24,
            divisions: 24,
            valueFormatter: (v) => '${v.round()} dB',
            unit: 'dB',
            enabled: !state.active.multibandCompressor.gainAutos[band],
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.gains[band] = v.round(),
            ),
          ),
          _buildAutoToggle(
            l.autoAttack,
            state.active.multibandCompressor.attackAutos[band],
            (v) => state.update(
              (s) => s.multibandCompressor.attackAutos[band] = v,
            ),
          ),
          LabeledSlider(
            label: l.attack,
            value: state.active.multibandCompressor.attacks[band].toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            enabled: !state.active.multibandCompressor.attackAutos[band],
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.attacks[band] = v.round(),
            ),
          ),
          _buildAutoToggle(
            l.autoRelease,
            state.active.multibandCompressor.releaseAutos[band],
            (v) => state.update(
              (s) => s.multibandCompressor.releaseAutos[band] = v,
            ),
          ),
          LabeledSlider(
            label: l.release,
            value: state.active.multibandCompressor.releases[band].toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            enabled: !state.active.multibandCompressor.releaseAutos[band],
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.releases[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.kneeMulti,
            value: state.active.multibandCompressor.kneeMultis[band].toDouble(),
            min: 0,
            max: 100,
            valueFormatter: (v) => '${(v / 100 * 4).toStringAsFixed(1)}x',
            toDisplay: (v) => v / 100 * 4,
            fromDisplay: (v) => v / 4 * 100,
            unit: 'x',
            decimals: 1,
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.kneeMultis[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.maxAttack,
            value: state.active.multibandCompressor.maxAttacks[band].toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.maxAttacks[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.maxRelease,
            value: state.active.multibandCompressor.maxReleases[band]
                .toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.maxReleases[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.crest,
            value: state.active.multibandCompressor.crests[band].toDouble(),
            min: 5,
            max: 300,
            valueFormatter: (v) => '${v.round()} ms',
            unit: 'ms',
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.crests[band] = v.round(),
            ),
          ),
          LabeledSlider(
            label: l.adapt,
            value: state.active.multibandCompressor.adapts[band].toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) => state.update(
              (s) => s.multibandCompressor.adapts[band] = v.round(),
            ),
          ),
          _buildAutoToggle(
            l.noClip,
            state.active.multibandCompressor.noClips[band],
            (v) => state.update((s) => s.multibandCompressor.noClips[band] = v),
          ),
          if (band < 4)
            LabeledSlider(
              label: l.crossover,
              value: state.active.multibandCompressor.crossovers[band]
                  .toDouble(),
              min: 20,
              max: 20000,
              divisions: 3996,
              valueFormatter: (v) => '${v.round()} Hz',
              unit: 'Hz',
              onChanged: (v) => state.update(
                (s) => s.multibandCompressor.crossovers[band] = v.round(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackGain(ViperState state, S l) {
    return EffectCard(
      title: l.playbackGainControl,
      masterEnabled: state.masterEnabled,
      enabled: state.active.playbackGainControl.enable,
      onToggle: (v) => state.update((s) => s.playbackGainControl.enable = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.strength,
            value: state.active.playbackGainControl.strength.toDouble(),
            min: 50,
            max: 300,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            toDisplay: (v) => v / 100,
            fromDisplay: (v) => v * 100,
            unit: 'x',
            decimals: 1,
            onChanged: (v) =>
                state.update((s) => s.playbackGainControl.strength = v.round()),
          ),
          LabeledSlider(
            label: l.maxGain,
            value: state.active.playbackGainControl.maxGain.toDouble(),
            min: 100,
            max: 1000,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            toDisplay: (v) => v / 100,
            fromDisplay: (v) => v * 100,
            unit: 'x',
            decimals: 1,
            onChanged: (v) =>
                state.update((s) => s.playbackGainControl.maxGain = v.round()),
          ),
          LabeledSlider(
            label: l.outputThreshold,
            value: state.active.playbackGainControl.outputThreshold.toDouble(),
            min: 30,
            max: 100,
            valueFormatter: (v) {
              final pct = v.round();
              final dB = pct > 0 ? 20.0 * log(pct / 100.0) / ln10 : -99.9;
              return '${dB.toStringAsFixed(1)}dB';
            },
            toDisplay: _rawToDb,
            fromDisplay: _dbToRaw,
            unit: 'dB',
            decimals: 1,
            onChanged: (v) => state.update(
              (s) => s.playbackGainControl.outputThreshold = v.round(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLufs(ViperState state, S l) {
    return EffectCard(
      title: l.lufsTargeting,
      masterEnabled: state.masterEnabled,
      enabled: state.active.lufs.enable,
      onToggle: (v) => state.update((s) => s.lufs.enable = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.target,
            value: state.active.lufs.target.toDouble(),
            min: 80,
            max: 240,
            valueFormatter: (v) => '${(v / -10.0).toStringAsFixed(1)} LUFS',
            toDisplay: (v) => v / -10.0,
            fromDisplay: (v) => v * -10.0,
            unit: 'LUFS',
            decimals: 1,
            onChanged: (v) => state.update((s) => s.lufs.target = v.round()),
          ),
          LabeledSlider(
            label: l.maxGain,
            value: state.active.lufs.maxGain.toDouble(),
            min: 0,
            max: 120,
            valueFormatter: (v) => '${(v / 10.0).toStringAsFixed(1)} dB',
            toDisplay: (v) => v / 10.0,
            fromDisplay: (v) => v * 10.0,
            unit: 'dB',
            decimals: 1,
            onChanged: (v) => state.update((s) => s.lufs.maxGain = v.round()),
          ),
          LabeledSlider(
            label: l.speed,
            value: state.active.lufs.speed.toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            valueFormatter: (v) => [
              l.speedSlow,
              l.speedMedium,
              l.speedFast,
            ][v.round().clamp(0, 2)],
            editable: false,
            onChanged: (v) => state.update((s) => s.lufs.speed = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDdc(BuildContext context, ViperState state, S l) {
    return EffectCard(
      title: l.viperDdc,
      masterEnabled: state.masterEnabled,
      enabled: state.active.ddc.enable,
      onToggle: (v) => state.setDdcEnabled(v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.file,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<String>(
                  value: state.ddcFiles.contains(state.active.ddc.device)
                      ? state.active.ddc.device
                      : '',
                  items: [
                    ComboBoxItem<String>(value: '', child: Text(l.none)),
                    ...state.ddcFiles.map(
                      (name) =>
                          ComboBoxItem<String>(value: name, child: Text(name)),
                    ),
                  ],
                  onChanged: (name) {
                    if (name == null) return;
                    if (name.isEmpty) {
                      state.clearDdcSelection();
                    } else {
                      state.loadDdcByName(name);
                    }
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    dialogTitle: l.importDdcProfile,
                    type: FileType.custom,
                    allowedExtensions: ['vdc'],
                  );
                  if (result != null && result.files.single.path != null) {
                    state.importDdc(result.files.single.path!);
                  }
                },
                child: Text(l.importBtn),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: state.active.ddc.device.isEmpty
                    ? null
                    : () => state.deleteDdc(state.active.ddc.device),
                child: Text(l.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConvolver(BuildContext context, ViperState state, S l) {
    return EffectCard(
      title: l.convolver,
      masterEnabled: state.masterEnabled,
      enabled: state.active.convolver.enable,
      onToggle: (v) => state.setConvolverEnabled(v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.file,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<String>(
                  value:
                      state.kernelFiles.contains(state.active.convolver.kernel)
                      ? state.active.convolver.kernel
                      : '',
                  items: [
                    ComboBoxItem<String>(value: '', child: Text(l.none)),
                    ...state.kernelFiles.map(
                      (name) =>
                          ComboBoxItem<String>(value: name, child: Text(name)),
                    ),
                  ],
                  onChanged: (name) {
                    if (name == null) return;
                    if (name.isEmpty) {
                      state.clearKernelSelection();
                    } else {
                      state.loadKernelByName(name);
                    }
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.crossChannel,
            value: state.active.convolver.crossChannel.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            unit: '%',
            onChanged: (v) =>
                state.update((s) => s.convolver.crossChannel = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    dialogTitle: l.importConvolverKernel,
                    type: FileType.custom,
                    allowedExtensions: ['wav', 'irs'],
                  );
                  if (result != null && result.files.single.path != null) {
                    state.importKernel(result.files.single.path!);
                  }
                },
                child: Text(l.importBtn),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: state.active.convolver.kernel.isEmpty
                    ? null
                    : () => state.deleteKernel(state.active.convolver.kernel),
                child: Text(l.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerOptimization(ViperState state, S l) {
    final active = state.active.speakerCorrection.enable && state.masterEnabled;
    return AnimatedOpacity(
      opacity: state.masterEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.speakerOptimization,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? AppColors.enabledText
                      : AppColors.disabledText,
                ),
              ),
            ),
            ToggleSwitch(
              checked: state.active.speakerCorrection.enable,
              onChanged: state.masterEnabled
                  ? (v) => state.update((s) => s.speakerCorrection.enable = v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showDsSaveDialog(BuildContext context, ViperState state, S l) {
    _dsPresetNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
          title: Text(l.saveDsPreset),
          content: TextBox(
            controller: _dsPresetNameController,
            placeholder: l.presetName,
            autofocus: true,
          ),
          actions: [
            Button(child: Text(l.cancel), onPressed: () => Navigator.pop(ctx)),
            FilledButton(
              child: Text(l.save),
              onPressed: () {
                final name = _dsPresetNameController.text.trim();
                if (name.isEmpty) return;
                state.saveDsPreset(name);
                Navigator.pop(ctx);
                final idx = state.dsPresetFiles.indexOf(name);
                if (idx >= 0) {
                  setState(() => _selectedDsPreset = 1000 + idx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAutoToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 100),
          ToggleSwitch(checked: value, onChanged: onChanged),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.subtitleText),
          ),
        ],
      ),
    );
  }
}
