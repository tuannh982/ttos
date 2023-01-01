set architecture i386:x86-64
file target/bootstrap.bin
target remote localhost:1234
layout split
break _start
break cr0_disable_paging
break setup_page_tables
break cr4_enable_pae
break cr0_enable_paging
break boot.S:108