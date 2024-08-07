#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n53_ale_ld_w_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x35
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
  TEST_LD_W_ALE(0xb27f9788, 0xd059c, -0x7bb, -0x7bc, 0x3958f252)
  la.local  s4, 1f 
1: 
  ld.w    t2, a0, -0x7bb 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0     //return to kernel mode
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0 
  bne     t1, t0, inst_error  

  li.w      t5, 0x0   //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_ALE)

###2
  li.w      t7, DATABASE
  li.w      s2, 0x06 
  TEST_LD_W_ALE(0x3101bbec, 0xd7748, 0x000006a2, 0x000006a0, 0xc0442bd0)
  la.local  s4, 1f
  st.w    s4, t7, 4 
1:
  ld.w    t2, a0, 0x6a2
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
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
  TEST_LD_W_ALE(0x94a1ade4, 0xd59dc, 0x00004ee, 0x00004ec, 0x68929b5c)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1: 
  ld.w    t2, a0, 0x4ee 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###4
  li.w      s2, 0x06 
  TEST_LD_W_ALE(0xe2b0a2c0, 0xd7748, 0x0000173, 0x0000170, 0x7423d85f)
  la.local  s4, 1f 
1: 
  ld.w    t2, a0, 0x173 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###5
  li.w      s2, 0x06 
  TEST_LD_W_ALE(0x0f9edafa, 0xd5bac, 0x0000003e, 0x0000003c, 0xdd064458)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1: 
  ld.w    t2, a0, 0x3e 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###6
  li.w      s2, 0x06 
  TEST_LD_W_ALE(0x5077f320, 0xd0704, -0x1c1, -0x1c4, 0x15148b6c)
  la.local  s4, 1f 
1: 
  ld.w    t2, a0, -0x1c1 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###7
  li.w      s2, 0x06 
  TEST_LD_W_ALE(0xb27f9788, 0xd759c, -0x7bb, -0x7bc, 0x3958f252)
  la.local  s4, 1f 
  csrwr   s2, csr_era
1: 
  ld.w    t2, a0, -0x7bb 
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 
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
END(n53_ale_ld_w_ex_test)
