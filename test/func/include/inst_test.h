#include "cpu_cde.h"
#include "test_define.h"

/* 1 */
#define TEST_LU12I_W(in_a, ref_base) \
    lu12i.w   a0, ref_base&0x80000?ref_base-0x100000:ref_base; \
    lu12i.w   t0, in_a&0x80000?in_a-0x100000:in_a;  \
    NOP4; \
    add.w  a0, a0, t1; \
    add.w  t1, t1, t2; \
    NOP4; \
    bne   t0, a0, inst_error; \
    NOP4

/* 2 */
#define TEST_ADD_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    add.w v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 3 */
#define TEST_ADDI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    addi.w v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    NOP4; \
    bne   v0, v1, inst_error; \
    NOP4

/* 4 */
#define TEST_SUB_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    sub.w v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 5 */
#define TEST_SLT(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    slt v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 6 */
#define TEST_SLTU(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    sltu v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 7 */
#define TEST_AND(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    and v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 8 */
#define TEST_OR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    or v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 9 */
#define TEST_XOR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    xor v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 10 */
#define TEST_NOR(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    nor v0, t0, t1; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 11 */
#define TEST_SLLI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    slli.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 12 */
#define TEST_SRLI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    srli.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 13 */
#define TEST_SRAI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    srai.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 14 */
#define TEST_LD_W(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (v1, ref); \
    st.w t1, t0, offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    NOP4; \
    st.w a0, a0, offset_align; \
    st.w a1, a1, offset_align; \
    ld.w v0, t0, offset; \
    ld.w a2, a0, offset_align; \
    ld.w a0, a1, offset_align; \
    ld.w a2, a1, offset_align; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 15 */
#define TEST_ST_W(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (v1, ref); \
    st.w t1, t0, offset; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -4; \
    NOP4; \
    st.w a0, a0, offset; \
    st.w a1, a1, offset; \
    ld.w v0, t0, offset_align; \
    ld.w a2, a0, offset; \
    ld.w a0, a1, offset; \
    ld.w a2, a1, offset; \
    NOP4; \
    bne v0, v1, inst_error; \
    NOP4

/* 16 */
#define TEST_BEQ(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    NOP4; \
1000:; \
    LI (v0, back_flag); \
    beq t1, t0, 3000f; \
    NOP4; \
    b 4000f; \
    NOP4; \
2000:; \
    LI (t0, in_a); \
    LI (t1, in_b); \
    NOP4; \
    beq t0, t1, 1000b; \
    NOP4; \
    b 4000f; \
    NOP4; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    NOP4 ; \
    bne v0, s5, inst_error; \
    NOP4; \
    bne v1, s6, inst_error; \
    NOP4

/* 17 */
#define TEST_BNE(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    NOP4; \
1000:; \
    LI (v0, back_flag); \
    bne t1, t0, 3000f; \
    NOP4; \
    b 4000f; \
    NOP4; \
2000:; \
    LI (t0, in_a); \
    LI (t1, in_b); \
    NOP4; \
    bne t0, t1, 1000b; \
    NOP4; \
    b 4000f; \
    NOP4; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    NOP4 ; \
    bne v0, s5, inst_error; \
    NOP4; \
    bne v1, s6, inst_error; \
    NOP4

/* 18 */
#define BL_INST_NUM (3+2*NOP_INSERT*4)*4
#define TEST_BL(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    NOP; \
    add.w s7, zero, $r1; \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    bl 2000f; \
1000:; \
    NOP4; \
    add.w a1, ra, zero; \
    LI (v0, back_flag); \
1001:; \
    bl 3000f; \
    NOP4; \
    b 4000f;/*a2*/ \
2000:; \
    NOP4; \
    add.w a0, ra, zero; \
    bl 1000b; \
    NOP4; \
    b 4000f;/*a1*/ \
3000:; \
    NOP4; \
    add.w a2, ra, zero; \
    LI (v1, front_flag); \
