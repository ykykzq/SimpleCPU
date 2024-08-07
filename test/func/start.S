#include "asm.h"
#include "regdef.h"
#include "cpu_cde.h"
#include "test_define.h"
#include "test_config.h"

#define TEST_NUM (TEST1*20 + TEST2*16 + TEST3*10 + TEST4*1 + TEST5*11 + TEST6*12 + TEST7*2 + TEST8*7 + TEST9*2)


#if TEST8
#define CSR_INIT
#endif

##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
    .globl    _start
    .globl     start
    .globl    __main
_start:
start:
    li.w     t0, 0xffffffff
    addi.w t0, zero, -1
#ifdef CSR_INIT
    ori    $r1,$r0,0x28
    csrwr  $r1,0x0
#endif
    b    locate
    NOP4

##avoid "j locate" not taken
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0

##avoid cpu run error
.org 0x0ec
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0
.org 0x100
test_finish:
    addi.w    t0, t0, 1
    LI        (t2, UART_ADDR)
    st.w      zero, t2, 0
1:
    b         1b
    NOP4

##avoid cpu run error
    lu12i.w   t0, -0x80000
    addi.w    t1, t1, 1
    or        t2, t0, zero
    add.w     t3, t5, t6
    ld.w      t4, t0, 0

#if (!SHORT_TEST1)
/*
 *  exception handle
 */
.org 0x8000   //0x1c008000
1:  
    GET_EXIMM(t1)
    li.w    t0, IMM_SYSCALL 
    beq   t1, t0, syscall_ex  #syscall  
    li.w    t0, IMM_BREAK 
    beq   t1, t0, brk_ex      #break 
    li.w    t0, IMM_INE 
    beq   t1, t0, ine_ex      #reserved inst 
    li.w    t0, IMM_INT 
    beq   t1, t0, int_ex      #interrupt 
    li.w    t0, IMM_ADEF 
    beq   t1, t0, adef_ex     #adef 
    li.w    t0, IMM_ALE 
    beq   t1, t0, ale_ex      #ale 
    li.w    t0, IMM_PME 
    beq   t1, t0, pme_ex      #pme
    li.w    t0, IMM_LDINV
    beq   t1, t0, ld_page_invalid
    li.w    t0, IMM_STINV
    beq   t1, t0, st_page_invalid
    li.w    t0, IMM_TLBPRV
    beq   t1, t0, tlb_prl_error
    li.w    t0, IMM_TLBM
    beq   t1, t0, tlb_page_modified_error
    li.w    t0, IMM_FETCHINV
    beq   t1, t0, fetch_page_invalid
    li.w    t0, IMM_TLBADEM
    beq   t1, t0, tlb_adem_error
    li.w    t0, IMM_TLBADEF
    beq   t1, t0, tlb_adef_error
    li.w    t0, IMM_KERNEL 
    beq   t1, t0, syscall_bak_kernel_mode
    b     test_end

syscall_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(SYS)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x10 
    b        ex_finish  

brk_ex: 
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(BRK)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x20 
    b        ex_finish  

ine_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(INE)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x30 
    b        ex_finish 

int_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(INT)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    li.w       t1, 0x1 
    csrwr    t1, csr_ticlr 
    bne      t1, zero, ex_finish 
    li.w       t1, 0x0 
    li.w       t0, 0x3 
    csrxchg  t1, t0, csr_estat 
    csrrd    t1, csr_estat
    li.w       t0, 0x1fff 
    and      t0, t0, t1 
    bne      t0, zero, ex_finish 
    lu12i.w  s2, 0x40 
    b        ex_finish 

adef_ex:
    add.w    s2, zero, zero
    csrwr    s5, csr_era
    bne      s4, s5, ex_finish 
    CHECK_ECODE   (ADE)
    CHECK_ESUBCODE(ADEF_SUBCODE)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x50 
    b        ex_finish  

ale_ex:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(ALE)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    lu12i.w  s2, 0x60 
    b        ex_finish  
    
pme_ex:
    add.w    s2, zero, zero 
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(PME)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish 
    srli.w   s8, s8, 13 
    slli.w   s8, s8, 13
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x70 
    b        ex_finish  

