#include "apo_registry.h"

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <aclapi.h>
#include <sddl.h>
#include <windows.h>

#include <sstream>
#include <string>
#include <thread>

namespace {

constexpr wchar_t kRenderRoot[] =
    L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\MMDevices\\Audio\\Render";

constexpr wchar_t kViperClsid[] = L"{B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}";

// Modes property value used by AudioEndpointBuilder when the endpoint has no
// custom mode list. {C18E2F7E-...} is the inert "raw" mode.
constexpr wchar_t kDefaultMode[] = L"{C18E2F7E-933D-4965-B7D1-1EEF228D2AF3}";

// PKEY_FX (d04e05a6) effect CLSID slots:
//   ,5 PKEY_FX_StreamEffectClsid     REG_SZ
//   ,6 PKEY_FX_ModeEffectClsid       REG_SZ
//   ,7 PKEY_FX_EndpointEffectClsid   REG_SZ
//   ,13 PKEY_CompositeFX_StreamEffectClsid     REG_MULTI_SZ (effect chain)
//   ,14 PKEY_CompositeFX_ModeEffectClsid       REG_MULTI_SZ
//   ,15 PKEY_CompositeFX_EndpointEffectClsid   REG_MULTI_SZ
// PKEY_FX_PROCESSINGMODES (d3993a3f) modes slots hold REG_MULTI_SZ mode-id
// GUIDs, not CLSIDs.
constexpr wchar_t kClsidSfx[] = L"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},5";
constexpr wchar_t kClsidMfx[] = L"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},6";
constexpr wchar_t kClsidCompositeSfx[] =
    L"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},13";
constexpr wchar_t kClsidCompositeMfx[] =
    L"{d04e05a6-594b-4fb6-a80d-01af5eed7d1d},14";
constexpr wchar_t kModesSfx[] = L"{d3993a3f-99c2-4402-b5ec-a92a0367664b},5";
constexpr wchar_t kModesMfx[] = L"{d3993a3f-99c2-4402-b5ec-a92a0367664b},6";
constexpr wchar_t kPkeyEfxStream[] =
    L"{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5";

std::wstring FormatHr(LSTATUS rc) {
  wchar_t buf[256];
  DWORD n = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM, nullptr,
                           static_cast<DWORD>(rc), 0, buf,
                           sizeof(buf) / sizeof(buf[0]), nullptr);
  std::wstring text;
  if (n > 0) {
    text.assign(buf, n);
    while (!text.empty() && (text.back() == L'\r' || text.back() == L'\n')) {
      text.pop_back();
    }
  }
  std::wostringstream os;
  os << L"0x" << std::hex << static_cast<unsigned long>(rc);
  if (!text.empty())
    os << L" (" << text << L")";
  return os.str();
}

std::string Narrow(const std::wstring &w) {
  if (w.empty())
    return {};
  int sz = WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()),
                               nullptr, 0, nullptr, nullptr);
  std::string out(static_cast<size_t>(sz), '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()),
                      out.data(), sz, nullptr, nullptr);
  return out;
}

std::wstring Widen(const std::string &s) {
  if (s.empty())
    return {};
  int sz = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()),
                               nullptr, 0);
  std::wstring out(static_cast<size_t>(sz), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()),
                      out.data(), sz);
  return out;
}

// Enable SeTakeOwnership, SeRestore, SeBackup on the current process token.
bool EnableTakeOwnershipPrivileges(std::wstring *err) {
  HANDLE token = nullptr;
  if (!OpenProcessToken(GetCurrentProcess(),
                        TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &token)) {
    if (err)
      *err = L"OpenProcessToken: " + FormatHr(GetLastError());
    return false;
  }
  struct {
    DWORD count;
    LUID_AND_ATTRIBUTES privs[3];
  } tp{};
  tp.count = 3;
  const wchar_t *names[3] = {SE_TAKE_OWNERSHIP_NAME, SE_RESTORE_NAME,
                             SE_BACKUP_NAME};
  for (int i = 0; i < 3; ++i) {
    if (!LookupPrivilegeValueW(nullptr, names[i], &tp.privs[i].Luid)) {
      if (err)
        *err = L"LookupPrivilegeValue: " + FormatHr(GetLastError());
      CloseHandle(token);
      return false;
    }
    tp.privs[i].Attributes = SE_PRIVILEGE_ENABLED;
  }
  AdjustTokenPrivileges(token, FALSE, reinterpret_cast<PTOKEN_PRIVILEGES>(&tp),
                        sizeof(tp), nullptr, nullptr);
  DWORD rc = GetLastError();
  CloseHandle(token);
  if (rc == ERROR_NOT_ALL_ASSIGNED) {
    if (err)
      *err = L"AdjustTokenPrivileges: ERROR_NOT_ALL_ASSIGNED (some "
             L"privileges are missing from the process token)";
    return false;
  }
  if (rc != ERROR_SUCCESS) {
    if (err)
      *err = L"AdjustTokenPrivileges: " + FormatHr(rc);
    return false;
  }
  return true;
}

