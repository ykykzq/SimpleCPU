#include "asm.h"
#include "regdef.h"
#include "inst_test.h"
#include "test_config.h"

LEAF(n52_adef_ex_test)
   
  addi.w  s0, s0, 1 
  li.w    t4, 0x34
  LI_EXIMM(t0,s2,IMM_ADEF)
  //clear ti
  li.w      t0, 0x1 
  csrwr   t0, csr_ticlr 
  //init usr mode
  li.w      t0, 0x3
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  lu12i.w s7, 0x50 
  li.w      t5, 0x3 //used for verify prmd  

##inst test
###1 
  TEST_ADEF(0x227f9789) 
  jirl    s5, s4, 0 
  add.w   zero, zero, zero
  bne     s2, s7, inst_error  
  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0    //return to kernel mode
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0
  bne     t1, t0, inst_error  

  li.w      t5, 0x0   //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_ADEF)

###2
  li.w      t7, DATABASE
  li.w      s2, 0x05 
  TEST_ADEF(0x3101bbed)
  csrwr   s6, csr_era
  la.local  s5, 1f
  st.w    t7, t7, 4
  st.w    s4, t7, 4 
1:  ertn  
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  
  li.w      s2, 0x5 
  st.w    s2, t7, 0 

###3
  li.w      s2, 0x05
  TEST_ADEF(0x44790977)
  csrwr   s6, csr_era 
  la.local  s5, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
1:  ertn
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  

###4
  li.w      s2, 0x05
  TEST_ADEF(0x92b0a2c3)
  jirl    s5, s4, 0 
  add.w   zero, zero, zero
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  

###5
  li.w      s2, 0x05
  TEST_ADEF(0xaf9edafa)
  csrwr   s6, csr_era 
  la.local  s5, 1f
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
1:  ertn
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  

###6 
  li.w      s2, 0x05
  TEST_ADEF(0xb088f329)
  jirl    s5, s4, 0 
  add.w   zero, zero, zero
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  

###7
  li.w      s2, 0x05
  TEST_ADEF(0x827f97ab)
  csrwr   s6, csr_era 
  la.local  s5, 1f
1:  ertn
  csrwr   t0, csr_era
  bne     s2, s7, inst_error 
  csrrd   t0, csr_badv 
  bne     a3, t0, inst_error  

###should not generate adef excp
#if TEST9
## 8
  add.w     t2, ra, zero
  li.w      t0, 0x9 
  csrwr     t0, csr_dmw0

  li.w      t0, 0x3
  csrxchg t0, t0, csr_crmd  //usr mode

  li.w      t0, 0xd0010
  li.w      t1, 0x4c000020
  st.w      t1, t0, 0 
  cacop     0x10, t0, 0x0
  cacop     0x11, t0, 0x0
  nop;nop;nop;nop;nop;
  jirl      ra, t0, 0

## 9
  li.w      t0, 0xa0000000
  li.w      t1, 0x4c000020  //write in "jirl zero, ra, 0" inst
  st.w      t1, t0, 0 
  cacop     0x10, t0, 0x0
  cacop     0x11, t0, 0x0
  nop;nop;nop;nop;nop;
  jirl      ra, t0, 0

  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0      //return to kernel mode

  li.w      t0, 0x19 
  csrwr     t0, csr_dmw0
 
  add.w     ra, t2, zero
#endif

  li.w      t0, 0x0 
  li.w      t1, 0x3 
  csrxchg   t0, t1, csr_crmd 
###score +++
  addi.w  s3, s3, 1
###output (s0<<24)|s3 
inst_error:
  slli.w  t1, s0, 24 
  or      t0, t1, s3 
  st.w    t0, s1, 0 
  jirl    zero, ra, 0 
END(n52_adef_ex_test)
