#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  wchar_t exePath[MAX_PATH];
  if (::GetModuleFileNameW(nullptr, exePath, MAX_PATH)) {
    wchar_t* lastSlash = wcsrchr(exePath, L'\\');
    if (lastSlash) {
      *lastSlash = L'\0';
      ::SetCurrentDirectoryW(exePath);
    }
  }

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  bool autostart = false;
  for (const auto& arg : command_line_arguments) {
    if (arg == "--autostart") {
      autostart = true;
      break;
    }
  }

  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(autostart ? -32000 : 10, autostart ? -32000 : 10);
  Win32Window::Size size(autostart ? 1 : 1280, autostart ? 1 : 720);
  if (!window.Create(L"viper4windows", origin, size)) {
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(false);
  if (autostart) {
    ::ShowWindow(window.GetHandle(), SW_HIDE);
  } else {
    window.Show();
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
