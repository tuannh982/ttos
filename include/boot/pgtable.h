#ifndef PGTABLE_H
#define PGTABLE_H

#define PAGE_BIT_PRESENT 0       // page present
#define PAGE_BIT_RW 1            // page writeable
#define PAGE_BIT_USER 2          // userspace accessible
#define PAGE_BIT_WRITE_THROUGH 3 // page write through (write directly to memory)
#define PAGE_BIT_DISABLE_CACHE 4 // page cache disabled
#define PAGE_BIT_ACCESSED 5      // page was accessed, raised by CPU
#define PAGE_BIT_DIRTY 6         // page was written, raised by CPU
#define PAGE_BIT_HUGEPAGE        // huge page

#define PAGE_PRESENT (1 << PAGE_BIT_PRESENT)
#define PAGE_RW (1 << PAGE_BIT_RW)
#define PAGE_USER (1 << PAGE_BIT_USER)
#define PAGE_WRITE_THROUGH (1 << PAGE_BIT_WRITE_THROUGH)
#define PAGE_DISABLE_CACHE (1 << PAGE_BIT_DISABLE_CACHE)
#define PAGE_ACCESSED (1 << PAGE_BIT_ACCESSED)
#define PAGE_DIRTY (1 << PAGE_BIT_DIRTY)
#define PAGE_HUGEPAGE (1 << PAGE_BIT_HUGEPAGE)

#endif