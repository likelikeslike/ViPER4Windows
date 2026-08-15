#include "cli_client.h"

#include <windows.h>

#include <cstdio>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace {

const wchar_t kPipeName[] = L"\\\\.\\pipe\\ViPER4Windows_Control";

std::wstring Widen(const std::string &utf8) {
  if (utf8.empty())
    return std::wstring();
  int len = ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                  static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring wide(len, L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                        wide.data(), len);
  return wide;
}

void WriteConsoleUtf8(DWORD stdHandle, const std::string &utf8) {
  HANDLE h = ::GetStdHandle(stdHandle);
  if (h == nullptr || h == INVALID_HANDLE_VALUE)
    return;
  DWORD mode = 0;
  if (::GetConsoleMode(h, &mode)) {
    std::wstring wide = Widen(utf8);
    DWORD written = 0;
    ::WriteConsoleW(h, wide.data(), static_cast<DWORD>(wide.size()), &written,
                    nullptr);
  } else {
    DWORD written = 0;
    ::WriteFile(h, utf8.data(), static_cast<DWORD>(utf8.size()), &written,
                nullptr);
  }
}

void OutLine(const std::string &s) {
  WriteConsoleUtf8(STD_OUTPUT_HANDLE, s + "\n");
}

void ErrLine(const std::string &s) {
  WriteConsoleUtf8(STD_ERROR_HANDLE, s + "\n");
}

const std::set<std::string> &TopVerbs() {
  static const std::set<std::string> verbs = {
      "preset", "master", "device", "status", "help", "--help", "-h"};
  return verbs;
}

const std::set<std::string> &DestructiveCommands() {
  static const std::set<std::string> cmds = {"preset delete", "device delete"};
  return cmds;
}

const char kHelpText[] =
    "ViPER4Windows command-line interface.\n"
    "Requires the ViPER4Windows app to be running; commands are applied live.\n"
    "\n"
    "Usage: viper4windows <command> [args] [--yes]\n"
    "\n"
    "preset list                 List saved presets\n"
    "preset load <name>          Load a preset (updates the UI and audio "
    "live)\n"
    "preset save <name>          Save the current settings as a preset\n"
    "preset delete <name>        Delete a preset (prompts y/N unless --yes)\n"
    "preset rename <old> <new>   Rename a preset\n"
    "preset import <path>        Import a preset .json file\n"
    "\n"
    "master                      Show master on/off state\n"
    "master on|off               Enable or disable all effects\n"
    "master toggle               Flip the master state\n"
    "\n"
    "device current              Show the current output device\n"
    "device list                 List devices the app has seen (persisted, not "
    "a live scan)\n"
    "device show [id]            Show a device's id, name and type (default: "
    "current device)\n"
    "device delete <id>          Delete a device's saved settings (prompts y/N "
    "unless --yes)\n"
    "\n"
    "status                      Show master, driver, APO and device status\n"
    "\n"
    "help, --help                Show this help\n"
    "\n"
    "Flags:\n"
    "  --yes, -y                 Skip confirmation prompts on destructive "
    "commands\n";

struct ParsedCommand {
  std::vector<std::string> tokens;
  bool yes = false;
};

ParsedCommand ParseArgs(const std::vector<std::string> &args) {
  ParsedCommand parsed;
  for (const auto &a : args) {
    if (a == "--autostart")
      continue;
    if (a == "--yes" || a == "-y") {
      parsed.yes = true;
      continue;
    }
    parsed.tokens.push_back(a);
  }
  return parsed;
}

std::string CommandKey(const std::vector<std::string> &tokens) {
  if (tokens.size() >= 2)
    return tokens[0] + " " + tokens[1];
  if (!tokens.empty())
    return tokens[0];
  return "";
}

bool IsDestructive(const std::vector<std::string> &tokens) {
  return DestructiveCommands().count(CommandKey(tokens)) > 0;
}

std::string Join(const std::vector<std::string> &tokens, char sep) {
  std::string out;
  for (size_t i = 0; i < tokens.size(); ++i) {
    if (i > 0)
      out += sep;
    out += tokens[i];
  }
  return out;
}

bool Confirm(const std::vector<std::string> &tokens) {
  const std::string target = tokens.size() >= 3 ? tokens[2] : "";
  WriteConsoleUtf8(STD_OUTPUT_HANDLE,
                   "This will delete \"" + target + "\". Continue? [y/N] ");
  std::string line;
  if (!std::getline(std::cin, line))
    return false;
  for (auto &c : line)
    c = static_cast<char>(::tolower(c));
  size_t start = line.find_first_not_of(" \t\r\n");
  size_t end = line.find_last_not_of(" \t\r\n");
  if (start == std::string::npos)
    return false;
  line = line.substr(start, end - start + 1);
  return line == "y" || line == "yes";
}

