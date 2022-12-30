KERNEL_SOURCE_PATH = src/kernel

LOADER_OBJS = \
	$(KERNEL_SOURCE_PATH)/boot/boot.S.o \
	$(KERNEL_SOURCE_PATH)/boot/loader.c.o

# build tools
CC:=i686-elf-gcc
LD:=i686-elf-ld
# tool opts
CFLAGS:=$(CFLAGS) -I. -I $(KERNEL_SOURCE_PATH)/include -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS:=$(LDFLAGS) -nostdlib

.PHONY: all clean run-kernel run-iso
.SUFFIXES: .o .c .S .asm

$(KERNEL_SOURCE_PATH)/%.c.o: $(KERNEL_SOURCE_PATH)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL_SOURCE_PATH)/%.S.o: $(KERNEL_SOURCE_PATH)/%.S
	$(CC) $(CFLAGS) -c $< -o $@

loader.bin: $(LOADER_OBJS) 
	$(CC) -T $(KERNEL_SOURCE_PATH)/linker.ld -o target/$@ -ffreestanding -O2 -nostdlib $(LOADER_OBJS) -lgcc
	grub-file --is-x86-multiboot target/loader.bin

os.iso: loader.bin
	mkdir -p target/iso/boot/grub
	cp $(KERNEL_SOURCE_PATH)/boot/grub.cfg target/iso/boot/grub/grub.cfg
	cp target/loader.bin target/iso/boot/loader.bin
	grub-mkrescue /usr/lib/grub/i386-pc/ -o target/os.iso target/iso

all: os.iso

run-kernel:
	qemu-system-x86_64 -kernel target/loader.bin

run-iso:
	qemu-system-x86_64 -cdrom target/os.iso

clean:
	rm -rf target/*
	rm -rf $(KERNEL_OBJS)
	find . -name "*.o" -type f -delete