ld_page_invalid:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(PIL)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x1
    b        ex_finish  
    
st_page_invalid:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(PIS)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x2
    b        ex_finish  
    
tlb_prl_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(PPI)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x7
    b        ex_finish  
    
tlb_page_modified_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE(PME)
    csrrd    t0, csr_estat 
    li.w       t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w       t1, 0x00040000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x4
    b        ex_finish  
     
fetch_page_invalid:
    add.w    s2, zero, zero
    li.w       t0, 0xffffffff
    csrrd    t0, csr_era 
    bne      s8, t0, ex_finish 
    addi.w   t0, s4, 0x0
    csrwr    t0, csr_era
    CHECK_ECODE(PIF)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0x3
    b        ex_finish  

tlb_adem_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    CHECK_ECODE   (ADE         )
    CHECK_ESUBCODE(ADEM_SUBCODE)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish 
    csrrd    t0, csr_tlbehi
    bne      t0, zero, ex_finish 
    lu12i.w  s2, 0x81
    b        ex_finish  
     
tlb_adef_error:
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s8, t0, ex_finish 
    addi.w   t0, s4, 0x0
    csrwr    t0, csr_era
    CHECK_ECODE   (ADE         )
    CHECK_ESUBCODE(ADEF_SUBCODE)
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t5, t0, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish 
    csrrd    t0, csr_tlbehi
    bne      t0, zero, ex_finish 
    lu12i.w  s2, 0x80
    b        ex_finish  

syscall_bak_kernel_mode:
    li.w       t0, 0x3 
    csrxchg  zero, t0, csr_prmd 
    csrrd    t1, csr_era 
    addi.w   t1, t1, 0x4 
    csrwr    t1, csr_era 
    ertn

.org TLBREBASE   //TLBREBASE
    add.w    s2, zero, zero
    csrrd    t0, csr_era 
    bne      s4, t0, ex_finish 
    csrrd    t0, csr_estat 
    li.w       t1, 0x7fff0000 
    and      t0, t0, t1 
    li.w       t1, 0x003f0000 
    bne      t1, t0, ex_finish 
    csrrd    t0, csr_crmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    li.w       t1, 0x0 
    bne      t1, t0, ex_finish
    csrrd    t0, csr_prmd 
    li.w       t1, 0x7 
    and      t0, t0, t1 
    bne      t0, t5, ex_finish 
    csrrd    t0, csr_badv
    bne      t0, s8, ex_finish
    csrrd    t0, csr_tlbehi
    bne      t0, s8, ex_finish
    lu12i.w  s2, 0xe
    b        ex_finish  
 
ex_finish:
    add.w    zero, zero, zero
    csrrd    t1, csr_era 
    addi.w   t1, t1, 0x4 
    csrwr    t1, csr_era 
    addi.w   t1, s2, 0x0
    bne      s2, zero, ex_ret
    lu12i.w  s2, 0xffff 
ex_ret:
    ertn

#endif

.org CODEBASE
locate:

    LI (a0, LED_RG1_ADDR)
    LI (a1, LED_RG0_ADDR)
    LI (a2, LED_ADDR)
    LI (s1, NUM_ADDR)

    LI (t1, 0x0002)
    LI (t2, 0x0001)
    LI (t3, 0x0000ffff)
    lu12i.w   s3, 0
    NOP4

    st.w      t1, a0, 0
    st.w      t2, a1, 0
    st.w      t3, a2, 0
    st.w      s3, s1, 0
    lu12i.w   s0, 0
    NOP4
inst_test: 
############################
###TEST1 test
#if TEST1
    bl n1_lu12i_w_test    #lu12i.w
    NOP4
    bl idle_1s
    NOP4

    bl n2_add_w_test   #add.w
    NOP4
    bl idle_1s
    NOP4

    bl n3_addi_w_test  #add.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n4_sub_w_test   #sub.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n5_slt_test    #slt
    NOP4
    bl idle_1s
    NOP4
    
    bl n6_sltu_test   #sltu
    NOP4
    bl idle_1s
    NOP4
    
    bl n7_and_test    #and
    NOP4
    bl idle_1s
    NOP4
    
    bl n8_or_test     #or
    NOP4
    bl idle_1s
    NOP4
    
    bl n9_xor_test    #xor
    NOP4
    bl idle_1s
    NOP4
    
    bl n10_nor_test   #nor
    NOP4
    bl idle_1s
    NOP4
    
    bl n11_slli_w_test   #slli.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n12_srli_w_test   #srli.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n13_srai_w_test   #srai.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n14_ld_w_test    #ld.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n15_st_w_test    #st.w
    NOP4
    bl idle_1s
    NOP4
    
    bl n16_beq_test   #beq
    NOP4
    bl idle_1s
    NOP4
    
    bl n17_bne_test   #bne
    NOP4
    bl idle_1s
    NOP4
    
    bl n18_bl_test   #bl
    NOP4
    bl idle_1s
    NOP4
    
    bl n19_jirl_test    #jirl
    NOP4
    bl idle_1s
    NOP4
    
    bl n20_b_test    #b
    NOP4
    bl idle_1s
    NOP4
    
#endif
############################
############################
###TEST2 test
#if TEST2
    bl n21_pcaddu12i_test   #pcaddu12i
    bl idle_1s
    
    bl n22_slti_test   #slti
    bl idle_1s
    
    bl n23_sltui_test  #sltui
    bl idle_1s
    
    bl n24_andi_test   #andi
    bl idle_1s
    
    bl n25_ori_test    #ori
    bl idle_1s
    
    bl n26_xori_test   #xori
    bl idle_1s
    
    bl n27_sll_w_test   #sll.w
    bl idle_1s
    
    bl n28_sra_w_test   #sra.w
    bl idle_1s
    
    bl n29_srl_w_test   #srl.w
    bl idle_1s
    
    bl n30_div_w_test    #div.w
    bl idle_1s
    
    bl n31_div_wu_test   #div.wu
    bl idle_1s
    
    bl n32_mul_w_test   #mul.w
    bl idle_1s
    
    bl n33_mulh_w_test  #mulh.w
    bl idle_1s
    
    bl n34_mulh_wu_test   #mulh.wu
    bl idle_1s
    
    bl n35_mod_w_test   #mod.w
    bl idle_1s
    
    bl n36_mod_wu_test   #mod.wu
    bl idle_1s
    
#endif
############################
############################
###TEST3 test
#if TEST3
    bl n37_blt_test          #blt
    bl idle_1s
    
    bl n38_bge_test       #bge
    bl idle_1s
    
    bl n39_bltu_test       #bltu
    bl idle_1s
    
    bl n40_bgeu_test       #bgeu
    bl idle_1s
    
    bl n41_ld_b_test       #ld.b
    bl idle_1s
    
    bl n42_ld_h_test     #ld.h
    bl idle_1s
    
    bl n43_ld_bu_test     #ld.bu
    bl idle_1s
    
    bl n44_ld_hu_test       #ld.hu
    bl idle_1s
    
    bl n45_st_b_test       #st.b
    bl idle_1s
    
    bl n46_st_h_test    #st.h
    bl idle_1s
    
#endif
############################
############################
###TEST4 test
#if TEST4 
    bl test4_init

    bl n47_syscall_ex_test       #syscall
    bl idle_1s
#endif 
############################
############################
###TEST5 test 
#if TEST5 
    bl test5_init

    bl n48_brk_ex_test         #brk ex 
    bl idle_1s 

    bl n49_ti_ex_test          #timer int ex 
    bl idle_1s 

    bl n50_ine_ex_test         #ine ex 
    bl idle_1s  

    bl n51_soft_int_ex_test    #soft int ex 
    bl idle_1s 

    bl n52_adef_ex_test         #adef ex 
    bl idle_1s  

    bl n53_ale_ld_w_ex_test     #ld.w ale ex 
    bl idle_1s 

    bl n54_ale_ld_h_ex_test     #ld.h ale ex 
    bl idle_1s 

    bl n55_ale_ld_hu_ex_test    #ld.hu ale ex 
    bl idle_1s 
    
    bl n56_ale_st_h_ex_test      #st.h ale ex 
    bl idle_1s 

    bl n57_ale_st_w_ex_test      #st.w ale ex 
    bl idle_1s 

    bl n58_rdcnt_test          #rdcntvl.w and rdcntvh.w test
    bl idle_1s

