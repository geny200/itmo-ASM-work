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
#include <vector>
#include <string>
void task_hec_to_dec() {
    uint32_t nCnt = 0;
    srand(time(0));
    std::string sAlfa = "0123456789abcdefABCDEF";
    std::vector<std::string> pConf = { "+", "-", "0", " ", "9", "+-", "+0", "-0", "09", "017", "0+-9", " +", "- ", "+ ", " 0", "0+- 9", "0+- 1", "0+- 17" };
    std::vector<std::string> pNums = { "1", "-1", "80000000", "-80000000", "800000000", "-800000000", "1234", "80000000000000008000000000000000", "-80000000000000008000000000000000", "f000c00a0b00f0", "f", "10" };
    for (auto& iConf : pConf) {

        for (int len = 1; len <= 128 / 4; len++) {
            for (size_t q = 0; q < 900; q++)
            {
                char buff1[200]{ 0 };
                char buff2[200]{ 0 };
                std::string sInput = "";
                int x = rand() % (sAlfa.size() - 1);
                sInput.push_back(sAlfa[1 + x]);
                for (int i = 0; i < len - 1; i++) {
                    x = rand() % sAlfa.size();
                    sInput.push_back(sAlfa[x]);
                }
                hex_print(buff1, iConf.c_str(), sInput.c_str());
                test_hex(buff2, iConf.c_str(), sInput.c_str());

                if (std::string(buff1) != std::string(buff2)) {
                    std::cout << std::endl << "Err:" << std::endl
                        << "conf: |" << iConf << "|" << std::endl
                        << "numb: |" << sInput << "|" << std::endl
                        << "my \t|" << buff1 << "|" << std::endl
                        << "test \t|" << buff2 << "|" << std::endl << std::endl;
                }
            }

        }
        for (auto& iNum : pNums) {
            //std::cout << ++nCnt << ' ';
            char buff1[200]{ 0 };
            char buff2[200]{ 0 };
            hex_print(buff1, iConf.c_str(), iNum.c_str());
            test_hex(buff2, iConf.c_str(), iNum.c_str());
            if (std::string(buff1) != std::string(buff2)) {
                std::cout << std::endl << "Err:" << std::endl
                    << "conf: |" << iConf << "|" << std::endl
                    << "numb: |" << iNum << "|" << std::endl
                    << "my \t|" << buff1 << "|" << std::endl
                    << "test \t|" << buff2 << "|" << std::endl << std::endl;
            }
        }
    }
    
    char buff1[200]{ 0 };
    hex_print(buff1, " +", "1234");
    std::cout << std::endl << "out: |" << buff1 << "|";
}
#endif

void x86_tasks() {

#ifdef _M_IX86 
    printf("x86_tasks:\n");
    //printf("arctang:\n");
    //task_arctang();

    //printf("\nmax(sign):\n");
    //task_max_sign();

    //printf("\nmax(unsign):\n");
    //task_max();

    printf("\nhec_to_dec:\n");
    task_hec_to_dec();
    printf("\nend_x86_tasks\n");
#else
    printf("x86_tasks - _M_IX86 doesn't defined\n");
#endif
}

