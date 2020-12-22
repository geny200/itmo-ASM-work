#include "CustomPrint.h"
#include <cassert>
#include <stdint.h>
#include <time.h> 
#include <string.h>
#include <iostream>

#ifdef _M_X64
extern "C" uint32_t _cdecl my_strlen(char*);

void task_str_len() {
    const uint32_t ncSize = 1000000000;
    char* pData = new char[ncSize] { 0 };

    for (size_t i = 0; i != ncSize; ++i) {
        pData[i] = 1;
    }
    pData[ncSize - 1] = 0;

    clock_t start = clock();
    uint32_t nSizeEval = my_strlen(pData);
    clock_t end1 = clock();
    uint32_t nSizeEval2 = strlen(pData);
    clock_t end2 = clock();

    std::cout << "size: 1)" << nSizeEval << " 2)" << nSizeEval2 << std::endl
        << "my:\t" << (double)(end1 - start) << " ms" << std::endl
        << "naive:\t" << (double)(end2 - end1) << " ms" << std::endl;
    assert(nSizeEval == nSizeEval2);
}
#endif

void x64_tasks() {
#ifdef _M_X64
    printf("x64_tasks:\n");
    printf("str_len:\n");
    task_str_len();
    printf("\nend_x64_tasks\n");
#else
    printf("x64_tasks - _M_X64 doesn't defined\n");
#endif
}