// Take ownership and grant Admin+SYSTEM FullControl on the FxProperties key.
LSTATUS RewriteFxPropertiesAcl(const std::wstring &fx_path,
                               std::wstring *diag) {
  HKEY key = nullptr;
  LSTATUS rc = RegOpenKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0,
                             WRITE_OWNER | KEY_WOW64_64KEY, &key);
  if (rc != ERROR_SUCCESS) {
    if (diag)
      *diag = L"open WRITE_OWNER: " + FormatHr(rc);
    return rc;
  }
  PSID admin_sid = nullptr;
  ConvertStringSidToSidW(L"S-1-5-32-544", &admin_sid);
  rc = SetSecurityInfo(key, SE_REGISTRY_KEY, OWNER_SECURITY_INFORMATION,
                       admin_sid, nullptr, nullptr, nullptr);
  RegCloseKey(key);
  if (rc != ERROR_SUCCESS) {
    if (diag)
      *diag = L"SetSecurityInfo OWNER: " + FormatHr(rc);
    LocalFree(admin_sid);
    return rc;
  }

  rc = RegOpenKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0,
                     WRITE_DAC | KEY_WOW64_64KEY, &key);
  if (rc != ERROR_SUCCESS) {
    if (diag)
      *diag = L"open WRITE_DAC: " + FormatHr(rc);
    LocalFree(admin_sid);
    return rc;
  }
  PSID system_sid = nullptr;
  ConvertStringSidToSidW(L"S-1-5-18", &system_sid);
  EXPLICIT_ACCESS_W ea[2] = {};
  ea[0].grfAccessPermissions = KEY_ALL_ACCESS;
  ea[0].grfAccessMode = SET_ACCESS;
  ea[0].grfInheritance = SUB_CONTAINERS_AND_OBJECTS_INHERIT;
  ea[0].Trustee.TrusteeForm = TRUSTEE_IS_SID;
  ea[0].Trustee.TrusteeType = TRUSTEE_IS_GROUP;
  ea[0].Trustee.ptstrName = static_cast<LPWCH>(admin_sid);
  ea[1] = ea[0];
  ea[1].Trustee.ptstrName = static_cast<LPWCH>(system_sid);
  ea[1].Trustee.TrusteeType = TRUSTEE_IS_USER;
  PACL acl = nullptr;
  rc = SetEntriesInAclW(2, ea, nullptr, &acl);
  if (rc != ERROR_SUCCESS) {
    if (diag)
      *diag = L"SetEntriesInAcl: " + FormatHr(rc);
  } else {
    rc = SetSecurityInfo(key, SE_REGISTRY_KEY,
                         DACL_SECURITY_INFORMATION |
                             PROTECTED_DACL_SECURITY_INFORMATION,
                         nullptr, nullptr, acl, nullptr);
    if (rc != ERROR_SUCCESS && diag) {
      *diag = L"SetSecurityInfo DACL: " + FormatHr(rc);
    }
  }
  if (acl)
    LocalFree(acl);
  RegCloseKey(key);
  LocalFree(admin_sid);
  LocalFree(system_sid);
  return rc;
}

LSTATUS WriteSz(HKEY key, const wchar_t *name, const wchar_t *value) {
  return RegSetValueExW(
      key, name, 0, REG_SZ, reinterpret_cast<const BYTE *>(value),
      static_cast<DWORD>((wcslen(value) + 1) * sizeof(wchar_t)));
}

