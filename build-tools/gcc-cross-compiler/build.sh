#!/bin/bash
set -e
# build binutils
mkdir build-binutils 
cd build-binutils
../src-binutils/configure --prefix="$PREFIX" --target="$TARGET" --with-sysroot --disable-nls --disable-werror
make
make install
# build gcc
cd ..
mkdir build-gcc 
cd build-gcc
../src-gcc/configure --prefix="$PREFIX" --target="$TARGET" --disable-nls --enable-languages=c,c++ --without-headers
make -j$((`nproc`+1)) all-gcc
make -j$((`nproc`+1)) all-target-libgcc
make install-gcc
make install-target-libgcc
