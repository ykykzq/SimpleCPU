#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n72_dmw_test)
    addi.w s0, s0 ,0x1
	li.w     s2, 0x0

    //store some values
    //for DA mode
    li.w     t0, 0xf
    li.w     t1, 0xe0000000
    st.w   t0, t1, 0x0
    
    //for DMW mode
    li.w     t8, 0x4c000020
    li.w     t1, 0xc0000000
    st.w   t8, t1, 0x0

    li.w     t7, 0xbb
    li.w     t1, 0x80000000
    st.w   t7, t1, 0x0

    //for TLB mode
    li.w     t0, 0xc
    li.w     t1, 0x90000000
    st.w   t0, t1, 0x0

    // config the DMW for ld
    li.w     t0, 0xec000009
    csrwr  t0, csr_dmw0

    invtlb 0x0, zero, zero
    
    li.w     t0, 0x48000008
    csrwr  t0, csr_dmw1

    csrwr  zero, csr_tlbehi

    invtlb 0x0, zero, zero
   
    //config the TLB entry for inst fetching
    la.local t0, 1f
1:
    add.w zero, zero, zero
    li.w     t1, 0xffffe000
    and    t4, t0, t1 
    srli.w t4, t4, 0x4
    li.w     t1, 0x4d
    or     t1, t4, t1
    li.w     t2, 0x14d
    or     t2, t4, t2
    li.w     t3, 0x0c000000
    csrwr t3, csr_tlbidx 
    csrwr t0, csr_tlbehi 
    csrwr t1, csr_tlbelo0 
    csrwr t2, csr_tlbelo1 
    tlbwr  

    li.w     t0, DATABASE
    li.w     t1, 0xffffe000 
    and    t4, t0, t1 
    srli.w t4, t4, 0x4 
    li.w     t1, 0x4f 
    or     t1, t4, t1 
    li.w     t2, 0x14f 
    or     t2, t4, t2 
    li.w     t3, 0x0c000002 
    csrwr t3, csr_tlbidx 
    csrwr t0, csr_tlbehi 
    csrwr t1, csr_tlbelo0 
    csrwr t2, csr_tlbelo1 
    tlbwr   

    li.w     t0, 0x1c008000 
    li.w     t1, 0xffffe000
    and    t4, t0, t1 
    srli.w t4, t4, 0x4
    li.w     t1, 0x4d
    or     t1, t4, t1
    li.w     t2, 0x14d
    or     t2, t4, t2
    li.w     t3, 0x0c000003
    csrwr t3, csr_tlbidx 
    csrwr t0, csr_tlbehi 
    csrwr t1, csr_tlbelo0 
    csrwr t2, csr_tlbelo1 
    tlbwr  

    // config the TLB entry for ld
    FILL_TLB_ITEM(0x0c000001, 0xe0000000, 0x900004d, 0x0)
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=0
    li.w      t0, 0x10
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w      t0, 0xe0000000
    ld.w    t3, t0, 0x0

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x3
    li.w      t1, 0x3
    csrxchg t0, t1, csr_crmd
  
    li.w      t0, 0xe0000000       //should not generate adem excp
    ld.w    t0, t0, 0x0
    bne     t0, t3, inst_error
  
    add.w   t2, ra, zero 
    li.w      t0, 0xe0000000       //should not generate adef excp
    jirl    ra, t0, 0 
    add.w   ra, t2, zero

    //let DA=0 and PG=1 and prl=3
    //li      t0, 0x13
    //li      t1, 0x1f
    //csrxchg t0, t1, csr_crmd 

    li.w      t0, 0x40000000
    ld.w    t6, t0, 0x0

    bne s2, zero, inst_error
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0   //return to kernel mode 
    li.w      s2, 0x0

    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    bne     t3, t8, inst_error
    bne     t6, t7, inst_error

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
END(n72_dmw_test)
