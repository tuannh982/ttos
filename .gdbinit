set architecture i386:x86-64
file target/bootstrap.bin
target remote localhost:1234
layout split
break _start
