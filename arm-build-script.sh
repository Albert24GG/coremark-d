#!/bin/bash

mkdir -p /root/coremark-d
cd /root/coremark-d

cp -r /coremark-d-source/{*.d,Makefile.arm,posix} .

make -f Makefile.arm

cp coremark_ldc coremark_gdc /output

# Run any additional command passed to docker run
exec "$@"
