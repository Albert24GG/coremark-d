module posix.core_portme;
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

import core.stdc.stdio;
import core.stdc.stdlib;
import coremark;

version (CALLGRIND_RUN)
{

    void callgrind_start();
    void callgrind_stop();

}

static if (MEM_METHOD == MEM_MALLOC)
{
    /* Function: portable_malloc
        Provide malloc() functionality in a platform specific way.
*/
    void* portable_malloc(size_t size)
    {
        return malloc(size);
    }
    /* Function: portable_free
        Provide free() functionality in a platform specific way.
*/
    void portable_free(void* p)
    {
        free(p);
    }
}
else
{
    void* portable_malloc(size_t size)
    {
        return null;
    }

    void portable_free(void* p)
    {
        p = null;
    }
}

static if ((SEED_METHOD == SEED_VOLATILE))
{
    static if (VALIDATION_RUN)
    {
        /*volatile*/
        ee_s32 seed1_volatile = 0x3415;
        /*volatile*/
        ee_s32 seed2_volatile = 0x3415;
        /*volatile*/
        ee_s32 seed3_volatile = 0x66;
    }
    static if (PERFORMANCE_RUN)
    {
        /*volatile*/
        ee_s32 seed1_volatile = 0x0;
        /*volatile*/
        ee_s32 seed2_volatile = 0x0;
        /*volatile*/
        ee_s32 seed3_volatile = 0x66;
    }
    static if (PROFILE_RUN)
    {
        /*volatile*/
        ee_s32 seed1_volatile = 0x8;
        /*volatile*/
        ee_s32 seed2_volatile = 0x8;
        /*volatile*/
        ee_s32 seed3_volatile = 0x8;
    }
    /*volatile*/
    ee_s32 seed4_volatile = ITERATIONS;
    /*volatile*/
    ee_s32 seed5_volatile = 0;
}
/* Porting: Timing functions
        How to capture time and convert to seconds must be ported to whatever is
   supported by the platform. e.g. Read value from on board RTC, read value from
   cpu clock cycles performance counter etc. Sample implementation for standard
   time.h and windows.h definitions included.
*/
/* Define: TIMER_RES_DIVIDER
        Divider to trade off timer resolution and total time that can be
   measured.

        Use lower values to increase resolution, but make sure that overflow
   does not occur. If there are issues with the return value overflowing,
   increase this value.
        */
static if (USE_CLOCK)
{
    enum NSECS_PER_SEC = CLOCKS_PER_SEC;
    enum EE_TIMER_TICKER_RATE = 1_000;
    alias CORETIMETYPE = clock_t;
    enum string GETMYTIME(string _t) = `(*` ~ _t ~ ` = clock())`;
    enum string MYTIMEDIFF(string fin, string ini) = `((` ~ fin ~ `) - (` ~ ini ~ `))`;
    enum TIMER_RES_DIVIDER = 1;
    enum SAMPLE_TIME_IMPLEMENTATION = 1;
}
else version (_MSC_VER)
{
    enum NSECS_PER_SEC = 10_000_000;
    enum EE_TIMER_TICKER_RATE = 1_000;
    alias CORETIMETYPE = FILETIME;
    enum string GETMYTIME(string _t) = `GetSystemTimeAsFileTime(` ~ _t ~ `);`;
    enum string MYTIMEDIFF(string fin, string ini) = `
    (((*cast(long*)&`
        ~ fin ~ `) - (*cast(long*)&` ~ ini ~ `)) / TIMER_RES_DIVIDER)`;
    /* setting to millisces resolution by default with MSDEV */
    enum TIMER_RES_DIVIDER = 1_000;

    enum SAMPLE_TIME_IMPLEMENTATION = 1;
}
else static if (HAS_TIME_H)
{
    import core.sys.posix.time;

    enum NSECS_PER_SEC = 1_000_000_000;
    enum EE_TIMER_TICKER_RATE = 1_000;
    alias CORETIMETYPE = timespec;
    enum string GETMYTIME(string _t) = `clock_gettime(CLOCK_REALTIME, ` ~ _t ~ `);`;
    enum string MYTIMEDIFF(string fin, string ini) = `
    ((`
        ~ fin ~ `.tv_sec - ` ~ ini ~ `.tv_sec) * (NSECS_PER_SEC / TIMER_RES_DIVIDER) 
     + (`
        ~ fin ~ `.tv_nsec - ` ~ ini ~ `.tv_nsec) / TIMER_RES_DIVIDER)`;
    /* setting to 1/1000 of a second resolution by default with linux */
    enum TIMER_RES_DIVIDER = 1_000_000;

    enum SAMPLE_TIME_IMPLEMENTATION = 1;
}
else
{
    enum SAMPLE_TIME_IMPLEMENTATION = 0;
}
enum EE_TICKS_PER_SEC = (NSECS_PER_SEC / TIMER_RES_DIVIDER);

