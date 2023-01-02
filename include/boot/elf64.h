#ifndef ELF64_H
#define ELF64_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

// https://en.wikipedia.org/wiki/Executable_and_Linkable_Format

#define ELF_MAGIC 0x464C457F

struct elf64_header
{
    union e_ident
    {
        struct data
        {
            uint32_t ei_mag;
            uint8_t ei_class;
            uint8_t ei_data;
            uint8_t ei_version;
            uint8_t ei_osabi;
            uint8_t ei_abiversion;
            uint8_t ei_pad[7];
        } data;
        uint8_t raw[16];
    } e_ident;
    uint16_t e_type;
    uint16_t e_machine;
    uint32_t e_version;
    uint64_t e_entry;
    uint64_t e_phoff;
    uint64_t e_shoff;
    uint32_t e_flags;
    uint16_t e_ehsize;
    uint16_t e_phentsize;
    uint16_t e_phnum;
    uint16_t e_shentsize;
    uint16_t e_shnum;
    uint16_t e_shstrndx;
};

typedef struct elf64_header elf64_header_t;

struct elf64_program_header
{
    uint32_t p_type;
    uint32_t p_flags;
    uint64_t p_offset;
    uint64_t p_vaddr;
    uint64_t p_paddr;
    uint64_t p_filesz;
    uint64_t p_memsz;
    uint64_t p_align;
};

typedef struct elf64_program_header elf64_program_header_t;

struct elf64_section_header
{
    uint32_t sh_name;
    uint32_t sh_type;
    uint64_t sh_flags;
    uint64_t sh_addr;
    uint64_t sh_offset;
    uint64_t sh_size;
    uint32_t sh_link;
    uint32_t sh_info;
    uint64_t sh_addralign;
    uint64_t sh_entsize;
};

typedef struct elf64_section_header elf64_section_header_t;

#endif