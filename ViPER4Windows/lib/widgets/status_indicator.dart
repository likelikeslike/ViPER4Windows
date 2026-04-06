import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import 'package:viper4windows/models/viper_state.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();

    Color dotColor;
    String tooltip;
    if (state.apoConnected && state.apoProcessing) {
      dotColor = const Color(0xFF00E676);
      tooltip = 'APO active (${state.apoSampleRate} Hz)';
    } else if (state.apoConnected) {
      dotColor = const Color(0xFFFFD740);
      tooltip = 'APO connected, idle';
    } else {
      dotColor = const Color(0xFFFF5252);
      tooltip = 'APO not found';
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
