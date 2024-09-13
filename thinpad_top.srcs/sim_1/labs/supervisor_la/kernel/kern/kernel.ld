ENTRY(INITLOCATE)
OUTPUT("kernel.elf")
OUTPUT_ARCH(loongarch)

PROVIDE(SerialData = 0xBFD003F8);
PROVIDE(SerialStat = 0xBFD003FC);

/* Qemu serial constants */


PROVIDE(KERNEL_STACK_INIT = 0x80800000);
PROVIDE(USER_STACK_INIT = 0x807F0000);
SECTIONS
{
    . = 0x807F0000;
    .bss : {
        _sbss = .;         /* define a global symbol at bss start */
        *(.bss.uregs)
        *(.bss)
        *(.bss.ptes)
        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end */
    }
    .rodata : {
        *(.rodata)
    }
    PROVIDE(uregs_sp = uregs + 2 * 4);
    PROVIDE(uregs_fp = uregs + 21 * 4);
    . = 0x80000000;
    .text : {
        *(.text.init)
        . = 0x1000;
        *(.text.ebase)
        . = 0x1180;
        *(.text.ebase180)
        . = ALIGN(0x1000);
        *(.text)
        . = ALIGN(0x1000); /* "fixed" utest address */
        *(.text.utest)
    }
}
