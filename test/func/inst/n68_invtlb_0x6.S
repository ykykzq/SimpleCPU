#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n68_invtlb_0x6_test)
    addi.w s0, s0 ,1
    addi.w s2, zero, 0x0

    csrrd  t5, csr_tlbehi 
    csrrd  t6, csr_tlbelo0 
    csrrd  t7, csr_tlbelo1 
    csrrd  t8, csr_tlbidx 
    li.w   t0, 0x80000000 
    or     t8, t8, t0 
    srli.w t8, t8, TLB_IDX

    li.w    s4, 0x000000aa
	li.w    t0, 8<<13
	li.w    t1, 1<<13
    add.w s5, t0, t1
    invtlb 0x6, s4, s5

	li.w     t0, 0x0c000000
    addi.w t4, t0, 0x1
1:
    addi.w t1, t0, 0x0
    csrwr t1, csr_tlbidx
    tlbrd
    csrrd t1, csr_tlbehi
#li    t2, 0x0 
    bne   t1, t5, inst_error
    csrrd t1, csr_tlbelo0
#li    t2, 0x0
    bne   t1, t6, inst_error
    csrrd t1, csr_tlbelo1
#li    t2, 0x0
    bne   t1, t7, inst_error
    li.w  t1, 0x3f000000
    csrxchg zero, t1, csr_tlbidx
    csrrd t1, csr_tlbidx
    srli.w  t1, t1, TLB_IDX
#li    t2, 0x04000000
    bne   t1, t8, inst_error
    addi.w t0, t0, 0x1  
    bne   t0, t4, 1b

	li.w     t4, 0x0c000000
    addi.w t0, t4, 0x1
    addi.w t4, t4, 0x10
2:
    addi.w t1, t0, 0x0
    csrwr t1, csr_tlbidx
    tlbrd
    csrrd t1, csr_tlbidx
    srli.w t1, t1, TLB_IDX
    li.w  t2, 0x00c00000
    bne   t1, t2, inst_error
    addi.w t0, t0, 0x1  
    bne   t0, t4, 2b

###detect exception
    bne s2, zero, inst_error
###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error:  
    slli.w t1, s0, 24
    or t0, t1, s3 
    st.w t0, s1, 0x0
    jirl zero, ra, 0x0
END(n68_invtlb_0x6_test)