static if (SAMPLE_TIME_IMPLEMENTATION)
{
    /** Define Host specific (POSIX), or target specific global time variables. */
    private CORETIMETYPE start_time_val, stop_time_val;

    /* Function: start_time
        This function will be called right before starting the timed portion of
   the benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or zeroing some system parameters - e.g. setting the cpu clocks
   cycles to 0.
*/
    void start_time()
    {
        mixin(GETMYTIME!(`&start_time_val`));
        version (CALLGRIND_RUN)
        {
            callgrind_start();
        }

        version (MICA)
        {
            asm
            {
                int3;
            }
        }
    }
    /* Function: stop_time
        This function will be called right after ending the timed portion of the
   benchmark.

        Implementation may be capturing a system timer (as implemented in the
   example code) or other system parameters - e.g. reading the current value of
   cpu cycles counter.
*/
    void stop_time()
    {
        version (CALLGRIND_RUN)
        {
            callgrind_stop();
        }

        version (MICA)
        {
            asm
            {
                int3;
            }
        }
        mixin(GETMYTIME!(`&stop_time_val`));
    }
    /* Function: get_time
        Return an abstract "ticks" number that signifies time on the system.

        Actual value returned may be cpu cycles, milliseconds or any other
   value, as long as it can be converted to seconds by <time_in_secs>. This
   methodology is taken to accommodate any hardware or simulated platform. The
   sample implementation returns millisecs by default, and the resolution is
   controlled by <TIMER_RES_DIVIDER>
*/
    CORE_TICKS get_time()
    {
        CORE_TICKS elapsed = cast(CORE_TICKS)(mixin(MYTIMEDIFF!(`stop_time_val`, `start_time_val`)));
        return elapsed;
    }
    /* Function: time_in_secs
        Convert the value returned by get_time to seconds.

        The <secs_ret> type is used to accommodate systems with no support for
   floating point. Default implementation implemented by the EE_TICKS_PER_SEC
   macro above.
*/
    secs_ret time_in_secs(CORE_TICKS ticks)
    {
        secs_ret retval = (cast(secs_ret) ticks) / cast(secs_ret) EE_TICKS_PER_SEC;
        return retval;
    }
}
else
{
    static assert(0, "Please implement timing functionality in core_portme.c");
} /* SAMPLE_TIME_IMPLEMENTATION */

ee_u32 default_num_contexts = MULTITHREAD;

/* Function: portable_init
        Target specific initialization code
        Test for some common mistakes.
*/
void portable_init(core_portable* p, int* argc, char** argv)
{

    version (PRINT_ARGS)
    {
        int i = void;
        for (i = 0; i < *argc; i++)
        {
            ee_printf("Arg[%d]=%s\n", i, argv[i]);
        }
    }

    cast(void) argc; // prevent unused warning
    cast(void) argv; // prevent unused warning

    if (ee_ptr_int.sizeof != (ee_u8*).sizeof)
    {
        ee_printf(
            "ERROR! Please define ee_ptr_int to a type that holds a "
                ~ "pointer!\n");
    }
    if (ee_u32.sizeof != 4)
    {
        ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
    }
    static if ((MAIN_HAS_NOARGC && (SEED_METHOD == SEED_ARG)))
    {
        ee_printf(
            "ERROR! Main has no argc, but SEED_METHOD defined to SEED_ARG!\n");
    }

    static if ((MULTITHREAD > 1) && (SEED_METHOD == SEED_ARG))
    {
        int nargs = *argc, i = void;
        if ((nargs > 1) && (*argv[1] == 'M'))
        {
            default_num_contexts = parseval(argv[1] + 1);
            if (default_num_contexts > MULTITHREAD)
                default_num_contexts = MULTITHREAD;
            /* Shift args since first arg is directed to the portable part and not
         * to coremark main */
            --nargs;
            for (i = 1; i < nargs; i++)
                argv[i] = argv[i + 1];
            *argc = nargs;
        }
    } /* sample of potential platform specific init via command line, reset \
          the number of contexts being used if first argument is M<n>*/
    p.portable_id = 1;
}
/* Function: portable_fini
        Target specific final code
*/
void portable_fini(core_portable* p)
{
    p.portable_id = 0;
}

