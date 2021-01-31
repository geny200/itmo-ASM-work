#include "CustomPrint.h"
#include <cassert>
#include <stdint.h>
#include <time.h> 
#include <string>
#include <iostream>
#include <vector>
#include <random>





#ifdef _M_X64
std::mt19937 generator(123);

// double to string task
extern "C" void _fastcall dbl2str(const double* in, char* out_buf);

// strlen task
extern "C" uint32_t _fastcall my_strlen(const char*);

void task_str_len() {
    const uint32_t ncSize = 1000000000;
    std::string sData(ncSize, 1);
    clock_t tMy, tLib;

    sData.back() = 0;

    tMy = clock();
    uint32_t nSizeEval = my_strlen(sData.data());
    tMy = clock() - tMy;

    tLib = clock();
    uint32_t nSizeEval2 = strlen(sData.data());
    tLib = clock() - tLib;

    if (nSizeEval != nSizeEval2)
        std::cout << "Error!" << std::endl
        << "my size  = " << nSizeEval << std::endl
        << "lib size = " << nSizeEval2 << std::endl;

    std::cout << "size = " << nSizeEval << std::endl
        << "elements:   " << ncSize - 1 << std::endl
        << "time my:    " << tMy << std::endl
        << "time naive: " << tLib << std::endl
        << std::endl;
    return;
}

void test_common(const std::vector<uint64_t>& vBench) {
    char buffer[35]{ 0 };

    for (auto& iNum : vBench) {
        double dReal, dCheck;
        uint64_t nCheck;

        memcpy(&dReal, &iNum, 8);
        dbl2str(&dReal, buffer);
        dCheck = std::stod(buffer);
        memcpy(&nCheck, &dCheck, 8);

        if (iNum != nCheck) {
            std::cout << "Error!" << std::endl
                << "my out    : " << buffer << std::endl
                << "real num  : " << dReal << std::endl
                << "in uint64 : " << iNum << std::endl
                << "out uint64: " << nCheck << std::endl
                << std::endl;
        }
    }
    std::cout << "finish " << vBench.size() << " tests" << std::endl;
    return;
}

void test_random_zeros(uint32_t anSize) {
    std::cout << "test_random_zeros start" << std::endl;

    std::uniform_real_distribution<double> dis(-1, 1);
    std::vector<uint64_t> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        double r = dis(generator);
        memcpy(&iNum, &r, 8);
    }

    test_common(vBench);

    std::cout << "test_random_zeros end" << std::endl
        << std::endl;
    return;
}

void test_random_denorm(uint32_t anSize) {
    std::cout << "test_de_normalize start" << std::endl;

    std::vector<uint64_t> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        iNum = generator();
    }

    test_common(vBench);

    std::cout << "test_de_normalize end" << std::endl
        << std::endl;
    return;
}

void test_random_big(uint32_t anSize) {
    std::cout << "test_random_big start" << std::endl;
  
    std::uniform_real_distribution<double> dis(DBL_MIN, DBL_MAX);
    std::vector<uint64_t> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        double r = dis(generator);
        memcpy(&iNum, &r, 8);
    }

    test_common(vBench);

    std::cout << "test_random_big end" << std::endl
        << std::endl;
    return;
}

void test_random_all() {
    std::cout << "test_random_all start" << std::endl;
    char buffer[35]{ 0 };

    for (size_t i = 0, k = UINT64_MAX / INT_MAX, t = 0; i != INT_MAX; ++i, t += k) {
        double dNum;
        double dCheck;
        uint64_t nCheck;
        uint64_t nRand = t + generator() % k;
        
        memcpy(&dNum, &nRand, 8);
        dbl2str(&dNum, buffer);
        dCheck = std::stod(buffer);
        memcpy(&nCheck, &dCheck, 8);

        if (isnan(dNum) & isnan(dCheck))
            continue;
        if (isinf(dNum) & isinf(dCheck))
            continue;

        if (nRand != nCheck) {
            std::cout << "Error!" << std::endl
                << "my out    : " << buffer << std::endl
                << "real num  : " << dNum << std::endl
                << "in uint64 : " << nRand << std::endl
                << "out uint64: " << nCheck << std::endl
                << std::endl;
        }
    }
    std::cout << "finish " << INT_MAX << " tests" << std::endl;
    std::cout << "test_random_all end" << std::endl;
    return;
}

void bench_common(const std::vector<double>& vBench) {
    char buffer[35]{ 0 };
    clock_t tMy, tNaive;

    tMy = clock();
    for (auto& iNum : vBench) {
        dbl2str(&iNum, buffer);
    }

    tMy = clock() - tMy;
    std::cout << "elements: " << vBench.size() << std::endl
        << "time: " << tMy << std::endl
        << std::endl;
}

void bench_random_zeros(uint32_t anSize) {
    std::cout << "bench random_zeros" << std::endl;

    std::uniform_real_distribution<double> dis(-1, 1);
    std::vector<double> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        iNum = dis(generator);
    }
    
    bench_common(vBench);

    std::cout << std::endl;
    return;
}

void bench_random_denorm(uint32_t anSize) {
    std::cout << "bench de_normalize start" << std::endl;

    std::vector<double> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        uint64_t r = generator();
        memcpy(&iNum, &r, 8);
    }

    bench_common(vBench);

    std::cout << std::endl;
    return;
}

void bench_random_big(uint32_t anSize) {
    std::cout << "bench random_big start" << std::endl;

    std::uniform_real_distribution<double> dis(DBL_MIN, DBL_MAX);

    std::vector<double> vBench(anSize, 0);

    for (auto& iNum : vBench) {
        iNum = dis(generator);
    }

    bench_common(vBench);
    std::cout << std::endl;
    return;
}

void task_dbl2str() {
    char buffer[35]{ 0 };

    uint64_t bit_num = 4886405779497671769;
    double dNum;
    memcpy(&dNum, &bit_num, 8);
    //dNum = 1.5;

    dbl2str(&dNum, buffer); 
    std::cout << "num: " << buffer << std::endl
        << std::endl;
    return;
}
#endif

void x64_tasks() {
#ifdef _M_X64
    std::cout << "x64_tasks" << std::endl;

    std::cout << "+ str_len" << std::endl;
    task_str_len();

    std::cout << "+ dbl2str" << std::endl;
    task_dbl2str();

    uint32_t nSize = 100000;
    bench_random_zeros(nSize);
    bench_random_denorm(nSize);
    bench_random_big(nSize);

    //test_random_zeros(nSize);
    //test_random_denorm(nSize);
    //test_random_big(nSize);
    //test_random_all();

    std::cout << "end_x64_tasks" << std::endl 
        << std::endl;
#else
    std::cout << "x64_tasks - _M_X64 doesn't defined" << std::endl
        << std::endl;
#endif
}