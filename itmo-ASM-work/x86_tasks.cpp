#include "CustomPrint.h"
#include <stdint.h>
#include <time.h> 
#include <random>
#include <iostream>

#ifdef _M_IX86 
std::mt19937 mersene(123);

extern "C" void     _cdecl fact(int32_t);
extern "C" double   _cdecl arctang(float, uint32_t);
extern "C" int8_t   _cdecl min_ubytes(int8_t*, uint32_t);
extern "C" int8_t   _cdecl max_sbytes(int8_t*, uint32_t);
extern "C" void     _cdecl test_hex(char* out_buf, const char* format, const char* hex_number);
extern "C" void     _cdecl hex_print(char* out_buf, const char* format, const char* hex_number);

void task_factorial() {
    fact(7);
    return;
}

void task_arctang() {
    clock_t start = clock();

    double d = arctang(0.4f, 1000000);

    clock_t end = clock();
    double seconds = (double)(end - start);

    printf("number: %f\n ms: %f", d, seconds);
    return;
}

void task_max() {
    uint32_t nSize = 8 * 10000000;
    int8_t* pData = new int8_t[nSize]{};
    for (size_t i = 0; i != nSize; ++i) {
        pData[i] = mersene();
    }

    clock_t start = clock();
    int8_t result = min_ubytes(pData, nSize);
    clock_t end1 = clock();

    int8_t nNaive = 0;
    for (size_t i = 0; i != nSize; ++i) {
        if (nNaive < pData[i])
            nNaive = pData[i];
    }
    clock_t end2 = clock();
    delete[] pData;

    printf("\ntask more big\nnumber: %d\n my - ms: \t%f\n naive - ms: \t%f", (int)result, (double)(end1 - start), (double)(end2 - end1));
    return;
}

void task_max_sign() {
    uint32_t nSize = 8 * 10000000;
    int8_t* pData = new int8_t[nSize]{};
    for (size_t i = 0; i != nSize; ++i) {
        pData[i] = mersene();
    }

    clock_t start = clock();
    int8_t result = max_sbytes(pData, nSize);
    clock_t end1 = clock();

    int8_t nNaive = 0;
    for (size_t i = 0; i != nSize; ++i) {
        if (nNaive < pData[i])
            nNaive = pData[i];
    }
    clock_t end2 = clock();
    delete[] pData;

    printf("number: %d\n my - ms: \t%f\n naive - ms: \t%f", (int)result, (double)(end1 - start), (double)(end2 - end1));
    return;
}

void task_hec_to_dec() {
    char buff1[100]{ 0 };
    hex_print(buff1, buff1, "123456789123456789");
    std::cout << "out: |" << buff1 << "|";
    //test_hex(buff1, "", "123456789123456789"); // 562046894926727218533
}
#endif

void x86_tasks() {

#ifdef _M_IX86 
    printf("x86_tasks:\n");
    printf("arctang:\n");
    task_arctang();

    printf("\nmax(sign):\n");
    task_max_sign();

    printf("\nmax(unsign):\n");
    task_max();

    printf("\nhec_to_dec:\n");
    task_hec_to_dec();
    printf("\nend_x86_tasks\n");
#else
    printf("x86_tasks - _M_IX86 doesn't defined\n");
#endif
}

