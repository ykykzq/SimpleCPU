#include <asm.h>
#include <regdef.h>
#include <cpu_cde.h>

#define TEST_NUM 42

#define lab3  1
#define lab6  1
#define lab7  1

##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:
    li    t0, 0xffffffff
    addiu t0, zero, 0xffff
	b	locate
	nop

##avoid "j locate" not taken
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
    nop

##avoid cpu run error
.org 0x0ec
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
.org 0x100
test_finish:
    addiu t0, t0, 1
    li t1, 0xff
    LI (t2, UART_ADDR)
    sw t1, 0x0(t2)
    b test_finish
    nop
##avoid cpu run error
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
/*
 *  exception handle
 */
.org 0x380
1:  
    addiu t0, t0, 1
    b 1b
    nop


locate:
	.set noreorder

    LI (a0, LED_RG1_ADDR)
    LI (a1, LED_RG0_ADDR)
    LI (a2, LED_ADDR)
    LI (s1, NUM_ADDR)

    LI (t1, 0x0002)
    LI (t2, 0x0001)
    LI (t3, 0x0000ffff)
    lui s3, 0
    NOP4

    sw t1, 0(a0)
    sw t2, 0(a1)
    sw t3, 0(a2)
    sw s3, 0(s1)
    lui s0, 0
    NOP4
inst_test:
############################
###lab3 test
#if lab3
    jal n1_lui_test    #lui
    nop
    jal wait_1s
    nop
    jal n2_addu_test   #addu
    nop
    jal wait_1s
    nop
    jal n3_addiu_test  #addiu
    nop
    jal wait_1s
    nop
    
    jal n5_slt_test    #slt
    nop
    jal wait_1s
    nop
    
    jal n7_and_test    #and
    nop
    jal wait_1s
    nop
    jal n8_or_test     #or
    nop
    jal wait_1s
    nop
    jal n9_xor_test    #xor
    nop
    jal wait_1s
    nop
    jal n10_nor_test   #nor
    nop
    jal wait_1s
    nop
    jal n11_sll_test   #sll
    nop
    jal wait_1s
    nop
    jal n12_srl_test   #srl
    nop
    jal wait_1s
    nop
    jal n13_sra_test   #sra
    nop
    jal wait_1s
    nop
    jal n14_lw_test    #lw
    nop
    jal wait_1s
    nop
    jal n15_sw_test    #sw
    nop
    jal wait_1s
    nop
    jal n16_beq_test   #beq
    nop
    jal wait_1s
    nop
    jal n17_bne_test   #bne
    nop
    jal wait_1s
    nop
    jal n18_jal_test   #jal
    nop
    jal wait_1s
    nop
    jal n19_jr_test    #jr
    nop
    jal wait_1s
    nop
    jal n20_beq_ds_test  #beq delay slot
    nop
    jal wait_1s
    nop
    jal n21_bne_ds_test  #bne delay slot
    nop
    jal wait_1s
    nop
    jal n22_jal_ds_test  #jal delay slot
    nop
    jal wait_1s
    nop
    jal n23_jr_ds_test   #jr delay slot
    nop
    jal wait_1s
    nop
#endif
############################
############################
###lab6 test
#if lab6
    jal n24_add_test    #add
    nop
    jal wait_1s
    nop
    jal n25_addi_test   #addi
    nop
    jal wait_1s
    nop
    jal n26_sub_test    #sub
    nop
    jal wait_1s
    nop
    
    
    jal n29_andi_test   #andi
    nop
    jal wait_1s
    nop
    jal n30_ori_test    #ori
    nop
    jal wait_1s
    nop
    jal n31_xori_test   #xori
    nop
    jal wait_1s
    nop
    jal n32_sllv_test   #sllv
    nop
    jal wait_1s
    nop
    jal n33_srav_test   #srav
    nop
    jal wait_1s
    nop
    jal n34_srlv_test   #srlv
    nop
    jal wait_1s
    nop
    
#endif
############################
############################
###lab7 test
#if lab7
    jal n43_j_test          #j
    nop
    jal wait_1s
    nop
    jal n44_bgez_test       #bgez
    nop
    jal wait_1s
    nop
    
    jal n46_blez_test       #blez
    nop
    jal wait_1s
    nop
    jal n47_bltz_test       #bltz
    nop
    jal wait_1s
    nop
    
    jal n50_jalr_test       #jalr
    nop
    jal wait_1s
    nop
    jal n51_j_ds_test       #j delay slot
    nop
    jal wait_1s
    nop
    jal n52_bgez_ds_test    #bgez delay slot
    nop
    jal wait_1s
    nop
    
    jal n54_blez_ds_test    #blez delay slot
    nop
    jal wait_1s
    nop
    jal n55_bltz_ds_test    #bltz delay slot
    nop
    jal wait_1s
    nop
    
    jal n58_jalr_ds_test    #jalr delay slot
    nop
    jal wait_1s
    nop
    jal n59_lb_test         #lb
    nop
    jal wait_1s
    nop
    
    jal n65_sb_test         #sb
    nop
    jal wait_1s
    nop
    
#endif
############################


test_end:
    LI  (s0, TEST_NUM)
    NOP4
    beq s0, s3, 1f
    nop

    LI (a0, LED_ADDR)
	LI (a1, LED_RG1_ADDR)
    LI (a2, LED_RG0_ADDR)
	
    LI (t1, 0x0002)
    NOP4
    
	sw zero, 0(a0)
    sw t1, 0(a1)
    sw t1, 0(a2)
    b  2f
    nop
1:
    LI (t1, 0x0001)
    LI (a0, LED_RG1_ADDR)
	LI (a1, LED_RG0_ADDR)
    NOP4
    sw t1, 0(a0)
    sw t1, 0(a1)

2:
	//LI (t1, 0xff)
	//LI (t0, UART_ADDR)
	//sw t1, 0(t0)

	jal test_finish
    nop

wait_1s:
    LI (t0,SW_INTER_ADDR)
    LI (t1, 0xaaaa)

    #initial t3
    lw    t2, 0x0(t0)   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor   t2, t2, t1
    NOP4
    sll   t3, t2, 9     #t3 = switch interleave << 9
    NOP4
    addiu t3, t3, 1
    NOP4

sub1:  
    addiu t3, t3, -1

    #select min{t3, switch_interleave}
    lw    t2, 0x0(t0)   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor   t2, t2, t1
    NOP4
    sll   t2, t2, 9     #switch interleave << 9
    NOP4
    sltu  t4, t3, t2
    NOP4
    bnez  t4, 1f 
    nop
    addu  t3, t2, 0
    NOP4
1:
    bne   t3,zero, sub1
    nop
    jr ra
    nop
