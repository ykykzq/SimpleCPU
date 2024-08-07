#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n76_dcacop_op1)
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
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero

    li.w        t7, 0xd0100000
# set up the inst DMW, let the MAT=01(Coherent Cached)
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

    li.w      t0, 0xd0100000
    li.w      t1, 0xffffffff
    st.w    t1, t0, 0x0
    ld.w    t1, t0, 0x0
    li.w      t1, 0xeeeeeeee
    st.w    t1, t0, 0x0

# deal with the coherence in the old cacop in dcacop by index

    li.w        t0, 0xd0100000

    li.w        t1, 0xffffffff
    slli.w    t1, t1, OFFSET
    li.w        t2, 0xffffffff
    slli.w    t2, t2, OFFSET+INDEX
    li.w        t3, 0x0
    nor       t2, t3, t2
    and       t1, t1, t2

    and       t0, t0, t1

    li.w        t1, 0x0 
    li.w        t2, WAY 
invalid_cache_line: 
    cacop     0x09, t0, 0x0 
    addi.w    t0, t0, 0x1 
    addi.w    t1, t1, 0x1 
    bne       t1, t2, invalid_cache_line

# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero

    li.w        t0, 0xd0100000
    ld.w      t1, t0, 0x0
    li.w        t2, 0xeeeeeeee
    bne       t1, t2, inst_error

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
END(n76_dcacop_op1)
