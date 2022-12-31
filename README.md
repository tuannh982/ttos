\# Name TBD
====

## Prerequisites
- qemu-system-x86_64
- x86_64-elf-gdb

## Quickstarts

Build the cross-compiler & start the build containers:
```bash
# build the build tools 
# -- this might be very slow on Mac with ARM chip)
build-tools/build-gcc-cross-compiler.sh
# start build envs
make configure
```

Build the kernel
```bash
make clean && make all
```

Run the kernel
```bash
make run-iso
```

## Debug the kernel

First, start QEMU with debug flags (debug flags were included in Makefile)
```bash
make run-debug
```

Start GDB
```bash
x86_64-elf-gdb -tui
```

