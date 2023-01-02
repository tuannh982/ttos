#include <boot/multiboot.h>

void kmain(multiboot_info_t *mbi);

void kmain(multiboot_info_t *mbi)
{
    // Hello
    __asm__ __volatile__(
        "push    %rax\n\t"
        "push    %rcx\n\t"
        "mov     $0xb87b6, %rcx\n\t"
        "mov     $0x2f4c2f4c2f452f48, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "mov     $0x2f522f462f202f4f, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "mov     $0x2f362f202f4d2f4f, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "mov     $0x2f542f492f422f34, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "mov     $0x2f522f452f4b2f20, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "mov     $0x2f4c2f452f4e, %rax\n\t"
        "mov     %rax, (%rcx)\n\t"
        "add     $8, %rcx\n\t"
        "pop     %rcx\n\t"
        "pop     %rax\n\t");
    for (;;)
    {
    }
    return;
}