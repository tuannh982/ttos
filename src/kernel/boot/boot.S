#define ASM_FILE 1
#include <multiboot.h>

/* The size of our stack (16KB). */
#define STACK_SIZE 0x4000

#define MULTIBOOT_HEADER_FLAGS MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_VIDEO_MODE

# ------------------------------------------------------
.section .multiboot

.align 4
multiboot_header:
    # The layout of the Multiboot header must be as follows:

    # Offset	Type	Field Name	Note
    # 0	u32	magic	required
    # 4	u32	flags	required
    # 8	u32	checksum	required
    # 12	u32	header_addr	if flags[16] is set
    # 16	u32	load_addr	if flags[16] is set
    # 20	u32	load_end_addr	if flags[16] is set
    # 24	u32	bss_end_addr	if flags[16] is set
    # 28	u32	entry_addr	if flags[16] is set
    # 32	u32	mode_type	if flags[2] is set
    # 36	u32	width	if flags[2] is set
    # 40	u32	height	if flags[2] is set
    # 44	u32	depth	if flags[2] is set
    
    .long   MULTIBOOT_HEADER_MAGIC
    .long   MULTIBOOT_HEADER_FLAGS
    .long -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
    .long 0
    .long 0
    .long 0
    .long 0
    .long 0       
    .long 0
    .long 1024
    .long 768
    .long 32

# ------------------------------------------------------
.section .text

.global _start
.type _start, @function
_start:
    /* Initialize the stack pointer. */
    movl    $(stack + STACK_SIZE), %esp

    /* Reset EFLAGS. */
    pushl   $0
    popf

    /* Push the pointer to the Multiboot information structure. */
    pushl   %ebx
    /* Push the magic value. */
    pushl   %eax

    /* Now enter the C main function... */
    call    lmain

    /* Halt. */
    pushl   $halt_message
    call    printf
    
loop:   hlt
    jmp     loop

halt_message:
    .asciz  "Halted."

    /* Our stack area. */
    .comm   stack, STACK_SIZE