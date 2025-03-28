module posix.core_portme_h;
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
        This file contains configuration constants required to execute on
   different platforms
*/

public import posix.core_portme_posix_overrides_h;

/************************/
/* Data types and settings */
/************************/
/* Configuration: HAS_FLOAT
        Define to 1 if the platform supports floating point.
*/
enum HAS_FLOAT = 1;

/* Configuration: HAS_TIME_H
        Define to 1 if platform has the time.h header file,
        and implementation of functions thereof.
*/
enum HAS_TIME_H = 1;

/* Configuration: USE_CLOCK
        Define to 1 if platform has the time.h header file,
        and implementation of functions thereof.
*/
enum USE_CLOCK = 0;

/* Configuration: HAS_STDIO
        Define to 1 if the platform has stdio.h.
*/
enum HAS_STDIO = 1;

/* Configuration: HAS_PRINTF
        Define to 1 if the platform has stdio.h and implements the printf
   function.
*/
enum HAS_PRINTF = 1;

/* Configuration: CORE_TICKS
        Define type of return from the timing functions.
 */
version (Windows)
{
    public import core.sys.windows.windows;

    alias CORE_TICKS = size_t;
}
else static if (HAS_TIME_H)
{
    public import core.stdc.time;

    alias CORE_TICKS = clock_t;
}
else
{
    static assert(0, "Please define type of CORE_TICKS and implement start_time, end_time get_time and time_in_secs functions!");
}

/* Definitions: COMPILER_VERSION, COMPILER_FLAGS, MEM_LOCATION
        Initialize these strings per platform
*/
version (COMPILER_VERSION)
{
}
else
{
    version (LDC)
    {
        import std.conv;

        enum COMPILER_VERSION = to!string(__VERSION__);
    }
    else version (GNU)
    {
        import std.conv;

        enum COMPILER_VERSION = "GCC" ~ to!string(__VERSION__);
    }
    else
    {
        enum COMPILER_VERSION = "Please put compiler version here (e.g. gcc 4.1)";
    }
}

// TODO: figure this out
enum COMPILER_FLAGS = "" /* "Please put compiler flags here (e.g. -o3)" */ ;

version (MEM_LOCATION)
{
}
else
{
    enum MEM_LOCATION = "Please put data memory location here\n\t\t\t(e.g. code in flash, data on heap etc)";
    enum MEM_LOCATION_UNSPEC = 1;
}

public import core.stdc.stdint;

/* Data Types:
        To avoid compiler issues, define the data types that need ot be used for
   8b, 16b and 32b in <core_portme.h>.

        *Imprtant*:
        ee_ptr_int needs to be the data type used to hold pointers, otherwise
   coremark may fail!!!
*/
alias ee_s16 = short;
alias ee_u16 = ushort;
alias ee_s32 = int;
alias ee_f32 = double;
alias ee_u8 = ubyte;
alias ee_u32 = uint;
alias ee_ptr_int = uintptr_t;
alias ee_size_t = size_t;
/* align an offset to point to a 32b value */
enum string align_mem(string x) = `cast(void*)(4 + ((cast(ee_ptr_int)(` ~ x ~ `)-1) & ~3))`;

/* Configuration: SEED_METHOD
        Defines method to get seed values that cannot be computed at compile
   time.

        Valid values:
        SEED_ARG - from command line.
        SEED_FUNC - from a system function.
        SEED_VOLATILE - from volatile variables.
*/
// TODO: figure this out
/* enum SEED_METHOD = SEED_ARG; */
enum SEED_METHOD = 0;

/* Configuration: MEM_METHOD
        Defines method to get a block of memry.

        Valid values:
        MEM_MALLOC - for platforms that implement malloc and have malloc.h.
        MEM_STATIC - to use a static memory array.
        MEM_STACK - to allocate the data block on the stack (NYI).
*/
// TODO: figure this out
/* enum MEM_METHOD = MEM_MALLOC; */
enum MEM_METHOD = 1;

/* Configuration: MULTITHREAD
        Define for parallel execution

        Valid values:
        1 - only one context (default).
        N>1 - will execute N copies in parallel.

        Note:
        If this flag is defined to more then 1, an implementation for launching
   parallel contexts must be defined.

        Two sample implementations are provided. Use <USE_PTHREAD> or <USE_FORK>
   to enable them.

        It is valid to have a different implementation of <core_start_parallel>
   and <core_end_parallel> in <core_portme.c>, to fit a particular architecture.
*/
enum MULTITHREAD = 1;

