import 'package:fluent_ui/fluent_ui.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/theme/app_colors.dart';

class NumberInputDialog extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int decimals;
  final String unit;
  final ValueChanged<double> onCommit;

  const NumberInputDialog({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.decimals,
    required this.unit,
    required this.onCommit,
  });

  static Future<void> show(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    int decimals = 0,
    String unit = '',
    required ValueChanged<double> onCommit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => NumberInputDialog(
        label: label,
        value: value,
        min: min,
        max: max,
        decimals: decimals,
        unit: unit,
        onCommit: onCommit,
      ),
    );
  }

  @override
  State<NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<NumberInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toStringAsFixed(widget.decimals),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      final rounded = double.parse(clamped.toStringAsFixed(widget.decimals));
      widget.onCommit(rounded);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = S.of(context)!;
    final suffix = widget.unit.isEmpty ? '' : ' (${widget.unit})';
    final minStr = widget.min.toStringAsFixed(widget.decimals);
    final maxStr = widget.max.toStringAsFixed(widget.decimals);
    final rangeHint = widget.unit.isEmpty
        ? 'Range: $minStr \u2013 $maxStr'
        : 'Range: $minStr \u2013 $maxStr ${widget.unit}';
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 240),
      title: Text('${widget.label}$suffix'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            placeholder: '$minStr .. $maxStr',
            onSubmitted: (_) => _commit(),
          ),
          const SizedBox(height: 8),
          Text(
            rangeHint,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitleText,
            ),
          ),
        ],
      ),
      actions: [
        Button(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _commit, child: Text(l.save)),
      ],
    );
  }
}
