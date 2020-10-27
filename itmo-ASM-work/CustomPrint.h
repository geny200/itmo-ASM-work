#pragma once
#include <stdio.h>

extern "C" int printf2(char const* const _Format, ...) {
    int _Result;
    va_list _ArgList;
    __crt_va_start(_ArgList, _Format);
    _Result = _vfprintf_l(stdout, _Format, NULL, _ArgList);
    __crt_va_end(_ArgList);
    return _Result;
}