4000:; \
    add.w $r1, zero, s7; \
    LI (t5, b_flag_ref); \
    LI (t4, f_flag_ref); \
    bne v0, t5, inst_error; \
    NOP4; \
    addi.w a2, a2, BL_INST_NUM; \
    NOP; \
    bne v1, t4, inst_error; \
    NOP4; \
    bne a2, a1, inst_error; \
    NOP4

/* 19 */
#define JIRL_INST_NUM0 (3+1*4*NOP_INSERT)*4
#define JIRL_INST_NUM1 (9+6*4*NOP_INSERT)*4
#define TEST_JIRL(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    NOP; \
    add.w s7, zero, $r1; \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    bl 1f; \
1:  ;  /*r1*/   \
    NOP4; \
    addi.w t0, $r1, JIRL_INST_NUM0; \
    addi.w t1, $r1, JIRL_INST_NUM1; \
    b 2000f; \
1000:; /*t0*/ \
    NOP4; \
    LI (v0, back_flag); \
    jirl zero, t1, 0; \
    NOP4; \
    b 4000f; \
    NOP4; \
2000:; \
    jirl zero, t0, 0; \
    NOP4; \
    b 4000f; \
3000:; /*t1*/\
    NOP4; \
    LI (v1, front_flag); \
4000:; \
    LI (s5, b_flag_ref); \
    LI (s6, f_flag_ref); \
    add.w $r1, zero, s7; \
    bne v0, s5, inst_error; \
    NOP4; \
    bne v1, s6, inst_error; \
    NOP4; \

/* 20 */
#define TEST_B(back_flag, front_flag, b_flag_ref, f_flag_ref) \
    LI (t4, back_flag); \
    LI (t5, front_flag); \
    lu12i.w v0, 0x0; \
    lu12i.w v1, 0x0; \
    b 2000f; \
    NOP4; \
1000:; \
    LI (v0, back_flag); \
1001:; \
    b 3000f; \
    NOP4; \
    b 4000f; \
    NOP4; \
2000:; \
    b 1000b; \
    NOP4; \
    b 4000f; \
    NOP4; \
3000:; \
    LI (v1, front_flag); \
4000:; \
    LI (t5, b_flag_ref); \
    LI (t4, f_flag_ref); \
    bne v0, t5, inst_error; \
    NOP4; \
    bne v1, t4, inst_error; \
    NOP4

/* 21 */
#define TEST_PCADDU12I(data) \
    add.w   t3, zero, ra;\
    lu12i.w t0, data&0x80000?data-0x100000:data;   \
    bl 1f;              \
    pcaddu12i  t1, data&0x80000?data-0x100000:data;   \
    b  2f;              \
  1:;  \
    add.w   t0, ra, t0; \
    jirl    zero, ra, 0;   \
  2:;  \
    add.w   ra, zero, t3;\
    bne  t1, t0, inst_error 

/* 22 */
#define TEST_SLTI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    slti v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    bne v0, v1, inst_error

/* 23 */
#define TEST_SLTUI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    sltui v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    bne v0, v1, inst_error

/* 24 */
#define TEST_ANDI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    andi v0, t0, in_b; \
    bne v0, v1, inst_error

/* 25 */
#define TEST_ORI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    ori v0, t0, in_b; \
    bne v0, v1, inst_error 

/* 26 */
#define TEST_XORI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    xori v0, t0, in_b; \
    bne v0, v1, inst_error 

/* 27 */
#define TEST_SLL_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    sll.w v0, t0, t1; \
    bne v0, v1, inst_error

/* 28 */
#define TEST_SRA_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    sra.w v0, t0, t1; \
    bne v0, v1, inst_error

/* 29 */
#define TEST_SRL_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    srl.w v0, t0, t1; \
    bne v0, v1, inst_error

/* 30 */
#define TEST_DIV_W(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    div.w t3, t0, t1; \
    li.w t4, ref; \
    bne t4, t3, inst_error 

/* 31 */
#define TEST_DIV_WU(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    div.wu t3, t0, t1; \
    li.w t4, ref; \
    bne t4, t3, inst_error  

