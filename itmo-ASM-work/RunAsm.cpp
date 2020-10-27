#include "CustomPrint.h"
#include <stdio.h>
#include <stdint.h>
#include <time.h> 

extern "C" void     _cdecl fact     (int32_t);
extern "C" double   _cdecl arctang  (float, uint32_t);

int main() {
    fact(7);

    clock_t start = clock();

    double d = arctang(0.4f, 1000000);

    clock_t end = clock();
    double seconds = (double)(end - start);

    printf("number: %f\n ms: %f", d, seconds);

    return 0;
}