    .org 0x0
    .text
    .global _start
_start:
    lu12i.w	$a0,-0x7ff00
    lu12i.w	$a1,-0x7fc00 
    lu12i.w	$a2, 0x00300
    add.w	$a2,$a0,$a2
    ld.w	$t0,$a0,0
    st.w	$t0,$a1,0
    addi.w	$a0,$a0,4
    addi.w	$a1,$a1,4
    bne	$a0,$a2,-0x00010
    jirl	$zero,$ra,0
