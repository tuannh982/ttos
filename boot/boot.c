#include <boot/multiboot.h>
#include <boot/vga.h>
#include <boot/vga_utils.h>
#include <boot/elf64.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern void enter_long_mode();

void loader_init();
void load_kernel_module(uint32_t magic, multiboot_info_t *mbi);

static void *load_kernel_image(multiboot_info_t *mbi);
static void *load_elf_module(multiboot_uint32_t mod_start, multiboot_uint32_t mod_end);

void loader_init()
{
    /* Clear the screen. */
    vga_clear();
}

void load_kernel_module(uint32_t magic, multiboot_info_t *mbi)
{
    void *kernel_entry = load_kernel_image(mbi);
    enter_long_mode();
}

static void *load_kernel_image(multiboot_info_t *mbi)
{
    // check multiboot flags
    multiboot_uint32_t mb_flags = mbi->flags;
    void *kentry = NULL;
    // multiboot module supported
    if (mb_flags & MULTIBOOT_INFO_MODS)
    {
        multiboot_uint32_t mods_count = mbi->mods_count;
        multiboot_uint32_t mods_addr = mbi->mods_addr;
        if (mods_count > 0)
        {
            // kernel module is always the first module
            multiboot_module_t *mod = (multiboot_module_t *)mods_addr;
            kentry = load_elf_module(mod->mod_start, mod->mod_end);
        }
    }
    return kentry;
}

static void *load_elf_module(multiboot_uint32_t mod_start, multiboot_uint32_t mod_end)
{
    elf64_header_t *elf_header = (elf64_header_t *)mod_start;
    // check ELF magic value
    if (elf_header->e_ident.data.ei_mag != ELF_MAGIC){
        vga_printf("\nNo magic\n");
        return NULL;
    }
    vga_printf("\n\n\nBoot OK, Shutup\n");
    // TODO
    return NULL;
}