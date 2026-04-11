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

typedef _WaitForSingleObject =
    Uint32 Function(IntPtr hHandle, Uint32 dwMilliseconds);
typedef _WaitForSingleObjectDart =
    int Function(int hHandle, int dwMilliseconds);

const _invalidHandle = -1;
const _pageReadWrite = 0x04;
const _fileMapReadWrite = 0x0006; // FILE_MAP_READ | FILE_MAP_WRITE
const _bulkShmSize = 65536;
const _headerSize = 32;

const bulkCmdDdc = 1;
const bulkCmdConvolverPrepare = 2;
const bulkCmdConvolverChunk = 3;
const bulkCmdConvolverCommit = 4;

final _log = AppLogger('BulkData');

class BulkDataService {
  static const _shmName = r'Global\ViPER4Windows_BulkData';
  static const _eventName = r'Global\ViPER4Windows_BulkDataReady';
  static const _ackEventName = r'Global\ViPER4Windows_BulkDataAck';

  late final DynamicLibrary _kernel32;
  late final _CreateFileMappingWDart _createFileMapping;
  late final _MapViewOfFileDart _mapViewOfFile;
  late final _UnmapViewOfFileDart _unmapViewOfFile;
  late final _CloseHandleDart _closeHandle;
  late final _CreateEventWDart _createEvent;
  late final _SetEventDart _setEvent;
  late final _WaitForSingleObjectDart _waitForSingleObject;

  int _hMap = 0;
  Pointer? _pView;
  int _hBulkEvent = 0;
  int _hAckEvent = 0;
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
    _waitForSingleObject = _kernel32
        .lookupFunction<_WaitForSingleObject, _WaitForSingleObjectDart>(
          'WaitForSingleObject',
        );
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

    final ackNamePtr = _ackEventName.toNativeUtf16();
    _hAckEvent = _createEvent(saPtr, 0, 0, ackNamePtr);
    calloc.free(ackNamePtr);

    freeSecurityAttributes(sa, _pSD);
    _log.info('Opened: $_shmName');
  }

  bool sendCommand(
    int command,
    int param,
    Uint8List data, {
    int arg1 = 0,
    int arg2 = 0,
    int arg3 = 0,
    int arg4 = 0,
  }) {
    if (_pView == null || _pView == nullptr) return false;
    if (data.length > _bulkShmSize - _headerSize) return false;

    final dst = _pView!.cast<Uint8>();
    final header = ByteData(_headerSize);
    header.setUint32(0, command, Endian.little);
    header.setUint32(4, param, Endian.little);
    header.setUint32(8, data.length, Endian.little);
    header.setUint32(12, arg1, Endian.little);
    header.setUint32(16, arg2, Endian.little);
    header.setUint32(20, arg3, Endian.little);
    header.setUint32(24, arg4, Endian.little);
    header.setUint32(28, 0, Endian.little);

    final headerBytes = header.buffer.asUint8List();
    for (var i = 0; i < _headerSize; i++) {
      dst[i] = headerBytes[i];
    }
    for (var i = 0; i < data.length; i++) {
      dst[_headerSize + i] = data[i];
    }

    if (_hBulkEvent != 0) _setEvent(_hBulkEvent);
    if (_hAckEvent != 0) {
      return _waitForSingleObject(_hAckEvent, 2000) == 0;
    }
    return false;
  }

  bool sendCommandNoData(
    int command, {
    int arg1 = 0,
    int arg2 = 0,
    int arg3 = 0,
    int arg4 = 0,
  }) {
    return sendCommand(
      command,
      0,
      Uint8List(0),
      arg1: arg1,
      arg2: arg2,
      arg3: arg3,
      arg4: arg4,
    );
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

    final arrSize = coeffs44100.length;
    final naturalSize = 4 + arrSize * 4 * 2;
    int wireSize;
    if (naturalSize <= 256) {
      wireSize = 256;
    } else if (naturalSize <= 1024) {
      wireSize = 1024;
    } else {
      _log.warning('DDC data too large: $naturalSize bytes');
      return;
    }

    final buffer = Uint8List(wireSize);
    final bd = ByteData.sublistView(buffer);
    bd.setUint32(0, arrSize, Endian.little);
    var offset = 4;
    for (final f in coeffs44100) {
      bd.setFloat32(offset, f, Endian.little);
      offset += 4;
    }
    for (final f in coeffs48000) {
      bd.setFloat32(offset, f, Endian.little);
      offset += 4;
    }

    sendCommand(bulkCmdDdc, 65547, buffer);
    _log.info('DDC sent: $arrSize coefficients');
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

    final totalFloats = floats.length;
    sendCommandNoData(
      bulkCmdConvolverPrepare,
      arg1: totalFloats,
      arg2: channelCount,
    );

    final floatBytes = ByteData(totalFloats * 4);
    for (var i = 0; i < totalFloats; i++) {
      floatBytes.setFloat32(i * 4, floats[i], Endian.little);
    }
    final floatByteList = floatBytes.buffer.asUint8List();
    final crcValue = _crc32(floatByteList);

    const maxFloatsPerChunk = 2046;
    var floatOffset = 0;
    var chunkIndex = 0;
    while (floatOffset < totalFloats) {
      final remaining = totalFloats - floatOffset;
      final floatsInChunk = remaining < maxFloatsPerChunk
          ? remaining
          : maxFloatsPerChunk;
      final chunkByteCount = floatsInChunk * 4;

      final chunkBuffer = Uint8List(8192);
      final cbd = ByteData.sublistView(chunkBuffer);
      cbd.setUint32(0, chunkIndex, Endian.little);
      cbd.setUint32(4, floatsInChunk, Endian.little);
      for (var i = 0; i < chunkByteCount; i++) {
        chunkBuffer[8 + i] = floatByteList[floatOffset * 4 + i];
      }

      sendCommand(bulkCmdConvolverChunk, 65541, chunkBuffer);
      floatOffset += floatsInChunk;
      chunkIndex++;
    }

    final kernelId = _stableHash(fileName) & 0x7FFFFFFF;
    sendCommandNoData(
      bulkCmdConvolverCommit,
      arg1: totalFloats,
      arg2: crcValue,
      arg3: kernelId,
    );
    _log.info(
      'Convolver sent: $fileName ($totalFloats floats, $chunkIndex chunks)',
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

  int _crc32(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xEDB88320 : 0);
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
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
    if (_hAckEvent != 0) {
      _closeHandle(_hAckEvent);
      _hAckEvent = 0;
    }
    _log.info('Closed');
  }
}
