SOURCE = src/kernel
SOURCE_INCLUDE = $(SOURCE)/include
TARGET = target

CC = i686-elf-gcc
CFLAGS = -std=gnu99 -ffreestanding -O2 -Wall -Wextra

.PHONY: all clean run

boot.o:
	mkdir -p $(TARGET)/boot
	$(CC) $(CFLAGS) -I $(SOURCE_INCLUDE) -c $(SOURCE)/boot/boot.S -o $(TARGET)/boot/boot.o

loader.o:
	mkdir -p $(TARGET)/boot
	$(CC) $(CFLAGS) -I $(SOURCE_INCLUDE) -c $(SOURCE)/boot/loader.c -o $(TARGET)/boot/loader.o

loader.bin: boot.o loader.o
	$(CC) -T $(SOURCE)/boot/linker.ld -o $(TARGET)/boot/loader.bin -ffreestanding -O2 -nostdlib $(TARGET)/boot/boot.o $(TARGET)/boot/loader.o -lgcc

all: loader.bin

run:
	qemu-system-x86_64 -kernel $(TARGET)/boot/loader.bin

clean:
	rm -rf target/*
	