LSTATUS WriteMultiSzSingle(HKEY key, const wchar_t *name,
                           const wchar_t *value) {
  // REG_MULTI_SZ: <value>\0\0
  size_t vlen = wcslen(value);
  std::vector<wchar_t> buf(vlen + 2, L'\0');
  memcpy(buf.data(), value, vlen * sizeof(wchar_t));
  return RegSetValueExW(key, name, 0, REG_MULTI_SZ,
                        reinterpret_cast<const BYTE *>(buf.data()),
                        static_cast<DWORD>(buf.size() * sizeof(wchar_t)));
}

LSTATUS OpenOrCreateFxKey(const std::wstring &fx_path, REGSAM access,
                          HKEY *out_key) {
  LSTATUS rc = RegOpenKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0,
                             access | KEY_WOW64_64KEY, out_key);
  if (rc == ERROR_FILE_NOT_FOUND) {
    DWORD dispo = 0;
    rc = RegCreateKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0, nullptr,
                         REG_OPTION_NON_VOLATILE, access | KEY_WOW64_64KEY,
                         nullptr, out_key, &dispo);
  }
  return rc;
}

bool RegisterEndpoint(const std::wstring &endpoint_id, std::wstring *err) {
  std::wstring fx_path =
      std::wstring(kRenderRoot) + L"\\" + endpoint_id + L"\\FxProperties";

  HKEY key = nullptr;
  LSTATUS rc = OpenOrCreateFxKey(fx_path, KEY_SET_VALUE, &key);
  if (rc == ERROR_ACCESS_DENIED) {
    std::wstring acl_diag;
    LSTATUS acl_rc = RewriteFxPropertiesAcl(fx_path, &acl_diag);
    if (acl_rc != ERROR_SUCCESS) {
      if (err)
        *err = L"ACL rewrite failed: " + acl_diag;
      return false;
    }
    rc = OpenOrCreateFxKey(fx_path, KEY_SET_VALUE, &key);
  }
  if (rc != ERROR_SUCCESS) {
    if (err)
      *err = L"open FxProperties for write: " + FormatHr(rc);
    return false;
  }

  auto remove_if_multi_sz_clsid = [&](const wchar_t *name) {
    DWORD type = 0;
    DWORD bsz = 0;
    if (RegQueryValueExW(key, name, nullptr, &type, nullptr, &bsz) !=
            ERROR_SUCCESS ||
        type != REG_MULTI_SZ || bsz == 0) {
      return;
    }
    std::vector<wchar_t> buf(bsz / sizeof(wchar_t) + 1, L'\0');
    if (RegQueryValueExW(key, name, nullptr, &type,
                         reinterpret_cast<BYTE *>(buf.data()),
                         &bsz) != ERROR_SUCCESS) {
      return;
    }
    if (_wcsicmp(buf.data(), kViperClsid) == 0) {
      RegDeleteValueW(key, name);
    }
  };
  remove_if_multi_sz_clsid(kModesMfx);
  remove_if_multi_sz_clsid(L"{d3993a3f-99c2-4402-b5ec-a92a0367664b},7");

  WriteSz(key, kClsidSfx, kViperClsid);
  WriteSz(key, kClsidMfx, kViperClsid);
  WriteMultiSzSingle(key, kClsidCompositeSfx, kViperClsid);
  WriteMultiSzSingle(key, kClsidCompositeMfx, kViperClsid);

  DWORD type = 0, sz = 0;
  if (RegQueryValueExW(key, kModesSfx, nullptr, &type, nullptr, &sz) ==
      ERROR_FILE_NOT_FOUND) {
    WriteMultiSzSingle(key, kModesSfx, kDefaultMode);
  }
  if (RegQueryValueExW(key, kModesMfx, nullptr, &type, nullptr, &sz) ==
      ERROR_FILE_NOT_FOUND) {
    WriteMultiSzSingle(key, kModesMfx, kDefaultMode);
  }
  RegDeleteValueW(key, kPkeyEfxStream);

  RegCloseKey(key);
  return true;
}

