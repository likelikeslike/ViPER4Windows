import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';

class PresetPage extends StatefulWidget {
  const PresetPage({super.key});

  @override
  State<PresetPage> createState() => _PresetPageState();
}

class _PresetPageState extends State<PresetPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showRenameDialog(ViperState state, S l, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 200),
        title: Text(l.deviceRenameTitle),
        content: TextBox(
          controller: controller,
          placeholder: l.presetName,
          autofocus: true,
        ),
        actions: [
          Button(child: Text(l.cancel), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                state.renamePreset(oldName, newName);
              }
              Navigator.pop(ctx);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;
    final modeLabel = state.fxType == 0 ? l.headphone : l.speaker;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.pagePresets,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.saveCurrentSettings,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.enabledText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
                      placeholder: l.presetName,
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
                    child: Text(l.save),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: () async {
                      final result = await FilePicker.pickFiles(
                        dialogTitle: l.importPreset,
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (result != null && result.files.single.path != null) {
                        state.importPreset(result.files.single.path!);
                      }
                    },
                    child: Text(l.importBtn),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Expander(
            initiallyExpanded: true,
            header: Text(
              l.navPresets,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.enabledText,
              ),
            ),
            content: state.presetFiles.isEmpty
                ? Text(
                    l.selectPreset,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.disabledText,
                    ),
                  )
                : Column(
                    children: [
                      for (final preset in state.presetFiles)
                        _buildPresetCard(state, l, preset),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(ViperState state, S l, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            state.presetIsHeadphone(name)
                ? FluentIcons.headset
                : FluentIcons.volume2,
            size: 14,
            color: AppColors.subtitleText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.enabledText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              FluentIcons.edit,
              size: 14,
              color: AppColors.subtitleText,
            ),
            onPressed: () => _showRenameDialog(state, l, name),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(FluentIcons.play, size: 14, color: AppColors.accent),
            onPressed: () {
              final result = state.loadPreset(name);
              if (result >= 0) {
                final target = result == 1 ? l.speaker : l.headphone;
                displayInfoBar(
                  context,
                  builder: (ctx, close) => InfoBar(
                    title: Text(l.presetLoadedTo(name, target)),
                    severity: InfoBarSeverity.success,
                    action: IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: close,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              FluentIcons.delete,
              size: 14,
              color: Color(0xFFCF6679),
            ),
            onPressed: () => state.deletePreset(name),
          ),
        ],
      ),
    );
  }
}
