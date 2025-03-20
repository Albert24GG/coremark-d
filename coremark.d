module coremark;
@nogc nothrow:
extern (C):
__gshared:
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

/* Topic: Description
        This file contains  declarations of the various benchmark functions.
*/

/* Configuration: TOTAL_DATA_SIZE
        Define total size for data algorithms will operate on
*/
enum TOTAL_DATA_SIZE = 2 * 1000;

enum SEED_ARG = 0;
enum SEED_FUNC = 1;
enum SEED_VOLATILE = 2;

enum MEM_STATIC = 0;
enum MEM_MALLOC = 1;
enum MEM_STACK = 2;

public import posix.core_portme_h;

static if (HAS_STDIO)
{
    public import core.stdc.stdio;
}
static if (HAS_PRINTF)
{
    alias ee_printf = printf;
}

/* Actual benchmark execution in iterate */
void* iterate(void* pres);

/* Typedef: secs_ret
        For machines that have floating point support, get number of seconds as
   a double. Otherwise an unsigned int.
*/
static if (HAS_FLOAT)
{
    alias secs_ret = double;
}
else
{
    alias secs_ret = ee_u32;
}

static if (MAIN_HAS_NORETURN)
{
    version = MAIN_RETURN_VAL;
    enum MAIN_RETURN_TYPE = void;
}
else
{
    enum MAIN_RETURN_VAL = 0;
    alias MAIN_RETURN_TYPE = int;
}

void start_time();
void stop_time();
CORE_TICKS get_time();
secs_ret time_in_secs(CORE_TICKS ticks);

/* Misc useful functions */
ee_u16 crcu8(ee_u8 data, ee_u16 crc);
ee_u16 crc16(ee_s16 newval, ee_u16 crc);
ee_u16 crcu16(ee_u16 newval, ee_u16 crc);
ee_u16 crcu32(ee_u32 newval, ee_u16 crc);
ee_u8 check_data_types();
void* portable_malloc(ee_size_t size);
void portable_free(void* p);
ee_s32 parseval(char* valstring);

/* Algorithm IDS */
enum ID_LIST = (1 << 0);
enum ID_MATRIX = (1 << 1);
enum ID_STATE = (1 << 2);
enum ALL_ALGORITHMS_MASK = (ID_LIST | ID_MATRIX | ID_STATE);
enum NUM_ALGORITHMS = 3;

/* list data structures */
struct list_data
{
    ee_s16 data16;
    ee_s16 idx;
}

alias list_data_s = list_data;

struct list_head
{
    list_head_s* next;
    list_data_s* info;
}

alias list_head_s = list_head;

/*matrix benchmark related stuff */
enum MATDAT_INT = 1;
static if (MATDAT_INT)
{
    alias MATDAT = ee_s16;
    alias MATRES = ee_s32;
}
else
{
    alias MATDAT = ee_f16;
    alias MATRES = ee_f32;
}

struct mat_params
{
    int N;
    MATDAT* A;
    MATDAT* B;
    MATRES* C;
}

/* state machine related stuff */
/* List of all the possible states for the FSM */
enum core_state_e
{
    CORE_START = 0,
    CORE_INVALID,
    CORE_S1,
    CORE_S2,
    CORE_INT,
    CORE_FLOAT,
    CORE_EXPONENT,
    CORE_SCIENTIFIC,
    NUM_CORE_STATES
}

alias CORE_STATE = core_state_e;

alias CORE_START = core_state_e.CORE_START;
alias CORE_INVALID = core_state_e.CORE_INVALID;
alias CORE_S1 = core_state_e.CORE_S1;
alias CORE_S2 = core_state_e.CORE_S2;
alias CORE_INT = core_state_e.CORE_INT;
alias CORE_FLOAT = core_state_e.CORE_FLOAT;
alias CORE_EXPONENT = core_state_e.CORE_EXPONENT;
alias CORE_SCIENTIFIC = core_state_e.CORE_SCIENTIFIC;
alias NUM_CORE_STATES = core_state_e.NUM_CORE_STATES;

/* Helper structure to hold results */
struct core_results
{
    /* inputs */
    ee_s16 seed1; /* Initializing seed */
    ee_s16 seed2; /* Initializing seed */
    ee_s16 seed3; /* Initializing seed */
    void*[4] memblock; /* Pointer to safe memory location */
    ee_u32 size; /* Size of the data */
    ee_u32 iterations; /* Number of iterations to execute */
    ee_u32 execs; /* Bitmask of operations to execute */
    list_head_s* list;
    mat_params mat;
    /* outputs */
    ee_u16 crc;
    ee_u16 crclist;
    ee_u16 crcmatrix;
    ee_u16 crcstate;
    ee_s16 err;
    /* ultithread specific */
    core_portable port;
}

/* Multicore execution handling */
static if (MULTITHREAD > 1)
{
    ee_u8 core_start_parallel(core_results* res);
    ee_u8 core_stop_parallel(core_results* res);
}

/* list benchmark functions */
list_head* core_list_init(ee_u32 blksize, list_head* memblock, ee_s16 seed);
ee_u16 core_bench_list(core_results* res, ee_s16 finder_idx);

/* state benchmark functions */
void core_init_state(ee_u32 size, ee_s16 seed, ee_u8* p);
ee_u16 core_bench_state(ee_u32 blksize, ee_u8* memblock, ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc);

/* matrix benchmark functions */
ee_u32 core_init_matrix(ee_u32 blksize, void* memblk, ee_s32 seed, mat_params* p);
ee_u16 core_bench_matrix(mat_params* p, ee_s16 seed, ee_u16 crc);
