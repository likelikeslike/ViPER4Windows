import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:viper4windows/models/viper_params_layout.dart';
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
const _fileMapReadWrite = 0x0006;

const _paramsShmName = r'Global\ViPER4Windows_Params';
const _paramsShmSize = 4096;

const _statusShmName = r'Global\ViPER4Windows_Status';
const _statusShmSize = 256;

const _eventName = r'Global\ViPER4Windows_ParamsChanged';

const _v4wMagic = 0x534D3456;
const _v4wFormatVersion = 2;

const _hdrMagic = 0;
const _hdrVersion = 4;
const _hdrActiveIndex = 8;
const _hdrUpdateCount = 12;
const _hdrMasterEnabled = 16;
const _hdrSize = 24;

const _slotAOffset = _hdrSize;
final _slotBOffset = _hdrSize + ViperParamsLayout.SIZE;

const _statusMagic = 0;
const _statusSampleRate = 20;
const _statusProcessedFrames = 24;
const _statusVersionName = 32;
const _statusVersionNameLen = 32;
const _statusArchString = 64;
const _statusArchStringLen = 16;

final _log = AppLogger('SHM');

class SharedMemoryService {
  late final DynamicLibrary _kernel32;
  late final _CreateFileMappingWDart _createFileMapping;
  late final _MapViewOfFileDart _mapViewOfFile;
  late final _UnmapViewOfFileDart _unmapViewOfFile;
  late final _CloseHandleDart _closeHandle;
  late final _CreateEventWDart _createEvent;
  late final _SetEventDart _setEvent;

  int _hParamsMap = 0;
  Pointer? _pParamsView;
  int _hStatusMap = 0;
  Pointer? _pStatusView;
  int _hEvent = 0;
  Pointer? _pSD;

  int _producerActiveSlot = 1;
  int _updateCount = 0;

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

    final paramsName = _paramsShmName.toNativeUtf16();
    _hParamsMap = _createFileMapping(
      _invalidHandle, saPtr, _pageReadWrite, 0, _paramsShmSize, paramsName,
    );
    calloc.free(paramsName);
    if (_hParamsMap == 0) {
      _log.error('CreateFileMapping failed for $_paramsShmName');
      freeSecurityAttributes(sa, _pSD);
      return;
    }
    _pParamsView = _mapViewOfFile(
      _hParamsMap, _fileMapReadWrite, 0, 0, _paramsShmSize,
    );
    if (_pParamsView == null || _pParamsView == nullptr) {
      _log.error('MapViewOfFile failed for params shm');
      _closeHandle(_hParamsMap);
      _hParamsMap = 0;
      freeSecurityAttributes(sa, _pSD);
      return;
    }
    _initParamsHeader();

    final statusName = _statusShmName.toNativeUtf16();
    _hStatusMap = _createFileMapping(
      _invalidHandle, saPtr, _pageReadWrite, 0, _statusShmSize, statusName,
    );
    calloc.free(statusName);
    if (_hStatusMap != 0) {
      _pStatusView = _mapViewOfFile(
        _hStatusMap, _fileMapReadWrite, 0, 0, _statusShmSize,
      );
    }

    final eventNamePtr = _eventName.toNativeUtf16();
    _hEvent = _createEvent(saPtr, 0, 0, eventNamePtr);
    calloc.free(eventNamePtr);

