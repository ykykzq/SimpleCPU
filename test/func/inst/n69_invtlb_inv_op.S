#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n69_invtlb_inv_op_test) 
    li.w     t0, 0x1c008000 
    csrwr  t0, csr_eentry

    LI_EXIMM(t0,t1,IMM_INE)

    addi.w s0, s0 ,1
    addi.w s2, zero, 0x0
### 
    csrrd    t5, csr_crmd 
    andi     t5, t5, 0x7
    la.local s4, 1f
1:
    invtlb  0x7, zero, zero
    lu12i.w t1, 0x30
    bne     s2, t1, inst_error 

    addi.w   s2, zero, 0x0 
    la.local s4, 1f
1:
    invtlb  0x8, zero, zero
    lu12i.w t1, 0x30
    bne     s2, t1, inst_error 

    addi.w   s2, zero, 0x0 
    la.local s4, 1f
1:
    invtlb  0x9, zero, zero
    lu12i.w t1, 0x30
    bne     s2, t1, inst_error 

    addi.w   s2, zero, 0x0 
    la.local s4, 1f
1:
    invtlb  0xa, zero, zero
    lu12i.w t1, 0x30
    bne     s2, t1, inst_error

###score ++
    addi.w s3, s3, 1
###output (s0<<24)|s3
inst_error:  
    slli.w  t1, s0, 24
    or   t0, t1, s3 
    st.w   t0, s1, 0x0
    jirl zero, ra, 0x0
END(n69_invtlb_inv_op_test)
