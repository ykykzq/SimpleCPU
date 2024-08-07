#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n48_brk_ex_test)

  addi.w  s0, s0, 1 
  li.w    t4, 0x30
  LI_EXIMM(t0,s2,IMM_BREAK)
  //clear ti
  li.w      t0, 0x1 
  csrwr   t0, csr_ticlr 
  //init usr mode
  li.w      t0, 0x3
  li.w      t1, 0x7 
  csrxchg t0, t1, csr_crmd 
  lu12i.w s7, 0x20 
  li.w      t5, 0x3 //used for verify prmd
###test inst 
###1
  la.local s4, break_pc1
break_pc1:
  break 0 
  bne     s2, s7, inst_error 
  LI_EXIMM(t0,s2,IMM_KERNEL)
  syscall 0     //return to kernel mode
  csrrd   t0, csr_crmd 
  li.w      t1, 0x7 
  and     t0, t0, t1 
  li.w      t1, 0x0
  bne     t1, t0, inst_error 

  li.w      t5, 0x0 //used for verify prmd 
  LI_EXIMM(t0,s2,IMM_BREAK)

###2 
  li.w      t7, DATABASE
  li.w      s2, 0x02 
  la.local  s4, break_pc2
  st.w    s4, t7, 4 
break_pc2:
  break 0
  st.w    s4, t7, 0 
  ld.w    t1, t7, 4 
  bne     t1, s4, inst_error  
  bne     s2, s7, inst_error 
  li.w      s2, 0x2 
  st.w    s2, t7, 0 

###3
  li.w      s2, 0x02
  la.local  s4, break_pc3 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  div.w   t7, t1, t4 
break_pc3:
  break 0
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###4
  li.w      s2, 0x02
  la.local  s4, break_pc4 
break_pc4:
  break 0
  div.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###5
  li.w      s2, 0x02
  la.local  s4, break_pc5 
  li.w      t7, 0xf 
  li.w      t8, 0xf
  mul.w   t7, t4, t7
break_pc5:
  break 0
  beq     t8, t7, inst_error 
  bne     s2, s7, inst_error 

###6
  li.w      s2, 0x02 
  la.local  s4, break_pc6 
break_pc6:
  break 0
  mul.w   t0, t0, t4 
  bne     s2, s7, inst_error 

###7
  li.w      s2, 0x02
  la.local  s4, break_pc7 
  csrwr   s2, csr_era
break_pc7:
  break 0
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
END(n48_brk_ex_test)