    freeSecurityAttributes(sa, _pSD);
    _log.info('Opened: $_paramsShmName + $_statusShmName');
  }

  void _initParamsHeader() {
    if (_pParamsView == null || _pParamsView == nullptr) return;
    final bytes = _pParamsView!.cast<Uint8>();
    final bd = ByteData(_hdrSize);
    bd.setUint32(_hdrMagic, _v4wMagic, Endian.little);
    bd.setUint32(_hdrVersion, _v4wFormatVersion, Endian.little);
    bd.setUint32(_hdrActiveIndex, 0, Endian.little);
    bd.setUint32(_hdrUpdateCount, 0, Endian.little);
    bd.setUint32(_hdrMasterEnabled, 0, Endian.little);
    final src = bd.buffer.asUint8List();
    for (var i = 0; i < _hdrSize; i++) {
      bytes[i] = src[i];
    }
  }

  void writeParams(ByteData params, {required bool masterEnabled}) {
    if (_pParamsView == null || _pParamsView == nullptr) return;
    if (params.lengthInBytes != ViperParamsLayout.SIZE) {
      _log.error(
        'writeParams: payload size ${params.lengthInBytes} != ${ViperParamsLayout.SIZE}',
      );
      return;
    }
    final bytes = _pParamsView!.cast<Uint8>();
    final src = params.buffer.asUint8List();

    final nextSlot = 1 - _producerActiveSlot;
    final slotOffset = nextSlot == 0 ? _slotAOffset : _slotBOffset;
    for (var i = 0; i < ViperParamsLayout.SIZE; i++) {
      bytes[slotOffset + i] = src[i];
    }

    final hdrBd = ByteData(4);
    hdrBd.setUint32(0, masterEnabled ? 1 : 0, Endian.little);
    final hdrSrc = hdrBd.buffer.asUint8List();
    for (var i = 0; i < 4; i++) {
      bytes[_hdrMasterEnabled + i] = hdrSrc[i];
    }

    final base = _pParamsView!.address;
    Pointer<Int32>.fromAddress(base + _hdrActiveIndex).value = nextSlot;
    _producerActiveSlot = nextSlot;

    _updateCount++;
    Pointer<Int32>.fromAddress(base + _hdrUpdateCount).value = _updateCount;

    if (_hEvent != 0) {
      _setEvent(_hEvent);
    }
  }

  ({int sampleRate, int processedFrames, String version, String arch})
  readApoStatus() {
    if (_pStatusView == null || _pStatusView == nullptr) {
      return (sampleRate: 0, processedFrames: 0, version: '', arch: '');
    }

    final bytes = _pStatusView!.cast<Uint8>();
    final magic = _readUint32(bytes, _statusMagic);
    if (magic != _v4wMagic) {
      return (sampleRate: 0, processedFrames: 0, version: '', arch: '');
    }
    final sampleRate = _readUint32(bytes, _statusSampleRate);
    final processedFrames = _readUint64(bytes, _statusProcessedFrames);
    final version = _readNullTerminatedString(
      bytes, _statusVersionName, _statusVersionNameLen,
    );
    final arch = _readNullTerminatedString(
      bytes, _statusArchString, _statusArchStringLen,
    );
    return (
      sampleRate: sampleRate,
      processedFrames: processedFrames,
      version: version,
      arch: arch,
    );
  }

  static int _readUint32(Pointer<Uint8> bytes, int offset) {
    final bd = ByteData(4);
    for (var i = 0; i < 4; i++) {
      bd.setUint8(i, bytes[offset + i]);
    }
    return bd.getUint32(0, Endian.little);
  }

  static int _readUint64(Pointer<Uint8> bytes, int offset) {
    final bd = ByteData(8);
    for (var i = 0; i < 8; i++) {
      bd.setUint8(i, bytes[offset + i]);
    }
    return bd.getUint64(0, Endian.little);
  }

  static String _readNullTerminatedString(
    Pointer<Uint8> bytes, int offset, int maxLen) {
    final out = <int>[];
    for (var i = 0; i < maxLen; i++) {
      final b = bytes[offset + i];
      if (b == 0) break;
      out.add(b);
    }
    return String.fromCharCodes(out);
  }

  void close() {
    if (_pParamsView != null && _pParamsView != nullptr) {
      _unmapViewOfFile(_pParamsView!);
      _pParamsView = null;
    }
    if (_hParamsMap != 0) {
      _closeHandle(_hParamsMap);
      _hParamsMap = 0;
    }
    if (_pStatusView != null && _pStatusView != nullptr) {
      _unmapViewOfFile(_pStatusView!);
      _pStatusView = null;
    }
    if (_hStatusMap != 0) {
      _closeHandle(_hStatusMap);
      _hStatusMap = 0;
    }
    if (_hEvent != 0) {
      _closeHandle(_hEvent);
      _hEvent = 0;
    }
    _log.info('Closed');
  }
}
