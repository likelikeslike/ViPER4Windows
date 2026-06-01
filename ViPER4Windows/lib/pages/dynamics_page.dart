import 'dart:math';
import 'package:file_picker/file_picker.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import 'package:viper4windows/models/dynamic_system_preset.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/widgets/effect_card.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/l10n/app_localizations.dart';

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
      enabled: state.active.dynamicSystem.enabled,
      onToggle: (v) => state.update((s) => s.dynamicSystem.enabled = v),
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
                  value: _selectedDsPreset,
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
                      setState(() => _selectedDsPreset = 0);
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
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.xLow = v.round()),
          ),
          LabeledSlider(
            label: l.xHighFreq,
            value: state.active.dynamicSystem.xHigh.toDouble(),
            min: 0,
            max: 12000,
            divisions: 2400,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.xHigh = v.round()),
          ),
          LabeledSlider(
            label: l.yLowFreq,
            value: state.active.dynamicSystem.yLow.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.yLow = v.round()),
          ),
          LabeledSlider(
            label: l.yHighFreq,
            value: state.active.dynamicSystem.yHigh.toDouble(),
            min: 0,
            max: 300,
            divisions: 60,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.yHigh = v.round()),
          ),
          LabeledSlider(
            label: l.sideGainLow,
            value: state.active.dynamicSystem.sideGainLow.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.sideGainLow = v.round()),
          ),
          LabeledSlider(
            label: l.sideGainHigh,
            value: state.active.dynamicSystem.sideGainHigh.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.dynamicSystem.sideGainHigh = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildFetCompressor(ViperState state, S l) {
    return EffectCard(
      title: l.fetCompressor,
      masterEnabled: state.masterEnabled,
      enabled: state.active.fet.enabled,
      onToggle: (v) => state.update((s) => s.fet.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.threshold,
            value: state.active.fet.threshold.toDouble(),
            min: -48,
            max: 0,
            divisions: 48,
            valueFormatter: (v) => '${v.round()} dB',
            onChanged: (v) => state.update((s) => s.fet.threshold = v.round()),
          ),
          LabeledSlider(
            label: l.ratio,
            value: state.active.fet.ratio.toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => (v / 100).toStringAsFixed(1),
            onChanged: (v) => state.update((s) => s.fet.ratio = v.round()),
          ),
          _buildAutoToggle(
            l.autoKnee,
            state.active.fet.autoKnee,
            (v) => state.update((s) => s.fet.autoKnee = v),
          ),
          LabeledSlider(
            label: l.knee,
            value: state.active.fet.knee.toDouble(),
            min: 0,
            max: 12,
            divisions: 12,
            valueFormatter: (v) => '${v.round()} dB',
            enabled: !state.active.fet.autoKnee,
            onChanged: (v) => state.update((s) => s.fet.knee = v.round()),
          ),
          LabeledSlider(
            label: l.kneeMulti,
            value: state.active.fet.kneeMulti.toDouble(),
            min: 0,
            max: 400,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.fet.kneeMulti = v.round()),
          ),
          _buildAutoToggle(
            l.autoGain,
            state.active.fet.autoGain,
            (v) => state.update((s) => s.fet.autoGain = v),
          ),
          LabeledSlider(
            label: l.gain,
            value: state.active.fet.gain.toDouble(),
            min: 0,
            max: 24,
            divisions: 24,
            valueFormatter: (v) => '${v.round()} dB',
            enabled: !state.active.fet.autoGain,
            onChanged: (v) => state.update((s) => s.fet.gain = v.round()),
          ),
          _buildAutoToggle(
            l.autoAttack,
            state.active.fet.autoAttack,
            (v) => state.update((s) => s.fet.autoAttack = v),
          ),
          LabeledSlider(
            label: l.attack,
            value: state.active.fet.attack.toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            enabled: !state.active.fet.autoAttack,
            onChanged: (v) => state.update((s) => s.fet.attack = v.round()),
          ),
          LabeledSlider(
            label: l.maxAttack,
            value: state.active.fet.maxAttack.toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) => state.update((s) => s.fet.maxAttack = v.round()),
          ),
          _buildAutoToggle(
            l.autoRelease,
            state.active.fet.autoRelease,
            (v) => state.update((s) => s.fet.autoRelease = v),
          ),
          LabeledSlider(
            label: l.release,
            value: state.active.fet.release.toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            enabled: !state.active.fet.autoRelease,
            onChanged: (v) => state.update((s) => s.fet.release = v.round()),
          ),
          LabeledSlider(
            label: l.maxRelease,
            value: state.active.fet.maxRelease.toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) => state.update((s) => s.fet.maxRelease = v.round()),
          ),
          LabeledSlider(
            label: l.crest,
            value: state.active.fet.crest.toDouble(),
            min: 5,
            max: 300,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) => state.update((s) => s.fet.crest = v.round()),
          ),
          LabeledSlider(
            label: l.adapt,
            value: state.active.fet.adapt.toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.update((s) => s.fet.adapt = v.round()),
          ),
          _buildAutoToggle(
            l.noClip,
            state.active.fet.noClip,
            (v) => state.update((s) => s.fet.noClip = v),
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
      enabled: state.active.mbc.enabled,
      onToggle: (v) => state.update((s) => s.mbc.enabled = v),
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
                  : state.active.mbc.crossovers[band - 1];
              final highFreq = band < 4
                  ? state.active.mbc.crossovers[band]
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
            state.active.mbc.bandEnables[band],
            (v) => state.update((s) => s.mbc.bandEnables[band] = v),
          ),
          LabeledSlider(
            label: l.threshold,
            value: state.active.mbc.thresholds[band].toDouble(),
            min: -48,
            max: 0,
            divisions: 48,
            valueFormatter: (v) => '${v.round()} dB',
            onChanged: (v) =>
                state.update((s) => s.mbc.thresholds[band] = v.round()),
          ),
          LabeledSlider(
            label: l.ratio,
            value: state.active.mbc.ratios[band].toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => (v / 100).toStringAsFixed(1),
            onChanged: (v) =>
                state.update((s) => s.mbc.ratios[band] = v.round()),
          ),
          _buildAutoToggle(
            l.autoKnee,
            state.active.mbc.autoKnees[band],
            (v) => state.update((s) => s.mbc.autoKnees[band] = v),
          ),
          LabeledSlider(
            label: l.knee,
            value: state.active.mbc.knees[band].toDouble(),
            min: 0,
            max: 12,
            divisions: 12,
            valueFormatter: (v) => '${v.round()} dB',
            enabled: !state.active.mbc.autoKnees[band],
            onChanged: (v) =>
                state.update((s) => s.mbc.knees[band] = v.round()),
          ),
          _buildAutoToggle(
            l.autoGain,
            state.active.mbc.autoGains[band],
            (v) => state.update((s) => s.mbc.autoGains[band] = v),
          ),
          LabeledSlider(
            label: l.gain,
            value: state.active.mbc.gains[band].toDouble(),
            min: 0,
            max: 24,
            divisions: 24,
            valueFormatter: (v) => '${v.round()} dB',
            enabled: !state.active.mbc.autoGains[band],
            onChanged: (v) =>
                state.update((s) => s.mbc.gains[band] = v.round()),
          ),
          _buildAutoToggle(
            l.autoAttack,
            state.active.mbc.autoAttacks[band],
            (v) => state.update((s) => s.mbc.autoAttacks[band] = v),
          ),
          LabeledSlider(
            label: l.attack,
            value: state.active.mbc.attacks[band].toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            enabled: !state.active.mbc.autoAttacks[band],
            onChanged: (v) =>
                state.update((s) => s.mbc.attacks[band] = v.round()),
          ),
          _buildAutoToggle(
            l.autoRelease,
            state.active.mbc.autoReleases[band],
            (v) => state.update((s) => s.mbc.autoReleases[band] = v),
          ),
          LabeledSlider(
            label: l.release,
            value: state.active.mbc.releases[band].toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            enabled: !state.active.mbc.autoReleases[band],
            onChanged: (v) =>
                state.update((s) => s.mbc.releases[band] = v.round()),
          ),
          LabeledSlider(
            label: l.kneeMulti,
            value: state.active.mbc.kneeMultis[band].toDouble(),
            min: 0,
            max: 400,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) =>
                state.update((s) => s.mbc.kneeMultis[band] = v.round()),
          ),
          LabeledSlider(
            label: l.maxAttack,
            value: state.active.mbc.maxAttacks[band].toDouble(),
            min: 1,
            max: 100,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) =>
                state.update((s) => s.mbc.maxAttacks[band] = v.round()),
          ),
          LabeledSlider(
            label: l.maxRelease,
            value: state.active.mbc.maxReleases[band].toDouble(),
            min: 5,
            max: 500,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) =>
                state.update((s) => s.mbc.maxReleases[band] = v.round()),
          ),
          LabeledSlider(
            label: l.crest,
            value: state.active.mbc.crests[band].toDouble(),
            min: 5,
            max: 300,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) =>
                state.update((s) => s.mbc.crests[band] = v.round()),
          ),
          LabeledSlider(
            label: l.adapt,
            value: state.active.mbc.adapts[band].toDouble(),
            min: 0,
            max: 200,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.mbc.adapts[band] = v.round()),
          ),
          _buildAutoToggle(
            l.noClip,
            state.active.mbc.noClips[band],
            (v) => state.update((s) => s.mbc.noClips[band] = v),
          ),
          if (band < 4)
            LabeledSlider(
              label: l.crossover,
              value: state.active.mbc.crossovers[band].toDouble(),
              min: 20,
              max: 20000,
              divisions: 3996,
              valueFormatter: (v) => '${v.round()} Hz',
              onChanged: (v) =>
                  state.update((s) => s.mbc.crossovers[band] = v.round()),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackGain(ViperState state, S l) {
    return EffectCard(
      title: l.playbackGainControl,
      masterEnabled: state.masterEnabled,
      enabled: state.active.agc.enabled,
      onToggle: (v) => state.update((s) => s.agc.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.strength,
            value: state.active.agc.strength.toDouble(),
            min: 50,
            max: 300,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.agc.strength = v.round()),
          ),
          LabeledSlider(
            label: l.maxGain,
            value: state.active.agc.maxGain.toDouble(),
            min: 100,
            max: 1000,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.agc.maxGain = v.round()),
          ),
          LabeledSlider(
            label: l.outputThreshold,
            value: state.active.agc.outputThreshold.toDouble(),
            min: 30,
            max: 100,
            valueFormatter: (v) {
              final pct = v.round();
              final dB = pct > 0 ? 20.0 * log(pct / 100.0) / ln10 : -99.9;
              return '${dB.toStringAsFixed(1)}dB';
            },
            onChanged: (v) =>
                state.update((s) => s.agc.outputThreshold = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildLufs(ViperState state, S l) {
    return EffectCard(
      title: l.lufsTargeting,
      masterEnabled: state.masterEnabled,
      enabled: state.active.lufs.enabled,
      onToggle: (v) => state.update((s) => s.lufs.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.target,
            value: state.active.lufs.target.toDouble(),
            min: 80,
            max: 240,
            valueFormatter: (v) => '${(v / -10.0).toStringAsFixed(1)} LUFS',
            onChanged: (v) => state.update((s) => s.lufs.target = v.round()),
          ),
          LabeledSlider(
            label: l.maxGain,
            value: state.active.lufs.maxGain.toDouble(),
            min: 0,
            max: 120,
            valueFormatter: (v) => '${(v / 10.0).toStringAsFixed(1)} dB',
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
      enabled: state.active.ddc.enabled,
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
                      state.update((s) => s.ddc.device = '');
                      state.setDdcEnabled(false);
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
      enabled: state.active.convolver.enabled,
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
                      state.update((s) => s.convolver.kernel = '');
                      state.setConvolverEnabled(false);
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
    final active =
        state.active.speakerCorrection.enabled && state.masterEnabled;
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
              checked: state.active.speakerCorrection.enabled,
              onChanged: state.masterEnabled
                  ? (v) => state.update((s) => s.speakerCorrection.enabled = v)
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
          Checkbox(checked: value, onChanged: (v) => onChanged(v ?? false)),
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
