import 'package:fluent_ui/fluent_ui.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/number_input_dialog.dart';

class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? valueFormatter;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final int decimals;
  final String unit;
  final double Function(double raw)? toDisplay;
  final double Function(double display)? fromDisplay;
  final bool editable;

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
    this.decimals = 0,
    this.unit = '',
    this.toDisplay,
    this.fromDisplay,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        valueFormatter?.call(value) ?? value.toStringAsFixed(0);
    final canEdit = enabled && editable;

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
            child: GestureDetector(
              onTap: canEdit ? () => _showEditDialog(context) : null,
              child: MouseRegion(
                cursor: canEdit ? SystemMouseCursors.click : MouseCursor.defer,
                child: Text(
                  displayValue,
                  textAlign: TextAlign.right,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: canEdit
                        ? AppColors.accent
                        : enabled
                        ? AppColors.subtitleText
                        : const Color(0xFF606060),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final double Function(double) toDisp = toDisplay ?? (v) => v;
    final double Function(double) fromDisp = fromDisplay ?? (v) => v;
    final a = toDisp(min);
    final b = toDisp(max);
    NumberInputDialog.show(
      context,
      label: label,
      value: toDisp(value.clamp(min, max).toDouble()),
      min: a < b ? a : b,
      max: a < b ? b : a,
      decimals: decimals,
      unit: unit,
      onCommit: (display) =>
          onChanged(fromDisp(display).clamp(min, max).toDouble()),
    );
  }
}
