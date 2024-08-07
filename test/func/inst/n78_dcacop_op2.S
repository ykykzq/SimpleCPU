#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n78_dcacop_op2)
    addi.w    s0, s0, 0x1
    add.w     s2, zero, zero

    //clear ti
    li.w      t0, 0x1 
    csrwr   t0, csr_ticlr  

    li.w    t0, 0x1c008000
    csrwr zero, csr_eentry
    csrwr t0, csr_eentry
    li.w    t1, 0x1c000000 + TLBREBASE
    csrwr zero, csr_tlbrentry
    csrwr t1, csr_tlbrentry 
 
    la.local  t7, start
start: 
# clear DMW
    csrwr     zero, csr_dmw0 
    csrwr     zero, csr_dmw1  

    li.w      t0, 0xd0100000
    li.w      t1, 0xffff
    st.w    t1, t0, 0x0 

# set up the DMW, let the MAT=01(Coherent Cached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x19
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero

    li.w        t7, 0xd0100000
# set up the inst DMW, let the MAT=01(Coherent Cached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x19
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero 

# set up the CRMD, let DA=0, PG=1, and PRL=0
    //let DA=0 and PG=1 and prl=0
    li.w      t0, 0x10
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

# the size of cacop li.wne: 16Bytes( 4 insts)

    li.w      t0, 0xd0100000
    li.w      t1, 0xffffffff
    st.w    t1, t0, 0x0
    ld.w    t1, t0, 0x0
    li.w      t1, 0xeeeeeeee
    st.w    t1, t0, 0x0

# deal with the coherence in the old cacop in dcacop by hitting
    li.w        t0, 0xd0100000
    cacop     0x11, t0, 0x0

# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x9
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero

    li.w        t0, 0xd0100000
    ld.w      t1, t0, 0x0
    li.w        t2, 0xeeeeeeee
    bne       t1, t2, inst_error

# next codes are used to test if invalid addr would triger tlb error
# set PG=1, DA=0
    li.w        t0, 0x10
    li.w        t1, 0x18
    csrxchg   t0, t1, csr_crmd  

# fill in an present but invalid TLB entry
    FILL_TLB_ITEM(0x0c000000, 0x80f00000, 0x00abc040, 0x00afc040)
# fill in a present and valid item and prl = 0 TLB entry
    FILL_TLB_ITEM(0x0c000001, 0x20ab<<13, 0x000c0041, 0x000d0041)

    csrrd   t0, csr_crmd
    li.w      t1, 0x3
    and     t5, t0, t1
   
# test if cacop can triger tlb refill error or not 
    lu12i.w s7, 0xe 
    li.w s8, 0x2aeff << 13
    la.local s4, tlb_refill_error
tlb_refill_error:
    cacop 0x11, s8, 0x0 
    bne   s2, s7, inst_error
    csrrd t0, csr_crmd
    li.w    t1, 0x7 
    and   t0, t0, t1
    bne   t5, t0, inst_error

# test if cacop can triger tlb page invalid error or not
    li.w    t0, DATABASE
    li.w    t1, 0x8 
    st.w  t1, t0, 0

    lu12i.w s7, 0x1 
    li.w s8, 0x80f00000
    la.local s4, tlb_invalid_error
tlb_invalid_error:
    cacop 0x11, s8, 0x0 
    bne   s2, s7, inst_error
    csrrd t0, csr_crmd
    li.w    t1, 0x7 
    and   t0, t0, t1
    bne   t5, t0, inst_error
   
inst_pass:
###detect exception
#   bne s2, zero, inst_error
###score ++
    addi.w    s3, s3, 0x1
###output
inst_error:
    li.w        t0, 0x8 
    li.w        t1, 0x1f 
    csrxchg   t0, t1, csr_crmd 

    slli.w    t1, s0, 24
    or        t0, t1, s3
    st.w      t0, s1, 0x0
    jirl      zero, ra, 0x0
END(n78_dcacop_op2)
