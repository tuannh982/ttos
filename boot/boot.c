#include <boot/multiboot.h>
#include <boot/vga.h>
#include <boot/vga_utils.h>
#include <boot/elf64.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern void enter_long_mode();
extern void enter_kernel(uint32_t kernel_entry, uint32_t mbi);

void loader_init();
void load_kernel_module(uint32_t magic, multiboot_info_t *mbi);

static uint64_t load_kernel_image(multiboot_info_t *mbi);
static uint64_t load_elf_module(multiboot_uint32_t mod_start);
static void memcpy(uint8_t *dst, uint8_t *src, size_t n);

void loader_init()
{
    /* Clear the screen. */
    vga_clear();
}

void load_kernel_module(uint32_t magic, multiboot_info_t *mbi)
{
    uint64_t kernel_entry = load_kernel_image(mbi);
    enter_long_mode();
    vga_printf("multiboot information address = 0x%x\n", mbi);
    vga_printf("kernel entry address = 0x%x\n", kernel_entry);
    enter_kernel((uint32_t)kernel_entry, (uint32_t)mbi);
}

static uint64_t load_kernel_image(multiboot_info_t *mbi)
{
    // check multiboot flags
    multiboot_uint32_t mb_flags = mbi->flags;
    uint64_t kentry = 0;
    // multiboot module supported
    if (mb_flags & MULTIBOOT_INFO_MODS)
    {
        multiboot_uint32_t mods_count = mbi->mods_count;
        multiboot_uint32_t mods_addr = mbi->mods_addr;
        vga_printf("multiboot mods count = %d\n", mods_count);
        vga_printf("multiboot mods address = 0x%x\n", mods_addr);
        if (mods_count > 0)
        {
            // kernel module is always the first module
            multiboot_module_t *mod = (multiboot_module_t *)mods_addr;
            kentry = load_elf_module(mod->mod_start);
        }
    }
    return kentry;
}

static uint64_t load_elf_module(multiboot_uint32_t mod_start)
{
    uint8_t *image = (uint8_t *)mod_start;
    vga_printf("image address = 0x%x\n", image);
    elf64_header_t *elf_header = (elf64_header_t *)image;
    // check ELF magic value
    if (elf_header->e_ident.data.ei_mag != ELF_MAGIC)
    {
        vga_printf("No ELF magic found\n");
        return 0;
    }
    elf64_program_header_t *program_header = (elf64_program_header_t *)(image + elf_header->e_phoff);
    elf64_program_header_t *program_header_end = program_header + elf_header->e_phnum;
    vga_printf("e_phoff = 0x%x\n", program_header);
    vga_printf("e_phnum = %d\n", elf_header->e_phnum);
    for (; program_header < program_header_end; program_header++)
    {
        uint8_t *program_address = (uint8_t *)((uint32_t)(program_header->p_paddr));
        vga_printf("program_header = 0x%x, program_address = 0x%x\n", program_header, program_address);
        memcpy(program_address, image + program_header->p_offset, program_header->p_filesz);
    }
    return elf_header->e_entry;
}

static void memcpy(uint8_t *dst, uint8_t *src, size_t n)
{
    size_t i = 0;
    for (; i < n; i++)
    {
        *dst++ = *src++;
    }
}