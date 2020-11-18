#include "CustomPrint.h"
#include <stdint.h>
#include <time.h> 
#include <random>
#include <iostream>

std::mt19937 mersene(123);

extern "C" void     _cdecl fact     (int32_t);
extern "C" double   _cdecl arctang  (float, uint32_t);
extern "C" int8_t  _cdecl min_ubytes(int8_t*, uint32_t);
extern "C" int8_t   _cdecl max_sbytes(int8_t*, uint32_t);

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
    delete pData;

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
    delete pData;

    printf("number: %d\n my - ms: \t%f\n naive - ms: \t%f", (int)result, (double)(end1 - start), (double)(end2 - end1));
    return;
}

int main() {
    //task_arctang();
    task_max_sign();
    task_max();
    //task_min();
    return 0;
}