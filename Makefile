KERNEL_SOURCE_PATH = src/kernel

KERNEL_OBJS = \
	$(KERNEL_SOURCE_PATH)/boot/boot.S.o \
	$(KERNEL_SOURCE_PATH)/boot/loader.c.o

KERNEL_LINK_LIST = \
	$(KERNEL_OBJS)

CC = i686-elf-gcc
CFLAGS = -I. -I $(KERNEL_SOURCE_PATH)/include -std=gnu99 -ffreestanding -O2 -Wall -Wextra
LDFLAGS = -nostdlib

.PHONY: all clean run
.SUFFIXES: .o .c .S

$(KERNEL_SOURCE_PATH)/%.c.o: $(KERNEL_SOURCE_PATH)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL_SOURCE_PATH)/%.S.o: $(KERNEL_SOURCE_PATH)/%.S
	$(CC) $(CFLAGS) -c $< -o $@

os.bin: $(KERNEL_OBJS) 
	$(CC) -T $(KERNEL_SOURCE_PATH)/linker.ld -o $@ $(CFLAGS) $(LDFLAGS) $(KERNEL_LINK_LIST)
	grub-file --is-x86-multiboot os.bin

all: os.bin

run:
	qemu-system-x86_64 -kernel os.bin

clean:
	rm -rf $(KERNEL_OBJS)