#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n71_tlb_ex_test)
    addi.w s0, s0, 0x1
  
    invtlb    0x0, zero, zero

    //clear ti
    li.w      t0, 0x1 
    csrwr   t0, csr_ticlr 
      
    li.w    t0, 0x1c008000
    csrwr t0, csr_eentry
    li.w    t1, 0x1c000000 + TLBREBASE
    csrwr t1, csr_tlbrentry

    li.w        t3, 0x0c000001
    li.w        t0, 0x1c008000
    li.w        t1, 0xffffe000
    and       t4, t0, t1
    srli.w    t4, t4, 0x4 
    li.w        t1, 0x4d
    or        t1, t4, t1
    li.w        t2, 0x14d
    or        t2, t4, t2
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
 
    li.w        t0, DATABASE
    li.w        t1, 0xffffe000
    and       t4, t0, t1
    srli.w    t4, t4, 0x4 
    li.w        t1, 0x5f
    or        t1, t4, t1
    li.w        t2, 0x14d
    or        t2, t4, t2
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
   
    la.local  t0, 7f
7:
    li.w        t1, 0xffffe000
    and       t4, t0, t1
    srli.w    t4, t4, 0x4 
    li.w        t1, 0x4d
    or        t1, t4, t1
    li.w        t2, 0x14d
    or        t2, t4, t2
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
    FILL_TLB_ITEM_r
  
    //set datm=1
    li.w      t0, 0xa0 
    li.w      t1, 0x180
    csrxchg t0, t1, csr_crmd

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

### TLB refill error
    li.w      t5, 0x3
    lu12i.w s7, 0xe
    li.w s8, 0x200ff << 13
    la.local s4, 1f
1:
    ld.w  t2, s8, 0x0
    bne   s2, s7, inst_error 
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0   //return to kernel mode

### TLB page invalid error in ld
    
    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    LI_EXIMM(t0,s2,IMM_LDINV)

    ###fill in a present but invalid TLB item
    FILL_TLB_ITEM(0x0c000000, 0x20fff<<13, 0x000f004c, 0x000a004c) 
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w       t5, 0x3
    lu12i.w  s7, 0x1
    li.w       s8, 0x20fff<<13 
    la.local s4, 2f
    li.w    t0, 0xffffffff
2:
    ld.w  t0, s8, 0x0
    bne   s2, s7, inst_error 
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0    //return to kernel mode

### TLB page invalid error in st
    
    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    LI_EXIMM(t0,s2,IMM_STINV)

    ###fill in a present but invalid TLB item
    FILL_TLB_ITEM(0x0c000000, 0x200ab<<13, 0x000c004c, 0x000d004c) 
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w       t5, 0x3
    lu12i.w  s7, 0x2
    li.w       s8, 0x200ab<<13
    li.w       t0, 0xfff
    la.local s4, 3f
3:
    st.w  t0, s8, 0x0
    bne   s2, s7, inst_error 
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0   //return to kernel mode 

### TLB PME 
    //let DA=1 and PG=0 and prl=0 
    li.w      t0, 0x08 
    li.w      t1, 0x1f 
    csrxchg t0, t1, csr_crmd  

    LI_EXIMM(t0,s2,IMM_PME)
    
    li.w      t0, 0xd0010 
    li.w      s2, 0xff 
    st.w    s2, t0, 0

    ###fill in a present but not dirty TLB item 
    FILL_TLB_ITEM(0x0c000000, 0x200ab<<13, 0x000d04d, 0x000d14d)
    
    //let DA=0 and PG=1 and prl=0 
    li.w       t0, 0x10 
    li.w       t1, 0x18 
    csrxchg  t0, t1, csr_crmd

    li.w       t5, 0x0 
    lu12i.w  s7, 0x70 
    li.w       s8, 0x200ab<<13 
    addi.w   s8, s8, 0x10
    li.w       t0, 0xfff  
    la.local s4, 1f 
1:
    st.w     t0, s8, 0 
    bne      s2, s7, inst_error 
    li.w       t0, 0x08 
    li.w       t1, 0x1f 
    csrxchg  t0, t1, csr_crmd  
    li.w       t0, 0xd0010 
    ld.w     t1, t0, 0 
    li.w       t2, 0xff 
    bne      t2, t1, inst_error

