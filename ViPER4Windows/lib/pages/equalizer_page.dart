import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/eq_presets.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/effect_card.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

class EqualizerPage extends StatefulWidget {
  const EqualizerPage({super.key});

  @override
  State<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends State<EqualizerPage> {
  int _selectedPreset = -1;
  int _dynEqSelectedBand = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _presetNameController = TextEditingController();

  static const _bandCounts = [10, 15, 25, 31];

  @override
  void dispose() {
    _scrollController.dispose();
    _presetNameController.dispose();
    super.dispose();
  }

  void _applyPreset(ViperState state, int presetIndex) {
    final presets = EqPresets.presetsForCount(state.active.eq.bandCount);
    final bands = List<double>.from(presets[presetIndex]);
    state.update((s) => s.eq.bands = bands);
    for (var i = 0; i < bands.length; i++) {
      state.sendEQBand(i, bands[i]);
    }
    state.active.eq.bandsMap[state.active.eq.bandCount] = bands;
    setState(() => _selectedPreset = presetIndex);
  }

  void _resetBands(ViperState state) {
    final count = state.active.eq.bandCount;
    final bands = List<double>.filled(count, 0.0);
    state.update((s) => s.eq.bands = bands);
    for (var i = 0; i < count; i++) {
      state.sendEQBand(i, 0.0);
    }
    state.active.eq.bandsMap[count] = bands;
    setState(() => _selectedPreset = 5);
  }

  void _adjustBand(ViperState state, int index, double delta) {
    final current = state.active.eq.bands[index];
    final next = double.parse(
      (current + delta).clamp(-12.0, 12.0).toStringAsFixed(1),
    );
    state.sendEQBand(index, next);
    setState(() => _selectedPreset = -1);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;
    final bandCount = state.active.eq.bandCount;
    final labels = EqLabels.fullLabels(bandCount);

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pageEqualizer,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        EffectCard(
          title: l.firEqualizer,
          masterEnabled: state.masterEnabled,
          enabled: state.active.eq.enabled,
          onToggle: (v) => state.update((s) => s.eq.enabled = v),
          child: _buildContent(state, bandCount, labels, l),
        ),
        _buildDynEq(state, l),
      ],
    );
  }

  Widget _buildContent(
    ViperState state,
    int bandCount,
    List<String> labels,
    S l,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBandCountPicker(state, bandCount, l),
          const SizedBox(height: 12),
          _buildPresetPicker(state, l),
          const SizedBox(height: 12),
          _buildBandSliders(state, bandCount, labels),
          const SizedBox(height: 12),
          _buildResetButton(state, l),
        ],
      ),
    );
  }

  Widget _buildBandCountPicker(ViperState state, int bandCount, S l) {
    return Row(
      children: [
        Text(
          l.bands,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitleText,
          ),
        ),
        const SizedBox(width: 12),
        ..._bandCounts.map((count) {
          final selected = bandCount == count;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ToggleButton(
              checked: selected,
              onChanged: (_) {
                state.setEQBandCount(count);
                setState(() => _selectedPreset = -1);
              },
              style: ToggleButtonThemeData(
                checkedButtonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    AppColors.accent.withValues(alpha: 0.25),
                  ),
                  foregroundColor: WidgetStateProperty.all(AppColors.accent),
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
                    AppColors.disabledText,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: AppColors.cardBorder, width: 1),
                    ),
                  ),
                ),
              ),
              child: SizedBox(
                width: 30,
                child: Center(
                  child: Text('$count', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPresetPicker(ViperState state, S l) {
    final userPresets = state.eqPresetsForCurrentBandCount();
    final items = <ComboBoxItem<int>>[
      ComboBoxItem<int>(
        value: -1,
        child: Text(
          l.custom,
          style: TextStyle(fontSize: 12, color: AppColors.enabledText),
        ),
      ),
      ...List.generate(EqPresets.builtins.length, (i) {
        return ComboBoxItem<int>(
          value: i,
          child: Text(
            EqPresets.builtins[i].nameOf(l),
            style: TextStyle(fontSize: 12, color: AppColors.enabledText),
          ),
        );
      }),
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

    return Row(
      children: [
        Text(
          l.preset,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitleText,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: ComboBox<int>(
            value: _selectedPreset,
            items: items,
            onChanged: (v) {
              if (v == null) return;
              if (v >= 1000) {
                final idx = v - 1000;
                if (idx < userPresets.length) {
                  state.loadEqPreset(userPresets[idx]);
                  setState(() => _selectedPreset = v);
                }
              } else if (v == -1) {
                setState(() => _selectedPreset = -1);
              } else {
                _applyPreset(state, v);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(FluentIcons.save, size: 14),
          onPressed: () => _showSaveDialog(context, state, l),
        ),
        if (_selectedPreset >= 1000)
          IconButton(
            icon: Icon(FluentIcons.delete, size: 14, color: Colors.red),
            onPressed: () {
              final idx = _selectedPreset - 1000;
              if (idx < userPresets.length) {
                state.deleteEqPreset(userPresets[idx]);
                setState(() => _selectedPreset = -1);
              }
            },
          ),
      ],
    );
  }

  Widget _buildBandSliders(
    ViperState state,
    int bandCount,
    List<String> labels,
  ) {
    final needsScroll = bandCount > 15;

    if (!needsScroll) {
      final bandWidgets = List.generate(bandCount, (i) {
        final value = i < state.active.eq.bands.length
            ? state.active.eq.bands[i]
            : 0.0;
        final label = i < labels.length ? labels[i] : '${i + 1}';
        return _buildBandColumn(state, i, value, label);
      });
      return SizedBox(
        height: 280,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: bandWidgets.map((w) => Expanded(child: w)).toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bandWidth = constraints.maxWidth / 15;
        final bandWidgets = List.generate(bandCount, (i) {
          final value = i < state.active.eq.bands.length
              ? state.active.eq.bands[i]
              : 0.0;
          final label = i < labels.length ? labels[i] : '${i + 1}';
          return SizedBox(
            width: bandWidth,
            child: _buildBandColumn(state, i, value, label),
          );
        });
        return SizedBox(
          height: 296,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: bandWidgets,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBandColumn(ViperState state, int i, double value, String label) {
    final clamped = value.clamp(-12.0, 12.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 20,
          child: IconButton(
            icon: const Icon(FluentIcons.add, size: 9),
            onPressed: clamped >= 12.0
                ? null
                : () => _adjustBand(state, i, 0.1),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
        Text(
          clamped.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.accent,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: clamped,
              min: -12.0,
              max: 12.0,
              onChanged: (v) {
                final rounded = double.parse(v.toStringAsFixed(1));
                state.sendEQBand(i, rounded);
                setState(() => _selectedPreset = -1);
              },
              style: SliderThemeData(
                activeColor: WidgetStateProperty.all(AppColors.accent),
                inactiveColor: WidgetStateProperty.all(AppColors.cardBorder),
                thumbColor: WidgetStateProperty.all(AppColors.accent),
                margin: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 28,
          height: 20,
          child: IconButton(
            icon: const Icon(FluentIcons.remove, size: 9),
            onPressed: clamped <= -12.0
                ? null
                : () => _adjustBand(state, i, -0.1),
            style: ButtonStyle(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.disabledText),
        ),
      ],
    );
  }

  Widget _buildResetButton(ViperState state, S l) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        onPressed: () => _resetBands(state),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            AppColors.cardBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          l.resetToFlat,
          style: TextStyle(fontSize: 12, color: AppColors.enabledText),
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, ViperState state, S l) {
    _presetNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
          title: Text(l.saveEqPreset),
          content: TextBox(
            controller: _presetNameController,
            placeholder: l.presetName,
            autofocus: true,
          ),
          actions: [
            Button(child: Text(l.cancel), onPressed: () => Navigator.pop(ctx)),
            FilledButton(
              child: Text(l.save),
              onPressed: () {
                final name = _presetNameController.text.trim();
                if (name.isEmpty) return;
                state.saveEqPreset(name);
                Navigator.pop(ctx);
                final userPresets = state.eqPresetsForCurrentBandCount();
                final idx = userPresets.indexOf(name);
                if (idx >= 0) {
                  setState(() => _selectedPreset = 1000 + idx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _dynEqFreqLabel(int freq) => '$freq Hz';

  Widget _buildDynEq(ViperState state, S l) {
    final bandCount = state.active.dynamicEq.bandCount;
    final int band = _dynEqSelectedBand.clamp(0, max(0, bandCount - 1));
    if (band != _dynEqSelectedBand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _dynEqSelectedBand = band);
      });
    }

    return EffectCard(
      title: l.dynamicEq,
      masterEnabled: state.masterEnabled,
      enabled: state.active.dynamicEq.enabled,
      onToggle: (v) => state.update((s) => s.dynamicEq.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...List.generate(bandCount, (i) {
                  final selected = i == band;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ToggleButton(
                      checked: selected,
                      onChanged: (_) => setState(() => _dynEqSelectedBand = i),
                      style: ToggleButtonThemeData(
                        checkedButtonStyle: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            AppColors.accent,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.white,
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: BorderSide(
                                color: AppColors.accent,
                                width: 1,
                              ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dynEqFreqLabel(state.active.dynamicEq.freqs[i]),
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (bandCount > 1) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  _showDeleteBandDialog(context, state, l, i),
                              child: Icon(
                                FluentIcons.chrome_close,
                                size: 10,
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.subtitleText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                if (bandCount < 8 &&
                    (bandCount == 0 ||
                        state.active.dynamicEq.freqs[bandCount - 1] < 20000))
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      icon: const Icon(FluentIcons.add, size: 12),
                      onPressed: () {
                        state.addDynEqBand();
                        setState(
                          () => _dynEqSelectedBand =
                              state.active.dynamicEq.bandCount - 1,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (bandCount > 0) ...[
            Builder(
              builder: (_) {
                final minFreq = band > 0
                    ? state.active.dynamicEq.freqs[band - 1] + 5
                    : 20;
                final maxFreq = band < bandCount - 1
                    ? state.active.dynamicEq.freqs[band + 1] - 5
                    : 20000;
                return LabeledSlider(
                  label: l.frequency,
                  value: state.active.dynamicEq.freqs[band].toDouble().clamp(
                    minFreq.toDouble(),
                    maxFreq.toDouble(),
                  ),
                  min: minFreq.toDouble(),
                  max: maxFreq.toDouble(),
                  divisions: ((maxFreq - minFreq) / 5).round().clamp(1, 100000),
                  valueFormatter: (v) => _dynEqFreqLabel(v.round()),
                  onChanged: (v) =>
                      state.update((s) => s.dynamicEq.freqs[band] = v.round()),
                );
              },
            ),
            LabeledSlider(
              label: l.quality,
              value: state.active.dynamicEq.qs[band].toDouble(),
              min: 50,
              max: 800,
              valueFormatter: (v) => (v / 100).toStringAsFixed(1),
              onChanged: (v) =>
                  state.update((s) => s.dynamicEq.qs[band] = v.round()),
            ),
            LabeledSlider(
              label: l.targetGain,
              value: state.active.dynamicEq.gains[band].toDouble(),
              min: -120,
              max: 120,
              valueFormatter: (v) => '${(v / 10).toStringAsFixed(1)} dB',
              onChanged: (v) =>
                  state.update((s) => s.dynamicEq.gains[band] = v.round()),
            ),
            LabeledSlider(
              label: l.threshold,
              value: state.active.dynamicEq.thresholds[band].toDouble(),
              min: -800,
              max: 0,
              valueFormatter: (v) => '${(v ~/ 10)} dB',
              onChanged: (v) =>
                  state.update((s) => s.dynamicEq.thresholds[band] = v.round()),
            ),
            LabeledSlider(
              label: l.attack,
              value: state.active.dynamicEq.attacks[band].toDouble(),
              min: 1,
              max: 100,
              valueFormatter: (v) => '${v.round()} ms',
              onChanged: (v) =>
                  state.update((s) => s.dynamicEq.attacks[band] = v.round()),
            ),
            LabeledSlider(
              label: l.release,
              value: state.active.dynamicEq.releases[band].toDouble(),
              min: 10,
              max: 500,
              valueFormatter: (v) => '${v.round()} ms',
              onChanged: (v) =>
                  state.update((s) => s.dynamicEq.releases[band] = v.round()),
            ),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    l.filterType,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitleText,
                    ),
                  ),
                ),
                Expanded(
                  child: ComboBox<int>(
                    value: state.active.dynamicEq.filterTypes[band],
                    items: [
                      ComboBoxItem(value: 0, child: Text(l.peak)),
                      ComboBoxItem(value: 1, child: Text(l.lowShelf)),
                      ComboBoxItem(value: 2, child: Text(l.highShelf)),
                    ],
                    onChanged: (v) {
                      if (v != null)
                        state.update((s) => s.dynamicEq.filterTypes[band] = v);
                    },
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteBandDialog(
    BuildContext context,
    ViperState state,
    S l,
    int band,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 180),
          title: Text(l.deleteBandTitle),
          content: Text(l.deleteBandContent(band + 1)),
          actions: [
            Button(child: Text(l.cancel), onPressed: () => Navigator.pop(ctx)),
            FilledButton(
              child: Text(l.delete),
              onPressed: () {
                state.removeDynEqBand(band);
                setState(() {
                  if (_dynEqSelectedBand >= state.active.dynamicEq.bandCount) {
                    _dynEqSelectedBand = max(
                      0,
                      state.active.dynamicEq.bandCount - 1,
                    );
                  }
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }
}
