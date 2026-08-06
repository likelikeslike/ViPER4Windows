import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:viper4windows/services/file_logger.dart';
import 'package:viper4windows/services/win32_security.dart';

const pipeName = r'\\.\pipe\ViPER4Windows_Control';

const _pipeAccessDuplex = 0x00000003;
const _pipeTypeByte = 0x00000000;
const _pipeReadModeByte = 0x00000000;
const _pipeWait = 0x00000000;
const _pipeUnlimitedInstances = 255;
const _pipeBufferSize = 65536;
const _invalidHandleValue = -1;
const _errorPipeConnected = 535;

typedef _CreateNamedPipeW =
    IntPtr Function(
      Pointer<Utf16> lpName,
      Uint32 dwOpenMode,
      Uint32 dwPipeMode,
      Uint32 nMaxInstances,
      Uint32 nOutBufferSize,
      Uint32 nInBufferSize,
      Uint32 nDefaultTimeOut,
      Pointer lpSecurityAttributes,
    );
typedef _CreateNamedPipeWDart =
    int Function(
      Pointer<Utf16> lpName,
      int dwOpenMode,
      int dwPipeMode,
      int nMaxInstances,
      int nOutBufferSize,
      int nInBufferSize,
      int nDefaultTimeOut,
      Pointer lpSecurityAttributes,
    );

typedef _ConnectNamedPipe =
    Int32 Function(IntPtr hNamedPipe, Pointer lpOverlapped);
typedef _ConnectNamedPipeDart =
    int Function(int hNamedPipe, Pointer lpOverlapped);

typedef _ReadFile =
    Int32 Function(
      IntPtr hFile,
      Pointer<Uint8> lpBuffer,
      Uint32 nNumberOfBytesToRead,
      Pointer<Uint32> lpNumberOfBytesRead,
      Pointer lpOverlapped,
    );
typedef _ReadFileDart =
    int Function(
      int hFile,
      Pointer<Uint8> lpBuffer,
      int nNumberOfBytesToRead,
      Pointer<Uint32> lpNumberOfBytesRead,
      Pointer lpOverlapped,
    );

typedef _WriteFile =
    Int32 Function(
      IntPtr hFile,
      Pointer<Uint8> lpBuffer,
      Uint32 nNumberOfBytesToWrite,
      Pointer<Uint32> lpNumberOfBytesWritten,
      Pointer lpOverlapped,
    );
typedef _WriteFileDart =
    int Function(
      int hFile,
      Pointer<Uint8> lpBuffer,
      int nNumberOfBytesToWrite,
      Pointer<Uint32> lpNumberOfBytesWritten,
      Pointer lpOverlapped,
    );

typedef _FlushDisconnectClose = Int32 Function(IntPtr hObject);
typedef _FlushDisconnectCloseDart = int Function(int hObject);

typedef _GetLastError = Uint32 Function();
typedef _GetLastErrorDart = int Function();

final _log = AppLogger('ControlPipe');

class PipeRequest {
  final String line;
  final SendPort reply;
  PipeRequest(this.line, this.reply);
}

class ControlPipeServer {
  final List<String> Function(List<String> tokens) _handler;
  Isolate? _isolate;
  ReceivePort? _fromIsolate;

  ControlPipeServer(this._handler);

  Future<void> start() async {
    final fromIsolate = ReceivePort();
    _fromIsolate = fromIsolate;
    fromIsolate.listen((msg) {
      if (msg is PipeRequest) {
        final tokens = _tokenize(msg.line);
        List<String> reply;
        try {
          reply = _handler(tokens);
        } catch (e) {
          reply = ['ERR internal error: $e'];
        }
        msg.reply.send(reply);
      }
    });
    _isolate = await Isolate.spawn(_serverLoop, fromIsolate.sendPort);
    _log.info('Control pipe server started on $pipeName');
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _fromIsolate?.close();
    _fromIsolate = null;
  }

  static List<String> _tokenize(String line) =>
      line.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
}

