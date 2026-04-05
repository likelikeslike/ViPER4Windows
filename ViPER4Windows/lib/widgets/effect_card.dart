import 'package:fluent_ui/fluent_ui.dart';
import '../theme/app_colors.dart';

class EffectCard extends StatelessWidget {
  final String title;
  final bool enabled;
  final bool masterEnabled;
  final ValueChanged<bool> onToggle;
  final Widget child;

  const EffectCard({
    super.key,
    required this.title,
    required this.enabled,
    this.masterEnabled = true,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && masterEnabled;

    return AnimatedOpacity(
      opacity: masterEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Expander(
          initiallyExpanded: false,
          header: Row(
            children: [
              Expanded(
                child: Text(
                  title,
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
                checked: enabled,
                onChanged: masterEnabled ? (v) => onToggle(v) : null,
              ),
            ],
          ),
          content: AnimatedOpacity(
            opacity: active ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(ignoring: !active, child: child),
          ),
        ),
      ),
    );
  }
}
