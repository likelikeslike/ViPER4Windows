import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:viper4windows/app.dart';
import 'package:viper4windows/models/viper_state.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/settings_service.dart';
import 'package:viper4windows/services/shared_memory_service.dart';
import 'package:window_manager/window_manager.dart';

typedef _CreateMutexW =
    IntPtr Function(
      Pointer lpAttributes,
      Int32 bInitialOwner,
      Pointer<Utf16> lpName,
    );
typedef _CreateMutexWDart =
    int Function(
      Pointer lpAttributes,
      int bInitialOwner,
      Pointer<Utf16> lpName,
    );
typedef _GetLastError = Uint32 Function();
typedef _GetLastErrorDart = int Function();

const _errorAlreadyExists = 183;

bool _acquireSingleInstanceLock() {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final createMutex = kernel32.lookupFunction<_CreateMutexW, _CreateMutexWDart>(
    'CreateMutexW',
  );
  final getLastError = kernel32
      .lookupFunction<_GetLastError, _GetLastErrorDart>('GetLastError');
  final name = 'Global\\ViPER4Windows_SingleInstance'.toNativeUtf16();
  final handle = createMutex(nullptr, 1, name);
  final error = getLastError();
  calloc.free(name);
  if (handle == 0) return true;
  return error != _errorAlreadyExists;
}

final _log = AppLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _log.info('App starting');

  if (!_acquireSingleInstanceLock()) {
    _log.warning('Another instance running, exiting');
    exit(0);
  }
  _log.info('Single instance lock acquired');

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(950, 680),
    minimumSize: Size(800, 600),
    center: true,
    title: 'ViPER4Windows',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final shm = SharedMemoryService();
  final settings = SettingsService();
  final viperState = ViperState(shm: shm, settings: settings);

  await viperState.loadSettings();
  _log.info('Settings loaded, launching UI');

  runApp(
    ChangeNotifierProvider<ViperState>(
      create: (_) => viperState,
      child: const ViperApp(),
    ),
  );
}
