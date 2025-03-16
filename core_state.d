module core_state;
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

import coremark;

/* local functions */

/*
Topic: Description
        Simple state machines like this one are used in many embedded products.

        For more complex state machines, sometimes a state transition table
implementation is used instead, trading speed of direct coding for ease of
maintenance.

        Since the main goal of using a state machine in CoreMark is to excercise
the switch/if behaviour, we are using a small moore machine.

        In particular, this machine tests type of string input,
        trying to determine whether the input is a number or something else.
        (see core_state.png).
*/

/* Function: core_bench_state
        Benchmark function

        Go over the input twice, once direct, and once after introducing some
   corruption.
*/
ee_u16 core_bench_state(ee_u32 blksize, ee_u8* memblock, ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc)
{
    ee_u32[NUM_CORE_STATES] final_counts = void;
    ee_u32[NUM_CORE_STATES] track_counts = void;
    ee_u8* p = memblock;
    ee_u32 i = void;

    static if (CORE_DEBUG)
    {
        ee_printf("State Bench: %d,%d,%d,%04x\n", seed1, seed2, step, crc);
    }
    for (i = 0; i < NUM_CORE_STATES; i++)
    {
        final_counts[i] = track_counts[i] = 0;
    }
    /* run the state machine over the input */
    while (*p != 0)
    {
        CORE_STATE fstate = core_state_transition(&p, track_counts.ptr);
        final_counts[fstate]++;
        static if (CORE_DEBUG)
        {
            ee_printf("%d,", fstate);
        }
    }
    static if (CORE_DEBUG)
    {
        ee_printf("\n");
    }

    //! #endif
    p = memblock;
    while (p < (memblock + blksize))
    { /* insert some corruption */
        if (*p != ',')

            *p ^= cast(ee_u8) seed1;
        p += step;
    }
    p = memblock;
    /* run the state machine over the input again */
    while (*p != 0)
    {
        CORE_STATE fstate = core_state_transition(&p, track_counts.ptr);
        final_counts[fstate]++;
        static if (CORE_DEBUG)
        {
            ee_printf("%d,", fstate);
        }
    }
    static if (CORE_DEBUG)
    {
        ee_printf("\n");
    }

    //! #endif
    p = memblock;
    while (p < (memblock + blksize))
    { /* undo corruption is seed1 and seed2 are equal */
        if (*p != ',')

            *p ^= cast(ee_u8) seed2;
        p += step;
    }
    /* end timing */
    for (i = 0; i < NUM_CORE_STATES; i++)
    {
        crc = crcu32(final_counts[i], crc);
        crc = crcu32(track_counts[i], crc);
    }
    return crc;
}

/* Default initialization patterns */
private ee_u8*[4] intpat = [
    cast(ee_u8*) "5012", cast(ee_u8*) "1234", cast(ee_u8*) "-874",
    cast(ee_u8*) "+122"
];
private ee_u8*[4] floatpat = [
    cast(ee_u8*) "35.54400",
    cast(ee_u8*) ".1234500",
    cast(ee_u8*) "-110.700",
    cast(ee_u8*) "+0.64400"
];
private ee_u8*[4] scipat = [
    cast(ee_u8*) "5.500e+3",
    cast(ee_u8*) "-.123e-2",
    cast(ee_u8*) "-87e+832",
    cast(ee_u8*) "+0.6e-12"
];
private ee_u8*[4] errpat = [
    cast(ee_u8*) "T0.3e-1F",
    cast(ee_u8*) "-T.T++Tq",
    cast(ee_u8*) "1T3.4e4z",
    cast(ee_u8*) "34.0e-T^"
];

