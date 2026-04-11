import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:viper4windows/models/shared_params.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/win32_security.dart';

typedef _CreateFileMappingW =
    IntPtr Function(
      IntPtr hFile,
      Pointer lpAttributes,
      Uint32 flProtect,
      Uint32 dwMaxSizeHigh,
      Uint32 dwMaxSizeLow,
      Pointer<Utf16> lpName,
    );
typedef _CreateFileMappingWDart =
    int Function(
      int hFile,
      Pointer lpAttributes,
      int flProtect,
      int dwMaxSizeHigh,
      int dwMaxSizeLow,
      Pointer<Utf16> lpName,
    );

typedef _MapViewOfFile =
    Pointer Function(
      IntPtr hMap,
      Uint32 dwAccess,
      Uint32 dwOffsetHigh,
      Uint32 dwOffsetLow,
      IntPtr dwNumberOfBytes,
    );
typedef _MapViewOfFileDart =
    Pointer Function(
      int hMap,
      int dwAccess,
      int dwOffsetHigh,
      int dwOffsetLow,
      int dwNumberOfBytes,
    );

typedef _UnmapViewOfFile = Int32 Function(Pointer lpBaseAddress);
typedef _UnmapViewOfFileDart = int Function(Pointer lpBaseAddress);

typedef _CloseHandle = Int32 Function(IntPtr hObject);
typedef _CloseHandleDart = int Function(int hObject);

typedef _CreateEventW =
    IntPtr Function(
      Pointer lpAttributes,
      Int32 bManualReset,
      Int32 bInitialState,
      Pointer<Utf16> lpName,
    );
typedef _CreateEventWDart =
    int Function(
      Pointer lpAttributes,
      int bManualReset,
      int bInitialState,
      Pointer<Utf16> lpName,
    );

typedef _SetEvent = Int32 Function(IntPtr hEvent);
typedef _SetEventDart = int Function(int hEvent);

const _invalidHandle = -1;
const _pageReadWrite = 0x04;
const _fileMapReadWrite = 0x0006; // FILE_MAP_READ | FILE_MAP_WRITE
const _shmSize = 4096;

final _log = AppLogger('SHM');

class SharedMemoryService {
  static const _shmName = r'Global\ViPER4Windows_Params';
  static const _eventName = r'Global\ViPER4Windows_ParamsChanged';

  late final DynamicLibrary _kernel32;
  late final _CreateFileMappingWDart _createFileMapping;
  late final _MapViewOfFileDart _mapViewOfFile;
  late final _UnmapViewOfFileDart _unmapViewOfFile;
  late final _CloseHandleDart _closeHandle;
  late final _CreateEventWDart _createEvent;
  late final _SetEventDart _setEvent;

  int _hMap = 0;
  Pointer? _pView;
  int _hEvent = 0;
  Pointer? _pSD;

  SharedMemoryService() {
    _kernel32 = DynamicLibrary.open('kernel32.dll');
    _createFileMapping = _kernel32
        .lookupFunction<_CreateFileMappingW, _CreateFileMappingWDart>(
          'CreateFileMappingW',
        );
    _mapViewOfFile = _kernel32
        .lookupFunction<_MapViewOfFile, _MapViewOfFileDart>('MapViewOfFile');
    _unmapViewOfFile = _kernel32
        .lookupFunction<_UnmapViewOfFile, _UnmapViewOfFileDart>(
          'UnmapViewOfFile',
        );
    _closeHandle = _kernel32.lookupFunction<_CloseHandle, _CloseHandleDart>(
      'CloseHandle',
    );
    _createEvent = _kernel32.lookupFunction<_CreateEventW, _CreateEventWDart>(
      'CreateEventW',
    );
    _setEvent = _kernel32.lookupFunction<_SetEvent, _SetEventDart>('SetEvent');
  }

