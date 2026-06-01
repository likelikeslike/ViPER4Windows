import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/device_settings.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/theme/app_colors.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  String _formatTimeAgo(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    if (diff < 60000) return '${(diff / 1000).floor()}s ago';
    if (diff < 3600000) return '${(diff / 60000).floor()} min ago';
    if (diff < 86400000) return '${(diff / 3600000).floor()}h ago';
    return '${(diff / 86400000).floor()} days ago';
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showRenameDialog(
    ViperState state,
    String deviceId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    final l = S.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 200),
        title: Text(l.deviceRenameTitle),
        content: TextBox(
          controller: controller,
          placeholder: l.deviceRenameHint,
          autofocus: true,
        ),
        actions: [
          Button(child: Text(l.cancel), onPressed: () => Navigator.pop(ctx)),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                state.renameDevice(deviceId, newName);
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
    final devices = state.deviceList;

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.devicesTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        if (devices.isEmpty)
          Text(
            l.deviceNoDevices,
            style: const TextStyle(fontSize: 13, color: AppColors.disabledText),
          )
        else
          for (final device in devices) _buildDeviceRow(state, device, l),
      ],
    );
  }

  Widget _buildDeviceRow(ViperState state, Map<String, dynamic> device, S l) {
    final deviceId = device['deviceId'] as String? ?? '';
    final deviceName = device['deviceName'] as String? ?? deviceId;
    final isHeadphone = device['isHeadphone'] as bool? ?? true;
    final lastConnected = device['lastConnected'] as int?;
    final isActive = deviceId == state.currentDeviceId;
    final isBuiltIn =
        deviceId == DeviceInfo.defaultSpeaker ||
        deviceId == DeviceInfo.defaultWired;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.cardBorder,
        ),
      ),
      child: Expander(
        initiallyExpanded: false,
        header: Row(
          children: [
            if (isActive)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 10),
            Icon(
              isHeadphone ? FluentIcons.headset : FluentIcons.volume2,
              size: 16,
              color: AppColors.subtitleText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.enabledText,
                    ),
                  ),
                  if (!isActive)
                    Text(
                      _formatTimeAgo(lastConnected),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.disabledText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                l.deviceLabelType,
                isHeadphone ? l.headphone : l.speaker,
              ),
              _infoRow(l.deviceLabelId, deviceId),
              _infoRow(
                l.deviceLabelLastUsed,
                isActive ? '-' : _formatDate(lastConnected),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _actionButton(
                    icon: FluentIcons.download,
                    label: l.load,
                    onPressed: () {
                      state.loadDevicePreset(deviceId);
                      displayInfoBar(
                        context,
                        builder: (ctx, close) => InfoBar(
                          title: Text('${l.load}: $deviceName'),
                          severity: InfoBarSeverity.success,
                          action: IconButton(
                            icon: const Icon(FluentIcons.clear),
                            onPressed: close,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: FluentIcons.sync,
                    label: l.update,
                    onPressed: () {
                      state.saveDevicePreset(deviceId);
                      displayInfoBar(
                        context,
                        builder: (ctx, close) => InfoBar(
                          title: Text('${l.update}: $deviceName'),
                          severity: InfoBarSeverity.success,
                          action: IconButton(
                            icon: const Icon(FluentIcons.clear),
                            onPressed: close,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: FluentIcons.edit,
                    label: l.deviceRenameTitle,
                    onPressed: () =>
                        _showRenameDialog(state, deviceId, deviceName),
                  ),
                  const SizedBox(width: 16),
                  _actionButton(
                    icon: FluentIcons.delete,
                    label: l.delete,
                    onPressed: (isActive || isBuiltIn)
                        ? null
                        : () {
                            state.deleteDevice(deviceId);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: icon == FluentIcons.delete
                  ? (enabled ? const Color(0xFFCF6679) : AppColors.disabledText)
                  : (enabled ? AppColors.accent : AppColors.disabledText),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? AppColors.enabledText : AppColors.disabledText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.subtitleText,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.enabledText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
