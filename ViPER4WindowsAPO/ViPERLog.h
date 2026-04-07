#ifndef VIPER4WINDOWS_LOG_H
#define VIPER4WINDOWS_LOG_H

#include <cstdarg>
#include <cstdio>
#include <strsafe.h>
#include <windows.h>

static void ViPERLog(const char *fmt, ...) {
    char buf[1024];
    va_list args;
    va_start(args, fmt);
    StringCchVPrintfA(buf, _countof(buf), fmt, args);
    va_end(args);
    OutputDebugStringA(buf);

    static bool dirCreated = false;
    if (!dirCreated) {
        CreateDirectoryW(L"C:\\ProgramData\\ViPER4Windows", nullptr);
        dirCreated = true;
    }

    FILE *f = nullptr;
    fopen_s(&f, "C:\\ProgramData\\ViPER4Windows\\viper_apo.log", "a");
    if (f) {
        fputs(buf, f);
        fflush(f);
        fclose(f);
    }
}

#endif
