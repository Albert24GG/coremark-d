module core_main;
@nogc nothrow:
extern (C):
__gshared:

private template HasVersion(string versionId)
{
    mixin("version(" ~ versionId ~ ") {enum HasVersion = true;} else {enum HasVersion = false;}");
}

import core.stdc.config : c_long, c_ulong;

/*
Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Original Author: Shay Gal-on
*/

/* File: core_main.c
        This file contains the framework to acquire a block of memory, seed
   initial parameters, tun t he benchmark and report the results.
*/
import coremark;

/* Function: iterate
        Run the benchmark for a specified number of iterations.

        Operation:
        For each type of benchmarked algorithm:
                a - Initialize the data block for the algorithm.
                b - Execute the algorithm N times.

        Returns:
        NULL.
*/
private ee_u16[5] list_known_crc = [
    cast(ee_u16) 0xd4b0,
    cast(ee_u16) 0x3340,
    cast(ee_u16) 0x6a79,
    cast(ee_u16) 0xe714,
    cast(ee_u16) 0xe3c1
];
private ee_u16[5] matrix_known_crc = [
    cast(ee_u16) 0xbe52,
    cast(ee_u16) 0x1199,
    cast(ee_u16) 0x5608,
    cast(ee_u16) 0x1fd7,
    cast(ee_u16) 0x0747
];
private ee_u16[5] state_known_crc = [
    cast(ee_u16) 0x5e47,
    cast(ee_u16) 0x39bf,
    cast(ee_u16) 0xe5a4,
    cast(ee_u16) 0x8e3a,
    cast(ee_u16) 0x8d84
];
void* iterate(void* pres)
{
    ee_u32 i = void;
    ee_u16 crc = void;
    core_results* res = cast(core_results*) pres;
    ee_u32 iterations = res.iterations;
    res.crc = 0;
    res.crclist = 0;
    res.crcmatrix = 0;
    res.crcstate = 0;

    for (i = 0; i < iterations; i++)
    {
        crc = core_bench_list(res, 1);
        res.crc = crcu16(crc, res.crc);
        crc = core_bench_list(res, -1);
        res.crc = crcu16(crc, res.crc);
        if (i == 0)
            res.crclist = res.crc;
    }
    return null;
}

static if (SEED_METHOD == SEED_ARG)
{
    ee_s32 get_seed_args(int i, int argc, char** argv);
    enum string get_seed(string x) = `cast(ee_s16) get_seed_args(` ~ x ~ `, argc, argv)`;
    enum string get_seed_32(string x) = `get_seed_args(` ~ x ~ `, argc, argv)`;
}
else
{ /* via function or volatile */
    /* ee_s32 get_seed_32(int i); */
    enum string get_seed(string x) = `cast(ee_s16) get_seed_32(` ~ x ~ `)`;

}

static if (MEM_METHOD == MEM_STATIC)
{
    ee_u8[TOTAL_DATA_SIZE] static_memblk;
}
const(char)*[3] mem_name = [
    cast(const(char)*) "Static", cast(const(char)*) "Heap",
    cast(const(char)*) "Stack"
];
/* Function: main
        Main entry routine for the benchmark.
        This function is responsible for the following steps:

        1 - Initialize input seeds from a source that cannot be determined at
   compile time. 2 - Initialize memory block for use. 3 - Run and time the
   benchmark. 4 - Report results, testing the validity of the output if the
   seeds are known.

        Arguments:
        1 - first seed  : Any value
        2 - second seed : Must be identical to first for iterations to be
   identical 3 - third seed  : Any value, should be at least an order of
   magnitude less then the input size, but bigger then 32. 4 - Iterations  :
   Special, if set to 0, iterations will be automatically determined such that
   the benchmark will run between 10 to 100 secs

*/

