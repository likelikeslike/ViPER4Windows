import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/models/value_mappings.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

class OutputPage extends StatelessWidget {
  const OutputPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Master Limiter',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildOutputCard(state),
      ],
    );
  }

  Widget _buildOutputCard(ViperState state) {
    final volIdx = state.outputVolume;
    final volPercent = ValueMappings.safeIndex(
      ValueMappings.outputVolumeValues,
      volIdx,
    );

    final limIdx = state.limiter;
    final limPercent = ValueMappings.safeIndex(
      ValueMappings.limiterValues,
      limIdx,
    );

    return AnimatedOpacity(
      opacity: state.masterEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledSlider(
              label: 'Output Gain',
              value: volIdx.toDouble(),
              min: 0,
              max: 21,
              divisions: 21,
              enabled: state.masterEnabled,
              valueFormatter: (_) {
                final dB = volPercent > 0
                    ? 20.0 * log(volPercent / 100.0) / ln10
                    : -99.9;
                return '${dB.toStringAsFixed(1)}dB';
              },
              onChanged: (v) => state.outputVolume = v.round(),
            ),
            LabeledSlider(
              label: 'Output Pan',
              value: state.channelPan.toDouble(),
              min: -100,
              max: 100,
              divisions: 200,
              enabled: state.masterEnabled,
              valueFormatter: (v) {
                final iv = v.round();
                if (iv == 0) return 'Center';
                return iv > 0 ? 'R $iv' : 'L ${-iv}';
              },
              onChanged: (v) => state.channelPan = v.round(),
            ),
            LabeledSlider(
              label: 'Threshold Limit',
              value: limIdx.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              enabled: state.masterEnabled,
              valueFormatter: (_) {
                final dB = limPercent > 0
                    ? 20.0 * log(limPercent / 100.0) / ln10
                    : -99.9;
                return '${dB.toStringAsFixed(1)}dB';
              },
              onChanged: (v) => state.limiter = v.round(),
            ),
          ],
        ),
      ),
    );
  }
}
