#ifndef VIPER4WINDOWS_LOG_H
#define VIPER4WINDOWS_LOG_H

#include <cstdarg>
#include <cstdio>
#include <strsafe.h>
#include <windows.h>

namespace detail {

inline CRITICAL_SECTION &LogCS() {
    static CRITICAL_SECTION cs;
    static volatile LONG state = 0;
    if (InterlockedCompareExchange(&state, 1, 0) == 0) {
        InitializeCriticalSectionAndSpinCount(&cs, 4000);
        InterlockedExchange(&state, 2);
    } else {
        while (InterlockedCompareExchange(&state, 2, 2) != 2) {
            SwitchToThread();
        }
    }
    return cs;
}

}  // namespace detail

static void ViPERLog(const char *fmt, ...) {
    char buf[1024];
    va_list args;
    va_start(args, fmt);
    StringCchVPrintfA(buf, _countof(buf), fmt, args);
    va_end(args);
    OutputDebugStringA(buf);

    EnterCriticalSection(&detail::LogCS());

    static bool dir_created = false;
    if (!dir_created) {
        CreateDirectoryW(L"C:\\ProgramData\\ViPER4Windows", nullptr);
        dir_created = true;
    }

    FILE *f = nullptr;
    fopen_s(&f, "C:\\ProgramData\\ViPER4Windows\\viper_apo.log", "a");
    if (f) {
        fputs(buf, f);
        fflush(f);
        fclose(f);
    }

    LeaveCriticalSection(&detail::LogCS());
}

#endif
