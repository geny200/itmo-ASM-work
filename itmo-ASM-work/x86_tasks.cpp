#include "CustomPrint.h"
#include <stdint.h>
#include <time.h> 
#include <random>
#include <iostream>
#include <vector>
#include <string>

#ifdef _M_IX86 
std::mt19937 mersene(123);

// factorial task
extern "C" void     _cdecl fact(uint32_t);

// arctang task
extern "C" double   _cdecl arctang(float, uint32_t);

// max in signed array task
extern "C" int8_t   _cdecl max_sbytes(const int8_t*, uint32_t);

// hex to dec task
extern "C" void     _cdecl print(char* out_buf, const char* format, const char* hex_number);

// your hex to dec task (for testing)
extern "C" void     _cdecl test_hex(char* out_buf, const char* format, const char* hex_number);

void task_factorial(uint32_t anX) {
    std::cout << "fact(" << anX << ") = ";

    fact(anX);

    std::cout << std::endl;
    return;
}

void task_arctang(float afX) {
    size_t nCycles = 1000000;
    double dResult = 0.0;
    clock_t time = clock();

    dResult = arctang(afX, nCycles);

    time = clock() - time;

    std::cout << "arctg(" << afX << ") = " << dResult << ";" << std::endl
        << "cycles = " << nCycles << ";" << std::endl
        << "time: " << time << ";" << std::endl 
        << std::endl;
    return;
}

void task_max_signed() {
    std::vector<int8_t> vData(8 * 10000000);
    clock_t tMy, tNaive;
    int8_t nResult, nNaive;

    for (size_t i = 0; i != vData.size(); ++i) {
        vData[i] = mersene();
    }

    tMy = clock();
    nResult = max_sbytes(vData.data(), vData.size());
    tMy = clock() - tMy;

    nNaive = vData.front();
    tNaive = clock();
    for (size_t i = 0; i != vData.size(); ++i) {
        if (nNaive < vData[i])
            nNaive = vData[i];
    }
    tNaive = clock() - tNaive;

    if (nResult != nNaive)
        std::cout << "Error!" << std::endl
        << "my max    = " << nResult << std::endl
        << "naive max = " << nNaive << std::endl;

    std::cout << "max = " << (int)nResult << std::endl
        << "elements:   " << vData.size() << std::endl
        << "time my:    " << tMy << std::endl
        << "time naive: " << tNaive << std::endl 
        << std::endl;
    return;
}

void test_hex_to_dec() {
    std::cout << "test_hec_to_dec start" << std::endl;

    static const std::string sAlfa = "0123456789abcdefABCDEF";
    static const std::vector<std::string> pConf = {
        "+", "-", "0", " ", "9", "+-", "+0",
        "-0", "09", "017", "0+-9", " +", "- ",
        "+ ", " 0", "0+- 9", "0+- 1", "0+- 17"
    };
    static const std::vector<std::string> pNums = {
        "1", "-1", "80000000", "-80000000", "800000000", "-800000000",
        "1234", "80000000000000008000000000000000", "-80000000000000008000000000000000",
        "f000c00a0b00f0", "f", "10"
    };

    auto fPrintError = [](const std::string sConfig, const std::string sNumber, const char* pBuff1, const char* pBuff2) -> void {
        std::cout << std::endl
            << "Error" << std::endl
            << "config: |" << sConfig << "|" << std::endl
            << "number: |" << sNumber << "|" << std::endl
            << "my      |" << pBuff1  << "|" << std::endl
            << "test    |" << pBuff2  << "|" << std::endl
            << std::endl;
    };

    for (auto& iConfig : pConf) {
        // Unit tests
        for (auto& iNum : pNums) {
            char buff1[200]{ 0 };
            char buff2[200]{ 0 };

            print(buff1, iConfig.c_str(), iNum.c_str());
            test_hex(buff2, iConfig.c_str(), iNum.c_str());

            if (std::string(buff1) != std::string(buff2)) {
                fPrintError(iConfig, iNum, buff1, buff2);
            }
        }

        // Stress tests
        for (int len = 1; len <= 128 / 4; ++len) {
            for (size_t q = 0, nrIndex; q < 900; ++q) {
                std::string sNumber = "";
                nrIndex = mersene() % (sAlfa.size() - 1) + 1;
                sNumber.push_back(sAlfa[nrIndex]);

                for (size_t i = 0; i != len - 1; ++i) {
                    nrIndex = mersene() % sAlfa.size();
                    sNumber.push_back(sAlfa[nrIndex]);
                }

                for (size_t i = 0; i != 1; ++i, sNumber = "-" + sNumber)
                {
                    char buff1[200]{ 0 };
                    char buff2[200]{ 0 };

                    print(buff1, iConfig.c_str(), sNumber.c_str());
                    test_hex(buff2, iConfig.c_str(), sNumber.c_str());

                    if (std::string(buff1) != std::string(buff2)) {
                        fPrintError(iConfig, sNumber, buff1, buff2);
                    }
                }
            }
        }
    }
    std::cout << "test_hec_to_dec end" << std::endl
        << std::endl;
}


void task_hex_to_dec() {
    std::string sNumber = "1234";
    std::string sConfig = " +";
    char pBuffer[200]{ 0 };

    print(pBuffer, sConfig.c_str(), sNumber.c_str());

    std::cout << "print(\"" << sConfig << "\", \"" << sNumber << "\") = |" << pBuffer << "|" << std::endl
        << std::endl;
    return;
}
#endif

void x86_tasks() {

#ifdef _M_IX86 
    std::cout << "x86_tasks" << std::endl;

    std::cout << "+ factorial(X) to double print:" << std::endl;
    task_factorial(7);

    std::cout << "+ arctang(X):" << std::endl;
    task_arctang(0.4f);

    std::cout << "+ max in array (signed):" << std::endl;
    task_max_signed();

    std::cout << "+ hex to dec:" << std::endl;
    task_hex_to_dec();
    test_hex_to_dec();

    std::cout << "end_x86_tasks" << std::endl;
#else
    std::cout << "x86_tasks - _M_IX86 doesn't defined" << std::endl;
#endif
}

