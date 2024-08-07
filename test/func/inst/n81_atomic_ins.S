#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n81_atomic_ins_test)
    
    addi.w      s0, s0 ,1
    li.w          s2, 0x0 
    li.w          t0, 0x2 
    li.w          t1, 0x2 
    csrxchg     t1, t0, csr_llbctl    //clear LLbit
    li.w          t8, (DATABASE+0x00004) 

##inst test  
###1
    li.w          t7, 0xffff1234
    st.w        t7, t8, 0
    ll.w        t1, t8, 0 
    bne         t7, t1, inst_error 

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    bne         t2, t3, inst_error 

    li.w          t7, 0x1234ffff 
    move        t1, t7
    sc.w        t1, t8, 0 
    li.w          t0, 0x1 
    bne         t1, t0, inst_error  

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    li.w          t3, 0x0 
    bne         t2, t3, inst_error 

    ld.w        t1, t8, 0 
    bne         t7, t1, inst_error 

###2
    li.w          t7, 0xf1234
    st.w        t7, t8, 0
    ll.w        t1, t8, 0 
    bne         t7, t1, inst_error 

    li.w          t0, 0x2 
    li.w          t1, 0x2 
    csrxchg     t1, t0, csr_llbctl 
    li.w          t3, 0x1 
    and         t1, t1, t3 
    bne         t1, t3, inst_error 

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    li.w          t3, 0x0 
    bne         t2, t3, inst_error 

    li.w          t1, 0x4ffff 
    sc.w        t1, t8, 0 
    li.w          t0, 0x0 
    bne         t1, t0, inst_error 

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    li.w          t3, 0x0 
    bne         t2, t3, inst_error 

    ld.w        t1, t8, 0 
    bne         t7, t1, inst_error 

###3 
    li.w          t7, 0xff1212 
    li.w          t0, 0x4 
    li.w          t1, 0x4 
    csrxchg     t1, t0, csr_llbctl  
    csrrd       t1, csr_crmd 
    li.w          t0, 0x7 
    csrxchg     t1, t0, csr_prmd 
    la.local    t0, 1f 
    csrwr       t0, csr_era 

    st.w        t7, t8, 0
    ll.w        t1, t8, 0 
    bne         t7, t1, inst_error 

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    bne         t2, t3, inst_error 

    ertn
1:
    csrrd       t2, csr_llbctl 
    li.w          t3, 0x5 
    and         t2, t2, t3 
    li.w          t3, 0x1
    bne         t2, t3, inst_error 

    li.w          t7, 0x1212ff 
    move        t1, t7
    sc.w        t1, t8, 0 
    li.w          t0, 0x1 
    bne         t1, t0, inst_error  

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    li.w          t3, 0x0 
    bne         t2, t3, inst_error 

    ld.w        t1, t8, 0 
    bne         t7, t1, inst_error  


###4
    li.w          t7, 0xffabab 
    csrrd       t1, csr_crmd 
    li.w          t0, 0x7 
    csrxchg     t1, t0, csr_prmd 
    la.local    t0, 1f 
    csrwr       t0, csr_era 

    st.w        t7, t8, 0
    ll.w        t1, t8, 0 
    bne         t7, t1, inst_error 

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    bne         t2, t3, inst_error 

    ertn
1:
    csrrd       t2, csr_llbctl 
    li.w          t3, 0x5 
    and         t2, t2, t3 
    li.w          t3, 0x0
    bne         t2, t3, inst_error 

    li.w          t1, 0xababff 
    sc.w        t1, t8, 0 
    li.w          t0, 0x0 
    bne         t1, t0, inst_error  

    csrrd       t2, csr_llbctl 
    li.w          t3, 0x1 
    and         t2, t2, t3 
    li.w          t3, 0x0 
    bne         t2, t3, inst_error 

    ld.w        t1, t8, 0 
    bne         t7, t1, inst_error  

###score +++
  addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
  slli.w  t1, s0, 24 
  or      t0, t1, s3 
  st.w    t0, s1, 0 
  jirl    zero, ra, 0 
END(n81_atomic_ins_test)
