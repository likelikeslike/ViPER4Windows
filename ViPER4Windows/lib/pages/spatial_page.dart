import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
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
        _buildStereoImager(state, l),
        _buildCure(state, l),
      ],
    );
  }

  Widget _buildFieldSurround(ViperState state, S l) {
    return EffectCard(
      title: l.fieldSurround,
      masterEnabled: state.masterEnabled,
      enabled: state.active.fieldSurround.enabled,
      onToggle: (v) => state.update((s) => s.fieldSurround.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.widening,
            value: state.active.fieldSurround.widening.toDouble(),
            min: 0,
            max: 8,
            divisions: 8,
            onChanged: (v) =>
                state.update((s) => s.fieldSurround.widening = v.round()),
          ),
          LabeledSlider(
            label: l.midImage,
            value: state.active.fieldSurround.midImage.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) =>
                state.update((s) => s.fieldSurround.midImage = v.round()),
          ),
          LabeledSlider(
            label: l.depth,
            value: state.active.fieldSurround.depth.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) =>
                state.update((s) => s.fieldSurround.depth = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffSurround(ViperState state, S l) {
    return EffectCard(
      title: l.differentialSurround,
      masterEnabled: state.masterEnabled,
      enabled: state.active.diffSurround.enabled,
      onToggle: (v) => state.update((s) => s.diffSurround.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.delay,
            value: state.active.diffSurround.delay.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            valueFormatter: (v) => '${v.round()} ms',
            onChanged: (v) =>
                state.update((s) => s.diffSurround.delay = v.round()),
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
                checked: state.active.diffSurround.reverse,
                onChanged: state.masterEnabled
                    ? (v) => state.update((s) => s.diffSurround.reverse = v)
                    : null,
              ),
            ],
          ),
          LabeledSlider(
            label: l.wetDryMix,
            value: state.active.diffSurround.wetDryMix.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.diffSurround.wetDryMix = v.round()),
          ),
          LabeledSlider(
            label: l.lpCutoff,
            value: state.active.diffSurround.lpCutoff.toDouble(),
            min: 0,
            max: 20000,
            divisions: 4000,
            valueFormatter: (v) => v.round() == 0 ? 'Off' : '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.diffSurround.lpCutoff = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildVhe(ViperState state, S l) {
    return EffectCard(
      title: l.headphoneSurroundPlus,
      masterEnabled: state.masterEnabled,
      enabled: state.active.vhe.enabled,
      onToggle: (v) => state.update((s) => s.vhe.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.quality,
            value: state.active.vhe.quality.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (v) => state.update((s) => s.vhe.quality = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildReverberation(ViperState state, S l) {
    return EffectCard(
      title: l.reverberation,
      masterEnabled: state.masterEnabled,
      enabled: state.active.reverb.enabled,
      onToggle: (v) => state.update((s) => s.reverb.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.roomSize,
            value: state.active.reverb.roomSize.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) =>
                state.update((s) => s.reverb.roomSize = v.round()),
          ),
          LabeledSlider(
            label: l.width,
            value: state.active.reverb.width.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) => state.update((s) => s.reverb.width = v.round()),
          ),
          LabeledSlider(
            label: l.dampening,
            value: state.active.reverb.roomDampening.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (v) =>
                state.update((s) => s.reverb.roomDampening = v.round()),
          ),
          LabeledSlider(
            label: l.wetSignal,
            value: state.active.reverb.wet.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.update((s) => s.reverb.wet = v.round()),
          ),
          LabeledSlider(
            label: l.drySignal,
            value: state.active.reverb.dry.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) => state.update((s) => s.reverb.dry = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildStereoImager(ViperState state, S l) {
    return EffectCard(
      title: l.stereoImager,
      masterEnabled: state.masterEnabled,
      enabled: state.active.stereoImager.enabled,
      onToggle: (v) => state.update((s) => s.stereoImager.enabled = v),
      child: Column(
        children: [
          const SizedBox(height: 8),
          LabeledSlider(
            label: l.lowWidth,
            value: state.active.stereoImager.lowWidth.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.stereoImager.lowWidth = v.round()),
          ),
          LabeledSlider(
            label: l.midWidth,
            value: state.active.stereoImager.midWidth.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.stereoImager.midWidth = v.round()),
          ),
          LabeledSlider(
            label: l.highWidth,
            value: state.active.stereoImager.highWidth.toDouble(),
            min: 0,
            max: 200,
            divisions: 200,
            valueFormatter: (v) => '${v.round()}%',
            onChanged: (v) =>
                state.update((s) => s.stereoImager.highWidth = v.round()),
          ),
          LabeledSlider(
            label: l.lowCrossover,
            value: state.active.stereoImager.lowCrossover.toDouble(),
            min: 80,
            max: 400,
            divisions: 64,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.stereoImager.lowCrossover = v.round()),
          ),
          LabeledSlider(
            label: l.highCrossover,
            value: state.active.stereoImager.highCrossover.toDouble(),
            min: 2000,
            max: 8000,
            divisions: 1200,
            valueFormatter: (v) => '${v.round()} Hz',
            onChanged: (v) =>
                state.update((s) => s.stereoImager.highCrossover = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildCure(ViperState state, S l) {
    return EffectCard(
      title: l.auditorySystemProtection,
      masterEnabled: state.masterEnabled,
      enabled: state.active.cure.enabled,
      onToggle: (v) => state.update((s) => s.cure.enabled = v),
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
                  value: state.active.cure.strength,
                  items: [
                    ComboBoxItem(value: 0, child: Text(l.mild)),
                    ComboBoxItem(value: 1, child: Text(l.medium)),
                    ComboBoxItem(value: 2, child: Text(l.strong)),
                  ],
                  onChanged: (v) {
                    if (v != null) state.update((s) => s.cure.strength = v);
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
