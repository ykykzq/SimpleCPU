#include <inst_test.h>

    .org 0x0
    .text
    .global _start
_start:
    beq         zero,zero,fib

info:
    .asciz "Fib Finish."

    .p2align 2
feed:
    .asciz "All PASS!"

    .p2align 2
fib:
    addi.w      t0,zero,0x1   # t0 = 1
    addi.w      t1,zero,0x1   # t1 = 1
    lu12i.w     a0,-0x7fc00    # a0 = 0x80400000
    addi.w      a1,a0,0x100   # a1 = 0x80400100
loop0:
    add.w       t2,t0,t1     # t2 = t0+t1
    addi.w      t0,t1,0x0     # t0 = t1
    addi.w      t1,t2,0x0     # t1 = t2
    st.w        t2,a0,0x0
    ld.w        t3,a0,0x0
    bne         t2,t3,end
    addi.w      a0,a0,0x4     # a0 += 4
    bne         a0,a1,loop0

WRITESERIAL:
    lu12i.w     s0,-0x40300    # s0 = 0xbfd00000
    la.local    s1,info
    ld.b        a0,s1,0x0
loop1:
    addi.w      s1,s1,0x1
.TESTW:
    ld.b        t0,s0,0x3fc
    andi        t0,t0,0x001
    beq         t0,zero,.TESTW
    st.b        a0,s0,0x3F8
    ld.b        a0,s1,0x0
    bne         a0,zero,loop1

READSERIAL:
    # lui         s0,-0x40300
.TESTR:
    ld.b        t0,s0,0x3fc
    andi        t0,t0,0x002
    beq         t0,zero,.TESTR
    ld.b        a0,s0,0x3F8
    addi.w      t0,zero,0x54  # char 'T'
    bne         a0,t0,READSERIAL

RANDOMTEST:
    li.w        s0, 0x80400100 # s0 = 0x80400100
    li.w        s1, 0x0       # result
    ld.w        s2,s0,0x4     # selection
    ld.w        s3,s0,0x8     # random

