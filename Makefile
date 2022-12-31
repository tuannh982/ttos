CURRENT_DIR:=$(shell pwd)
# emulator
QEMU:=qemu-system-x86_64
QEMU_OPTS:=$(QEMU_OPTS)
QEMU_DEBUG_OPTS:=$(QEMU_OPTS) -s -S
# build envs
BUILD_ENV_CONFIGURE_CMD:=docker run -d --platform linux/amd64 --rm -it -v $(CURRENT_DIR):$(CURRENT_DIR) -w $(CURRENT_DIR)
BUILD_ENV_IMAGE:=gcc-cross-compiler
BUILD_ENV_I686_NAME:=buildenv-i686-elf
BUILD_ENV_X86_64_NAME:=buildenv-x86_64-elf
BUILD_ENV_I686:=docker exec $(BUILD_ENV_I686_NAME)
BUILD_ENV_X86_64:=docker exec $(BUILD_ENV_X86_64_NAME)
CC_I686:=i686-elf-gcc
CC_X86_64:=x86_64-elf-gcc
# build tools
CC32:=$(BUILD_ENV_I686) $(CC_I686)
CC64:=$(BUILD_ENV_X86_64) $(CC_X86_64)
GRUB_FILE:=$(BUILD_ENV_X86_64) grub-file
GRUB_MKRESCUE:=$(BUILD_ENV_X86_64) grub-mkrescue
# flags
BOOT_CFLAGS:=$(BOOT_CFLAGS) -I include -std=gnu99 -ffreestanding -O2 -Wall -Wextra -ggdb
CLDFLAGS:=$(CLDFLAGS) -ffreestanding -O2 -nostdlib -lgcc -ggdb

BOOT_OBJS = \
	boot/boot.S.o \
	boot/vga.c.o \
	boot/vga_utils.c.o \
	boot/loader.c.o \

.PHONY: all clean run-debug run-kernel run-iso
.SUFFIXES: .o .c .S .cpp

# bootstrap

boot/%.c.o: boot/%.c
	$(CC32) $(BOOT_CFLAGS) -c $< -o $@

boot/%.S.o: boot/%.S
	$(CC32) $(BOOT_CFLAGS) -c $< -o $@

bootstrap.bin: $(BOOT_OBJS)
	mkdir -p target
	$(CC32) -T linker.ld -o target/$@ $(CLDFLAGS) $(BOOT_OBJS) 
	$(GRUB_FILE) --is-x86-multiboot target/bootstrap.bin

# kernel: TODO

os.iso: bootstrap.bin
	mkdir -p target/iso/boot/grub
	cp boot/grub.cfg target/iso/boot/grub/grub.cfg
	cp target/bootstrap.bin target/iso/boot/bootstrap.bin
	$(GRUB_MKRESCUE) -o target/os.iso target/iso

all: os.iso

run-bootstrap:
	$(QEMU) $(QEMU_OPTS) -kernel target/bootstrap.bin

run-debug:
	$(QEMU) $(QEMU_DEBUG_OPTS) -cdrom target/os.iso

run-iso:
	$(QEMU) $(QEMU_OPTS) -cdrom target/os.iso

configure:
	$(BUILD_ENV_CONFIGURE_CMD) --name $(BUILD_ENV_I686_NAME) $(BUILD_ENV_IMAGE):i686-elf
	$(BUILD_ENV_CONFIGURE_CMD) --name $(BUILD_ENV_X86_64_NAME) $(BUILD_ENV_IMAGE):x86_64-elf

clean:
	rm -rf target/*
	rm -rf $(KERNEL_OBJS)
	find . -name "*.o" -type f -delete