/* 32 */
#define TEST_MUL_W(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    mul.w t3, t0, t1; \
    li.w t4, ref; \
    bne t3, t4, inst_error 

/* 33 */
#define TEST_MULH_W(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    mulh.w t3, t0, t1; \
    li.w t4, ref; \
    bne t3, t4, inst_error  

/* 34 */
#define TEST_MULH_WU(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    mulh.wu t3, t0, t1; \
    li.w t4, ref; \
    bne t3, t4, inst_error  

/* 35 */
#define TEST_MOD_W(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    mod.w t3, t0, t1; \
    li.w t4, ref; \
    bne t4, t3, inst_error 

/* 36 */
#define TEST_MOD_WU(in_a, in_b, ref) \
    li.w t0, in_a; \
    li.w t1, in_b; \
    mod.wu t3, t0, t1; \
    li.w t4, ref; \
    bne t4, t3, inst_error 

/* 37 */
#define TEST_BLT(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    b 2000f; \
1000:; \
    li.w t3, back_flag; \
    blt t0, t1, 3000f; \
    b 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    blt t0, t1, 1000b; \
    b 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, inst_error; \
    bne t4, s6, inst_error

/* 38 */
#define TEST_BGE(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    b 2000f; \
1000:; \
    li.w t3, back_flag; \
    bge t0, t1, 3000f; \
    b 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bge t0, t1, 1000b; \
    b 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, inst_error; \
    bne t4, s6, inst_error 

/* 39 */
#define TEST_BLTU(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    b 2000f; \
1000:; \
    li.w t3, back_flag; \
    bltu t0, t1, 3000f; \
    b 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bltu t0, t1, 1000b; \
    b 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, inst_error; \
    bne t4, s6, inst_error 

/* 40 */
#define TEST_BGEU(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    b 2000f; \
1000:; \
    li.w t3, back_flag; \
    bgeu t0, t1, 3000f; \
    b 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bgeu t0, t1, 1000b; \
    b 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, inst_error; \
    bne t4, s6, inst_error 

/* 41 */
#define TEST_LD_B(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t1, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.b t4, t0, offset&0x800?offset-0x1000:offset; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error  

/* 42 */
#define TEST_LD_H(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t1, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.h t4, t0, offset&0x800?offset-0x1000:offset; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error 

/* 43 */
#define TEST_LD_BU(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t1, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.bu t4, t0, offset&0x800?offset-0x1000:offset; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error 

/* 44 */
#define TEST_LD_HU(data, base_addr, offset, offset_align, ref) \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t1, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -8; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.hu t4, t0, offset&0x800?offset-0x1000:offset; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error  

/* 45 */
#define TEST_ST_B(init_data, data, base_addr, offset, offset_align, ref) \
    LI (t2, init_data); \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t2, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.b t1, t0, offset&0x800?offset-0x1000:offset; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -4; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w t4, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error  

/* 46 */
#define TEST_ST_H(init_data, data, base_addr, offset, offset_align, ref) \
    LI (t2, init_data); \
    LI (t1, data); \
    LI (t0, base_addr); \
    LI (t3, ref); \
    st.w t2, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.h t1, t0, offset&0x800?offset-0x1000:offset; \
    addi.w a0, t0, 4; \
    addi.w a1, t0, -4; \
    st.w a0, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    st.w a1, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w t4, t0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a0, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a1, a0, offset_align&0x800?offset_align-0x1000:offset_align; \
    ld.w a2, a1, offset_align&0x800?offset_align-0x1000:offset_align; \
    bne t3, t4, inst_error  

/* 47 */
//syscall exception

/* 48 */
//break exception

/* 49 */
#define TEST_TI_EX(time_val) \
    li.w      t0, 0x4;    \
    li.w      t1, 0x4;    \
    csrxchg t0, t1, csr_crmd;  \
    li.w      t0, 0x1fff; \
    csrwr   t0, csr_ectl; \
    li.w      t0, time_val; \
    ori     t0, t0, 0x1;  \
    csrwr   t0, csr_tcfg; \
