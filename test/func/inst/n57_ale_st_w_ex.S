#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n57_ale_st_w_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x39
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
  TEST_ST_W_ALE(0xb189c470, 0xd7bd1, 0x0000774, 0x0000773, 0xb189c470)
  la.local  s4, 1f 
1: 
  st.w    a1, a0, 0x774
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x773  
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

  li.w      t5, 0x0 //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_ALE)

###2
  li.w      t7, DATABASE
  li.w      s2, 0x06 
  TEST_ST_W_ALE(0xc052b3f0, 0xd23d4, 0x00006a2, 0x00006a0, 0xc052b3f0)
  la.local  s4, 1f
  st.w    t7, t7, 4
  st.w    s4, t7, 4 
1:
  st.w    a1, a0, 0x6a2
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x6a0 
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
  TEST_ST_W_ALE(0x994c0280, 0xd8850, 0x000048b, 0x0000488, 0xa10febaf)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1: 
  st.w    a1, a0, 0x48b 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0x488
  bne     t2, t3, inst_error
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###4
  li.w      s2, 0x06 
  TEST_ST_W_ALE(0xeb54b87c, 0xda256, 0x000000c3, 0x000000c2, 0xeb54b87c)
  la.local  s4, 1f 
1: 
  st.w    a1, a0, 0xc3 
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, 0xc2 
  bne     t2, t3, inst_error
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###5
  li.w      s2, 0x06 
  TEST_ST_W_ALE(0xebdc8860, 0xd206c, -0x33e, -0x340, 0x80032066)
  la.local  s4, 1f 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1: 
  st.w    a1, a0, -0x33e 
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x340 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###6
  li.w      s2, 0x06 
  TEST_ST_W_ALE(0x0c41f5e8, 0xd82d8, -0x777, -0x778, 0x634858c8)
  la.local  s4, 1f 
1: 
  st.w    a1, a0, -0x777 
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x778 
  bne     t2, t3, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error

###7
  li.w      s2, 0x06 
  TEST_ST_W_ALE(0xcb09da60, 0xd1750, -0x6d9, -0x6dc, 0x80031751)
  la.local  s4, 1f 
  csrwr   s2, csr_era
1: 
  st.w    t2, a0, -0x6d9 
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 
  ld.w    t2, a0, -0x6dc 
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
END(n57_ale_st_w_ex_test)
