#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n73_icacop_op0)
    addi.w    s0, s0, 0x1 
    add.w     s2, zero, zero

    la.local  t7, start
start:
# clear DMW
    csrwr     zero, csr_dmw0 
    csrwr     zero, csr_dmw1  
# set up the DMW, let the MAT=01(Coherent Cached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x11
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero

# set up the PRMD, let DA=0, PG=1, and PRL=0
    //let DA=0 and PG=1 and prl=0
    li.w      t0, 0x10
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

# the size of cacop li.wne: 16Bytes( 4 insts)
    .align 4
code_block:
    b       jump_point_1        #1
    add.w   zero, zero, zero   #2
    add.w   zero, zero, zero   #2
    add.w   zero, zero, zero   #2
    .align 4
code_to_be_changed:         
    b       inst_error         #3 
jump_point_1:
    b       jump_point_2
    add.w   zero, zero, zero   #4
    add.w   zero, zero, zero   #4
    .align 4
new_code:
    b       inst_pass 
jump_point_2:
    add.w   zero, zero, zero   #4
    add.w   zero, zero, zero   #4
    add.w   zero, zero, zero   #4

change_code:

# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero
    
# bypass the icacop and directly write to the physical memory
    la.local  t0, code_to_be_changed
    la.local  t1, new_code
    ld.w      t2, t1, 0x0 
    li.w        t3, 0x1000 
    add.w     t2, t2, t3
    st.w      t2, t0, 0x0

# invalid the old inst in icacche by index

    li.w        t1, 0xffffffff
    slli.w    t1, t1, OFFSET
    li.w        t2, 0xffffffff
    slli.w    t2, t2, OFFSET+INDEX
    li.w        t3, 0x0
    nor       t2, t3, t2
    and       t1, t1, t2

    and      t0, t0, t1

    li.w        t1, 0x0 
    li.w        t2, WAY 

invalid_cache_line: 
    cacop     0x00, t0, 0x0 
    addi.w    t0, t0, 0x1 
    addi.w    t1, t1, 0x1 
    bne       t1, t2, invalid_cache_line

# set up the DMW, let the MAT=01(Coherent Cached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x11
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero

# go back to the changed code
    b         code_to_be_changed

inst_pass:
###detect exception 
    bne s2, zero, inst_error 
###score ++
    addi.w    s3, s3, 0x1 
###output
inst_error: 
    li.w        t0, 0x8 
    li.w        t1, 0x1f 
    csrxchg   t0, t1, csr_crmd

    slli.w    t1, s0, 24
    or        t0, t1, s3 
    st.w      t0, s1, 0x0
    jirl      zero, ra, 0x0
END(n73_icacop_op0)
