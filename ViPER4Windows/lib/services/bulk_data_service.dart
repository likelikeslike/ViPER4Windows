import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
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
const _bulkShmSize = 4 * 1024 * 1024;
const _headerSize = 32;

const _bulkDdcBase = 0;
const _bulkDdcRegionSize = 2 * 1024 * 1024;
const _bulkConvolverBase = _bulkDdcRegionSize;
const _bulkConvolverRegionSize = 2 * 1024 * 1024;

const _bulkSeqOffset = 8;

const _v4wMagic = 0x534D3456;
const _v4wFormatVersion = 2;

const _bulkCmdDdc = 1;
const _bulkCmdConvolverKernel = 2;

final _log = AppLogger('BulkData');

class BulkDataService {
  static const _shmName = r'Global\ViPER4Windows_BulkData';
  static const _eventName = r'Global\ViPER4Windows_BulkDataReady';

  late final DynamicLibrary _kernel32;
  late final _CreateFileMappingWDart _createFileMapping;
  late final _MapViewOfFileDart _mapViewOfFile;
  late final _UnmapViewOfFileDart _unmapViewOfFile;
  late final _CloseHandleDart _closeHandle;
  late final _CreateEventWDart _createEvent;
  late final _SetEventDart _setEvent;

  int _hMap = 0;
  Pointer? _pView;
  int _hBulkEvent = 0;
  int _ddcSeq = 0;
  int _convolverSeq = 0;
  Pointer? _pSD;

  BulkDataService() {
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
      _bulkShmSize,
      shmNamePtr,
    );
    calloc.free(shmNamePtr);

    if (_hMap == 0) {
      _log.error('CreateFileMapping failed for $_shmName');
      freeSecurityAttributes(sa, _pSD);
      return;
    }

    _pView = _mapViewOfFile(_hMap, _fileMapReadWrite, 0, 0, _bulkShmSize);
    if (_pView == null || _pView == nullptr) {
      _log.error('MapViewOfFile failed');
      _closeHandle(_hMap);
      _hMap = 0;
      freeSecurityAttributes(sa, _pSD);
      return;
    }

    final eventNamePtr = _eventName.toNativeUtf16();
    _hBulkEvent = _createEvent(saPtr, 0, 0, eventNamePtr);
    calloc.free(eventNamePtr);

