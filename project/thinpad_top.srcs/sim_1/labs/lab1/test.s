
./lab1.elf:     file format elf32-loongarch
./lab1.elf


Disassembly of section .text:

80000000 <_start>:
_start():
80000000:	0280040c 	addi.w	$r12,$r0,1(0x1)
80000004:	0280040d 	addi.w	$r13,$r0,1(0x1)
80000008:	15008004 	lu12i.w	$r4,-523264(0x80400)
8000000c:	02840085 	addi.w	$r5,$r4,256(0x100)

80000010 <loop>:
loop():
80000010:	0010358e 	add.w	$r14,$r12,$r13
80000014:	028001ac 	addi.w	$r12,$r13,0
80000018:	028001cd 	addi.w	$r13,$r14,0
8000001c:	2980008e 	st.w	$r14,$r4,0
80000020:	2880008f 	ld.w	$r15,$r4,0
80000024:	5c000dcf 	bne	$r14,$r15,12(0xc) # 80000030 <end>
80000028:	02801084 	addi.w	$r4,$r4,4(0x4)
8000002c:	5fffe485 	bne	$r4,$r5,-28(0x3ffe4) # 80000010 <loop>

80000030 <end>:
end():
80000030:	5c000080 	bne	$r4,$r0,0 # 80000030 <end>
