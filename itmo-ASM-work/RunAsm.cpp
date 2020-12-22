#include "CustomPrint.h"
#include "ModeHead.h"

extern "C" int printf2(char const* const _Format, ...) {
    int _Result;
    va_list _ArgList;
    __crt_va_start(_ArgList, _Format);
    _Result = _vfprintf_l(stdout, _Format, NULL, _ArgList);
    __crt_va_end(_ArgList);
    return _Result;
}

int main() {
#ifdef _M_X64
    x64_tasks();
#elif _M_IX86
    x86_tasks();
#endif
    return 0;
}