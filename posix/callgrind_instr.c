#include <valgrind/callgrind.h>

void callgrind_start() { CALLGRIND_START_INSTRUMENTATION; }

void callgrind_stop() { CALLGRIND_STOP_INSTRUMENTATION; }
