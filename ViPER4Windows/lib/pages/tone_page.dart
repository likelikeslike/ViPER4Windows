import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/value_mappings.dart';
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
        _buildViperClarity(state, l),
        _buildSpectrumExtension(state, l),
        _buildTubeSimulator(state, l),
        _buildAnalogX(state, l),
      ],
    );
  }

  Widget _buildViperBass(ViperState state, S l) {
    final isSubwoofer = state.viperBassMode == 2;
    final gainLabels = isSubwoofer
        ? ValueMappings.subwooferGainDbLabels
        : ValueMappings.bassGainDbLabels;
    return EffectCard(
      title: l.viperBass,
      masterEnabled: state.masterEnabled,
      enabled: state.viperBassEnabled,
      onToggle: (v) => state.viperBassEnabled = v,
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
                  value: state.viperBassMode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.bassNatural)),
                    ComboBoxItem(value: 1, child: Text(l.bassPureBass)),
                    ComboBoxItem(value: 2, child: Text(l.bassSubwoofer)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.viperBassMode = v;
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
              value: state.viperBassFrequency.toDouble(),
              min: 0,
              max: 135,
              divisions: 135,
              valueFormatter: (v) => '${v.round() + 15}Hz',
              onChanged: (v) => state.viperBassFrequency = v.round(),
            ),
          LabeledSlider(
            label: l.gain,
            value: state.viperBassGain.toDouble(),
            min: 0,
            max: gainLabels.length - 1,
            divisions: gainLabels.length - 1,
            valueFormatter: (v) {
              final idx = v.round();
              if (idx < gainLabels.length) {
                return '${gainLabels[idx]}dB';
              }
              return '$idx';
            },
            onChanged: (v) => state.viperBassGain = v.round(),
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
                checked: state.viperBassAntiPop,
                onChanged: state.masterEnabled
                    ? (v) => state.viperBassAntiPop = v
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViperBassMono(ViperState state, S l) {
    final isSubwoofer = state.viperBassMonoMode == 2;
    final gainLabels = isSubwoofer
        ? ValueMappings.subwooferGainDbLabels
        : ValueMappings.bassGainDbLabels;
    return EffectCard(
      title: l.viperBassMono,
      masterEnabled: state.masterEnabled,
      enabled: state.viperBassMonoEnabled,
      onToggle: (v) => state.viperBassMonoEnabled = v,
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
                  value: state.viperBassMonoMode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.bassNatural)),
                    ComboBoxItem(value: 1, child: Text(l.bassPureBass)),
                    ComboBoxItem(value: 2, child: Text(l.bassSubwoofer)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.viperBassMonoMode = v;
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
              value: state.viperBassMonoFrequency.toDouble(),
              min: 0,
              max: 135,
              divisions: 135,
              valueFormatter: (v) => '${v.round() + 15}Hz',
              onChanged: (v) => state.viperBassMonoFrequency = v.round(),
            ),
          LabeledSlider(
            label: l.gain,
            value: state.viperBassMonoGain.toDouble(),
            min: 0,
            max: gainLabels.length - 1,
            divisions: gainLabels.length - 1,
            valueFormatter: (v) {
              final idx = v.round();
              if (idx < gainLabels.length) {
                return '${gainLabels[idx]}dB';
              }
              return '$idx';
            },
            onChanged: (v) => state.viperBassMonoGain = v.round(),
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
                checked: state.viperBassMonoAntiPop,
                onChanged: state.masterEnabled
                    ? (v) => state.viperBassMonoAntiPop = v
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViperClarity(ViperState state, S l) {
    return EffectCard(
      title: l.viperClarity,
      masterEnabled: state.masterEnabled,
      enabled: state.viperClarityEnabled,
      onToggle: (v) => state.viperClarityEnabled = v,
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
                  value: state.viperClarityMode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.clarityNatural)),
                    ComboBoxItem(value: 1, child: Text(l.clarityOZone)),
                    ComboBoxItem(value: 2, child: Text(l.clarityXHiFi)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.viperClarityMode = v;
                  },
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.gain,
            value: state.viperClarityGain.toDouble(),
            min: 0,
            max: 9,
            divisions: 9,
            valueFormatter: (v) {
              final idx = v.round();
              if (idx < ValueMappings.clarityGainDbLabels.length) {
                return '${ValueMappings.clarityGainDbLabels[idx]}dB';
              }
              return '$idx';
            },
            onChanged: (v) => state.viperClarityGain = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumExtension(ViperState state, S l) {
    return EffectCard(
      title: l.spectrumExtension,
      masterEnabled: state.masterEnabled,
      enabled: state.spectrumExtensionEnabled,
      onToggle: (v) => state.spectrumExtensionEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.strength,
            value: state.spectrumExtensionBark.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.spectrumExtensionBark = v.round(),
          ),
          LabeledSlider(
            label: l.exciter,
            value: state.spectrumExtensionExciter.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.spectrumExtensionExciter = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildTubeSimulator(ViperState state, S l) {
    final active = state.tubeSimulatorEnabled && state.masterEnabled;
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
              checked: state.tubeSimulatorEnabled,
              onChanged: state.masterEnabled
                  ? (v) => state.tubeSimulatorEnabled = v
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
      enabled: state.analogXEnabled,
      onToggle: (v) => state.analogXEnabled = v,
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
                  value: state.analogXMode,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.analogXMild)),
                    ComboBoxItem(value: 1, child: Text(l.analogXMedium)),
                    ComboBoxItem(value: 2, child: Text(l.analogXStrong)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.analogXMode = v;
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
