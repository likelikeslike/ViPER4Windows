import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:viper4windows/services/file_logger.dart';

// GUIDs
final _clsidMMDeviceEnumerator = _GUID.allocate(0xBCDE0395, 0xE52F, 0x467C, [
  0x8E,
  0x3D,
  0xC4,
  0x57,
  0x92,
  0x91,
  0x69,
  0x2E,
]);
final _iidIMMDeviceEnumerator = _GUID.allocate(0xA95664D2, 0x9614, 0x4F35, [
  0xA7,
  0x46,
  0xDE,
  0x8D,
  0xB6,
  0x36,
  0x17,
  0xE6,
]);

// PKEY_AudioEndpoint_FormFactor: {1da5d803-d492-4edd-8c23-e0c0ffee7f0e} pid=0
final _pkeyFormFactorFmtId = _GUID.allocate(0x1DA5D803, 0xD492, 0x4EDD, [
  0x8C,
  0x23,
  0xE0,
  0xC0,
  0xFF,
  0xEE,
  0x7F,
  0x0E,
]);
const _pkeyFormFactorPid = 0;

// PKEY_AudioEndpoint_GUID: {1da5d803-d492-4edd-8c23-e0c0ffee7f0e} pid=4
final _pkeyEndpointGuidFmtId = _GUID.allocate(0x1DA5D803, 0xD492, 0x4EDD, [
  0x8C,
  0x23,
  0xE0,
  0xC0,
  0xFF,
  0xEE,
  0x7F,
  0x0E,
]);
const _pkeyEndpointGuidPid = 4;

// PKEY_Device_FriendlyName: {a45c254e-df1c-4efd-8020-67d146a850e0} pid=14
final _pkeyFriendlyNameFmtId = _GUID.allocate(0xA45C254E, 0xDF1C, 0x4EFD, [
  0x80,
  0x20,
  0x67,
  0xD1,
  0x46,
  0xA8,
  0x50,
  0xE0,
]);
const _pkeyFriendlyNamePid = 14;

const _vtLpwstr = 31;

const _clsctxAll = 0x17;
const _eRender = 0;
const _eConsole = 0;
const _stgmRead = 0x00000000;

// EndpointFormFactor values
const _formFactorHeadphones = 3;
const _formFactorHeadset = 5;

// COM function types
typedef _CoInitializeExNative =
    Int32 Function(Pointer pvReserved, Uint32 dwCoInit);
typedef _CoInitializeExDart = int Function(Pointer pvReserved, int dwCoInit);

typedef _CoCreateInstanceNative =
    Int32 Function(
      Pointer rclsid,
      Pointer pUnkOuter,
      Uint32 dwClsContext,
      Pointer riid,
      Pointer<Pointer> ppv,
    );
typedef _CoCreateInstanceDart =
    int Function(
      Pointer rclsid,
      Pointer pUnkOuter,
      int dwClsContext,
      Pointer riid,
      Pointer<Pointer> ppv,
    );

typedef _CoUninitializeNative = Void Function();
typedef _CoUninitializeDart = void Function();

// IUnknown vtable: QueryInterface, AddRef, Release
// IMMDeviceEnumerator vtable: [3]=EnumAudioEndpoints, [4]=GetDefaultAudioEndpoint, ...
// GetDefaultAudioEndpoint(this, dataFlow, role, ppEndpoint) -> HRESULT
typedef _GetDefaultAudioEndpointNative =
    Int32 Function(
      Pointer self,
      Int32 dataFlow,
      Int32 role,
      Pointer<Pointer> ppEndpoint,
    );
typedef _GetDefaultAudioEndpointDart =
    int Function(
      Pointer self,
      int dataFlow,
      int role,
      Pointer<Pointer> ppEndpoint,
    );

// IMMDevice vtable: [3]=Activate, [4]=OpenPropertyStore, ...
// OpenPropertyStore(this, stgmAccess, ppProperties) -> HRESULT
typedef _OpenPropertyStoreNative =
    Int32 Function(
      Pointer self,
      Uint32 stgmAccess,
      Pointer<Pointer> ppProperties,
    );
typedef _OpenPropertyStoreDart =
    int Function(Pointer self, int stgmAccess, Pointer<Pointer> ppProperties);

// IPropertyStore vtable: [3]=GetCount, [4]=GetAt, [5]=GetValue, ...
// GetValue(this, pkey, pv) -> HRESULT
typedef _GetValueNative =
    Int32 Function(Pointer self, Pointer pkey, Pointer pv);
typedef _GetValueDart = int Function(Pointer self, Pointer pkey, Pointer pv);

