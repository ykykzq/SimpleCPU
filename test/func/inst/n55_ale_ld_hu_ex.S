#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n55_ale_ld_hu_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x37
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
  TEST_LD_HU_ALE(0x0233e52c, 0xd1348, -0x6e7, -0x6e8, 0x93252910)
  la.local  s4, 1f 
1: 
  ld.hu    t2, a0, -0x6e7 
  bne     s2, s7, inst_error 
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

  li.w      t5, 0x0 //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_ALE)

###2
  li.w      t7, DATABASE
  li.w      s2, 0x06 
  TEST_LD_HU_ALE(0x2ba90e90, 0xd2ca8, 0x0000577, 0x0000574, 0x854aa680)
  la.local  s4, 1f
  st.w    t7, t7, 4
  st.w    s4, t7, 4 
1:
  ld.hu    t2, a0, 0x577
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
  TEST_LD_HU_ALE(0x9554e8d4, 0xd1570, -0x71d, -0x720, 0x541f6c5c)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1: 
  ld.hu    t2, a0, -0x71d 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###4
  li.w      s2, 0x06 
  TEST_LD_HU_ALE(0x8ef75a20, 0xd69cc, -0x7bf, -0x7c0, 0x224cf16c)
  la.local  s4, 1f 
1: 
  ld.hu    t2, a0, -0x7bf 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###5
  li.w      s2, 0x06 
  TEST_LD_HU_ALE(0xcb7ef7d5, 0xd0438, -0x2c5, -0x2c8, 0x516f5fa2)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1: 
  ld.hu    t2, a0, -0x2c5 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###6
  li.w      s2, 0x06 
  TEST_LD_HU_ALE(0x5118e811, 0xd2c20, 0x0000115, 0x0000114, 0x3537cc30)
  la.local  s4, 1f 
1: 
  ld.hu    t2, a0, 0x115 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###7
  li.w      s2, 0x06 
  TEST_LD_HU_ALE(0xd80241b4, 0xd3d5c, 0x00003e9, 0x00003e8, 0x63c6e7af)
  la.local  s4, 1f 
  csrwr   s2, csr_era
1: 
  ld.hu    t2, a0, 0x3e9 
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
END(n55_ale_ld_hu_ex_test)
