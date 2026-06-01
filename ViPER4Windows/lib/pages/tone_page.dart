import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/effect_card.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

class TonePage extends StatelessWidget {
  const TonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pageTone,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildViperBass(state, l),
        _buildViperBassMono(state, l),
        _buildPsychoBass(state, l),
        _buildViperClarity(state, l),
        _buildSpectrumExtension(state, l),
        _buildTubeSimulator(state, l),
        _buildAnalogX(state, l),
      ],
    );
  }

  Widget _buildViperBass(ViperState state, S l) {
    final isSubwoofer = state.active.bass.mode == 2;
    return EffectCard(
      title: l.viperBass,
      masterEnabled: state.masterEnabled,
      enabled: state.active.bass.enabled,
      onToggle: (v) => state.update((s) => s.bass.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.mode,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: state.active.bass.mode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.bassNatural)),
                    ComboBoxItem(value: 1, child: Text(l.bassPureBass)),
                    ComboBoxItem(value: 2, child: Text(l.bassSubwoofer)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.update((s) => s.bass.mode = v);
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isSubwoofer)
            LabeledSlider(
              label: l.frequency,
              value: state.active.bass.frequency.toDouble(),
              min: 0,
              max: 135,
              divisions: 135,
              valueFormatter: (v) => '${v.round() + 15}Hz',
              onChanged: (v) =>
                  state.update((s) => s.bass.frequency = v.round()),
            ),
          LabeledSlider(
            label: l.gain,
            value: state.active.bass.gain.toDouble(),
            min: 50,
            max: 1000,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.bass.gain = v.round()),
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.antiPop,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              ToggleSwitch(
                checked: state.active.bass.antiPop,
                onChanged: state.masterEnabled
                    ? (v) => state.update((s) => s.bass.antiPop = v)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViperBassMono(ViperState state, S l) {
    final isSubwoofer = state.active.bassMono.mode == 2;
    return EffectCard(
      title: l.viperBassMono,
      masterEnabled: state.masterEnabled,
      enabled: state.active.bassMono.enabled,
      onToggle: (v) => state.update((s) => s.bassMono.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.mode,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: state.active.bassMono.mode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.bassNatural)),
                    ComboBoxItem(value: 1, child: Text(l.bassPureBass)),
                    ComboBoxItem(value: 2, child: Text(l.bassSubwoofer)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.update((s) => s.bassMono.mode = v);
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!isSubwoofer)
            LabeledSlider(
              label: l.frequency,
              value: state.active.bassMono.frequency.toDouble(),
              min: 0,
              max: 135,
              divisions: 135,
              valueFormatter: (v) => '${v.round() + 15}Hz',
              onChanged: (v) =>
                  state.update((s) => s.bassMono.frequency = v.round()),
            ),
          LabeledSlider(
            label: l.gain,
            value: state.active.bassMono.gain.toDouble(),
            min: 50,
            max: 1000,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.bassMono.gain = v.round()),
          ),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.antiPop,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              ToggleSwitch(
                checked: state.active.bassMono.antiPop,
                onChanged: state.masterEnabled
                    ? (v) => state.update((s) => s.bassMono.antiPop = v)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPsychoBass(ViperState state, S l) {
    return EffectCard(
      title: l.psychoBass,
      masterEnabled: state.masterEnabled,
      enabled: state.active.psychoBass.enabled,
      onToggle: (v) => state.update((s) => s.psychoBass.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.cutoff,
            value: state.active.psychoBass.cutoff.toDouble(),
            min: 60,
            max: 150,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.psychoBass.cutoff = v.round()),
          ),
          LabeledSlider(
            label: l.intensity,
            value: state.active.psychoBass.intensity.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.psychoBass.intensity = v.round()),
          ),
          LabeledSlider(
            label: l.harmonicOrder,
            value: state.active.psychoBass.harmonicOrder.toDouble(),
            min: 2,
            max: 5,
            divisions: 3,
            onChanged: (v) =>
                state.update((s) => s.psychoBass.harmonicOrder = v.round()),
          ),
          LabeledSlider(
            label: l.originalLevel,
            value: state.active.psychoBass.originalLevel.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.psychoBass.originalLevel = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildViperClarity(ViperState state, S l) {
    return EffectCard(
      title: l.viperClarity,
      masterEnabled: state.masterEnabled,
      enabled: state.active.clarity.enabled,
      onToggle: (v) => state.update((s) => s.clarity.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.mode,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: state.active.clarity.mode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.clarityNatural)),
                    ComboBoxItem(value: 1, child: Text(l.clarityOZone)),
                    ComboBoxItem(value: 2, child: Text(l.clarityXHiFi)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.update((s) => s.clarity.mode = v);
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.gain,
            value: state.active.clarity.gain.toDouble(),
            min: 0,
            max: 450,
            valueFormatter: (v) => '${(v / 100).toStringAsFixed(1)}x',
            onChanged: (v) => state.update((s) => s.clarity.gain = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumExtension(ViperState state, S l) {
    return EffectCard(
      title: l.spectrumExtension,
      masterEnabled: state.masterEnabled,
      enabled: state.active.vse.enabled,
      onToggle: (v) => state.update((s) => s.vse.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.strength,
            value: state.active.vse.strength.toDouble(),
            min: 2200,
            max: 8200,
            divisions: 1200,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) => state.update((s) => s.vse.strength = v.round()),
          ),
          LabeledSlider(
            label: l.exciter,
            value: state.active.vse.exciter.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.update((s) => s.vse.exciter = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildTubeSimulator(ViperState state, S l) {
    final active = state.active.tube.enabled && state.masterEnabled;
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
                l.tubeSimulator,
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
              checked: state.active.tube.enabled,
              onChanged: state.masterEnabled
                  ? (v) => state.update((s) => s.tube.enabled = v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalogX(ViperState state, S l) {
    return EffectCard(
      title: l.analogX,
      masterEnabled: state.masterEnabled,
      enabled: state.active.analog.enabled,
      onToggle: (v) => state.update((s) => s.analog.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.mode,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: state.active.analog.mode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.mild)),
                    ComboBoxItem(value: 1, child: Text(l.medium)),
                    ComboBoxItem(value: 2, child: Text(l.strong)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.update((s) => s.analog.mode = v);
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
