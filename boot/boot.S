#define ASM_FILE 1
#include <boot/multiboot.h>
#include <boot/pgtable.h>
#include <boot/gdt.h>

.code32

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

/* Page tables */
/* 64bit paging, 4KB per page, https://wiki.osdev.org/Page_Tables */
.align 4096
page_table_pml4:
.skip 4096
page_table_pdp:
.skip 4096
page_table_pd:
.skip 4096

/* Stack */
.align 16
/* The size of our stack (16KB). */
#define STACK_SIZE 0x4000
stack_bottom:
.skip STACK_SIZE
stack_top:

# ------------------------------------------------------
.section .text

.global _start
.type _start, @function
_start:
    /* Clear interrupts */
    cli
    /* Setup stack */
    movl    $stack_top, %esp
    movl    $stack_top, %ebp

    /* Push the pointer to the Multiboot information structure. */
    pushl   %ebx
    /* Push the magic value. */
    pushl   %eax

    call    loader_init

    /* Perform checks for 64bit mode supports */    
    call    check_multiboot
    call    check_long_mode

    /* Load kernel module to memory */
    call    load_kernel_module

halted:
    pushl   $halted_message
    call    vga_printf
    
hlt_loop:   
    hlt
    jmp     hlt_loop

.global enter_kernel
enter_kernel:
    /* Save the old base stack address */
    pushl   %ebp
    /* Rebase the stack */
    mov     %esp, %ebp

    /* Loading the Global Descriptor Table */
    lgdt    gdt64_pointer

    /* perform a long jump */
    ljmp    $8, $_start64

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
        mov     $0x80000000, %eax
        cpuid
        cmp     $0x80000001, %eax
        /* if eax is smaller than $0x80000001, then long mode is not supported */
        jb      _no_long_mode
        /* Get Extended Processor Info and Feature Bits */
        mov     $0x80000001, %eax
        cpuid
        /* check Long mode bit on edx */
        test    $(1 << 29), %edx
        jz      _no_long_mode

    ret
    _cpuid_not_supported:
        pushl   $cpuid_not_supported_message
        jmp     print_and_halted
    _no_long_mode:
        pushl   $no_long_mode_message
        jmp     print_and_halted

.global enter_long_mode
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
        mov     %cr0, %eax
        and     $(~(1 << CR0_BIT_ENABLE_PAGING)), %eax
        mov     %eax, %cr0
    
    /* Setup new page tables */
    setup_page_tables:
        /* write first P3 (PDP) entry to P4 (PML4) table */
        mov     $page_table_pdp, %eax
        or      $(PAGE_PRESENT | PAGE_RW), %eax
        mov     %eax, page_table_pml4
        /* write first P2 (PD) entry to P3 (PDP) table */
        mov     $page_table_pd, %eax
        or      $(PAGE_PRESENT | PAGE_RW), %eax
        mov     %eax, page_table_pdp

        /* map P2 (PD) table entries */
        map_pd_table:
            /* P1 table, don't enable HUGEPAGE bit */
            mov     $(PAGE_PRESENT | PAGE_RW | PAGE_HUGEPAGE), %eax
            mov     $page_table_pd, %ebx
            mov     $0, %ecx
            /* do a loop to map P2 (PD) table entries */
            map_pd_table_loop:
                mov     %eax, (%ebx)
                /* 2 MB */
                add     $0x200000, %eax
                /* loop unti we've filled 512 entries */
                add     $0x8, %ebx
                inc     %ecx
                cmp     $512, %ecx
                jne     map_pd_table_loop

    /* Set the PAE enable bit in CR4 */
    cr4_enable_pae:
        mov    %cr4, %eax
        bts     $CR4_BIT_PAE, %eax
        mov    %eax, %cr4

    /* Load CR3 with the physical address of the PML4 (Level 4 Page Map) */
    cr3_load_page_table:
        mov     $page_table_pml4, %eax
        mov     %eax, %cr3

    /* Enable long mode by setting the LME flag (bit 8) in MSR 0xC0000080 (aka EFER) */
    msr_enable_long_mode:
        mov     $0xC0000080, %ecx
        rdmsr
        bts     $EFER_BIT_LME, %eax
        wrmsr

    /* Enable paging */
    cr0_enable_paging:
        mov     %cr0, %eax
        bts     $CR0_BIT_ENABLE_PAGING, %eax
        mov     %eax, %cr0

    ret

# ------------------------------------------------------
.align 16
gdt64:
    .quad 0
gdt64_code_segment:
    /* code descriptor: executable, descriptor, present, long mode */
    .quad GDT_SEGMENT_DESCRIPTOR_ACCESS_E | GDT_SEGMENT_DESCRIPTOR_ACCESS_S | GDT_SEGMENT_DESCRIPTOR_ACCESS_P | GDT_SEGMENT_DESCRIPTOR_FLAGS_L
    /* data descriptor: writable, descriptor, present */
    .quad GDT_SEGMENT_DESCRIPTOR_BIT_ACCESS_RW | GDT_SEGMENT_DESCRIPTOR_ACCESS_S | GDT_SEGMENT_DESCRIPTOR_ACCESS_P
gdt64_end:
.align 16
gdt64_pointer:
    .word gdt64_end - gdt64 - 1
    .long gdt64
    .long 0
.align 16
# ------------------------------------------------------

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
    /* Clear all segment registers */
    clear_segment_registers:
        mov     $0, %rax
        mov     %ax, %ss
        mov     %ax, %ds
        mov     %ax, %es
        mov     %ax, %fs
        mov     %ax, %gs

    /* Since we've rebase the stack, now the arguments are located at EBP + 8 and EBP + 12 */
    mov     8(%ebp), %eax
    /* Trick the processor to load 64bit address */
    .long   0

    /* The multiboot information */
    mov     12(%ebp), %edi

    /* Jump to our kernel main*/
    jmp     *(%eax)

hlt64_loop:   
    hlt
    jmp     hlt64_loop