MAIN_RETURN_TYPE main(int argc, char** argv)
{

    //! #if MAIN_HAS_NOARGC
    static if (MAIN_HAS_NOARGC)
    {
        int argc = 0;
        char** argv;
    }
    //! #endif

    ee_u16 i, j = 0, num_algorithms = 0;
    ee_s16 known_id = -1, total_errors = 0;
    ee_u16 seedcrc = 0;
    CORE_TICKS total_time = void;
    core_results[MULTITHREAD] results = void;
    static if (MEM_METHOD == MEM_STACK)
    {
        ee_u8[TOTAL_DATA_SIZE * MULTITHREAD] stack_memblock = void;
    }
    /* first call any initializations needed */
    portable_init(&(results[0].port), &argc, argv);
    /* First some checks to make sure benchmark will run ok */
    if (list_head_s.sizeof > 128)
    {
        ee_printf("list_head structure too big for comparable data!\n");
        return MAIN_RETURN_VAL;
    }
    results[0].seed1 = mixin(get_seed!(`1`));
    results[0].seed2 = mixin(get_seed!(`2`));
    results[0].seed3 = mixin(get_seed!(`3`));
    results[0].iterations = mixin(get_seed_32!(`4`));
    version (CORE_DEBUG)
    {
        results[0].iterations = 1;
    }
    results[0].execs = mixin(get_seed_32!(`5`));
    if (results[0].execs == 0)
    { /* if not supplied, execute all algorithms */
        results[0].execs = ALL_ALGORITHMS_MASK;
    }
    /* put in some default values based on one seed only for easy testing */
    if ((results[0].seed1 == 0) && (results[0].seed2 == 0)
        && (results[0].seed3 == 0))
    { /* performance run */
        results[0].seed1 = 0;
        results[0].seed2 = 0;
        results[0].seed3 = 0x66;
    }
    if ((results[0].seed1 == 1) && (results[0].seed2 == 0)
        && (results[0].seed3 == 0))
    { /* validation run */
        results[0].seed1 = 0x3415;
        results[0].seed2 = 0x3415;
        results[0].seed3 = 0x66;
    }
    static if (MEM_METHOD == MEM_STATIC)
    {
        results[0].memblock[0] = cast(void*) static_memblk;
        results[0].size = TOTAL_DATA_SIZE;
        results[0].err = 0;
        static if (MULTITHREAD > 1)
        {
            static assert(0, "Cannot use a static data area with multiple contexts!");
        }
    }
    else static if (MEM_METHOD == MEM_MALLOC)
    {
        for (i = 0; i < MULTITHREAD; i++)
        {
            ee_s32 malloc_override = mixin(get_seed!(`7`));
            if (malloc_override != 0)
                results[i].size = malloc_override;
            else
                results[i].size = TOTAL_DATA_SIZE;
            results[i].memblock[0] = portable_malloc(results[i].size);
            results[i].seed1 = results[0].seed1;
            results[i].seed2 = results[0].seed2;
            results[i].seed3 = results[0].seed3;
            results[i].err = 0;
            results[i].execs = results[0].execs;
        }
    }
    else static if (MEM_METHOD == MEM_STACK)
    {
        for (i = 0; i < MULTITHREAD; i++)
        {
            results[i].memblock[0] = stack_memblock.ptr + i * TOTAL_DATA_SIZE;
            results[i].size = TOTAL_DATA_SIZE;
            results[i].seed1 = results[0].seed1;
            results[i].seed2 = results[0].seed2;
            results[i].seed3 = results[0].seed3;
            results[i].err = 0;
            results[i].execs = results[0].execs;
        }
    }
    else
    {
        static assert(0, "Please define a way to initialize a memory block.");
    }
    /* Data init */
    /* Find out how space much we have based on number of algorithms */
    for (i = 0; i < NUM_ALGORITHMS; i++)
    {
        if ((1 << cast(ee_u32) i) & results[0].execs)
            num_algorithms++;
    }
    for (i = 0; i < MULTITHREAD; i++)
        results[i].size = results[i].size / num_algorithms;
    /* Assign pointers */
    for (i = 0; i < NUM_ALGORITHMS; i++)
    {
        ee_u32 ctx = void;
        if ((1 << cast(ee_u32) i) & results[0].execs)
        {
            for (ctx = 0; ctx < MULTITHREAD; ctx++)
                results[ctx].memblock[i + 1]
                    = cast(char*)(
                        results[ctx].memblock[0]) + results[0].size * j;
            j++;
        }
    }
    /* call inits */
    for (i = 0; i < MULTITHREAD; i++)
    {
        if (results[i].execs & ID_LIST)
        {
            results[i].list = core_list_init(
                results[0].size, cast(list_head*) results[i].memblock[1], results[i].seed1);
        }
        if (results[i].execs & ID_MATRIX)
        {
            core_init_matrix(results[0].size,
                results[i].memblock[2],
                cast(ee_s32) results[i].seed1
                    | ((cast(ee_s32) results[i].seed2) << 16),
                    &(results[i].mat));
        }
        if (results[i].execs & ID_STATE)
        {
            core_init_state(
                results[0].size, results[i].seed1, cast(ee_u8*) results[i].memblock[3]);
        }
    }

    /* automatically determine number of iterations if not set */
    if (results[0].iterations == 0)
    {
        secs_ret secs_passed = 0;
        ee_u32 divisor = void;
        results[0].iterations = 1;
        while (secs_passed < cast(secs_ret) 1)
        {
            results[0].iterations *= 10;
            start_time();
            iterate(&results[0]);
            stop_time();
            secs_passed = time_in_secs(get_time());
        }
        /* now we know it executes for at least 1 sec, set actual run time at
         * about 10 secs */
        divisor = cast(ee_u32) secs_passed;
        if (divisor == 0) /* some machines cast float to int as 0 since this
                             conversion is not defined by ANSI, but we know at
                             least one second passed */
            divisor = 1;
        results[0].iterations *= 1 + 10 / divisor;
    }
    /* perform actual benchmark */
    start_time();
    static if (MULTITHREAD > 1)
    {
        if (default_num_contexts > MULTITHREAD)
        {
            default_num_contexts = MULTITHREAD;
        }
        for (i = 0; i < default_num_contexts; i++)
        {
            results[i].iterations = results[0].iterations;
            results[i].execs = results[0].execs;
            core_start_parallel(&results[i]);
        }
        for (i = 0; i < default_num_contexts; i++)
        {
            core_stop_parallel(&results[i]);
        }
    }
    else
    {
        iterate(&results[0]);
    }
    stop_time();
    total_time = get_time();
    /* get a function of the input to report */
    seedcrc = crc16(cast(ee_s16) results[0].seed1, seedcrc);
    seedcrc = crc16(cast(ee_s16) results[0].seed2, seedcrc);
    seedcrc = crc16(cast(ee_s16) results[0].seed3, seedcrc);
    seedcrc = crc16(cast(ee_s16) results[0].size, seedcrc);

    switch (seedcrc)
    { /* test known output for common seeds */
    case 0x8a02: /* seed1=0, seed2=0, seed3=0x66, size 2000 per algorithm */
        known_id = 0;
        ee_printf("6k performance run parameters for coremark.\n");
        break;
    case 0x7b05: /*  seed1=0x3415, seed2=0x3415, seed3=0x66, size 2000 per
                        algorithm */
        known_id = 1;
        ee_printf("6k validation run parameters for coremark.\n");
        break;
    case 0x4eaf: /* seed1=0x8, seed2=0x8, seed3=0x8, size 400 per algorithm
                      */
        known_id = 2;
        ee_printf("Profile generation run parameters for coremark.\n");
        break;
    case 0xe9f5: /* seed1=0, seed2=0, seed3=0x66, size 666 per algorithm */
        known_id = 3;
        ee_printf("2K performance run parameters for coremark.\n");
        break;
    case 0x18f2: /*  seed1=0x3415, seed2=0x3415, seed3=0x66, size 666 per
                        algorithm */
        known_id = 4;
        ee_printf("2K validation run parameters for coremark.\n");
        break;
    default:
        total_errors = -1;
        break;
    }
    if (known_id >= 0)
    {
        for (i = 0; i < default_num_contexts; i++)
        {
            results[i].err = 0;
            if ((results[i].execs & ID_LIST)
                && (results[i].crclist != list_known_crc[known_id]))
            {
                ee_printf("[%u]ERROR! list crc 0x%04x - should be 0x%04x\n",
                    i,
                    results[i].crclist,
                    list_known_crc[known_id]);
                results[i].err++;
            }
            if ((results[i].execs & ID_MATRIX)
                && (results[i].crcmatrix != matrix_known_crc[known_id]))
            {
                ee_printf("[%u]ERROR! matrix crc 0x%04x - should be 0x%04x\n",
                    i,
                    results[i].crcmatrix,
                    matrix_known_crc[known_id]);
                results[i].err++;
            }
            if ((results[i].execs & ID_STATE)
                && (results[i].crcstate != state_known_crc[known_id]))
            {
                ee_printf("[%u]ERROR! state crc 0x%04x - should be 0x%04x\n",
                    i,
                    results[i].crcstate,
                    state_known_crc[known_id]);
                results[i].err++;
            }
            total_errors += results[i].err;
        }
    }
    total_errors += check_data_types();
    /* and report results */
    ee_printf("CoreMark Size    : %lu\n", cast(c_ulong) results[0].size);
    ee_printf("Total ticks      : %lu\n", cast(c_ulong) total_time);
    static if (HAS_FLOAT)
    {
        ee_printf("Total time (secs): %f\n", time_in_secs(total_time));
        if (time_in_secs(total_time) > 0)
            ee_printf("Iterations/Sec   : %f\n",
                default_num_contexts * results[0].iterations
                    / time_in_secs(total_time));
    }
    else
    {
        ee_printf("Total time (secs): %d\n", time_in_secs(total_time));
        if (time_in_secs(total_time) > 0)
            ee_printf("Iterations/Sec   : %d\n",
                default_num_contexts * results[0].iterations
                    / time_in_secs(total_time));
    }
    if (time_in_secs(total_time) < 10)
    {
        ee_printf(
            "ERROR! Must execute for at least 10 secs for a valid result!\n");
        total_errors++;
    }

    ee_printf("Iterations       : %lu\n",
        cast(c_ulong) default_num_contexts * results[0].iterations);
    ee_printf("Compiler version : %s\n", cast(const(char)*) COMPILER_VERSION);
    ee_printf("Compiler flags   : %s\n", cast(const(char)*) COMPILER_FLAGS);
    static if (MULTITHREAD > 1)
    {
        ee_printf("Parallel %s : %d\n", cast(const(char)*) PARALLEL_METHOD, default_num_contexts);
    }
    ee_printf("Memory location  : %s\n", cast(const(char)*) MEM_LOCATION);
    /* output for verification */
    ee_printf("seedcrc          : 0x%04x\n", seedcrc);
    if (results[0].execs & ID_LIST)
        for (i = 0; i < default_num_contexts; i++)
            ee_printf("[%d]crclist       : 0x%04x\n", i, results[i].crclist);
    if (results[0].execs & ID_MATRIX)
        for (i = 0; i < default_num_contexts; i++)
            ee_printf("[%d]crcmatrix     : 0x%04x\n", i, results[i].crcmatrix);
    if (results[0].execs & ID_STATE)
        for (i = 0; i < default_num_contexts; i++)
            ee_printf("[%d]crcstate      : 0x%04x\n", i, results[i].crcstate);
    for (i = 0; i < default_num_contexts; i++)
        ee_printf("[%d]crcfinal      : 0x%04x\n", i, results[i].crc);
    if (total_errors == 0)
    {
        ee_printf(
            "Correct operation validated. See README.md for run and reporting "
                ~ "rules.\n");
        static if (HAS_FLOAT)
        {
            if (known_id == 3)
            {
                ee_printf("CoreMark 1.0 : %f / %s %s",
                    default_num_contexts * results[0].iterations
                        / time_in_secs(total_time),
                        cast(const(char)*) COMPILER_VERSION,
                        cast(const(char)*) COMPILER_FLAGS);
                static if (HasVersion!"MEM_LOCATION" && !HasVersion!"MEM_LOCATION_UNSPEC")
                {
                    ee_printf(" / %s", cast(const(char)*) MEM_LOCATION);
                }
                else
                {
                    ee_printf(" / %s", mem_name[MEM_METHOD]);
                }

                static if (MULTITHREAD > 1)
                {
                    ee_printf(" / %d:%s", default_num_contexts, cast(const(char)*) PARALLEL_METHOD);
                }
                ee_printf("\n");
            }
        }
    }
    if (total_errors > 0)
        ee_printf("Errors detected\n");
    if (total_errors < 0)
        ee_printf(
            "Cannot validate operation for these seed values, please compare "
                ~ "with results on a known platform.\n");

    static if (MEM_METHOD == MEM_MALLOC)
    {
        for (i = 0; i < MULTITHREAD; i++)
            portable_free(results[i].memblock[0]);
    }
    /* And last call any target specific code for finalizing */
    portable_fini(&(results[0].port));

    return MAIN_RETURN_VAL;
}
