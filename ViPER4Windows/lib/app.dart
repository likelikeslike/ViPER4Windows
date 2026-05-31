import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:viper4windows/l10n/app_localizations.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/pages/devices_page.dart';
import 'package:viper4windows/pages/driver_page.dart';
import 'package:viper4windows/pages/dynamics_page.dart';
import 'package:viper4windows/pages/equalizer_page.dart';
import 'package:viper4windows/pages/output_page.dart';
import 'package:viper4windows/pages/preset_page.dart';
import 'package:viper4windows/pages/spatial_page.dart';
import 'package:viper4windows/pages/tone_page.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/theme/app_colors.dart';
import 'package:viper4windows/widgets/status_indicator.dart';
import 'package:window_manager/window_manager.dart';

const _deepBg = Color(0xFF1A1A2E);
const _navBg = Color(0xFF0F3460);
final _log = AppLogger('App');

class ViperApp extends StatelessWidget {
  const ViperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'ViPER4Windows',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FluentLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      themeMode: ThemeMode.dark,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.purple,
        scaffoldBackgroundColor: _deepBg,
        navigationPaneTheme: NavigationPaneThemeData(
          backgroundColor: _navBg,
          highlightColor: AppColors.accent,
        ),
        fontFamily: 'Inter',
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WindowListener {
  int _selectedIndex = 0;
  final SystemTray _systemTray = SystemTray();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _initTray();
    _log.info('Shell initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTrayMenu();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _systemTray.destroy();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      _log.info('Window close -> minimize to tray');
      context.read<ViperState>().saveSettingsSync();
      await windowManager.hide();
    }
  }

  Future<void> _initTray() async {
    await _systemTray.initSystemTray(
      iconPath: 'assets/app_icon.ico',
      toolTip: 'ViPER4Windows',
    );

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
        windowManager.focus();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  Future<void> _updateTrayMenu() async {
    final l = S.of(context);
    if (l == null) return;
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: l.trayShow,
        onClicked: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: l.trayQuit,
        onClicked: (_) async {
          _log.info('Quit requested');
          FileLogger.shared.flush();
          context.read<ViperState>().saveSettingsSync();
          await _systemTray.destroy();
          await windowManager.setPreventClose(false);
          await windowManager.destroy();
        },
      ),
    ]);
    await _systemTray.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ViperState>();
    final l = S.of(context)!;

    return NavigationView(
      titleBar: TitleBar(
        isBackButtonVisible: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StatusIndicator(),
            const SizedBox(width: 10),
            Text(
              l.appTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        endHeader: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.currentDeviceName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E676),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.currentDeviceName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            _buildFxToggle(state, l),
            const SizedBox(width: 16),
            _buildMasterToggle(state, l),
            const SizedBox(width: 8),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (i) => setState(() => _selectedIndex = i),
        displayMode: PaneDisplayMode.compact,
        size: const NavigationPaneSize(compactWidth: 40, openWidth: 180),
        items: [
          PaneItem(
            icon: Icon(FluentIcons.volume2, size: 16.0),
            title: Text(l.navOutput),
            body: const OutputPage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.equalizer, size: 16.0),
            title: Text(l.navEqualizer),
            body: const EqualizerPage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.music_note, size: 16.0),
            title: Text(l.navTone),
            body: const TonePage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.headset, size: 16.0),
            title: Text(l.navSpatial),
            body: const SpatialPage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.heart, size: 16.0),
            title: Text(l.navDynamics),
            body: const DynamicsPage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.devices4, size: 16.0),
            title: Text(l.navDevices),
            body: const DevicesPage(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.save_template, size: 16.0),
            title: Text(l.navPresets),
            body: const PresetPage(),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: Icon(FluentIcons.info, size: 16.0),
            title: Text(l.navDriverStatus),
            body: const DriverPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle(ViperState state, S l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.master,
          style: TextStyle(
            fontSize: 12,
            color: state.masterEnabled
                ? AppColors.accent
                : AppColors.disabledText,
          ),
        ),
        const SizedBox(width: 8),
        ToggleSwitch(
          checked: state.masterEnabled,
          onChanged: (v) => state.masterEnabled = v,
        ),
      ],
    );
  }

  Widget _buildFxToggle(ViperState state, S l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FxButton(
          label: l.headphone,
          selected: state.fxType == 0,
          onTap: () => state.fxType = 0,
        ),
        const SizedBox(width: 4),
        _FxButton(
          label: l.speaker,
          selected: state.fxType == 1,
          onTap: () => state.fxType = 1,
        ),
      ],
    );
  }
}

class _FxButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FxButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFF404060),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.accent : AppColors.disabledText,
          ),
        ),
      ),
    );
  }
}
