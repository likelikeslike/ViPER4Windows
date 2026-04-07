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
    switch (reason) {
        case DLL_PROCESS_ATTACH: {
            DisableThreadLibraryCalls(hModule);
            ViPERLog(
                "[ViPER] DllMain: DLL_PROCESS_ATTACH pid=%u\n", GetCurrentProcessId()
            );
            break;
        }
        case DLL_PROCESS_DETACH:
            ViPERLog("[ViPER] DllMain: DLL_PROCESS_DETACH\n");
            break;
    }
    return _Module.DllMain(reason, reserved);
}

STDAPI DllGetClassObject(REFCLSID rclsid, REFIID riid, LPVOID *ppv) {
    ViPERLog(
        "[ViPER] DllGetClassObject clsid.Data1=0x%08X riid.Data1=0x%08X\n",
        rclsid.Data1,
        riid.Data1
    );

    HRESULT hr = _Module.DllGetClassObject(rclsid, riid, ppv);
    ViPERLog("[ViPER] DllGetClassObject hr=0x%08X\n", hr);
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
