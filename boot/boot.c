#include <boot/multiboot.h>
#include <boot/vga.h>
#include <boot/vga_utils.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void loader_init();
void print_multiboot_info(uint32_t magic, multiboot_info_t *mbi);

void loader_init()
{
    /* Clear the screen. */
    vga_clear();
}

void print_multiboot_info(uint32_t magic, multiboot_info_t *mbi)
{
    vga_printf("Boot OK\n");
    // TODO
}