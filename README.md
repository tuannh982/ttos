\# Name TBD
====

## Prerequisites
- qemu-system-x86_64
- i386-elf-gdb

## Quickstarts

Build the cross-compiler:
```bash
build-tools/build-gcc-cross-compiler.sh
```

Build the kernel
```bash
# start the docker image with build tools
docker run -d --platform linux/amd64 --name buildenv-i686-elf --rm -it -v "$(pwd)":/mnt gcc-cross-compiler:i686-elf
# go into the container
docker exec -it buildenv-i686-elf /bin/bash
# inside container
cd /mnt/kernel
# build
make clean && make all
```

Run the kernel
```bash
cd kernel
make run-kernel
```

Run the packed ISO
```bash
cd kernel
make run-iso
```

## Debug the kernel

First, start QEMU with debug flags (debug flags were included in Makefile)
```bash
cd kernel
make run-debug
```

Start GDB
```bash
cd kernel
i386-elf-gdb -tui
```