slt:
    andi        t0,s2,0x1
    beq         t0,zero,slt_next
    TEST_SLT(0x7245316a, 0x783506f0, 0x00000001)
    TEST_SLT(0xf6301a6b, 0x00000000, 0x00000001)
    TEST_SLT(0x00000000, 0xf5be6ec0, 0x00000000)
    TEST_SLT(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x1
slt_next:

sltu:
    andi        t0,s2,0x2
    beq         t0,zero,sltu_next
    TEST_SLTU(0x158f2b29, 0x421c0a42, 0x00000001)
    TEST_SLTU(0x55caaca0, 0x00000000, 0x00000000)
    TEST_SLTU(0x00000000, 0xd2fb1bfc, 0x00000001)
    TEST_SLTU(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x2
sltu_next:

slti:
    andi        t0,s2,0x4
    beq         t0,zero,slti_next
    TEST_SLTI(0xd9d129b5, 0x00000988, 0x1)
    TEST_SLTI(0xba63960c, 0x00000000, 0x1)
    TEST_SLTI(0x00000000, 0x00000ef6, 0x0)
    TEST_SLTI(0x00000000, 0x00000000, 0x0)
    ori         s1,s1,0x4
slti_next:

sltui:
    andi        t0,s2,0x8
    beq         t0,zero,sltui_next
    TEST_SLTUI(0xc254e3d8, 0x00000469, 0x0)
    TEST_SLTUI(0x719d44a8, 0x00000000, 0x0)
    TEST_SLTUI(0x00000000, 0x00000625, 0x1)
    TEST_SLTUI(0x00000000, 0x00000000, 0x0)
    ori         s1,s1,8
sltui_next:

sll_w:
    andi        t0,s2,0x10
    beq         t0,zero,sll_w_next
    TEST_SLL_W(0x79dbdb34, 0x00000007, 0xeded9a00)
    TEST_SLL_W(0x323bd800, 0x00000000, 0x323bd800)
    TEST_SLL_W(0x00000000, 0x0000001e, 0x00000000)
    TEST_SLL_W(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x10
sll_w_next:

srl_w:
    andi        t0,s2,0x20
    beq         t0,zero,srl_w_next
    TEST_SRL_W(0x1f8f6000, 0x0000001c, 0x00000001)
    TEST_SRL_W(0x4adff964, 0x00000000, 0x4adff964)
    TEST_SRL_W(0x00000000, 0x0000000a, 0x00000000)
    TEST_SRL_W(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x20
srl_w_next:

sra_w:
    andi        t0,s2,0x40
    beq         t0,zero,sra_w_next
    TEST_SRA_W(0x3e594300, 0x00000003, 0x07cb2860)
    TEST_SRA_W(0x4043b9ee, 0x00000000, 0x4043b9ee)
    TEST_SRA_W(0x00000000, 0x00000005, 0x00000000)
    TEST_SRA_W(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x40
sra_w_next:

srai_w:
    andi        t0,s2,0x80
    beq         t0,zero,srai_w_next
    TEST_SRAI_W(0x7e0083f0, 0x00000009, 0x003f0041)
    TEST_SRAI_W(0x76668ec8, 0x00000000, 0x76668ec8)
    TEST_SRAI_W(0x00000000, 0x0000001f, 0x00000000)
    TEST_SRAI_W(0x00000000, 0x00000000, 0x00000000)
    ori         s1,s1,0x80
srai_w_next:

blt:
    andi        t0,s2,0x100
    beq         t0,zero,blt_next
    TEST_BLT(0x53da7664, 0xd0bb3643, 0xede1bda0, 0x9184955e, 0x00000000, 0x00000000)
    TEST_BLT(0xc815806e, 0x1d9f9515, 0xc6ecc9a4, 0x6f0d3944, 0xc6ecc9a4, 0x6f0d3944)
    TEST_BLT(0x77b54655, 0x4738bd02, 0xbf9ef915, 0xae4455e3, 0x00000000, 0x00000000)
    TEST_BLT(0xb94ac606, 0x48e54b38, 0x2d492742, 0xf0458c71, 0x2d492742, 0xf0458c71)
    ori         s1,s1,0x100
blt_next:

bge:
    andi        t0,s2,0x200
    beq         t0,zero,bge_next
    TEST_BGE(0x92592dfe, 0x7a3a35db, 0xa9323570, 0xad8a1211, 0x00000000, 0x00000000)
    TEST_BGE(0x7f0abb70, 0xf99858d2, 0xe4f97794, 0xefe63e5d, 0xe4f97794, 0xefe63e5d)
    TEST_BGE(0x576abeb2, 0x98405bbc, 0xd231a69c, 0x5d97e746, 0xd231a69c, 0x5d97e746)
    TEST_BGE(0xcf435850, 0x260b67a7, 0x8139b160, 0xa56a6657, 0x00000000, 0x00000000)
    ori         s1,s1,0x200
bge_next:

bltu:
    andi        t0,s2,0x400
    beq         t0,zero,bltu_next
    TEST_BLTU(0xae057640, 0xa3f3f054, 0x087ad72a, 0xf9772780, 0x00000000, 0x00000000)
    TEST_BLTU(0xa1331f07, 0xce878855, 0x5f6eebfc, 0xfbf37fbc, 0x5f6eebfc, 0xfbf37fbc)
    TEST_BLTU(0x8153e532, 0xe4021d1c, 0x0d18d27c, 0xfb5d6bc3, 0x0d18d27c, 0xfb5d6bc3)
    TEST_BLTU(0x1ac04a54, 0xc4e8bfcf, 0x29a4dc26, 0xff9f9594, 0x29a4dc26, 0xff9f9594)
    ori         s1,s1,0x400
bltu_next:

bgeu:
    andi        t0,s2,0x800
    beq         t0,zero,bgeu_next
    TEST_BGEU(0x3e290b61, 0x9d7d8a83, 0x26b8700b, 0xdbfe64e5, 0x00000000, 0x00000000)
    TEST_BGEU(0xfd5f4009, 0x7fac959f, 0xe3ac4197, 0x6c00bfbd, 0xe3ac4197, 0x6c00bfbd)
    TEST_BGEU(0x91f6d829, 0x2696df06, 0xe8257743, 0xa4f3dffe, 0xe8257743, 0xa4f3dffe)
    TEST_BGEU(0x7cb295e2, 0x29d3f4de, 0x0e04e57f, 0xafe1a821, 0x0e04e57f, 0xafe1a821)
    ori         s1,s1,0x800
bgeu_next:

    li.w        t0,0xfeed0000
    or          t0,t0,s1
    xor         t0,t0,s3
    st.w        t0,s0,0x0
    bne         s1,s2,end
FEEDBACK:
    lu12i.w     s0,-0x40300    # s0 = 0xbfd00000
    la.local    s1,feed
    ld.b        a0,s1,0x0
loop2:
    addi.w      s1,s1,0x1
.TEST:
    ld.b        t0,s0,0x3fc
    andi        t0,t0,0x001
    beq         t0,zero,.TEST
    st.b        a0,s0,0x3F8
    ld.b        a0,s1,0x0
    bne         a0,zero,loop2

end:
    beq         zero,zero,end