/* Function: core_init_state
        Initialize the input data for the state machine.

        Populate the input with several predetermined strings, interspersed.
        Actual patterns chosen depend on the seed parameter.

        Note:
        The seed parameter MUST be supplied from a source that cannot be
   determined at compile time
*/
void core_init_state(ee_u32 size, ee_s16 seed, ee_u8* p)
{
    ee_u32 total = 0, next = 0, i = void;
    ee_u8* buf = null;
    static if (CORE_DEBUG)
    {
        ee_u8* start = p;
        ee_printf("State: %d,%d\n", size, seed);
    }
    size--;
    next = 0;
    while ((total + next + 1) < size)
    {
        if (next > 0)
        {
            for (i = 0; i < next; i++)
                *(p + total + i) = buf[i];
            *(p + total + i) = ',';
            total += next + 1;
        }
        seed++;
        switch (seed & 0x7)
        {
        case 0: /* int */
        case 1: /* int */
        case 2: /* int */
            buf = intpat[(seed >> 3) & 0x3];
            next = 4;
            break;
        case 3: /* float */
        case 4: /* float */
            buf = floatpat[(seed >> 3) & 0x3];
            next = 8;
            break;
        case 5: /* scientific */
        case 6: /* scientific */
            buf = scipat[(seed >> 3) & 0x3];
            next = 8;
            break;
        case 7: /* invalid */
            buf = errpat[(seed >> 3) & 0x3];
            next = 8;
            break;
        default: /* Never happen, just to make some compilers happy */
            break;
        }
    }
    size++;
    while (total < size)
    { /* fill the rest with 0 */
        *(p + total) = 0;
        total++;
    }
    static if (CORE_DEBUG)
    {
        ee_printf("State Input: %s\n", start);
    }
}

private ee_u8 ee_isdigit(ee_u8 c)
{
    ee_u8 retval = void;
    retval = ((c >= '0') & (c <= '9')) ? 1 : 0;
    return retval;
}

/* Function: core_state_transition
        Actual state machine.

        The state machine will continue scanning until either:
        1 - an invalid input is detected.
        2 - a valid number has been detected.

        The input pointer is updated to point to the end of the token, and the
   end state is returned (either specific format determined or invalid).
*/

CORE_STATE core_state_transition(ee_u8** instr, ee_u32* transition_count)
{
    ee_u8* str = *instr;
    ee_u8 NEXT_SYMBOL = void;
    CORE_STATE state = CORE_START;
    for (; *str && state != CORE_INVALID; str++)
    {
        NEXT_SYMBOL = *str;
        if (NEXT_SYMBOL == ',') /* end of this input */
        {
            str++;
            break;
        }
        switch (state)
        {
        case CORE_START:
            if (ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_INT;
            }
            else if (NEXT_SYMBOL == '+' || NEXT_SYMBOL == '-')
            {
                state = CORE_S1;
            }
            else if (NEXT_SYMBOL == '.')
            {
                state = CORE_FLOAT;
            }
            else
            {
                state = CORE_INVALID;
                transition_count[CORE_INVALID]++;
            }
            transition_count[CORE_START]++;
            break;
        case CORE_S1:
            if (ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_INT;
                transition_count[CORE_S1]++;
            }
            else if (NEXT_SYMBOL == '.')
            {
                state = CORE_FLOAT;
                transition_count[CORE_S1]++;
            }
            else
            {
                state = CORE_INVALID;
                transition_count[CORE_S1]++;
            }
            break;
        case CORE_INT:
            if (NEXT_SYMBOL == '.')
            {
                state = CORE_FLOAT;
                transition_count[CORE_INT]++;
            }
            else if (!ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_INVALID;
                transition_count[CORE_INT]++;
            }
            break;
        case CORE_FLOAT:
            if (NEXT_SYMBOL == 'E' || NEXT_SYMBOL == 'e')
            {
                state = CORE_S2;
                transition_count[CORE_FLOAT]++;
            }
            else if (!ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_INVALID;
                transition_count[CORE_FLOAT]++;
            }
            break;
        case CORE_S2:
            if (NEXT_SYMBOL == '+' || NEXT_SYMBOL == '-')
            {
                state = CORE_EXPONENT;
                transition_count[CORE_S2]++;
            }
            else
            {
                state = CORE_INVALID;
                transition_count[CORE_S2]++;
            }
            break;
        case CORE_EXPONENT:
            if (ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_SCIENTIFIC;
                transition_count[CORE_EXPONENT]++;
            }
            else
            {
                state = CORE_INVALID;
                transition_count[CORE_EXPONENT]++;
            }
            break;
        case CORE_SCIENTIFIC:
            if (!ee_isdigit(NEXT_SYMBOL))
            {
                state = CORE_INVALID;
                transition_count[CORE_INVALID]++;
            }
            break;
        default:
            break;
        }
    }
    *instr = str;
    return state;
}
