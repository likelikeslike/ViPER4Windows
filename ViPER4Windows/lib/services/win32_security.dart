import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _ConvertStringSdToSdW =
    Int32 Function(
      Pointer<Utf16> sddl,
      Uint32 revision,
      Pointer<Pointer> ppSD,
      Pointer<Uint32> pSize,
    );
typedef _ConvertStringSdToSdWDart =
    int Function(
      Pointer<Utf16> sddl,
      int revision,
      Pointer<Pointer> ppSD,
      Pointer<Uint32> pSize,
    );

typedef _LocalFree = Pointer Function(Pointer hMem);
typedef _LocalFreeDart = Pointer Function(Pointer hMem);

final class SecurityAttributes extends Struct {
  @Uint32()
  external int nLength;
  external Pointer lpSecurityDescriptor;
  @Int32()
  external int bInheritHandle;
}

const securitySddl = 'D:(A;;GA;;;WD)(A;;GA;;;BA)(A;;GA;;;SY)S:(ML;;NW;;;LW)';

final _advapi32 = DynamicLibrary.open('advapi32.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _convertSddl = _advapi32
    .lookupFunction<_ConvertStringSdToSdW, _ConvertStringSdToSdWDart>(
      'ConvertStringSecurityDescriptorToSecurityDescriptorW',
    );

final _localFree = _kernel32.lookupFunction<_LocalFree, _LocalFreeDart>(
  'LocalFree',
);

(Pointer<SecurityAttributes>?, Pointer?) buildSecurityAttributes() {
  final sddlPtr = securitySddl.toNativeUtf16();
  final ppSD = calloc<Pointer>();
  final ok = _convertSddl(sddlPtr, 1, ppSD, nullptr);
  calloc.free(sddlPtr);
  if (ok == 0) {
    calloc.free(ppSD);
    return (null, null);
  }
  final pSD = ppSD.value;
  calloc.free(ppSD);

  final sa = calloc<SecurityAttributes>();
  sa.ref.nLength = sizeOf<SecurityAttributes>();
  sa.ref.lpSecurityDescriptor = pSD;
  sa.ref.bInheritHandle = 0;
  return (sa, pSD);
}

void freeSecurityAttributes(Pointer<SecurityAttributes>? sa, Pointer? pSD) {
  if (sa != null) {
    calloc.free(sa);
  }
  if (pSD != null) {
    _localFree(pSD);
  }
}
