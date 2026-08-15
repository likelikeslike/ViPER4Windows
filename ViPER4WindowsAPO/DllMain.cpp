#include <atlbase.h>
#include <atlcom.h>
#include <audioenginebaseapo.h>
#include <initguid.h>

#include "ViPER4WindowsAPO.h"
#include "ViPERLog.h"

class CViPER4WindowsModule : public CAtlDllModuleT<CViPER4WindowsModule> {};
CViPER4WindowsModule _Module;

OBJECT_ENTRY_AUTO(CLSID_ViPER4WindowsMFX, CViPER4WindowsMFX)
BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID reserved) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hModule);
    }
    return _Module.DllMain(reason, reserved);
}

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppv) {
    HRESULT hr = _Module.DllGetClassObject(rclsid, riid, ppv);
    if (FAILED(hr)) {
        ViPERLog(
            "[ViPER] DllGetClassObject FAILED hr=0x%08X clsid.Data1=0x%08X\n",
            hr,
            rclsid.Data1
        );
    }
    return hr;
}

STDAPI DllCanUnloadNow() {
    return _Module.DllCanUnloadNow();
}

STDAPI DllRegisterServer() {
    return _Module.DllRegisterServer(FALSE);
}

STDAPI DllUnregisterServer() {
    return _Module.DllUnregisterServer(FALSE);
}
