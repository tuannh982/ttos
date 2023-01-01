#define ASM_FILE 1
#include <boot/multiboot.h>
#include <boot/pgtable.h>

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
    
    #define MULTIBOOT_HEADER_FLAGS MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
    .long   MULTIBOOT_HEADER_MAGIC
    .long   MULTIBOOT_HEADER_FLAGS
    .long -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)
    .long 0
    .long 0
    .long 0
    .long 0
    .long 0       
    .long 0
    .long 0
    .long 0
    .long 0

# ------------------------------------------------------
.section .bss

.align 4096
/* 64bit paging, 4KB per page, https://wiki.osdev.org/Page_Tables */
page_table_pml4:
.skip 4096
page_table_pdp:
.skip 4096
page_table_pd:
.skip 4096
page_table_pt:
.skip 4096

.align 16
/* The size of our stack (16KB). */
#define STACK_SIZE 0x4000
stack_bottom:
.skip STACK_SIZE
stack_top:
# ------------------------------------------------------
.section .text

/* 32bit mode */
.code32

.global _start
.type _start, @function
_start:
    /* Clear interrupts */
    cli
    /* Setup stack */
    movl $stack_top, %esp
    movl $stack_top, %ebp

    /* Push the pointer to the Multiboot information structure. */
    pushl   %ebx
    /* Push the magic value. */
    pushl   %eax

    call    loader_init
    call    check_multiboot
    call    check_long_mode
    call    enter_long_mode
    # TODO setup GDT

    /* switch to 64bit mode */
    # .code64
    /* Calling the main loader */
    call    loader_main

halted:
    pushl   $halted_message
    call    vga_printf
    
hlt_loop:   
    hlt
    jmp     hlt_loop

/* check multiboot routine */
check_multiboot:
    /* compare the magic value with the previous saved eax */
    cmpl    $MULTIBOOT_BOOTLOADER_MAGIC, 4(%esp)
    jne     _no_multiboot
    ret
    _no_multiboot:
        pushl   $no_multiboot_message
        jmp     print_and_halted

/* check long mode routine */
check_long_mode:
    /* https://en.wikipedia.org/wiki/FLAGS_register */
    check_cpu_id:
        /* try flip ID bit of FLAGS register*/
        pushfl
        popl    %eax
        movl    %eax, %ecx
        xorl    $(1 << 21), %eax
        pushl   %eax
        popfl
        /* re-read to confirm we've flip ID bit */
        pushfl
        popl    %eax
        pushl   %ecx
        /* revert back to original state */
        popfl
        cmpl    %eax, %ecx
        je      _cpuid_not_supported
    
    /* https://en.wikipedia.org/wiki/CPUID */
    check_cpuid_long_mode:
        /* Get extended function information by calling CPUID with EAX = 80000000h */
        movl    $0x80000000, %eax
        cpuid
        cmpl    $0x80000001, %eax
        /* if eax is smaller than $0x80000001, then long mode is not supported */
        jb      _no_long_mode
        /* Get Extended Processor Info and Feature Bits */
        movl    $0x80000001, %eax
        cpuid
        /* check Long mode bit on edx */
        testl   $(1 << 29), %edx
        jz      _no_long_mode

    ret
    _cpuid_not_supported:
        pushl   $cpuid_not_supported_message
        jmp     print_and_halted
    _no_long_mode:
        pushl   $no_long_mode_message
        jmp     print_and_halted

/* https://wiki.osdev.org/Long_Mode */
enter_long_mode:
    # Steps to entering long mode
    # - Disable paging
    # - Setup new page tables
    # - Set the PAE enable bit in CR4
    # - Load CR3 with the physical address of the PML4 (Level 4 Page Map)
    # - Enable long mode by setting the LME flag (bit 8) in MSR 0xC0000080 (aka EFER)
    # - Enable paging

    #define CR0_BIT_ENABLE_PAGING 31
    #define CR4_BIT_PAE 5
    #define EFER_BIT_LME 8

    /* Disable paging */
    cr0_disable_paging:
        movl    %cr0, %eax
        andl    $(~(1 << CR0_BIT_ENABLE_PAGING)), %eax
        movl    %eax, %cr0
    
    /* Setup new page tables */
    setup_page_tables:
        /* write first P3 (PDP) entry to P4 (PML4) table */
        movl    $page_table_pdp, %eax
        orl     $(PAGE_PRESENT | PAGE_RW), %eax
        movl    %eax, page_table_pml4
        /* write first P2 (PD) entry to P3 (PDP) table */
        movl    $page_table_pd, %eax
        orl     $(PAGE_PRESENT | PAGE_RW), %eax
        movl    %eax, page_table_pdp
        /* write first P1 (PT) entry to P2 (PD) table */
        movl    $page_table_pt, %eax
        orl     $(PAGE_PRESENT | PAGE_RW), %eax
        movl    %eax, page_table_pd

        /* map P1 (PT) table entries */
        map_pt_table:
            movl    $page_table_pt, %ebx
            movl    $0, %ecx
            /* do a loop to map P1 (PT) table entries */
            map_pt_table_loop:
                /* 4096 */
                movl    $0x1000, %eax
                /* P1 table, don't enable HUGEPAGE bit */
                orl     $(PAGE_PRESENT | PAGE_RW), %eax 
                movl    %eax, (%ebx)
                /* loop unti we've filled 512 entries, or 2MB */
                addl    $0x8, %ebx
                incl    %ecx
                cmpl    $512, %ecx
                jne     map_pt_table_loop

    /* Set the PAE enable bit in CR4 */
    cr4_enable_pae:
        movl    %cr4, %eax
        orl     (1 << CR4_BIT_PAE), %eax
        movl    %eax, %cr4

    /* Load CR3 with the physical address of the PML4 (Level 4 Page Map) */
    cr3_load_page_table:
        movl    $page_table_pml4, %eax
        movl    %eax, %cr3

    /* Enable long mode by setting the LME flag (bit 8) in MSR 0xC0000080 (aka EFER) */
    msr_enable_long_mode:
        movl    $0xC0000080, %ecx
        rdmsr
        orl     $(1 << EFER_BIT_LME), %eax
        wrmsr

    /* Enable paging */
    cr0_enable_paging:
        movl    %cr0, %eax
        orl     $(1 << CR0_BIT_ENABLE_PAGING), %eax
        movl    %eax, %cr0

print_and_halted:
    call    vga_printf
    jmp     halted

# strings
halted_message:
    .asciz  "Halted\n"

no_multiboot_message:
    .asciz  "Multiboot bootloader magic mismatched\n"

cpuid_not_supported_message:
    .asciz  "CPUID feature not supported\n"

no_long_mode_message:
    .asciz  "Long Mode not supported\n"

.size _start, . - _start


# ------------------------------------------------------
.code64

_start64:
