#define TLBREBASE 0xf000
#define DATABASE  0x1d0000
#define CODEBASE  0x10000

#define TLB_ENTRY 16
#define TLB_IDX 4

#define WAY    2
#define OFFSET 4
#define INDEX  8

#if NOP_INSERT
  #define NOP  addi.w zero, zero, 0
#else
  #define NOP
#endif
#define NOP4 NOP;NOP;NOP;NOP

#define LI(reg, imm) \
    lu12i.w reg , (((imm>>12)+((imm&0x00000800)>>11))&0x000fffff)&0x80000?(((imm>>12)+((imm&0x00000800)>>11))&0x000fffff)-0x100000:(((imm>>12)+((imm&0x00000800)>>11))&0x000fffff); \
    NOP4; \
    addi.w reg, reg, (imm & 0x00000fff)&0x800?(imm & 0x00000fff)-0x1000:(imm & 0x00000fff)
#define LI_EXIMM(reg1,reg2,imm) \
    li.w    reg1, DATABASE; \
    li.w    reg2, imm; \
    st.w    reg2, reg1, 0

#define DAMODE(temp_reg1,temp_reg2)\
    li.w    temp_reg1, 0x18;\
    li.w    temp_reg2, 0x08;\
    csrxchg temp_reg2, temp_reg1, 0x0

#define PGMODE(temp_reg1,temp_reg2)\
    li.w    temp_reg1, 0x18;\
    li.w    temp_reg2, 0xk0;\
    csrxchg temp_reg2, temp_reg1, 0x0

#define GET_EXIMM(reg1) \
    li.w    reg1, DATABASE; \
    ld.w    reg1, reg1, 0

#define IMM_SYSCALL  0x1
#define IMM_BREAK    0x2
#define IMM_INE      0x3
#define IMM_INT      0x4
#define IMM_ADEF     0x5
#define IMM_ALE      0x6
#define IMM_PME      0x7
#define IMM_LDINV    0x8
#define IMM_STINV    0x9
#define IMM_TLBPRV   0xa
#define IMM_TLBM     0xb
#define IMM_FETCHINV 0xc
#define IMM_TLBADEM  0xd
#define IMM_TLBADEF  0xe
#define IMM_KERNEL   0xf
#define IMM_NONE     0x10

#define FILL_TLB_ITEM_r \
    addi.w t4, t3, 0x0; \
    addi.w t5, t0, 0x0; \
    addi.w t6, t1, 0x0; \
    addi.w t7, t2, 0x0; \
    csrwr t4, csr_tlbidx ; \
    li.w    t4, 0xffffe000 ; \
    and   t5, t5, t4     ; \
    csrwr t5, csr_tlbehi ; \
    csrwr t6, csr_tlbelo0 ; \
    csrwr t7, csr_tlbelo1 ; \
    tlbwr ; \
    addi.w t3, t3, 0x1 ;\
    li.w     t4, 0x1<<13 ;\
    li.w     t5, 0x2<<8  ;\
    add.w  t0, t0, t4  ;\
    add.w  t1, t1, t5  ;\
    add.w  t2, t2, t5  ;\

#define FILL_TLB_ITEM(in_tlbidx, in_tlbehi, in_tlbelo0, in_tlbelo1) \
    li.w t0, in_tlbidx ; \
    li.w t1, in_tlbehi ; \
    li.w t2, in_tlbelo0 ; \
    li.w t3, in_tlbelo1 ; \
    csrwr t0, csr_tlbidx ; \
    csrwr t1, csr_tlbehi ; \
    csrwr t2, csr_tlbelo0 ; \
    csrwr t3, csr_tlbelo1 ; \
    tlbwr ; \

#define FILL_TLB(ppn1, ppn2) \
    li.w t4, ppn1 ; \
    li.w t5, ppn2 ; \
    addi.w t2, t0, 0x0 ; \
    addi.w t3, t1, 0x0 ; \
    csrwr t2, csr_tlbidx ; \
    csrwr t3, csr_tlbehi ; \
    csrwr t4, csr_tlbelo0 ; \
    csrwr t5, csr_tlbelo1 ; \
    tlbwr ; \
    addi.w t0, t0, 0x1 ; \
	li.w     t5, 1<<13 ; \
    add.w t1, t1, t5 

#define TEST_TLBSRCH(in_asid, in_vpn, ref) \
    li.w    t1, in_asid; \
    csrwr t1, csr_asid; \
    li.w    t2, 8<<13; \
    li.w    t3, in_vpn<<13; \
    add.w t1, t3, t2; \
    csrwr t1, csr_tlbehi; \
    tlbsrch; \
    csrrd t2, csr_tlbidx; \
    li.w    t1, ref; \
    bne   t2, t1, inst_error


#define FILL_TLB_4MB(ppn) \
    li.w t4, ppn ; \
    li.w t5, ppn+0x20000; \
    addi.w t2, t0, 0x0 ; \
    addi.w t3, t1, 0x0 ; \
    csrwr t2, csr_tlbidx ; \
    csrwr t3, csr_tlbehi ; \
    csrwr t4, csr_tlbelo0 ; \
    csrwr t5, csr_tlbelo1 ; \
    tlbwr ; \
    addi.w t0, t0, 0x1 ; \
	li.w     t5, 1<<22 ; \
    add.w t1, t1, t5 

#define TEST_TLBSRCH_4MB(in_asid, in_vpn, ref) \
    li.w    t1, in_asid; \
    csrwr t1, csr_asid; \
    li.w    t2, 8<<22; \
    li.w    t3, in_vpn<<22; \
    add.w t1, t3, t2; \
    csrwr t1, csr_tlbehi; \
    tlbsrch; \
    csrrd t2, csr_tlbidx; \
    li.w    t1, ref; \
    bne   t2, t1, inst_error


#define TEST_TLBSRCH_NOMATCHING(in_asid, in_vpn) \
    csrwr zero, csr_tlbidx; \
    li.w    t1, in_asid; \
    csrwr t1, csr_asid; \
    li.w    t2, 8<<13; \
    li.w    t3, in_vpn<<13; \
    add.w t1, t3, t2; \
    csrwr t1, csr_tlbehi; \
    tlbsrch; \
    csrrd t2, csr_tlbidx; \
	srli.w t2, t2, 31; \
    li.w    t1, 0x1; \
    bne   t2, t1, inst_error

#define TEST_TLBSRCH_NOMATCHING_4MB(in_asid, in_vpn) \
    csrwr zero, csr_tlbidx; \
    li.w    t1, in_asid; \
    csrwr t1, csr_asid; \
    li.w    t2, 8<<22; \
    li.w    t3, in_vpn<<22; \
    add.w t1, t3, t2; \
    csrwr t1, csr_tlbehi; \
    tlbsrch; \
    csrrd t2, csr_tlbidx; \
	srli.w t2, t2, 31; \
    li.w    t1, 0x1; \
    bne   t2, t1, inst_error

#define GET_ECODE\
    csrrd    t0, csr_estat;\
    srli.w   t0, t0, 16;\
    li.w     t1, 0x3f;\
    and      t0, t0, t1;

#define GET_ESUBCODE\
    csrrd    t0, csr_estat;\
    srli.w   t0, t0, 22;\
    li.w     t1, 0x1ff;\
    and      t0, t0, t1;

#define CHECK_ECODE(ecode)\
    GET_ECODE\
    li.w     t1, ecode;\
    bne      t0, t1, ex_finish;

#define CHECK_ESUBCODE(esubcode)\
    GET_ESUBCODE\
    li.w     t1, esubcode;\
    bne      t0, t1, ex_finish;