bool UnregisterEndpoint(const std::wstring &endpoint_id, std::wstring *err) {
  std::wstring fx_path =
      std::wstring(kRenderRoot) + L"\\" + endpoint_id + L"\\FxProperties";

  HKEY key = nullptr;
  LSTATUS rc =
      RegOpenKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0,
                    KEY_SET_VALUE | KEY_QUERY_VALUE | KEY_WOW64_64KEY, &key);
  if (rc == ERROR_FILE_NOT_FOUND) {
    return true;
  }
  if (rc == ERROR_ACCESS_DENIED) {
    std::wstring acl_diag;
    LSTATUS acl_rc = RewriteFxPropertiesAcl(fx_path, &acl_diag);
    if (acl_rc != ERROR_SUCCESS) {
      if (err)
        *err = L"ACL rewrite failed: " + acl_diag;
      return false;
    }
    rc = RegOpenKeyExW(HKEY_LOCAL_MACHINE, fx_path.c_str(), 0,
                       KEY_SET_VALUE | KEY_QUERY_VALUE | KEY_WOW64_64KEY, &key);
  }
  if (rc != ERROR_SUCCESS) {
    if (err)
      *err = L"open FxProperties: " + FormatHr(rc);
    return false;
  }

  auto clear_if_viper_only = [&](const wchar_t *name) {
    DWORD type = 0;
    DWORD bsz = 0;
    if (RegQueryValueExW(key, name, nullptr, &type, nullptr, &bsz) !=
            ERROR_SUCCESS ||
        bsz == 0) {
      return;
    }
    std::vector<wchar_t> buf(bsz / sizeof(wchar_t) + 1, L'\0');
    if (RegQueryValueExW(key, name, nullptr, &type,
                         reinterpret_cast<BYTE *>(buf.data()),
                         &bsz) != ERROR_SUCCESS) {
      return;
    }
    if (type == REG_SZ && _wcsicmp(buf.data(), kViperClsid) == 0) {
      RegDeleteValueW(key, name);
    } else if (type == REG_MULTI_SZ && _wcsicmp(buf.data(), kViperClsid) == 0 &&
               buf[wcslen(buf.data()) + 1] == L'\0') {
      RegDeleteValueW(key, name);
    }
  };
  clear_if_viper_only(kClsidSfx);
  clear_if_viper_only(kClsidMfx);
  clear_if_viper_only(kClsidCompositeSfx);
  clear_if_viper_only(kClsidCompositeMfx);

  RegCloseKey(key);
  return true;
}

void HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto &method = call.method_name();
  const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());

  std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> shared(
      std::move(result));

  auto fail = [shared](const std::string &code, const std::wstring &msg) {
    shared->Error(code, Narrow(msg));
  };

  if (method == "enablePrivileges") {
    std::thread([shared, fail]() {
      std::wstring err;
      bool ok = EnableTakeOwnershipPrivileges(&err);
      if (ok)
        shared->Success(flutter::EncodableValue(true));
      else
        fail("PrivilegeError", err);
    }).detach();
    return;
  }

  if (method == "registerEndpoint" || method == "unregisterEndpoint") {
    if (!args) {
      shared->Error("ArgError", "expected map arguments");
      return;
    }
    auto it = args->find(flutter::EncodableValue("endpoint_id"));
    if (it == args->end() || !std::holds_alternative<std::string>(it->second)) {
      shared->Error("ArgError", "missing endpoint_id");
      return;
    }
    std::string endpoint_id_narrow = std::get<std::string>(it->second);
    std::wstring endpoint_id = Widen(endpoint_id_narrow);
    bool is_register = (method == "registerEndpoint");
    std::thread([shared, endpoint_id, is_register]() {
      std::wstring priv_err;
      if (!EnableTakeOwnershipPrivileges(&priv_err)) {
        shared->Error("PrivilegeError", Narrow(priv_err));
        return;
      }
      std::wstring err;
      bool ok = is_register ? RegisterEndpoint(endpoint_id, &err)
                            : UnregisterEndpoint(endpoint_id, &err);
      if (ok)
        shared->Success(flutter::EncodableValue(true));
      else
        shared->Error("RegError", Narrow(err));
    }).detach();
    return;
  }

  shared->NotImplemented();
}

} // namespace

void RegisterApoRegistryChannel(flutter::BinaryMessenger *messenger) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel;
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "v4w/apo_registry",
      &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue> &call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) { HandleMethodCall(call, std::move(result)); });
}