    freeSecurityAttributes(sa, _pSD);
    _log.info('Opened: $_shmName (${_bulkShmSize ~/ (1024 * 1024)} MB)');
  }

  bool _sendBulk(
    int base,
    int regionSize,
    int nextSeq,
    int command,
    Uint8List payload, {
    int arg1 = 0,
    int arg2 = 0,
    int arg3 = 0,
  }) {
    if (_pView == null || _pView == nullptr) return false;
    final maxPayload = regionSize - _headerSize;
    if (payload.length > maxPayload) {
      _log.warning('payload ${payload.length} > max $maxPayload');
      return false;
    }

    final dst = _pView!.cast<Uint8>();
    final header = ByteData(_headerSize);
    header.setUint32(0, _v4wMagic, Endian.little);
    header.setUint32(4, _v4wFormatVersion, Endian.little);
    header.setUint32(12, command, Endian.little);
    header.setUint32(16, payload.length, Endian.little);
    header.setUint32(20, arg1, Endian.little);
    header.setUint32(24, arg2, Endian.little);
    header.setUint32(28, arg3, Endian.little);

    final headerBytes = header.buffer.asUint8List();
    for (var i = 0; i < _headerSize; i++) {
      dst[base + i] = headerBytes[i];
    }
    for (var i = 0; i < payload.length; i++) {
      dst[base + _headerSize + i] = payload[i];
    }

    final seqBytes = ByteData(4)..setUint32(0, nextSeq, Endian.little);
    final seqList = seqBytes.buffer.asUint8List();
    for (var i = 0; i < 4; i++) {
      dst[base + _bulkSeqOffset + i] = seqList[i];
    }

    if (_hBulkEvent != 0) _setEvent(_hBulkEvent);
    return true;
  }

  void loadDdcFile(Uint8List fileContent) {
    final lines = String.fromCharCodes(fileContent).split('\n');
    List<double>? coeffs44100;
    List<double>? coeffs48000;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.startsWith('SR_44100:')) {
        coeffs44100 = _parseFloatList(line.substring('SR_44100:'.length));
      } else if (line.startsWith('SR_48000:')) {
        coeffs48000 = _parseFloatList(line.substring('SR_48000:'.length));
      }
    }

    if (coeffs44100 == null || coeffs48000 == null) {
      _log.warning('DDC parse failed: missing SR coefficients');
      return;
    }
    if (coeffs44100.length != coeffs48000.length) {
      _log.warning('DDC parse failed: coefficient count mismatch');
      return;
    }
    if (coeffs44100.isEmpty || coeffs44100.length % 5 != 0) {
      _log.warning(
        'DDC parse failed: invalid coefficient count ${coeffs44100.length}',
      );
      return;
    }

    final sectionCount = coeffs44100.length ~/ 5;
    final byteCount = sectionCount * 5 * 4 * 2;
    final payload = Uint8List(byteCount);
    final pd = ByteData.sublistView(payload);

    var offset = 0;
    for (final f in coeffs44100) {
      pd.setFloat32(offset, f, Endian.little);
      offset += 4;
    }
    for (final f in coeffs48000) {
      pd.setFloat32(offset, f, Endian.little);
      offset += 4;
    }

    final ok = _sendBulk(
      _bulkDdcBase,
      _bulkDdcRegionSize,
      ++_ddcSeq,
      _bulkCmdDdc,
      payload,
      arg1: sectionCount,
    );
    _log.info('DDC sent: $sectionCount sections (${ok ? "ok" : "failed"})');
  }

  void unloadConvolverKernel() {
    final ok = _sendBulk(
      _bulkConvolverBase,
      _bulkConvolverRegionSize,
      ++_convolverSeq,
      _bulkCmdConvolverKernel,
      Uint8List(0),
    );
    _log.info('Convolver unloaded (${ok ? "ok" : "failed"})');
  }

  void clearDdc() {
    final ok = _sendBulk(
      _bulkDdcBase,
      _bulkDdcRegionSize,
      ++_ddcSeq,
      _bulkCmdDdc,
      Uint8List(0),
      arg1: 0,
    );
    _log.info('DDC cleared (${ok ? "ok" : "failed"})');
  }

  void loadConvolverKernel(Uint8List wavData, String fileName) {
    final result = _decodeWavToFloat(wavData);
    if (result == null) {
      _log.warning('Convolver WAV decode failed: $fileName');
      return;
    }
    final (floats, channelCount) = result;
    if (floats.isEmpty) {
      _log.warning('Convolver empty WAV: $fileName');
      return;
    }
    if (channelCount < 1 || channelCount > 2) {
      _log.warning('Convolver unsupported channel count: $channelCount');
      return;
    }

    final frameCount = floats.length ~/ channelCount;
    final payloadBytes = frameCount * channelCount * 4;
    const maxPayload = _bulkConvolverRegionSize - _headerSize;
    if (payloadBytes > maxPayload) {
      _log.warning(
        'Convolver kernel too large: $payloadBytes bytes > $maxPayload',
      );
      return;
    }

    final payload = Uint8List(payloadBytes);
    final pd = ByteData.sublistView(payload);
    for (var i = 0; i < floats.length; i++) {
      pd.setFloat32(i * 4, floats[i], Endian.little);
    }

    final kernelId = _stableHash(fileName) & 0x7FFFFFFF;
    final ok = _sendBulk(
      _bulkConvolverBase,
      _bulkConvolverRegionSize,
      ++_convolverSeq,
      _bulkCmdConvolverKernel,
      payload,
      arg1: frameCount,
      arg2: channelCount,
      arg3: kernelId,
    );
    _log.info(
      'Convolver sent: $fileName (frames=$frameCount ch=$channelCount '
      'id=$kernelId ${ok ? "ok" : "failed"})',
    );
  }

  List<double>? _parseFloatList(String str) {
    final parts = str.split(',').where((s) => s.trim().isNotEmpty).toList();
    final result = <double>[];
    for (final part in parts) {
      final v = double.tryParse(part.trim());
      if (v == null) return null;
      result.add(v);
    }
    return result;
  }

  (List<double>, int)? _decodeWavToFloat(Uint8List wav) {
    if (wav.length < 44) return null;
    if (wav[0] != 0x52 || wav[1] != 0x49 || wav[2] != 0x46 || wav[3] != 0x46) {
      return null;
    }

    final bd = ByteData.sublistView(wav);
    final channelCount = bd.getInt16(22, Endian.little);
    final bitsPerSample = bd.getInt16(34, Endian.little);

    var dataOffset = 12;
    while (dataOffset + 8 <= wav.length) {
      final chunkId = String.fromCharCodes(
        wav.sublist(dataOffset, dataOffset + 4),
      );
      final chunkSize = bd.getInt32(dataOffset + 4, Endian.little);
      if (chunkId == 'data') {
        dataOffset += 8;
        final sampleCount = chunkSize ~/ (bitsPerSample ~/ 8);
        final result = List<double>.filled(sampleCount, 0.0);
        if (bitsPerSample == 16) {
          for (
            var i = 0;
            i < sampleCount && dataOffset + 2 <= wav.length;
            i++
          ) {
            final s = bd.getInt16(dataOffset, Endian.little);
            result[i] = s / 32768.0;
            dataOffset += 2;
          }
        } else if (bitsPerSample == 24) {
          for (
            var i = 0;
            i < sampleCount && dataOffset + 3 <= wav.length;
            i++
          ) {
            var val =
                wav[dataOffset] |
                (wav[dataOffset + 1] << 8) |
                (wav[dataOffset + 2] << 16);
            if ((val & 0x800000) != 0) val |= 0xFF000000;
            result[i] = val.toSigned(32) / 8388608.0;
            dataOffset += 3;
          }
        } else if (bitsPerSample == 32) {
          for (
            var i = 0;
            i < sampleCount && dataOffset + 4 <= wav.length;
            i++
          ) {
            result[i] = bd.getFloat32(dataOffset, Endian.little);
            dataOffset += 4;
          }
        }
        return (result, channelCount);
      }
      dataOffset += 8 + chunkSize;
      if (chunkSize % 2 != 0) dataOffset++;
    }
    return null;
  }

  int _stableHash(String str) {
    var hash = 2166136261;
    for (var i = 0; i < str.length; i++) {
      hash ^= str.codeUnitAt(i);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash;
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
    if (_hBulkEvent != 0) {
      _closeHandle(_hBulkEvent);
      _hBulkEvent = 0;
    }
    _log.info('Closed');
  }
}
