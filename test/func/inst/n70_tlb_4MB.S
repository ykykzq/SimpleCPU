#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n70_tlb_4MB)
    addi.w s0, s0 ,0x1
	li.w     s2, 0x0

    invtlb 0x0, zero, zero

    li.w  t0, 0x15000000            #index with 4MB PS
    li.w  t2, 8<<22
    li.w  t3, 1<<22
    add.w t1, t2, t3                #VPN

    li.w    t2, 0x000000aa
    csrwr t2, csr_asid

###TLB item 1
    FILL_TLB_4MB(0x00010000)
###TLB item 2
    FILL_TLB_4MB(0x00050000)
###TLB item 3
    FILL_TLB_4MB(0x00090000)
###TLB item 4 G=1
    FILL_TLB_4MB(0x000d0040)

    csrwr  zero, csr_tlbehi
    csrwr  zero, csr_tlbelo0
    csrwr  zero, csr_tlbelo1 
    csrwr  zero, csr_tlbidx

###tlb hit: G=0
    TEST_TLBSRCH_4MB(0x000000aa, 0x1, 0x00000000)
    TEST_TLBSRCH_4MB(0x000000aa, 0x2, 0x00000001)
    TEST_TLBSRCH_4MB(0x000000aa, 0x3, 0x00000002)
###tlb hit: G=1
    TEST_TLBSRCH_4MB(0x000000bb, 0x4, 0x00000003)
###tlb miss: no matching asid
    TEST_TLBSRCH_NOMATCHING_4MB(0x000003f0, 0x2)
###tlb miss: no matching VPN
    TEST_TLBSRCH_NOMATCHING_4MB(0x000000aa, 0x7f)

###detect exception
    bne s2, zero, inst_error
###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error:  
    slli.w t3, s0, 24
    or t0, t3, s3 
    st.w t0, s1, 0x0
    jirl zero, ra, 0x0
END(n70_tlb_4MB)
