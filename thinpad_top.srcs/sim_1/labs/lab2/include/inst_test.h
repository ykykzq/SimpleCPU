# define zero	$r0
# define ra	$r1
# define tp	$r2
# define sp	$r3
# define a0	$r4
# define a1	$r5
# define a2	$r6
# define a3	$r7
# define a4	$r8
# define a5	$r9
# define a6	$r10
# define a7	$r11
# define v0	$r10  //r4
# define v1	$r11  //r5
# define t0	$r12
# define t1	$r13
# define t2	$r14
# define t3	$r15
# define t4	$r16
# define t5	$r17
# define t6	$r18
# define t7	$r19
# define t8	$r20
# define x	$r21
# define fp	$r22
# define s0	$r23
# define s1	$r24
# define s2	$r25
# define s3	$r26
# define s4	$r27
# define s5	$r28
# define s6	$r29
# define s7	$r30
# define s8	$r31

#define NOP
#define NOP4 NOP;NOP;NOP;NOP

#define LI(reg, imm) \
    li.w reg,imm

#define TEST_SLT(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    slt v0, t0, t1; \
    NOP4; \
    bne v0, v1, slt_next

#define TEST_SLTU(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    NOP4; \
    sltu v0, t0, t1; \
    NOP4; \
    bne v0, v1, sltu_next

#define TEST_SLTI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    slti v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    bne v0, v1, slti_next

#define TEST_SLTUI(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    sltui v0, t0, in_b&0x800?in_b-0x1000:in_b; \
    bne v0, v1, sltui_next



#define TEST_SLL_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    sll.w v0, t0, t1; \
    bne v0, v1, sll_w_next

#define TEST_SRL_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    srl.w v0, t0, t1; \
    bne v0, v1, srl_w_next

#define TEST_SRA_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (t1, in_b); \
    LI (v1, ref); \
    sra.w v0, t0, t1; \
    bne v0, v1, sra_w_next

#define TEST_SRAI_W(in_a, in_b, ref) \
    LI (t0, in_a); \
    LI (v1, ref); \
    NOP4; \
    srai.w v0, t0, in_b; \
    NOP4; \
    bne v0, v1, srai_w_next



#define TEST_BLT(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    beq zero,zero, 2000f; \
1000:; \
    li.w t3, back_flag; \
    blt t0, t1, 3000f; \
    beq zero,zero, 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    blt t0, t1, 1000b; \
    beq zero,zero, 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, blt_next; \
    bne t4, s6, blt_next

#define TEST_BGE(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    beq zero,zero, 2000f; \
1000:; \
    li.w t3, back_flag; \
    bge t0, t1, 3000f; \
    beq zero,zero, 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bge t0, t1, 1000b; \
    beq zero,zero, 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, bge_next; \
    bne t4, s6, bge_next 

#define TEST_BLTU(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    beq zero,zero, 2000f; \
1000:; \
    li.w t3, back_flag; \
    bltu t0, t1, 3000f; \
    beq zero,zero, 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bltu t0, t1, 1000b; \
    beq zero,zero, 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, bltu_next; \
    bne t4, s6, bltu_next 

#define TEST_BGEU(in_a, in_b, back_flag, front_flag, b_flag_ref, f_flag_ref) \
    li.w t3, 0x0; \
    li.w t4, 0x0; \
    beq zero,zero, 2000f; \
1000:; \
    li.w t3, back_flag; \
    bgeu t0, t1, 3000f; \
    beq zero,zero, 4000f; \
2000:; \
    li.w t0, in_a; \
    li.w t1, in_b; \
    bgeu t0, t1, 1000b; \
    beq zero,zero, 4000f; \
3000:; \
    li.w t4, front_flag; \
4000:; \
    li.w s5, b_flag_ref; \
    li.w s6, f_flag_ref; \
    bne t3, s5, bgeu_next; \
    bne t4, s6, bgeu_next 







