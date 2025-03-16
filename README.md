## Building

```bash
gcc -O3 posix/callgrind_instr.c -c
dmd -of=coremark *.d callgrind_instr.o posix/*.d
```