  void open() {
    final (sa, pSD) = buildSecurityAttributes();
    _pSD = pSD;
    final saPtr = sa != null ? sa.cast<Never>() : nullptr;

    final shmNamePtr = _shmName.toNativeUtf16();
    _hMap = _createFileMapping(
      _invalidHandle,
      saPtr,
      _pageReadWrite,
      0,
      _shmSize,
      shmNamePtr,
    );
    calloc.free(shmNamePtr);

    if (_hMap == 0) {
      _log.error('CreateFileMapping failed for $_shmName');
      freeSecurityAttributes(sa, _pSD);
      return;
    }

    _pView = _mapViewOfFile(_hMap, _fileMapReadWrite, 0, 0, _shmSize);
    if (_pView == null || _pView == nullptr) {
      _log.error('MapViewOfFile failed');
      _closeHandle(_hMap);
      _hMap = 0;
      freeSecurityAttributes(sa, _pSD);
      return;
    }

    final eventNamePtr = _eventName.toNativeUtf16();
    _hEvent = _createEvent(saPtr, 0, 0, eventNamePtr);
    calloc.free(eventNamePtr);

    freeSecurityAttributes(sa, _pSD);
    _log.info('Opened: $_shmName');
  }

  void writeParams(ByteData data) {
    if (_pView == null || _pView == nullptr) return;

    final src = data.buffer.asUint8List();
    final dst = _pView!.cast<Uint8>();
    final writeLen = SharedParamsLayout.uiWriteSize;

    for (var i = 0; i < writeLen && i < src.length; i++) {
      if (i >= SharedParamsLayout.sequenceNumber &&
          i < SharedParamsLayout.sequenceNumber + 4) {
        continue;
      }
      dst[i] = src[i];
    }
    for (
      var i = SharedParamsLayout.sequenceNumber;
      i < SharedParamsLayout.sequenceNumber + 4 && i < writeLen;
      i++
    ) {
      dst[i] = src[i];
    }

    if (_hEvent != 0) {
      _setEvent(_hEvent);
    }
  }

  ({int sampleRate, int processTimeMs, String version, String arch})
  readApoStatus() {
    if (_pView == null || _pView == nullptr) {
      return (sampleRate: 0, processTimeMs: 0, version: '', arch: '');
    }

    final bytes = _pView!.cast<Uint8>();
    final bd = ByteData(8);

    for (var i = 0; i < 4; i++) {
      bd.setUint8(i, bytes[SharedParamsLayout.apoSampleRate + i]);
    }
    final sampleRate = bd.getUint32(0, Endian.little);

    final bd2 = ByteData(8);
    for (var i = 0; i < 8; i++) {
      bd2.setUint8(i, bytes[SharedParamsLayout.apoProcessTimeMs + i]);
    }
    final processTimeMs = bd2.getUint64(0, Endian.little);

    final versionBytes = <int>[];
    for (var i = 0; i < SharedParamsLayout.apoVersionStringLen; i++) {
      final b = bytes[SharedParamsLayout.apoVersionString + i];
      if (b == 0) break;
      versionBytes.add(b);
    }
    final version = String.fromCharCodes(versionBytes);

    final archBytes = <int>[];
    for (var i = 0; i < SharedParamsLayout.apoArchStringLen; i++) {
      final b = bytes[SharedParamsLayout.apoArchString + i];
      if (b == 0) break;
      archBytes.add(b);
    }
    final arch = String.fromCharCodes(archBytes);

    return (
      sampleRate: sampleRate,
      processTimeMs: processTimeMs,
      version: version,
      arch: arch,
    );
  }

  void close() {
    if (_pView != null && _pView != nullptr) {
      _unmapViewOfFile(_pView!);
      _pView = null;
    }
    if (_hMap != 0) {
      _closeHandle(_hMap);
      _hMap = 0;
    }
    if (_hEvent != 0) {
      _closeHandle(_hEvent);
      _hEvent = 0;
    }
    _log.info('Closed');
  }
}
