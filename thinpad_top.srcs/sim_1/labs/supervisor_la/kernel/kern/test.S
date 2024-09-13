#include <regdef.h>
#include <exception.h>

/*==============================================================
 *                        TEST for MONITOR
 *  Built-in test program
 *  Entry symbol prefix 'UTEST_'
 *==============================================================*/
    

    .section .text.utest
    .p2align 2

    /*  Simple test program
     *  Write integer 1 to register a0
     */
UTEST_SIMPLE:
    addi.w      a0,a0,0x1
    jirl        zero,ra,0x0
    /* End of test */

    /*  STREAM test program
     *  Continous memory read/write
     */
UTEST_STREAM:
    li.w        a0,0x80100000
    li.w        a1,0x80400000
    li.w        a2,0x00300000
    add.w       a2,a0,a2
stream_next:
    ld.w        t0,a0,0x0
    st.w        t0,a1,0x0
    addi.w      a0,a0,0x4
    addi.w      a1,a1,0x4
    bne         a0,a2,stream_next

    jirl        zero,ra,0x0
    /* End of test */

    /*  MATRIX test program
     *  Matrix multiplication
     *  Reference C code:
        void matrix(int a[128][128],int b[128][128],int c[128][128],unsigned int n) {
            unsigned int i,j,k;
            for (k=0; k!=n; k++) {
                for (i=0; i!=n; i++) {
                    int r = a[i][k];
                    for (j=0; j!=n; j++)
                        c[i][j] += r * b[k][j];
                }
            }
        }
     */
UTEST_MATRIX:
    // set arguments
    li.w        a0, 0x80400000
    li.w        a1, 0x80410000
    li.w        a2, 0x80420000
    li.w        a3, 96
    // a0 -> a
    // a1 -> b
    // a2 -> c
    // a3 -> n
    // t8 -> k
    // t1 -> i
    // t3 -> j
    // t7 -> r
    or          t8,zero,zero
loop1:
    beq         t8,a3,loop1end

    slli.w      t0,t8,2
    slli.w      t2,t8,9
    add.w       t0,a0,t0
    add.w       t2,a1,t2
    or          t1,zero,zero
loop2:
    beq         t1,a3,loop2end

    ld.w        t7,t0,0x0
    slli.w      a4,t1,9
    add.w       a4,a2,a4
    or          t4,t2,zero
    or          t3,zero,zero
loop3:
    beq         t3,a3,loop3end

    addi.w      t3,t3,1
    ld.w        t5,t4,0x0
    ld.w        t6,a4,0x0
    mul.w       t5,t7,t5
    addi.w      a4,a4,4
    addi.w      t4,t4,4
    add.w       t5,t6,t5
    st.w        t5,a4,-4
    b           loop3

loop3end:
    addi.w      t1,t1,1
    addi.w      t0,t0,512
    b           loop2

loop2end:
    addi.w      t8,t8,1
    b           loop1

loop1end:
    jirl        zero,ra,0x0
    /* End of test */

    /*  CryptoNight test program
     *  Run simplified CryptoNight memory-hard loop
     *  Reference C code:
        void crn(int pad[],unsigned int a,unsigned int b,unsigned int n) {
            unsigned int k;
            for (k=0; k!=0x80000; k++)
                pad[k] = k;
            for (k=0; k!=n; k++) {
                unsigned int t, addr1, addr2;
                addr1 = a & 0x7FFFF;
                t = (a >> 1) ^ (pad[addr1] << 1); // Replace the AES step
                pad[addr1] = t ^ b;
                addr2 = t & 0x7FFFF;
                b = t;
                t = pad[addr2];
                a += b * t;
                pad[addr2] = a;
                a ^= t;
            } 
        }
     */
UTEST_CRYPTONIGHT:
    // a0 -> pad
    // a1 -> a
    // a2 -> b
    // a3 -> n
    li.w        a0, 0x80400000
    li.w        a1, 0xdeadbeef
    li.w        a2, 0xfaceb00c
    li.w        a3, 0x100000
    or          t4,zero,a0
    or          t3,zero,zero
    li.w        t0,0x80000
fill_next:
    st.w        t3,t4,0
    addi.w      t3,t3,1
    addi.w      t4,t4,4
    bne         t3,t0,fill_next

    or          t1,zero,zero
    li.w        t2,0x7ffff
crn_hext:
    and         t0,a1,t2
    slli.w      t0,t0,2
    add.w       t0,a0,t0
    ld.w        t3,t0,0
    srli.w      t4,a1,1
    slli.w      t3,t3,1
    xor         t3,t3,t4
    and         t4,t3,t2
    xor         a2,t3,a2
    slli.w      t4,t4,2
    st.w        a2,t0,0
    add.w       t4,a0,t4
    ld.w        t0,t4,0
    or          a2,zero,t3
    mul.w       t3,t3,t0
    addi.w      t1,t1,1
    add.w       a1,t3,a1
    st.w        a1,t4,0
    xor         a1,t0,a1
    bne         a3,t1,crn_hext
crn_end:
    jirl        zero,ra,0x0
    /* End of test */

