import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/labeled_slider.dart';

class OutputPage extends StatelessWidget {
  const OutputPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pageMasterLimiter,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildOutputCard(state, l),
      ],
    );
  }

  Widget _buildOutputCard(ViperState state, S l) {
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
              label: l.outputGain,
              value: state.active.out.volume.toDouble(),
              min: 1,
              max: 200,
              enabled: state.masterEnabled,
              valueFormatter: (v) {
                final pct = v.round();
                final dB = pct > 0 ? 20.0 * log(pct / 100.0) / ln10 : -99.9;
                return '${dB.toStringAsFixed(1)}dB';
              },
              onChanged: (v) => state.update((s) => s.out.volume = v.round()),
            ),
            LabeledSlider(
              label: l.outputPan,
              value: state.active.out.channelPan.toDouble(),
              min: -100,
              max: 100,
              divisions: 200,
              enabled: state.masterEnabled,
              valueFormatter: (v) {
                final iv = v.round();
                if (iv == 0) return l.panCenter;
                return iv > 0 ? l.panRight(iv) : l.panLeft(-iv);
              },
              onChanged: (v) =>
                  state.update((s) => s.out.channelPan = v.round()),
            ),
            LabeledSlider(
              label: l.thresholdLimit,
              value: state.active.out.limiter.toDouble(),
              min: 30,
              max: 100,
              enabled: state.masterEnabled,
              valueFormatter: (v) {
                final pct = v.round();
                final dB = pct > 0 ? 20.0 * log(pct / 100.0) / ln10 : -99.9;
                return '${dB.toStringAsFixed(1)}dB';
              },
              onChanged: (v) => state.update((s) => s.out.limiter = v.round()),
            ),
          ],
        ),
      ),
    );
  }
}