/* Configuration: USE_PTHREAD
        Sample implementation for launching parallel contexts
        This implementation uses pthread_thread_create and pthread_join.

        Valid values:
        0 - Do not use pthreads API.
        1 - Use pthreads API

        Note:
        This flag only matters if MULTITHREAD has been defined to a value
   greater then 1.
*/
enum USE_PTHREAD = 0;

/* Configuration: USE_FORK
        Sample implementation for launching parallel contexts
        This implementation uses fork, waitpid, shmget,shmat and shmdt.

        Valid values:
        0 - Do not use fork API.
        1 - Use fork API

        Note:
        This flag only matters if MULTITHREAD has been defined to a value
   greater then 1.
*/
enum USE_FORK = 0;

/* Configuration: USE_SOCKET
        Sample implementation for launching parallel contexts
        This implementation uses fork, socket, sendto and recvfrom

        Valid values:
        0 - Do not use fork and sockets API.
        1 - Use fork and sockets API

        Note:
        This flag only matters if MULTITHREAD has been defined to a value
   greater then 1.
*/
enum USE_SOCKET = 0;

/* Configuration: MAIN_HAS_NOARGC
        Needed if platform does not support getting arguments to main.

        Valid values:
        0 - argc/argv to main is supported
        1 - argc/argv to main is not supported
*/
enum MAIN_HAS_NOARGC = 0;

/* Configuration: MAIN_HAS_NORETURN
        Needed if platform does not support returning a value from main.

        Valid values:
        0 - main returns an int, and return value will be 0.
        1 - platform does not support returning a value from main
*/
enum MAIN_HAS_NORETURN = 0;

/* Variable: default_num_contexts
        Number of contexts to spawn in multicore context.
        Override this global value to change number of contexts used.

        Note:
        This value may not be set higher then the <MULTITHREAD> define.

        To experiment, you can set the <MULTITHREAD> define to the highest value
   expected, and use argc/argv in the <portable_init> to set this value from the
   command line.
*/
extern ee_u32 default_num_contexts;

static if (MULTITHREAD > 1)
{
    static if (USE_PTHREAD)
    {
        public import core.sys.posix.pthread;

        enum PARALLEL_METHOD = "PThreads";
    }
    else static if (USE_FORK)
    {
        public import core.sys.posix.unistd;
        public import core.stdc.errno;
        public import core.sys.posix.sys.wait;
        public import core.sys.posix.sys.shm;
        public import core.stdc.string; /* for memcpy */
        enum PARALLEL_METHOD = "Fork";
    }
    else static if (USE_SOCKET)
    {
        public import core.sys.posix.sys.types;
        public import core.sys.posix.sys.socket;
        public import core.sys.posix.netinet.in_;
        public import core.sys.posix.arpa.inet;
        public import core.sys.posix.sys.wait;
        public import core.stdc.stdio;
        public import core.stdc.stdlib;
        public import core.stdc.string;
        public import core.sys.posix.unistd;
        public import core.stdc.errno;

        enum PARALLEL_METHOD = "Sockets";
    }
    else
    {
        enum PARALLEL_METHOD = "Proprietary";
        static assert(0, "Please implement multicore functionality in core_portme.c to use multiple contexts.");
    } /* Method for multithreading */
} /* MULTITHREAD > 1 */

struct core_portable
{
    static if (MULTITHREAD > 1)
    {
        static if (USE_PTHREAD)
        {
            pthread_t thread;
        }
        else static if (USE_FORK)
        {
            pid_t pid;
            int shmid;
            void* shm;
        }
        else static if (USE_SOCKET)
        {
            pid_t pid;
            int sock;
            sockaddr_in sa;
        } /* Method for multithreading */
    } /* MULTITHREAD>1 */
    ee_u8 portable_id;
}

/* target specific init/fini */
void portable_init(core_portable* p, int* argc, char** argv);
void portable_fini(core_portable* p);

// TODO: figure this out
/* static if (SEED_METHOD == SEED_VOLATILE) */
static if (SEED_METHOD == 2)
{
    static if (VALIDATION_RUN || PERFORMANCE_RUN || PROFILE_RUN)
    {
        enum RUN_TYPE_FLAG = 1;
    }
    else
    {
        static if (TOTAL_DATA_SIZE == 1200)
        {
            enum PROFILE_RUN = 1;
        }
        else
        {
            enum PERFORMANCE_RUN = 1;
        }
    }
} /* SEED_METHOD==SEED_VOLATILE */

/* CORE_PORTME_H */