1:;                       \
    b 1b;                 \
    csrwr   zero, csr_tcfg

#define TEST_TI_EX_CYC(time_val) \
    li.w      t0, 0x4;    \
    li.w      t1, 0x4;    \
    csrxchg t0, t1, csr_crmd;  \
    li.w      t0, 0x1fff; \
    csrwr   t0, csr_ectl; \
    li.w      t0, time_val; \
    ori     t0, t0, 0x3;  \
    csrwr   t0, csr_tcfg; \
1:;                       \
    b 1b;                 \
    la.local s4, 2f;      \
2:;                       \
    b 2b;                 \
    csrwr   zero, csr_tcfg 

/* 50 */
#define TEST_INE_EX(inst) \
    .word inst

/* 51 */
#define TEST_SOFT_INT_EX(estat_val) \
    li.w      t0, 0x4;    \
    li.w      t1, 0x4;    \
    csrxchg t0, t1, csr_crmd;  \
    li.w      t0, 0x1fff; \
    csrwr   t0, csr_ectl; \
    li.w      t0, estat_val; \
    csrwr   t0, csr_estat; \
1:                         \
    b 1b                  

/* 52 */
#define TEST_ADEF(addr) \
    li.w      s4, addr;   \
    li.w      a3, addr;   \
    li.w      s6, addr 

/* 53 */
#define TEST_LD_W_ALE(data, base_addr, offset, offset_align, ref) \
    li.w      t2, ref;    \
    li.w      t3, ref;    \
    li.w      a0, base_addr; \
    li.w      a1, data;   \
    addi.w  a3, a0, offset; \
    st.w    a1, a0, offset_align 

/* 54 */
#define TEST_LD_H_ALE(data, base_addr, offset, offset_align, ref) \
    li.w      t2, ref;    \
    li.w      t3, ref;    \
    li.w      a0, base_addr; \
    li.w      a1, data;   \
    addi.w  a3, a0, offset; \
    st.w    a1, a0, offset_align 

/* 55 */
#define TEST_LD_HU_ALE(data, base_addr, offset, offset_align, ref) \
    li.w      t2, ref;    \
    li.w      t3, ref;    \
    li.w      a0, base_addr; \
    li.w      a1, data;   \
    addi.w  a3, a0, offset; \
    st.w    a1, a0, offset_align  

/* 56 */
#define TEST_ST_H_ALE(data, base_addr, offset, offset_align, ref) \
    li.w      t2, ref;    \
    li.w      t3, ref;    \
    li.w      a0, base_addr; \
    li.w      a1, data;   \
    addi.w  a3, a0, offset; \
    st.w    t2, a0, offset_align 

/* 57 */
#define TEST_ST_W_ALE(data, base_addr, offset, offset_align, ref) \
    li.w      t2, ref;    \
    li.w      t3, ref;    \
    li.w      a0, base_addr; \
    li.w      a1, data;   \
    addi.w  a3, a0, offset; \
    st.w    t2, a0, offset_align 


/* 58 */
//read count

/* 59 */
//tlbrd tlbwr

/* 60 */
//tlbfill

/* 61 */
//tlbfill

/* 62~69 */
//invtlb

/* 70 */
//TLB 4MB

/* 71 */
//TLB EX

/* 72 */
//DMW test

/* 73~78 */
//cache op

/* 79 */
//cache writeback

/* 80 */
#define TEST_TI_EX_WAIT(time_val) \
    li.w      t0, 0x4;    \
    li.w      t1, 0x4;    \
    csrxchg t0, t1, csr_crmd;  \
    li.w      t0, 0x1fff; \
    csrwr   t0, csr_ectl; \
    li.w      t0, time_val; \
    ori     t0, t0, 0x1;  \
    csrwr   t0, csr_tcfg; \
    idle    0;            \
1:;                       \
    nop;                  \
    csrwr   zero, csr_tcfg

/* 81 */
//atomic inst