static if ((MULTITHREAD > 1))
{

    /* Function: core_start_parallel
        Start benchmarking in a parallel context.

        Three implementations are provided, one using pthreads, one using fork
   and shared mem, and one using fork and sockets. Other implementations using
   MCAPI or other standards can easily be devised.
*/
    /* Function: core_stop_parallel
        Stop a parallel context execution of coremark, and gather the results.

        Three implementations are provided, one using pthreads, one using fork
   and shared mem, and one using fork and sockets. Other implementations using
   MCAPI or other standards can easily be devised.
*/
    static if (USE_PTHREAD)
    {
        ee_u8 core_start_parallel(core_results* res)
        {
            return cast(ee_u8) pthread_create(
                &(res.port.thread), null, iterate, cast(void*) res);
        }

        ee_u8 core_stop_parallel(core_results* res)
        {
            void* retval = void;
            return cast(ee_u8) pthread_join(res.port.thread, &retval);
        }
    }
    else static if (USE_FORK)
    {
        import std.conv : octal;

        private int key_id = 0;
        ee_u8 core_start_parallel(core_results* res)
        {
            key_t key = 4321 + key_id;
            key_id++;
            res.port.pid = fork();
            res.port.shmid = shmget(key, 8, IPC_CREAT | octal!"0666");
            if (res.port.shmid < 0)
            {
                ee_printf("ERROR in shmget!\n");
            }
            if (res.port.pid == 0)
            {
                iterate(res);
                res.port.shm = shmat(res.port.shmid, null, 0);
                /* copy the validation values to the shared memory area  and quit*/
                if (res.port.shm == cast(char*)-1)
                {
                    ee_printf("ERROR in child shmat!\n");
                }
                else
                {
                    memcpy(res.port.shm, &(res.crc), 8);
                    shmdt(res.port.shm);
                }
                exit(0);
            }
            return 1;
        }

        ee_u8 core_stop_parallel(core_results* res)
        {
            int status = void;
            pid_t wpid = waitpid(res.port.pid, &status, WUNTRACED);
            if (wpid != res.port.pid)
            {
                ee_printf("ERROR waiting for child.\n");
                if (errno == ECHILD)
                    ee_printf("errno=No such child %d\n", res.port.pid);
                if (errno == EINTR)
                    ee_printf("errno=Interrupted\n");
                return 0;
            }
            /* after process is done, get the values from the shared memory area */
            res.port.shm = shmat(res.port.shmid, null, 0);
            if (res.port.shm == cast(char*)-1)
            {
                ee_printf("ERROR in parent shmat!\n");
                return 0;
            }
            memcpy(&(res.crc), res.port.shm, 8);
            shmdt(res.port.shm);
            return 1;
        }
    }
    else static if (USE_SOCKET)
    {
        private int key_id = 0;
        ee_u8 core_start_parallel(core_results* res)
        {
            int bound = void, buffer_length = 8;
            res.port.sa.sin_family = AF_INET;
            res.port.sa.sin_addr.s_addr = htonl(0x7F000001);
            res.port.sa.sin_port = htons(7654 + key_id);
            key_id++;
            res.port.pid = fork();
            if (res.port.pid == 0)
            { /* benchmark child */
                iterate(res);
                res.port.sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
                if (-1 == res.port.sock) /* if socket failed to initialize, exit */
                {
                    ee_printf("Error Creating Socket");
                }
                else
                {
                    int bytes_sent = sendto(res.port.sock,
                        &(res.crc),
                        buffer_length,
                        0,
                        cast(sockaddr*)&(res.port.sa),
                        sockaddr_in.sizeof);
                    if (bytes_sent < 0)
                        ee_printf("Error sending packet: %s\n", strerror(errno));
                    close(res.port.sock); /* close the socket */
                }
                exit(0);
            }
            /* parent process, open the socket */
            res.port.sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
            bound = bind(res.port.sock,
                cast(sockaddr*)&(res.port.sa),
                sockaddr.sizeof);
            if (bound < 0)
                ee_printf("bind(): %s\n", strerror(errno));
            return 1;
        }

        ee_u8 core_stop_parallel(core_results* res)
        {
            int status = void;
            int fromlen = sockaddr.sizeof;
            int recsize = recvfrom(res.port.sock,
                &(res.crc),
                8,
                0,
                cast(sockaddr*)&(res.port.sa),
                &fromlen);
            if (recsize < 0)
            {
                ee_printf("Error in receive: %s\n", strerror(errno));
                return 0;
            }
            pid_t wpid = waitpid(res.port.pid, &status, WUNTRACED);
            if (wpid != res.port.pid)
            {
                ee_printf("ERROR waiting for child.\n");
                if (errno == ECHILD)
                    ee_printf("errno=No such child %d\n", res.port.pid);
                if (errno == EINTR)
                    ee_printf("errno=Interrupted\n");
                return 0;
            }
            return 1;
        }
    }
    else
    { /* no standard multicore implementation */
        static assert(0, "Please implement multicore functionality in core_portme.c to use multiple contexts.");
    } /* multithread implementations */
}
