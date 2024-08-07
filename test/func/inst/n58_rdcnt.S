#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n58_rdcnt_test)

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
    
    addi.w      s0, s0 ,1
    li.w        t6, 0x3b
    li.w          s2, 0x0 
    li.w          s7, 0x1111ffff 
    move        t1, s7
    csrwr       t1, csr_tid

##inst test
###1 
    rdcntvl.w   t1
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t2
    rdcntid     t0 
    bne         t0, s7, inst_error 
    li.w          s7, 0xffff1111 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error 

###2 
    li.w          s7, 0xffffffff 
    move        t1, s7
    csrwr       t1, csr_tid
    li.w          t7, (DATABASE+0x00004) 
    st.w        s4, t7, 4
    rdcntvl.w   t1
    rdcntid     t0 
    st.w        s4, t7, 0 
    ld.w        t5, t7, 4 
    bne         t5, s4, inst_error
    bne         t0, s7, inst_error 
    st.w        t7, t7, 4 
    st.w        s4, t7, 4
    rdcntvh.w   t2
    rdcntid     t0 
    st.w        s4, t7, 0 
    ld.w        t5, t7, 4 
    bne         t5, s4, inst_error
    bne         t0, s7, inst_error 
    li.w          s7, 0xffff0000 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error  

###3
    li.w          s7, 0xffff 
    move        t1, s7
    csrwr       t1, csr_tid
    li.w          t7, 0xf 
    li.w          t8, 0xf
    div.w       t7, t1, t6 
    rdcntvl.w   t1
    rdcntid     t0 
    beq         t8, t7, inst_error 
    bne         t0, s7, inst_error 
    li.w          t7, 0xf 
    li.w          t8, 0xf
    div.w       t7, t1, t6 
    rdcntvh.w   t2
    rdcntid     t0 
    beq         t8, t7, inst_error 
    bne         t0, s7, inst_error 
    li.w          s7, 0x0 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error  

###4
    li.w          s7, 0xff 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t1
    rdcntid     t0 
    div.w       t7, t0, t6 
    bne         t0, s7, inst_error 
    rdcntvh.w   t2
    rdcntid     t0 
    div.w       t7, t0, t6 
    bne         t0, s7, inst_error 
    li.w          s7, 0xffff11 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error 

###5
    li.w          s7, 0xf 
    move        t1, s7
    csrwr       t1, csr_tid
    li.w          t7, 0xf 
    li.w          t8, 0xf
    mul.w       t7, t6, t7
    rdcntvl.w   t1
    rdcntid     t0 
    beq         t8, t7, inst_error 
    bne         t0, s7, inst_error 
    li.w          t7, 0xf 
    li.w          t8, 0xf
    mul.w       t7, t6, t7
    rdcntvh.w   t2
    rdcntid     t0 
    beq         t8, t7, inst_error 
    bne         t0, s7, inst_error 
    li.w          s7, 0xf11 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error 

###6
    li.w          s7, 0xfffff 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t1
    rdcntid     t0 
    mul.w       t7, t0, t6 
    bne         t0, s7, inst_error 
    rdcntvh.w   t2
    rdcntid     t0 
    mul.w       t7, t0, t6 
    bne         t0, s7, inst_error 
    li.w          s7, 0x11fff 
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error 
    
###7
    li.w          s7, 0x23232 
    move        t1, s7
    csrwr       t1, csr_tid
    csrwr       t7, csr_era 
    rdcntvl.w   t1
    rdcntid     t0 
    csrwr       t8, csr_era
    bne         t0, s7, inst_error 
    csrwr       t7, csr_era 
    rdcntvh.w   t2
    rdcntid     t0 
    csrwr       t8, csr_era
    bne         t0, s7, inst_error 
    li.w          s7, 0xabab
    move        t1, s7
    csrwr       t1, csr_tid
    rdcntvl.w   t3
    rdcntid     t0 
    bne         t0, s7, inst_error 
    rdcntvh.w   t4
    rdcntid     t0 
    bne         t0, s7, inst_error 
    sub.w       t1, t3, t1 
    sub.w       t2, t4, t2 
    bltu        t1, t2, inst_error 

###detect exception
  bne s2, zero, inst_error
###score +++
  addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
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

  slli.w  t1, s0, 24 
  or      t0, t1, s3 
  st.w    t0, s1, 0 
  jirl    zero, ra, 0 
END(n58_rdcnt_test)
