import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/services/apo_registration_service.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/theme/app_colors.dart';

final _log = AppLogger('DriverPage');

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  final ApoRegistrationService _registration = ApoRegistrationService();
  List<ApoEndpointInfo> _endpoints = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshEndpoints();
  }

  Future<void> _refreshEndpoints() async {
    setState(() => _loading = true);
    try {
      _endpoints = await _registration.listRenderEndpoints();
    } catch (e) {
      _log.error('Endpoint refresh failed: $e');
      _endpoints = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _runRegistrationAction(
    Future<bool> Function() action,
    String successMessage,
    String failureMessage,
  ) async {
    setState(() => _loading = true);
    try {
      final ok = await action();
      await _refreshEndpoints();
      if (mounted) {
        displayInfoBar(
          context,
          builder: (ctx, close) {
            return InfoBar(
              title: Text(ok ? successMessage : failureMessage),
              severity: ok ? InfoBarSeverity.success : InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    } catch (e) {
      _log.error('Registration action failed: $e');
      if (mounted) {
        displayInfoBar(
          context,
          builder: (ctx, close) {
            return InfoBar(
              title: Text('Error: $e'),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _registerAll() => _runRegistrationAction(
    _registration.registerOnAllEndpoints,
    'Registered on all endpoints. Audio service restarted. Reboot if effects do not work.',
    'Registration failed.',
  );

  Future<void> _registerSingle(String endpointId) => _runRegistrationAction(
    () => _registration.registerOnEndpoint(endpointId),
    'Registered. Audio service restarted. Reboot if effects do not work.',
    'Registration failed.',
  );

  Future<void> _unregisterSingle(String endpointId) => _runRegistrationAction(
    () => _registration.unregisterEndpoint(endpointId),
    'Unregistered. Audio service restarted. Reboot if effects persist.',
    'Unregistration failed.',
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();

    return ScaffoldPage.scrollable(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Driver Status',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusCard(state),
        const SizedBox(height: 12),
        _buildEndpointsCard(),
        const SizedBox(height: 12),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildStatusCard(ViperState state) {
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
            'APO Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          _statusRow(
            'Driver',
            state.apoConnected ? 'Installed' : 'Not Found',
            dotColor: state.apoConnected
                ? const Color(0xFF00E676)
                : const Color(0xFFFF5252),
          ),
          const Divider(),
          _statusRow(
            'Streaming',
            state.apoProcessing ? 'Active' : 'Inactive',
            dotColor: state.apoProcessing
                ? const Color(0xFF00E676)
                : const Color(0xFFFFD740),
          ),
          const Divider(),
          _statusRow(
            'Sampling Rate',
            state.apoSampleRate > 0 ? '${state.apoSampleRate} Hz' : 'Unknown',
          ),
          const Divider(),
          _statusRow(
            'Master Enable',
            state.masterEnabled ? 'On' : 'Off',
            dotColor: state.masterEnabled
                ? const Color(0xFF00E676)
                : AppColors.disabledText,
          ),
          const Divider(),
          _statusRow(
            'FX Mode',
            state.activeDeviceType == 0 ? 'Headphone' : 'Speaker',
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointsCard() {
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
                'Audio Endpoints',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              else ...[
                IconButton(
                  icon: const Icon(FluentIcons.refresh, size: 14),
                  onPressed: _refreshEndpoints,
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _registerAll,
                  child: const Text('Register All'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_endpoints.isEmpty && !_loading)
            const Text(
              'No active render endpoints found.',
              style: TextStyle(fontSize: 12, color: AppColors.disabledText),
            ),
          ..._endpoints.map(
            (ep) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ep.registered
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (ep.registered
                                      ? const Color(0xFF00E676)
                                      : const Color(0xFFFF5252))
                                  .withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ep.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.enabledText,
                          ),
                        ),
                        Text(
                          ep.registered ? 'ViPER registered' : 'Not registered',
                          style: TextStyle(
                            fontSize: 11,
                            color: ep.registered
                                ? const Color(0xFF00E676)
                                : AppColors.disabledText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Button(
                    onPressed: _loading
                        ? null
                        : () => ep.registered
                              ? _unregisterSingle(ep.id)
                              : _registerSingle(ep.id),
                    child: Text(ep.registered ? 'Unregister' : 'Register'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
            'Driver Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Version', '1.0.0'),
          const Divider(),
          _infoRow('Architecture', 'x64'),
          const Divider(),
          _infoRow('APO Type', 'MFX (Component)'),
          const Divider(),
          _infoRow('IPC', 'Shared Memory'),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, {Color? dotColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.subtitleText,
              ),
            ),
          ),
          const Spacer(),
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.enabledText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.subtitleText,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.enabledText,
            ),
          ),
        ],
      ),
    );
  }
}