HANDLE ConnectPipe() {
  for (int attempt = 0; attempt < 10; ++attempt) {
    HANDLE h = ::CreateFileW(kPipeName, GENERIC_READ | GENERIC_WRITE, 0,
                             nullptr, OPEN_EXISTING, 0, nullptr);
    if (h != INVALID_HANDLE_VALUE)
      return h;
    DWORD err = ::GetLastError();
    if (err == ERROR_FILE_NOT_FOUND)
      return INVALID_HANDLE_VALUE;
    if (err == ERROR_PIPE_BUSY) {
      ::WaitNamedPipeW(kPipeName, 200);
      continue;
    }
    return INVALID_HANDLE_VALUE;
  }
  return INVALID_HANDLE_VALUE;
}

bool WriteLine(HANDLE pipe, const std::string &line) {
  std::string data = line + "\n";
  size_t offset = 0;
  while (offset < data.size()) {
    DWORD written = 0;
    BOOL ok = ::WriteFile(pipe, data.data() + offset,
                          static_cast<DWORD>(data.size() - offset), &written,
                          nullptr);
    if (!ok || written == 0)
      return false;
    offset += written;
  }
  ::FlushFileBuffers(pipe);
  return true;
}

std::vector<std::string> ReadReply(HANDLE pipe) {
  std::string all;
  char buf[65536];
  while (true) {
    DWORD read = 0;
    BOOL ok = ::ReadFile(pipe, buf, sizeof(buf), &read, nullptr);
    if (!ok || read == 0)
      break;
    all.append(buf, read);
    if (all.find("\n.\n") != std::string::npos)
      break;
  }
  size_t sentinel = all.find("\n.\n");
  std::string body =
      sentinel != std::string::npos ? all.substr(0, sentinel) : all;
  std::vector<std::string> lines;
  std::stringstream ss(body);
  std::string line;
  while (std::getline(ss, line, '\n')) {
    if (!line.empty() && line.back() == '\r')
      line.pop_back();
    lines.push_back(line);
  }
  return lines;
}

int PrintReply(const std::vector<std::string> &reply) {
  if (reply.empty()) {
    ErrLine("ERR empty reply from ViPER4Windows");
    return 1;
  }
  const std::string &first = reply.front();
  if (first.rfind("ERR", 0) == 0) {
    ErrLine(first);
    for (size_t i = 1; i < reply.size(); ++i) {
      if (!reply[i].empty())
        ErrLine(reply[i]);
    }
    return 1;
  }
  std::string firstMsg;
  if (first != "OK") {
    if (first.rfind("OK ", 0) == 0) {
      firstMsg = first.substr(3);
    } else {
      firstMsg = first;
    }
  }
  if (!firstMsg.empty())
    OutLine(firstMsg);
  for (size_t i = 1; i < reply.size(); ++i) {
    OutLine(reply[i]);
  }
  return 0;
}

} // namespace

bool IsCliInvocation(const std::vector<std::string> &args) {
  for (const auto &a : args) {
    if (a == "--autostart")
      continue;
    return TopVerbs().count(a) > 0;
  }
  return false;
}

int RunCli(const std::vector<std::string> &args) {
  ParsedCommand parsed = ParseArgs(args);
  const std::vector<std::string> &tokens = parsed.tokens;

  if (tokens.empty() || tokens[0] == "help" || tokens[0] == "--help" ||
      tokens[0] == "-h") {
    WriteConsoleUtf8(STD_OUTPUT_HANDLE, kHelpText);
    return 3;
  }

  if (IsDestructive(tokens) && !parsed.yes) {
    if (!Confirm(tokens)) {
      OutLine("Aborted.");
      return 3;
    }
  }

  HANDLE pipe = ConnectPipe();
  if (pipe == INVALID_HANDLE_VALUE) {
    ErrLine("ViPER4Windows is not running. Start the app first.");
    return 2;
  }

  int code;
  if (!WriteLine(pipe, Join(tokens, ' '))) {
    ErrLine("ERR failed to send command");
    code = 1;
  } else {
    code = PrintReply(ReadReply(pipe));
  }
  ::CloseHandle(pipe);
  return code;
}