// PropVariantClear
typedef _PropVariantClearNative = Int32 Function(Pointer pvar);
typedef _PropVariantClearDart = int Function(Pointer pvar);

// IUnknown::Release
typedef _ReleaseNative = Uint32 Function(Pointer self);
typedef _ReleaseDart = int Function(Pointer self);

// GUID struct: 16 bytes
final class _GUID extends Struct {
  @Uint32()
  external int data1;
  @Uint16()
  external int data2;
  @Uint16()
  external int data3;
  @Uint8()
  external int data4_0;
  @Uint8()
  external int data4_1;
  @Uint8()
  external int data4_2;
  @Uint8()
  external int data4_3;
  @Uint8()
  external int data4_4;
  @Uint8()
  external int data4_5;
  @Uint8()
  external int data4_6;
  @Uint8()
  external int data4_7;

  static Pointer<_GUID> allocate(int d1, int d2, int d3, List<int> d4) {
    final p = calloc<_GUID>();
    p.ref.data1 = d1;
    p.ref.data2 = d2;
    p.ref.data3 = d3;
    p.ref.data4_0 = d4[0];
    p.ref.data4_1 = d4[1];
    p.ref.data4_2 = d4[2];
    p.ref.data4_3 = d4[3];
    p.ref.data4_4 = d4[4];
    p.ref.data4_5 = d4[5];
    p.ref.data4_6 = d4[6];
    p.ref.data4_7 = d4[7];
    return p;
  }
}

final class _PROPERTYKEY extends Struct {
  @Uint32()
  external int fmtid_data1;
  @Uint16()
  external int fmtid_data2;
  @Uint16()
  external int fmtid_data3;
  @Uint8()
  external int fmtid_data4_0;
  @Uint8()
  external int fmtid_data4_1;
  @Uint8()
  external int fmtid_data4_2;
  @Uint8()
  external int fmtid_data4_3;
  @Uint8()
  external int fmtid_data4_4;
  @Uint8()
  external int fmtid_data4_5;
  @Uint8()
  external int fmtid_data4_6;
  @Uint8()
  external int fmtid_data4_7;
  @Uint32()
  external int pid;
}

enum OutputDeviceType { headphone, speaker }

final _log = AppLogger('DeviceDetect');

class DeviceDetectionService {
  late final _CoInitializeExDart _coInitializeEx;
  late final _CoCreateInstanceDart _coCreateInstance;
  late final _CoUninitializeDart _coUninitialize;
  late final _PropVariantClearDart _propVariantClear;
  bool _comInitialized = false;

  DeviceDetectionService() {
    final ole32 = DynamicLibrary.open('ole32.dll');
    _coInitializeEx = ole32
        .lookupFunction<_CoInitializeExNative, _CoInitializeExDart>(
          'CoInitializeEx',
        );
    _coCreateInstance = ole32
        .lookupFunction<_CoCreateInstanceNative, _CoCreateInstanceDart>(
          'CoCreateInstance',
        );
    _coUninitialize = ole32
        .lookupFunction<_CoUninitializeNative, _CoUninitializeDart>(
          'CoUninitialize',
        );
    _propVariantClear = ole32
        .lookupFunction<_PropVariantClearNative, _PropVariantClearDart>(
          'PropVariantClear',
        );
  }

  ({String id, String name, bool isHeadphone}) detectActiveDevice() {
    const fallback = (id: '', name: '', isHeadphone: false);
    try {
      return _detectActiveDeviceImpl();
    } catch (e) {
      _log.error('detectActiveDevice failed: $e');
      return fallback;
    }
  }

