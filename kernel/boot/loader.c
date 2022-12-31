#include <boot/multiboot.h>
#include <boot/vga.h>

void loader_main(unsigned long magic, unsigned long addr);

void loader_main(unsigned long magic, unsigned long addr)
{
    multiboot_info_t *mbi;

    /* Clear the screen. */
    vga_clear();

    /* Am I booted by a Multiboot-compliant boot loader? */
    if (magic != MULTIBOOT_BOOTLOADER_MAGIC)
    {
        vga_putchar('E');
        vga_putchar('R');
        vga_putchar('R');
        // TODO error
        return;
    }

    /* Set MBI to the address of the Multiboot information structure. */
    mbi = (multiboot_info_t *)addr;

    vga_putchar('O');
    vga_putchar('K');
    // TODO
}