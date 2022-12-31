#include <boot/multiboot.h>
#include <boot/vga.h>
#include <boot/vga_utils.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void loader_main(uint32_t magic, uint32_t addr);
void loader_init();

void loader_init()
{
    /* Clear the screen. */
    vga_clear();
}

void loader_main(uint32_t magic, uint32_t addr)
{
    multiboot_info_t *mbi;

    vga_printf("Magic = 0x%x\n", magic);

    mbi = (multiboot_info_t *)addr;

    vga_printf("Boot OK\n");
    // TODO
}