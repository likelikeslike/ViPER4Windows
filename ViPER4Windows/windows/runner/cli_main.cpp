#include <windows.h>

#include <string>
#include <vector>

#include "cli_client.h"

namespace {

std::string Utf8FromUtf16(const wchar_t *utf16) {
  if (utf16 == nullptr)
    return std::string();
  int len = ::WideCharToMultiByte(CP_UTF8, 0, utf16, -1, nullptr, 0, nullptr,
                                  nullptr);
  if (len <= 1)
    return std::string();
  std::string utf8(len - 1, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, utf16, -1, utf8.data(), len, nullptr,
                        nullptr);
  return utf8;
}

std::vector<std::string> CommandLineArgs() {
  int argc = 0;
  wchar_t **argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  std::vector<std::string> args;
  if (argv == nullptr)
    return args;
  for (int i = 1; i < argc; ++i) {
    args.push_back(Utf8FromUtf16(argv[i]));
  }
  ::LocalFree(argv);
  return args;
}

} // namespace

int wmain() { return RunCli(CommandLineArgs()); }
