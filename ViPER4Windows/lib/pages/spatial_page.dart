import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/value_mappings.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/effect_card.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

class SpatialPage extends StatelessWidget {
  const SpatialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pageSpatial,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldSurround(state, l),
        _buildDiffSurround(state, l),
        _buildVhe(state, l),
        _buildReverberation(state, l),
        _buildCure(state, l),
      ],
    );
  }

  Widget _buildFieldSurround(ViperState state, S l) {
    return EffectCard(
      title: l.fieldSurround,
      masterEnabled: state.masterEnabled,
      enabled: state.fieldSurroundEnabled,
      onToggle: (v) => state.fieldSurroundEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.widening,
            value: state.fieldSurroundWidening.toDouble(),
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (v) => state.fieldSurroundWidening = v.round(),
          ),
          LabeledSlider(
            label: l.midImage,
            value: state.fieldSurroundMidImage.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.fieldSurroundMidImage = v.round(),
          ),
          LabeledSlider(
            label: l.depth,
            value: state.fieldSurroundDepth.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.fieldSurroundDepth = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffSurround(ViperState state, S l) {
    return EffectCard(
      title: l.differentialSurround,
      masterEnabled: state.masterEnabled,
      enabled: state.diffSurroundEnabled,
      onToggle: (v) => state.diffSurroundEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.delay,
            value: state.diffSurroundDelay.toDouble(),
            min: 0,
            max: 19,
            divisions: 19,
            valueFormatter: (v) {
              final idx = v.round();
              final ms = ValueMappings.safeIndex(
                ValueMappings.diffSurroundDelayValues,
                idx,
              );
              return '${ms ~/ 100}ms';
            },
            onChanged: (v) => state.diffSurroundDelay = v.round(),
          ),

          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  l.diffSurroundReverse,
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              ToggleSwitch(
                checked: state.diffSurroundReverse,
                onChanged: state.masterEnabled
                    ? (v) => state.diffSurroundReverse = v
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVhe(ViperState state, S l) {
    return EffectCard(
      title: l.headphoneSurroundPlus,
      masterEnabled: state.masterEnabled,
      enabled: state.vheEnabled,
      onToggle: (v) => state.vheEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.quality,
            value: state.vheQuality.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (v) => state.vheQuality = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildReverberation(ViperState state, S l) {
    return EffectCard(
      title: l.reverberation,
      masterEnabled: state.masterEnabled,
      enabled: state.reverberationEnabled,
      onToggle: (v) => state.reverberationEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.roomSize,
            value: state.reverberationRoomSize.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomSize = v.round(),
          ),
          LabeledSlider(
            label: l.width,
            value: state.reverberationRoomWidth.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomWidth = v.round(),
          ),
          LabeledSlider(
            label: l.dampening,
            value: state.reverberationRoomDampening.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomDampening = v.round(),
          ),
          LabeledSlider(
            label: l.wetSignal,
            value: state.reverberationWetSignal.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.reverberationWetSignal = v.round(),
          ),
          LabeledSlider(
            label: l.drySignal,
            value: state.reverberationDrySignal.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.reverberationDrySignal = v.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildCure(ViperState state, S l) {
    return EffectCard(
      title: l.auditorySystemProtection,
      masterEnabled: state.masterEnabled,
      enabled: state.cureEnabled,
      onToggle: (v) => state.cureEnabled = v,
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
                  value: state.cureCrossfeedStrength,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.cureMild)),
                    ComboBoxItem(value: 1, child: Text(l.cureMedium)),
                    ComboBoxItem(value: 2, child: Text(l.cureStrong)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.cureCrossfeedStrength = v;
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
