CURRENT_DIR:=$(shell pwd)
# emulator
QEMU:=qemu-system-x86_64
QEMU_OPTS:=$(QEMU_OPTS) -no-reboot -d int -D qemu.log
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
KERNEL_CFLAGS:=$(KERNEL_CFLAGS)-I include -mcmodel=kernel -ffreestanding -m64 -z max-page-size=0x1000 -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -std=gnu99 -O2 -Wall -Wextra -ggdb
CLDFLAGS:=$(CLDFLAGS) -ffreestanding -O2 -nostdlib -lgcc -ggdb

BOOT_OBJS = \
	boot/boot.S.o \
	boot/vga.c.o \
	boot/vga_utils.c.o \
	boot/boot.c.o \

KERNEL_OBJS = \
	kernel/kmain.c.o \

.PHONY: all clean run-debug run-kernel run-iso
.SUFFIXES: .o .c .S .cpp

# bootstrap

kernel/%.c.o: kernel/%.c
	$(CC64) $(KERNEL_CFLAGS) -c $< -o $@

kernel/%.S.o: kernel/%.S
	$(CC64) $(KERNEL_CFLAGS) -c $< -o $@

boot/%.c.o: boot/%.c
	$(CC32) $(BOOT_CFLAGS) -c $< -o $@

boot/%.S.o: boot/%.S
	$(CC32) $(BOOT_CFLAGS) -c $< -o $@

bootstrap.bin: $(BOOT_OBJS)
	mkdir -p target
	$(CC32) -T boot/linker.ld -o target/$@ $(CLDFLAGS) $(BOOT_OBJS) 
	$(GRUB_FILE) --is-x86-multiboot target/bootstrap.bin

kernel.bin: $(KERNEL_OBJS)
	mkdir -p target
	$(CC64) -T kernel/linker.ld -o target/$@ $(CLDFLAGS) $(KERNEL_OBJS) 

os.iso: bootstrap.bin kernel.bin
	mkdir -p target/iso/boot/grub
	cp boot/grub.cfg target/iso/boot/grub/grub.cfg
	cp target/bootstrap.bin target/iso/boot/bootstrap.bin
	cp target/kernel.bin target/iso/boot/kernel.bin
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