  ({String id, String name, bool isHeadphone}) _detectActiveDeviceImpl() {
    const fallback = (id: '', name: '', isHeadphone: false);
    if (!_ensureCom()) return fallback;

    final ppEnumerator = calloc<Pointer>();
    var hr = _coCreateInstance(
      _clsidMMDeviceEnumerator,
      nullptr,
      _clsctxAll,
      _iidIMMDeviceEnumerator,
      ppEnumerator,
    );
    if (hr < 0) {
      calloc.free(ppEnumerator);
      return fallback;
    }

    final pEnumerator = ppEnumerator.value;
    calloc.free(ppEnumerator);

    final ppDevice = calloc<Pointer>();
    final vtable = pEnumerator.cast<Pointer<Pointer>>().value;
    final getDefaultEndpoint = vtable[4]
        .cast<NativeFunction<_GetDefaultAudioEndpointNative>>()
        .asFunction<_GetDefaultAudioEndpointDart>();

    hr = getDefaultEndpoint(pEnumerator, _eRender, _eConsole, ppDevice);
    _release(pEnumerator);
    if (hr < 0) {
      calloc.free(ppDevice);
      return fallback;
    }

    final pDevice = ppDevice.value;
    calloc.free(ppDevice);

    final ppPropertyStore = calloc<Pointer>();
    final devVtable = pDevice.cast<Pointer<Pointer>>().value;
    final openPropertyStore = devVtable[4]
        .cast<NativeFunction<_OpenPropertyStoreNative>>()
        .asFunction<_OpenPropertyStoreDart>();

    hr = openPropertyStore(pDevice, _stgmRead, ppPropertyStore);
    _release(pDevice);
    if (hr < 0) {
      calloc.free(ppPropertyStore);
      return fallback;
    }

    final pPropertyStore = ppPropertyStore.value;
    calloc.free(ppPropertyStore);

    final formFactor = _readFormFactorProperty(pPropertyStore);
    final guid = _readStringProperty(
      pPropertyStore,
      _pkeyEndpointGuidFmtId,
      _pkeyEndpointGuidPid,
    );
    final name = _readStringProperty(
      pPropertyStore,
      _pkeyFriendlyNameFmtId,
      _pkeyFriendlyNamePid,
    );
    _release(pPropertyStore);

    final isHp =
        formFactor == _formFactorHeadphones || formFactor == _formFactorHeadset;
    return (id: guid, name: name, isHeadphone: isHp);
  }

  bool _ensureCom() {
    if (!_comInitialized) {
      final hr = _coInitializeEx(nullptr, 0x2);
      if (hr < 0 && hr != -2147417850) {
        _log.warning('COM init failed: 0x${hr.toRadixString(16)}');
        return false;
      }
      _comInitialized = true;
    }
    return true;
  }

  String _readStringProperty(
    Pointer pPropertyStore,
    Pointer<_GUID> fmtId,
    int pid,
  ) {
    final pkey = calloc<_PROPERTYKEY>();
    pkey.ref.fmtid_data1 = fmtId.ref.data1;
    pkey.ref.fmtid_data2 = fmtId.ref.data2;
    pkey.ref.fmtid_data3 = fmtId.ref.data3;
    pkey.ref.fmtid_data4_0 = fmtId.ref.data4_0;
    pkey.ref.fmtid_data4_1 = fmtId.ref.data4_1;
    pkey.ref.fmtid_data4_2 = fmtId.ref.data4_2;
    pkey.ref.fmtid_data4_3 = fmtId.ref.data4_3;
    pkey.ref.fmtid_data4_4 = fmtId.ref.data4_4;
    pkey.ref.fmtid_data4_5 = fmtId.ref.data4_5;
    pkey.ref.fmtid_data4_6 = fmtId.ref.data4_6;
    pkey.ref.fmtid_data4_7 = fmtId.ref.data4_7;
    pkey.ref.pid = pid;

    final propVariant = calloc<Uint8>(24);
    final vtable = pPropertyStore.cast<Pointer<Pointer>>().value;
    final getValue = vtable[5]
        .cast<NativeFunction<_GetValueNative>>()
        .asFunction<_GetValueDart>();

    final hr = getValue(pPropertyStore, pkey.cast(), propVariant.cast());
    calloc.free(pkey);

    if (hr < 0) {
      calloc.free(propVariant);
      return '';
    }

    final vt = propVariant.cast<Uint16>().value;
    String result = '';
    if (vt == _vtLpwstr) {
      final pStr = Pointer<Pointer<Utf16>>.fromAddress(
        propVariant.address + 8,
      ).value;
      if (pStr != nullptr) {
        result = pStr.toDartString();
      }
    }

    _propVariantClear(propVariant.cast());
    calloc.free(propVariant);
    return result;
  }

  OutputDeviceType detectOutputType() {
    if (!_ensureCom()) return OutputDeviceType.speaker;

    final ppEnumerator = calloc<Pointer>();
    var hr = _coCreateInstance(
      _clsidMMDeviceEnumerator,
      nullptr,
      _clsctxAll,
      _iidIMMDeviceEnumerator,
      ppEnumerator,
    );
    if (hr < 0) {
      calloc.free(ppEnumerator);
      return OutputDeviceType.speaker;
    }

    final pEnumerator = ppEnumerator.value;
    calloc.free(ppEnumerator);

    final formFactor = _getDefaultEndpointFormFactor(pEnumerator);
    _release(pEnumerator);

    if (formFactor == _formFactorHeadphones ||
        formFactor == _formFactorHeadset) {
      return OutputDeviceType.headphone;
    }
    return OutputDeviceType.speaker;
  }