### TLB privilage error
 
    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    LI_EXIMM(t0,s2,IMM_TLBPRV)

    ###fill in a present and valid item but prl = 0
    FILL_TLB_ITEM(0x0c000000, 0x200ab<<13, 0x000c0001, 0x000d0001) 
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w       t5, 0x3
    lu12i.w  s7, 0x7
    li.w       s8, 0x200ab<<13
    li.w       t0, 0xfff
    la.local s4, 4f
4:
    st.w  t0, s8, 0x0 
    bne   s2, s7, inst_error  
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0   //return to kernel mode

### TLB page modified error
 
    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    LI_EXIMM(t0,s2,IMM_TLBM)

    ###fill in a present and valid item but V=0
    FILL_TLB_ITEM(0x0c000000, 0x200ab<<13, 0x000c000d, 0x000d000d) 
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w       t5, 0x3
    lu12i.w  s7, 0x4
    li.w       s8, 0x200ab<<13
    li.w       t0, 0xfff
    la.local s4, 5f
5:
    st.w  t0, s8, 0x0
    bne   s2, s7, inst_error 
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0  // return to kernel mode

### TLB page invalid error in inst fetch
 
    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    LI_EXIMM(t0,s2,IMM_FETCHINV)

    ###fill in a present but invalid item
    FILL_TLB_ITEM(0x0c000000, 0x200ff<<13, 0x000c004c, 0x000d004c) 
    csrwr    zero, csr_tlbehi

    //let DA=0 and PG=1 and prl=3
    li.w      t0, 0x13
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w       t5, 0x3
    lu12i.w  s7, 0x3
    li.w       s8, 0x200ff<<13
    la.local s4, 6f
6:
    jirl  zero, s8, 0x0
    bne   s2, s7, inst_error
    LI_EXIMM(t0,s2,IMM_KERNEL)
    syscall 0  // return to kernel mode

### TLB address error in memory access: adem
//2023.4.3 ADE changed, no ADEM now
//    //let DA=1 and PG=0 and prl=0
//    li.w      t0, 0x08
//    li.w      t1, 0x1f
//    csrxchg t0, t1, csr_crmd 
//
//    LI_EXIMM(t0,s2,IMM_TLBADEM)
//
//    ###fill in a present and valid entry 
//    FILL_TLB_ITEM(0x0c000000,0x800fc000, 0x000f004d, 0x000a004d) 
//    csrwr    zero, csr_tlbehi
//
//    let DA=0 and PG=1 and prl=3
//    li.w      t0, 0x13
//    li.w      t1, 0x1f
//    csrxchg t0, t1, csr_crmd 
//
//    li.w       t5, 0x3
//    lu12i.w  s7, 0x81
//    li.w       s8, 0x800fc000
//    la.local s4, 7f
//7:
//    ld.w  t0, s8, 0x0
//    bne   s2, s7, inst_error 
//    LI_EXIMM(t0,s2,IMM_KERNEL)
//    syscall 0  // return to kernel mode


### TLB address error in inst fetch: adef
//2023.4.3 ADE changed, ADEF only happen when not aligned
//    //let DA=1 and PG=0 and prl=0
//    li.w      t0, 0x08
//    li.w      t1, 0x1f
//    csrxchg t0, t1, csr_crmd 
//
//    LI_EXIMM(t0,s2,IMM_TLBADEF)
//
//    ###fill in a present but invalid item 
//    FILL_TLB_ITEM(0x0c000000,0x800fc000, 0x000f004d, 0x000a004d) 
//    csrwr    zero, csr_tlbehi
//
//    //let DA=0 and PG=1 and prl=3
//    li.w      t0, 0x13
//    li.w      t1, 0x1f
//    csrxchg t0, t1, csr_crmd 
//
//    li.w       t5, 0x3
//    lu12i.w  s7, 0x80
//    li.w       s8, 0x800fc000
//    la.local s4, 8f
//8:
//    jirl  zero, s8, 0x0
//    bne   s2, s7, inst_error
//    LI_EXIMM(t0,s2,IMM_KERNEL)
//    syscall 0  // return to kernel mode

###func end here and recover the DA=1

    //let DA=1 and PG=0 and prl=0
    li.w      t0, 0x08
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd  

    //set datm=0 
    li.w      t0, 0x0 
    li.w      t1, 0x180 
    csrxchg t0, t1, csr_crmd

###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error:  
    slli.w t1, s0, 24
    or t0, t1, s3 
    st.w t0, s1, 0x0
    jirl zero, ra, 0x0
END(n71_tlb_ex_test)
