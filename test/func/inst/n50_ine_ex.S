#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n50_ine_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x32
  LI_EXIMM(t0,s2,IMM_INE)
  //clear ti
  li.w      t0, 0x1 
  csrwr   t0, csr_ticlr 
  //init usr mode
  li.w      t0, 0x3
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  lu12i.w s7, 0x30 
  li.w      t5, 0x3 //used for verify prmd 

##inst test 
###1 
  la.local  s4, 1f 
1: 
  TEST_INE_EX(0x0) 
  bne     s2, s7, inst_error  
  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0          //return to kernel mode
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0
  bne     t1, t0, inst_error  

  li.w      t5, 0   //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_INE)
###2
  li.w      t7, DATABASE
  li.w      s2, 0x03 
  la.local  s4, 1f
  st.w    t7, t7, 4
  st.w    s4, t7, 4 
1:
  TEST_INE_EX(0xffffffff) 
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error
  bne     s2, s7, inst_error 
  li.w      s2, 0x3
  st.w    s2, t7, 0 

###3
  li.w      s2, 0x03
  la.local  s4, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1:
  TEST_INE_EX(0xf9000000)
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###4
  li.w      s2, 0x03
  la.local  s4, 1f 
1:
  TEST_INE_EX(0x887b8000)
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###5
  li.w      s2, 0x03
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1:
  TEST_INE_EX(0x88000200)
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###6 
  li.w      s2, 0x03 
  la.local  s4, 1f
1:
  TEST_INE_EX(0xf36e0000)
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###7
  li.w      s2, 0x03 
  la.local  s4, 1f
  csrwr   s2, csr_era
1:
  TEST_INE_EX(0x94080000)
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 

  li.w      t0, 0x0 
  li.w      t1, 0x3 
  csrxchg t0, t1, csr_crmd 
###score +++
  addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
  slli.w  t1, s0, 24 
  or      t0, t1, s3 
  st.w    t0, s1, 0 
  jirl    zero, ra, 0 
END(n50_ine_ex_test)