  int _getDefaultEndpointFormFactor(Pointer pEnumerator) {
    final ppDevice = calloc<Pointer>();

    // vtable[4] = GetDefaultAudioEndpoint
    final vtable = pEnumerator.cast<Pointer<Pointer>>().value;
    final getDefaultEndpoint = vtable[4]
        .cast<NativeFunction<_GetDefaultAudioEndpointNative>>()
        .asFunction<_GetDefaultAudioEndpointDart>();

    final hr = getDefaultEndpoint(pEnumerator, _eRender, _eConsole, ppDevice);
    if (hr < 0) {
      calloc.free(ppDevice);
      return -1;
    }

    final pDevice = ppDevice.value;
    calloc.free(ppDevice);

    final result = _getFormFactor(pDevice);
    _release(pDevice);
    return result;
  }

  int _getFormFactor(Pointer pDevice) {
    final ppPropertyStore = calloc<Pointer>();

    // IMMDevice vtable[4] = OpenPropertyStore
    final vtable = pDevice.cast<Pointer<Pointer>>().value;
    final openPropertyStore = vtable[4]
        .cast<NativeFunction<_OpenPropertyStoreNative>>()
        .asFunction<_OpenPropertyStoreDart>();

    final hr = openPropertyStore(pDevice, _stgmRead, ppPropertyStore);
    if (hr < 0) {
      calloc.free(ppPropertyStore);
      return -1;
    }

    final pPropertyStore = ppPropertyStore.value;
    calloc.free(ppPropertyStore);

    final result = _readFormFactorProperty(pPropertyStore);
    _release(pPropertyStore);
    return result;
  }

  int _readFormFactorProperty(Pointer pPropertyStore) {
    final pkey = calloc<_PROPERTYKEY>();
    pkey.ref.fmtid_data1 = _pkeyFormFactorFmtId.ref.data1;
    pkey.ref.fmtid_data2 = _pkeyFormFactorFmtId.ref.data2;
    pkey.ref.fmtid_data3 = _pkeyFormFactorFmtId.ref.data3;
    pkey.ref.fmtid_data4_0 = _pkeyFormFactorFmtId.ref.data4_0;
    pkey.ref.fmtid_data4_1 = _pkeyFormFactorFmtId.ref.data4_1;
    pkey.ref.fmtid_data4_2 = _pkeyFormFactorFmtId.ref.data4_2;
    pkey.ref.fmtid_data4_3 = _pkeyFormFactorFmtId.ref.data4_3;
    pkey.ref.fmtid_data4_4 = _pkeyFormFactorFmtId.ref.data4_4;
    pkey.ref.fmtid_data4_5 = _pkeyFormFactorFmtId.ref.data4_5;
    pkey.ref.fmtid_data4_6 = _pkeyFormFactorFmtId.ref.data4_6;
    pkey.ref.fmtid_data4_7 = _pkeyFormFactorFmtId.ref.data4_7;
    pkey.ref.pid = _pkeyFormFactorPid;

    // PROPVARIANT is 24 bytes on x64 (16-byte vt + 8-byte pad/data)
    final propVariant = calloc<Uint8>(24);

    // IPropertyStore vtable[5] = GetValue
    final vtable = pPropertyStore.cast<Pointer<Pointer>>().value;
    final getValue = vtable[5]
        .cast<NativeFunction<_GetValueNative>>()
        .asFunction<_GetValueDart>();

    final hr = getValue(pPropertyStore, pkey.cast(), propVariant.cast());
    calloc.free(pkey);

    if (hr < 0) {
      calloc.free(propVariant);
      return -1;
    }

    final bd = propVariant.cast<Uint32>();
    final formFactor = bd[2];

    _propVariantClear(propVariant.cast());
    calloc.free(propVariant);

    return formFactor;
  }

  void _release(Pointer pUnknown) {
    final vtable = pUnknown.cast<Pointer<Pointer>>().value;
    final release = vtable[2]
        .cast<NativeFunction<_ReleaseNative>>()
        .asFunction<_ReleaseDart>();
    release(pUnknown);
  }

  void dispose() {
    if (_comInitialized) {
      _coUninitialize();
      _comInitialized = false;
    }
    calloc.free(_clsidMMDeviceEnumerator);
    calloc.free(_iidIMMDeviceEnumerator);
    calloc.free(_pkeyFormFactorFmtId);
    calloc.free(_pkeyEndpointGuidFmtId);
    calloc.free(_pkeyFriendlyNameFmtId);
  }
}
