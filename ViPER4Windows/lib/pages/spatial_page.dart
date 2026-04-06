import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
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

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Spatial',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldSurround(state),
        _buildDiffSurround(state),
        _buildVhe(state),
        _buildReverberation(state),
        _buildCure(state),
      ],
    );
  }

  Widget _buildFieldSurround(ViperState state) {
    return EffectCard(
      title: 'Field Surround',
      masterEnabled: state.masterEnabled,
      enabled: state.fieldSurroundEnabled,
      onToggle: (v) => state.fieldSurroundEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Widening',
            value: state.fieldSurroundWidening.toDouble(),
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (v) => state.fieldSurroundWidening = v.round(),
          ),
          LabeledSlider(
            label: 'Mid Image',
            value: state.fieldSurroundMidImage.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.fieldSurroundMidImage = v.round(),
          ),
          LabeledSlider(
            label: 'Depth',
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

  Widget _buildDiffSurround(ViperState state) {
    return EffectCard(
      title: 'Differential Surround',
      masterEnabled: state.masterEnabled,
      enabled: state.diffSurroundEnabled,
      onToggle: (v) => state.diffSurroundEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Delay',
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
        ],
      ),
    );
  }

  Widget _buildVhe(ViperState state) {
    return EffectCard(
      title: 'Headphone Surround+',
      masterEnabled: state.masterEnabled,
      enabled: state.vheEnabled,
      onToggle: (v) => state.vheEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Quality',
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

  Widget _buildReverberation(ViperState state) {
    return EffectCard(
      title: 'Reverberation',
      masterEnabled: state.masterEnabled,
      enabled: state.reverberationEnabled,
      onToggle: (v) => state.reverberationEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: 'Room Size',
            value: state.reverberationRoomSize.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomSize = v.round(),
          ),
          LabeledSlider(
            label: 'Width',
            value: state.reverberationRoomWidth.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomWidth = v.round(),
          ),
          LabeledSlider(
            label: 'Dampening',
            value: state.reverberationRoomDampening.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.reverberationRoomDampening = v.round(),
          ),
          LabeledSlider(
            label: 'Wet Signal',
            value: state.reverberationWetSignal.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.reverberationWetSignal = v.round(),
          ),
          LabeledSlider(
            label: 'Dry Signal',
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

  Widget _buildCure(ViperState state) {
    return EffectCard(
      title: 'Auditory System Protection',
      masterEnabled: state.masterEnabled,
      enabled: state.cureEnabled,
      onToggle: (v) => state.cureEnabled = v,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text(
                  'Preset',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitleText),
                ),
              ),
              Expanded(
                child: ComboBox<int>(
                  value: state.cureCrossfeedStrength,
                  items: List.generate(
                    ValueMappings.cureCrossfeedLabels.length,
                    (i) => ComboBoxItem(
                      value: i,
                      child: Text(ValueMappings.cureCrossfeedLabels[i]),
                    ),
                  ),
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
