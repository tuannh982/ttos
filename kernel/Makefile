QEMU:=qemu-system-x86_64
QEMU_OPTS:=$(QEMU_OPTS)
QEMU_DEBUG_OPTS:=$(QEMU_OPTS) -s -S
# build tools
CC:=i686-elf-gcc
LD:=i686-elf-ld
# flags
CFLAGS:=$(CFLAGS) -I include -std=gnu99 -ffreestanding -O2 -Wall -Wextra -ggdb
CLDFLAGS:=$(CLDFLAGS) -ffreestanding -O2 -nostdlib -lgcc -ggdb

LOADER_OBJS = \
	boot/boot.S.o \
	boot/vga.c.o \
	boot/vga_utils.c.o \
	boot/loader.c.o \

.PHONY: all clean run-debug run-kernel run-iso
.SUFFIXES: .o .c .S

%.c.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.S.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

loader.bin: $(LOADER_OBJS) 
	mkdir -p target
	$(CC) -T linker.ld -o target/$@ $(CLDFLAGS) $(LOADER_OBJS) 
	grub-file --is-x86-multiboot target/loader.bin

os.iso: loader.bin
	mkdir -p target/iso/boot/grub
	cp boot/grub.cfg target/iso/boot/grub/grub.cfg
	cp target/loader.bin target/iso/boot/loader.bin
	grub-mkrescue -o target/os.iso target/iso

all: os.iso

run-debug:
	$(QEMU) $(QEMU_DEBUG_OPTS) -kernel target/loader.bin

run-kernel:
	$(QEMU) $(QEMU_OPTS) -kernel target/loader.bin

run-iso:
	$(QEMU) $(QEMU_OPTS) -cdrom target/os.iso

clean:
	rm -rf target/*
	rm -rf $(KERNEL_OBJS)
	find . -name "*.o" -type f -delete