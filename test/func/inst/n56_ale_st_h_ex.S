#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n56_ale_st_h_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x38
  LI_EXIMM(t0,s2,IMM_ALE)
  //clear ti
  li.w      t0, 0x1 
  csrwr   t0, csr_ticlr 
  //init usr mode
  li.w      t0, 0x3
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  lu12i.w s7, 0x60 
  li.w      t5, 0x3 //used for verify prmd 

##inst test
###1 
  TEST_ST_H_ALE(0x47cdf6da, 0xd602a, -0x7cb, -0x7ce, 0x8003602a)
  la.local  s4, 1f 
1: 
  st.h    a1, a0, -0x7cb 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x7ce 
  bne     t2, t3, inst_error 
  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0   //return to kernel mode 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0
  bne     t1, t0, inst_error   

  li.w      t5, 0   //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_ALE)

###2
  li.w      t7, DATABASE
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0x6e9ce24e, 0xd2c08, 0x000009b, 0x0000098, 0x6e9ce24e)
  la.local  s4, 1f
  st.w    t7, t7, 4
  st.w    s4, t7, 4 
1:
  st.h    a1, a0, 0x9b
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x98 
  bne     t2, t3, inst_error
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0 
  bne     t1, t0, inst_error 
  li.w      s2, 0x6 
  st.w    s2, t7, 0  

###3
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0xbb1afce8, 0xd1356, 0x00001d3, 0x00001d2, 0x419f9f3b)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1: 
  st.h    a1, a0, 0x1d3 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x1d2 
  bne     t2, t3, inst_error
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###4
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0x190a65ca, 0xd372c, -0x70f, -0x710, 0x80033729)
  la.local  s4, 1f 
1: 
  st.h    a1, a0, -0x70f 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x710 
  bne     t2, t3, inst_error
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###5
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0x9fcc4ca0, 0xd1ff0, -0x49d, -0x4a0, 0x80031ff3)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1: 
  st.h    a1, a0, -0x49d 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x4a0 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###6
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0xbd6f420a, 0xd351b, 0x00006f2, 0x00006f1, 0x73b35a2b)
  la.local  s4, 1f 
1: 
  st.h    a1, a0, 0x6f2 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x6f1 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###7
  li.w      s2, 0x06 
  TEST_ST_H_ALE(0x00e95990, 0xd63d7, 0x00007c6, 0x00007c5, 0xa5210b0a)
  la.local  s4, 1f 
  csrwr   s2, csr_era
1: 
  st.h    t2, a0, 0x7c6 
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x7c5 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

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
END(n56_ale_st_h_ex_test)
