import 'package:fluent_ui/fluent_ui.dart';
import 'package:viper4windows/theme/app_colors.dart';

class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? valueFormatter;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.valueFormatter,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        valueFormatter?.call(value) ?? value.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled
                    ? AppColors.subtitleText
                    : const Color(0xFF606060),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: (divisions != null && divisions! <= 20)
                  ? divisions
                  : null,
              onChanged: enabled ? onChanged : null,
              style: SliderThemeData(
                activeColor: WidgetStateProperty.all(AppColors.accent),
                inactiveColor: WidgetStateProperty.all(AppColors.cardBorder),
                thumbColor: WidgetStateProperty.all(AppColors.accent),
                margin: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: enabled ? AppColors.accent : const Color(0xFF606060),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
