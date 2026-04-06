import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';

class PresetPage extends StatefulWidget {
  const PresetPage({super.key});

  @override
  State<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends State<PresetPage> {
  String? _selectedPreset;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();

    if (_selectedPreset != null &&
        !state.presetFiles.contains(_selectedPreset)) {
      _selectedPreset = null;
    }

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Presets',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildSaveCard(state),
        const SizedBox(height: 16),
        _buildLoadCard(state),
      ],
    );
  }

  Widget _buildSaveCard(ViperState state) {
    final modeLabel = state.fxType == 0 ? 'Headphone' : 'Speaker';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Save Current Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextBox(
                  controller: _nameController,
                  placeholder: 'Preset name',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.enabledText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  state.savePreset(name);
                  _nameController.clear();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCard(ViperState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Load / Manage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ComboBox<String>(
                  value: _selectedPreset,
                  placeholder: const Text('Select preset...'),
                  items: state.presetFiles
                      .map(
                        (name) => ComboBoxItem<String>(
                          value: name,
                          child: Text(name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPreset = v),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _selectedPreset == null
                    ? null
                    : () {
                        final result = state.loadPreset(_selectedPreset!);
                        if (result >= 0) {
                          final target = result == 1 ? 'Speaker' : 'Headphone';
                          displayInfoBar(
                            context,
                            builder: (ctx, close) {
                              return InfoBar(
                                title: Text(
                                  'Loaded "$_selectedPreset" to $target',
                                ),
                                severity: InfoBarSeverity.success,
                                action: IconButton(
                                  icon: const Icon(FluentIcons.clear),
                                  onPressed: close,
                                ),
                              );
                            },
                          );
                        }
                      },
                child: const Text('Load'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    dialogTitle: 'Import Preset',
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    state.importPreset(result.files.single.path!);
                  }
                },
                child: const Text('Import'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: _selectedPreset == null
                    ? null
                    : () {
                        state.deletePreset(_selectedPreset!);
                        setState(() => _selectedPreset = null);
                      },
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
