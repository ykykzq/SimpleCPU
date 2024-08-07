#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n49_ti_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x31
  LI_EXIMM(t0,s2,IMM_INT)
  //clear ti
  li.w      t0, 0x1 
  csrwr   t0, csr_ticlr 
  //init kernel mode
  li.w      t0, 0x0
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  lu12i.w s7, 0x40 
  li.w      t5, 0x4 //used for verify prmd 

##inst test
###1  
  la.local  s4, 1f 
  TEST_TI_EX(0x120) 
  bne     s2, s7, inst_error  
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x4 
  bne     t1, t0, inst_error  

  la.local  s4, 1f 
  TEST_TI_EX_CYC(0xe20)
  bne     s2, s7, inst_error
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x4 
  bne     t1, t0, inst_error  

###2
  li.w      t7, DATABASE
  li.w      s2, 0x04
  la.local  s4, 1f
  st.w    s4, t7, 4 
  TEST_TI_EX(0x74) 
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
  li.w      s2, 0x4 
  st.w    s2, t7, 0

  li.w      s2, 0x04
  la.local  s4, 1f
  st.w    t7, t7, 4
  TEST_TI_EX_CYC(0xe74) 
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, t7, inst_error  
  bne     s2, s7, inst_error 
  li.w      s2, 0x4 
  st.w    s2, t7, 0 

###3
  li.w      s2, 0x04
  la.local  s4, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
  TEST_TI_EX(0x10) 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

  li.w      s2, 0x04
  la.local  s4, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
  TEST_TI_EX_CYC(0xe50) 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###4
  li.w      s2, 0x04
  la.local  s4, 1f
  TEST_TI_EX(0x0) 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 

  li.w      s2, 0x04
  la.local  s4, 1f
  TEST_TI_EX_CYC(0xe55) 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###5
  li.w      s2, 0x04
  la.local  s4, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
  TEST_TI_EX(0x4) 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

  li.w      s2, 0x04
  la.local  s4, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
  TEST_TI_EX_CYC(0xe60) 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###6
  li.w      s2, 0x04
  la.local  s4, 1f
  TEST_TI_EX(0x8) 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 

  li.w      s2, 0x04
  la.local  s4, 1f
  TEST_TI_EX_CYC(0xe70) 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###7
  li.w      s2, 0x04
  la.local  s4, 1f
  csrwr   s2, csr_era
  TEST_TI_EX(0x34) 
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 

  li.w      s2, 0x04
  la.local  s4, 1f
  csrwr   s2, csr_era
  TEST_TI_EX_CYC(0xe80) 
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 

###8 LIE disable 
  li.w      t0, 0x0 
  li.w      t1, 0x3 
  csrxchg t0, t1, csr_crmd 

  LI_EXIMM(t0,s2,IMM_NONE)
  li.w      t0, 0x4 
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  li.w      t0, 0x0 
  csrwr   t0, csr_ectl
  li.w      t0, 0x4 
  ori     t0, t0, 0x1 
  csrwr   t0, csr_tcfg  //should be useless  
  li.w      t0, 0x80 
  li.w      t1, 0x0
1:
  addi.w  t0, t0, -0x1 
  bne     t0, t1, 1b    //idle for interrupt maybe

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
END(n49_ti_ex_test)
