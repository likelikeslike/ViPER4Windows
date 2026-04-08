import 'dart:math';
import 'package:file_picker/file_picker.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import 'package:viper4windows/models/value_mappings.dart';
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
        _buildPlaybackGain(state, l),
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
        ValueMappings.dynamicSystemDevices.length,
        (i) => ComboBoxItem<int>(
          value: i,
          child: Text(
            ValueMappings.dynamicSystemDevices[i].$1,
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
      enabled: state.dynamicSystemEnabled,
      onToggle: (v) => state.dynamicSystemEnabled = v,
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
                      state.dynamicSystemDevice = v;
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
            value: state.dynamicSystemStrength.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.dynamicSystemStrength = v.round(),
          ),
          LabeledSlider(
            label: l.xLowFreq,
            value: state.dsXLow.toDouble(),
            min: 0,
            max: 2400,
            divisions: 24,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) => state.dsXLow = v.round(),
          ),
          LabeledSlider(
            label: l.xHighFreq,
            value: state.dsXHigh.toDouble(),
            min: 0,
            max: 12000,
            divisions: 120,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) => state.dsXHigh = v.round(),
          ),
          LabeledSlider(
            label: l.yLowFreq,
            value: state.dsYLow.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) => state.dsYLow = v.round(),
          ),
          LabeledSlider(
            label: l.yHighFreq,
            value: state.dsYHigh.toDouble(),
            min: 0,
            max: 300,
            divisions: 300,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) => state.dsYHigh = v.round(),
          ),
          LabeledSlider(
            label: l.sideGainLow,
            value: state.dsSideGainLow.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.dsSideGainLow = v.round(),
          ),
          LabeledSlider(
            label: l.sideGainHigh,
            value: state.dsSideGainHigh.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.dsSideGainHigh = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildFetCompressor(ViperState state, S l) {
    return EffectCard(
      title: l.fetCompressor,
      masterEnabled: state.masterEnabled,
      enabled: state.fetCompressorEnabled,
      onToggle: (v) => state.fetCompressorEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.threshold,
            value: state.fetCompressorThreshold.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorThreshold = v.round(),
          ),
          LabeledSlider(
            label: l.ratio,
            value: state.fetCompressorRatio.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorRatio = v.round(),
          ),
          _buildAutoToggle(
            l.autoKnee,
            state.fetCompressorAutoKnee,
            (v) => state.fetCompressorAutoKnee = v,
          ),
          LabeledSlider(
            label: l.knee,
            value: state.fetCompressorKnee.toDouble(),
            min: 0,
            max: 200,
            enabled: !state.fetCompressorAutoKnee,
            onChanged: (v) => state.fetCompressorKnee = v.round(),
          ),
          LabeledSlider(
            label: l.kneeMulti,
            value: state.fetCompressorKneeMulti.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorKneeMulti = v.round(),
          ),
          _buildAutoToggle(
            l.autoGain,
            state.fetCompressorAutoGain,
            (v) => state.fetCompressorAutoGain = v,
          ),
          LabeledSlider(
            label: l.gain,
            value: state.fetCompressorGain.toDouble(),
            min: 0,
            max: 200,
            enabled: !state.fetCompressorAutoGain,
            onChanged: (v) => state.fetCompressorGain = v.round(),
          ),
          _buildAutoToggle(
            l.autoAttack,
            state.fetCompressorAutoAttack,
            (v) => state.fetCompressorAutoAttack = v,
          ),
          LabeledSlider(
            label: l.attack,
            value: state.fetCompressorAttack.toDouble(),
            min: 0,
            max: 200,
            enabled: !state.fetCompressorAutoAttack,
            onChanged: (v) => state.fetCompressorAttack = v.round(),
          ),
          LabeledSlider(
            label: l.maxAttack,
            value: state.fetCompressorMaxAttack.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorMaxAttack = v.round(),
          ),
          _buildAutoToggle(
            l.autoRelease,
            state.fetCompressorAutoRelease,
            (v) => state.fetCompressorAutoRelease = v,
          ),
          LabeledSlider(
            label: l.release,
            value: state.fetCompressorRelease.toDouble(),
            min: 0,
            max: 200,
            enabled: !state.fetCompressorAutoRelease,
            onChanged: (v) => state.fetCompressorRelease = v.round(),
          ),
          LabeledSlider(
            label: l.maxRelease,
            value: state.fetCompressorMaxRelease.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorMaxRelease = v.round(),
          ),
          LabeledSlider(
            label: l.crest,
            value: state.fetCompressorCrest.toDouble(),
            min: 0,
            max: 300,
            onChanged: (v) => state.fetCompressorCrest = v.round(),
          ),
          LabeledSlider(
            label: l.adapt,
            value: state.fetCompressorAdapt.toDouble(),
            min: 0,
            max: 200,
            onChanged: (v) => state.fetCompressorAdapt = v.round(),
          ),
          _buildAutoToggle(
            l.noClip,
            state.fetCompressorNoClip,
            (v) => state.fetCompressorNoClip = v,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackGain(ViperState state, S l) {
    return EffectCard(
      title: l.playbackGainControl,
      masterEnabled: state.masterEnabled,
      enabled: state.playbackGainEnabled,
      onToggle: (v) => state.playbackGainEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.strength,
            value: state.playbackGainStrength.toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (v) => state.playbackGainStrength = v.round(),
          ),
          LabeledSlider(
            label: l.maxGain,
            value: state.playbackGainMaxGain.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.playbackGainMaxGain = v.round(),
          ),
          LabeledSlider(
            label: l.outputThreshold,
            value: state.playbackGainOutputThreshold.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            valueFormatter: (v) {
              final idx = v.round();
              final pct = ValueMappings.safeIndex(
                ValueMappings.limiterValues,
                idx,
              );
              final dB = pct > 0 ? 20.0 * log(pct / 100.0) / ln10 : -99.9;
              return '${dB.toStringAsFixed(1)}dB';
            },
            onChanged: (v) => state.playbackGainOutputThreshold = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildDdc(BuildContext context, ViperState state, S l) {
    return EffectCard(
      title: l.viperDdc,
      masterEnabled: state.masterEnabled,
      enabled: state.ddcEnabled,
      onToggle: (v) => state.ddcEnabled = v,
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
                  value: state.ddcFiles.contains(state.ddcFilePath)
                      ? state.ddcFilePath
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
                      state.ddcFilePath = '';
                      state.ddcEnabled = false;
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
                onPressed: state.ddcFilePath.isEmpty
                    ? null
                    : () => state.deleteDdc(state.ddcFilePath),
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
      enabled: state.convolutionEnabled,
      onToggle: (v) => state.convolutionEnabled = v,
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
                  value: state.kernelFiles.contains(state.convolutionKernelPath)
                      ? state.convolutionKernelPath
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
                      state.convolutionKernelPath = '';
                      state.convolutionEnabled = false;
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
            value: state.convolutionCrossChannel.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.convolutionCrossChannel = v.round(),
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
                onPressed: state.convolutionKernelPath.isEmpty
                    ? null
                    : () => state.deleteKernel(state.convolutionKernelPath),
                child: Text(l.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerOptimization(ViperState state, S l) {
    final active = state.speakerCorrectionEnabled && state.masterEnabled;
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
              checked: state.speakerCorrectionEnabled,
              onChanged: state.masterEnabled
                  ? (v) => state.speakerCorrectionEnabled = v
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
