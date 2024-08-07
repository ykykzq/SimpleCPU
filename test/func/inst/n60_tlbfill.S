#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n60_tlbfill_test)
### disable trace comp
    li.w        t0, OPEN_TRACE_ADDR 
    li.w        t1, CONFREG_NULL 
    st.w        zero, t1, 0 
    st.w        zero, t1, 0  
    st.w        zero, t0, 0
    st.w        zero, t1, 0 
    st.w        zero, t1, 0   
    ld.w        zero, t1, 0
    ld.w        t0, t0, 0

    addi.w s0, s0 ,0x1
	li.w     s2, 0x0

    li.w     t0, 0x0c000000 #index
    li.w     t1, 0xabc<<13  #VPN
    li.w     t2, 0x0fabc041 #PFN1 
    li.w     t3, 0x0ffbc041 #PFN1 
    csrwr  t0, csr_tlbidx
    csrwr  t1, csr_tlbehi
    csrwr  t2, csr_tlbelo0
    csrwr  t3, csr_tlbelo1
    tlbfill
    tlbfill
    tlbfill
    tlbfill
   
    li.w     t6, TLB_ENTRY
    li.w     t5, 0x0
    li.w     t4, 0x0
    li.w     t0, 0x0c000000

2:
    addi.w t1, t0, 0x0
    csrwr  t1, csr_tlbidx
    tlbrd
    csrrd  t1, csr_tlbehi
    li.w     t2, 0xffffe000
    and    t1, t1, t2
    li.w     t2, 0xabc << 13
    bne    t1, t2, 1f
    addi.w t5, t5, 0x1 
1:
    addi.w t4, t4, 0x1 
    addi.w t0, t0, 0x1
    bne    t4, t6, 2b

    li.w     t1, 0x0
    beq    t5, t1, inst_error

###detect exception
    bne s2, zero, inst_error
###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error: 
### clear tlb-related CSR
    csrwr  zero, csr_tlbidx
    csrwr  zero, csr_tlbehi
    csrwr  zero, csr_tlbelo0
    csrwr  zero, csr_tlbelo1

### enable trace comp 
    li.w        t0, OPEN_TRACE_ADDR 
    li.w        t1, CONFREG_NULL
    st.w        zero, t1, 0 
    st.w        zero, t1, 0  
    st.w        t0, t0, 0
    st.w        zero, t1, 0 
    st.w        zero, t1, 0  
    ld.w        zero, t1, 0
    ld.w        t0, t0, 0 

    slli.w t1, s0, 24
    or t0, t1, s3 
    st.w t0, s1, 0x0
    jirl zero, ra, 0x0
END(n60_tlbfill_test)
