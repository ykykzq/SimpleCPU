#include "asm.h"
#include "regdef.h"
#include "inst_test.h"

LEAF(n79_cache_writeback)

    la.local  t7, start
start: 
    addi.w    s0, s0, 0x1
    add.w     s2, zero, zero

    csrwr     zero, csr_dmw0
    csrwr     zero, csr_dmw1

# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t7, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw0
    invtlb    0x0, zero, zero 

    li.w        t0, DATABASE
# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t0, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero 

//let DA=0 and PG=1 and prl=0
    li.w      t0, 0x10
    li.w      t1, 0x1f
    csrxchg t0, t1, csr_crmd 

    li.w        t0, DATABASE
    li.w        t1, 0x0 
    li.w        t2, WAY*4
    li.w        t3, 0x11111111
1: 
    st.w      t3, t0, 0x0
    li.w        t4, 0x1<<(OFFSET+INDEX+1)
    add.w     t0, t0, t4
    addi.w    t1, t1, 0x1 
    bne       t1, t2, 1b

    li.w        t0, DATABASE
# set up the inst DMW, let the MAT=01(Coherent Cached)
    li.w        t1, 0xe0000000
    and       t1, t0, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x11
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero 

# replace the modified cache li.wne

    li.w      t0, DATABASE
    ld.w    t1, t0, 0x0 
    li.w      t1, 0xffffffff
    st.w    t1, t0, 0x0

    li.w        t0, DATABASE+ (0x1<<(OFFSET+INDEX+1))
    li.w        t1, 0x1
    li.w        t2, WAY*4
2: 
    ld.w      t3, t0, 0x0
    li.w        t4, 0x1<<(OFFSET+INDEX+1)
    add.w     t0, t0, t4
    addi.w    t1, t1, 0x1 
    bne       t1, t2, 2b
 
    li.w        t0, DATABASE
# set up the DMW, let the MAT=00(Strongly-Ordered UnCached)
    li.w        t1, 0xe0000000
    and       t1, t0, t1
    srli.w    t2, t1, 0x4
    li.w        t3, 0x1
    or        t1, t1, t2
    or        t1, t1, t3
    csrwr     t1, csr_dmw1
    invtlb    0x0, zero, zero

    li.w        t0, DATABASE
    ld.w      t1, t0, 0x0
    li.w        t2, 0xffffffff
    //bne       t1, t2, inst_error

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
END(n79_cache_writeback)
