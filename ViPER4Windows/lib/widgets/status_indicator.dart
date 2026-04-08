import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/viper_state.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    Color dotColor;
    String tooltip;
    if (state.apoConnected && state.apoProcessing) {
      dotColor = const Color(0xFF00E676);
      tooltip = l.statusApoActive(state.apoSampleRate);
    } else if (state.apoConnected) {
      dotColor = const Color(0xFFFFD740);
      tooltip = l.statusApoIdle;
    } else {
      dotColor = const Color(0xFFFF5252);
      tooltip = l.statusApoNotFound;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dotColor,
          boxShadow: [
            BoxShadow(
              color: dotColor.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