Future<void> _serverLoop(SendPort toMain) async {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final createPipe = kernel32
      .lookupFunction<_CreateNamedPipeW, _CreateNamedPipeWDart>(
        'CreateNamedPipeW',
      );
  final connectPipe = kernel32
      .lookupFunction<_ConnectNamedPipe, _ConnectNamedPipeDart>(
        'ConnectNamedPipe',
      );
  final readFile = kernel32.lookupFunction<_ReadFile, _ReadFileDart>(
    'ReadFile',
  );
  final writeFile = kernel32.lookupFunction<_WriteFile, _WriteFileDart>(
    'WriteFile',
  );
  final flushBuffers = kernel32
      .lookupFunction<_FlushDisconnectClose, _FlushDisconnectCloseDart>(
        'FlushFileBuffers',
      );
  final disconnect = kernel32
      .lookupFunction<_FlushDisconnectClose, _FlushDisconnectCloseDart>(
        'DisconnectNamedPipe',
      );
  final closeHandle = kernel32
      .lookupFunction<_FlushDisconnectClose, _FlushDisconnectCloseDart>(
        'CloseHandle',
      );
  final getLastError = kernel32
      .lookupFunction<_GetLastError, _GetLastErrorDart>('GetLastError');

  final namePtr = pipeName.toNativeUtf16();

  while (true) {
    final (sa, pSD) = buildSecurityAttributes();
    final handle = createPipe(
      namePtr,
      _pipeAccessDuplex,
      _pipeTypeByte | _pipeReadModeByte | _pipeWait,
      _pipeUnlimitedInstances,
      _pipeBufferSize,
      _pipeBufferSize,
      0,
      sa == null ? nullptr : sa.cast(),
    );
    freeSecurityAttributes(sa, pSD);

    if (handle == _invalidHandleValue) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      continue;
    }

    final connected = connectPipe(handle, nullptr);
    if (connected == 0 && getLastError() != _errorPipeConnected) {
      disconnect(handle);
      closeHandle(handle);
      continue;
    }

    await _serveClient(
      handle,
      toMain: toMain,
      readFile: readFile,
      writeFile: writeFile,
      flushBuffers: flushBuffers,
    );

    disconnect(handle);
    closeHandle(handle);
  }
}

Future<void> _serveClient(
  int handle, {
  required SendPort toMain,
  required _ReadFileDart readFile,
  required _WriteFileDart writeFile,
  required _FlushDisconnectCloseDart flushBuffers,
}) async {
  final request = _readLine(handle, readFile);
  if (request == null) return;

  final replyPort = ReceivePort();
  toMain.send(PipeRequest(request, replyPort.sendPort));
  final msg = await replyPort.first;
  replyPort.close();

  final reply = msg is List
      ? msg.cast<String>()
      : const ['ERR malformed reply'];
  final payload = '${reply.join('\n')}\n.\n';
  _writeAll(handle, writeFile, payload);
  flushBuffers(handle);
}

String? _readLine(int handle, _ReadFileDart readFile) {
  final buf = calloc<Uint8>(_pipeBufferSize);
  final read = calloc<Uint32>();
  final sb = StringBuffer();
  try {
    while (true) {
      final ok = readFile(handle, buf, _pipeBufferSize, read, nullptr);
      final n = read.value;
      if (ok == 0 || n == 0) break;
      final chunk = utf8.decode(buf.asTypedList(n), allowMalformed: true);
      sb.write(chunk);
      if (chunk.contains('\n')) break;
    }
  } finally {
    calloc.free(buf);
    calloc.free(read);
  }
  final s = sb.toString();
  if (s.isEmpty) return null;
  final nl = s.indexOf('\n');
  return nl >= 0 ? s.substring(0, nl) : s;
}

void _writeAll(int handle, _WriteFileDart writeFile, String data) {
  final bytes = utf8.encode(data);
  final buf = calloc<Uint8>(bytes.length);
  final written = calloc<Uint32>();
  try {
    buf.asTypedList(bytes.length).setAll(0, bytes);
    var offset = 0;
    while (offset < bytes.length) {
      final ok = writeFile(
        handle,
        (buf + offset),
        bytes.length - offset,
        written,
        nullptr,
      );
      if (ok == 0 || written.value == 0) break;
      offset += written.value;
    }
  } finally {
    calloc.free(buf);
    calloc.free(written);
  }
}
