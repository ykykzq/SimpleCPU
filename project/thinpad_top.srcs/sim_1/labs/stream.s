
stream.elf:     file format elf32-loongarch
stream.elf


Disassembly of section .text:

80000000 <_start>:
_start():
80000000:	15002004 	lu12i.w	$r4,-524032(0x80100)
80000004:	15008005 	lu12i.w	$r5,-523264(0x80400)
80000008:	14006006 	lu12i.w	$r6,768(0x300)
8000000c:	00101886 	add.w	$r6,$r4,$r6
80000010:	2880008c 	ld.w	$r12,$r4,0
80000014:	298000ac 	st.w	$r12,$r5,0
80000018:	02801084 	addi.w	$r4,$r4,4(0x4)
8000001c:	028010a5 	addi.w	$r5,$r5,4(0x4)
80000020:	5ffff086 	bne	$r4,$r6,-16(0x3fff0) # 80000010 <_start+0x10>
80000024:	4c000020 	jirl	$r0,$r1,0