#endif

#if TEST6
    bl test6_init

    bl tlb_init
    bl n59_tlbrd_tlbwr_test
    bl idle_1s

    bl tlb_init
    bl n60_tlbfill_test
    bl idle_1s 

    bl tlb_init
    bl n61_tlbsrch_test
    bl idle_1s

    bl tlb_init
    bl n62_invtlb_0x0_test
    bl idle_1s

    bl tlb_init
    bl n63_invtlb_0x1_test
    bl idle_1s

    bl tlb_init
    bl n64_invtlb_0x2_test
    bl idle_1s

    bl tlb_init
    bl n65_invtlb_0x3_test
    bl idle_1s

    bl tlb_init
    bl n66_invtlb_0x4_test
    bl idle_1s

    bl tlb_init
    bl n67_invtlb_0x5_test
    bl idle_1s

    bl tlb_init
    bl n68_invtlb_0x6_test
    bl idle_1s

    bl tlb_init
    bl n69_invtlb_inv_op_test
    bl idle_1s
 
    bl n70_tlb_4MB
    bl idle_1s
#endif 

#if TEST7 
    bl test6_init
    
    bl n71_tlb_ex_test
    bl idle_1s

    bl n72_dmw_test
    bl idle_1s
#endif

#if TEST8
    bl test6_init

    bl n73_icacop_op0
    bl idle_1s

    bl n74_dcacop_op0
    bl idle_1s

    bl n75_icacop_op1
    bl idle_1s

    bl n76_dcacop_op1
    bl idle_1s

    bl n77_icacop_op2
    bl idle_1s

    bl n78_dcacop_op2
    bl idle_1s

    bl n79_cache_writeback
    bl idle_1s
#endif 

#if TEST9
    bl n80_ti_ex_idle_test      #timer int ex with idle
    bl idle_1s

    bl n81_atomic_ins_test      #ll.w and sc.w test
    bl idle_1s
#endif

test_end:
    LI  (s0, TEST_NUM)
    NOP4
    beq s0, s3, 1f
    NOP4

    LI (a0, LED_ADDR)
    LI (a1, LED_RG1_ADDR)
    LI (a2, LED_RG0_ADDR)

    LI (t1, 0x0002)
    NOP4
    
    st.w    zero, a0, 0
    st.w    t1, a1, 0
    st.w    t1, a2, 0
    li.w    a0, 0x1
    b  2f
    NOP4
1:
    LI (t1, 0x0001)
    LI (a0, LED_RG1_ADDR)
    LI (a1, LED_RG0_ADDR)
    NOP4
    st.w    t1, a0, 0
    st.w    t1, a1, 0
    li.w    a0, 0

2:
    //LI (t1, 0xff)
    //LI (t0, UART_ADDR)
    //sw t1, 0(t0)

    bl test_finish
    NOP4

idle_1s:
    NOP4
    LI (t0,SW_INTER_ADDR)
    LI (t1, 0xaaaa)

    #initial t3
    ld.w    t2, t0, 0   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor     t2, t2, t1
    NOP4
    slli.w  t3, t2, 9     #t3 = switch interleave << 9
    NOP4
    addi.w  t3, t3, 1
    NOP4

sub1:
    addi.w  t3, t3, -1

    #select min{t3, switch_interleave}
    ld.w    t2, t0, 0   #switch_interleave: {switch[7],1'b0, switch[6],1'b0...switch[0],1'b0}
    NOP4
    xor     t2, t2, t1
    NOP4
    slli.w  t2, t2, 9     #switch interleave << 9
    NOP4
    sltu    t4, t3, t2
    NOP4
    bne     t4, zero, 1f
    NOP4
    addi.w  t3, t2, 0
    NOP4
1:
    bne     t3, zero, sub1
    NOP4
    jirl    zero, ra, 0
    NOP4
