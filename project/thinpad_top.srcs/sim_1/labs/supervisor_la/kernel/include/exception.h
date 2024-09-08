#ifndef _EXCEPTION_H
#define _EXCEPTION_H

#define TF_SIZE     0x80    /* trap frame size */

#define EX_IRQ			0	/* Interupt */
#define EX_TLBL		1	/* TLB miss on a load */
#define EX_TLBS		2	/* TLB miss on a store */
#define EX_TLBI		3	/* TLB miss on a ifetch */
#define EX_MOD			4	/* TLB modified fault */
#define EX_TLBRI		5	/* TLB Read-Inhibit exception */
#define EX_TLBXI		6	/* TLB Execution-Inhibit exception */
#define EX_TLBPE		7	/* TLB Privilege Error */
#define EX_ADE			8	
#define EX_UNALIGN		9	
#define EX_OOB			10  
#define EX_SYS			11	/* System call */
#define EX_BP			12	/* Breakpoint */
#define EX_RI			13	/* Reserved inst */
#define EX_IPE			14	/* Inst. Privileged Error */
#define EX_FPDIS		15	
#define EX_LSXDIS		16  
#define EX_LASXDIS		17	
#define EX_FPE			18	/* Floating Point Exception */
#define EXCSUBCODE_FPE			0	/* Floating Point Exception */
#define EXCSUBCODE_VEC			1	/* Vector Exception */
#define EX_WATCH		19
#define EX_BTDIS		20
#define EX_BTE			21	/* Binary Trans. Exception */
#define EX_PSI			22
#define EX_HYP			23
#define EX_FC			24
#define EXCSUBCODE_SFC			0
#define EXCSUBCODE_HFC			1
#define EX_SE			25
#define EX_TLBR         0x3f

#define TF_ra       0x00
#define TF_tp       0x04
#define TF_sp       0x08
#define TF_a0       0x0C
#define TF_a1       0x10
#define TF_a2       0x14
#define TF_a3       0x18
#define TF_a4       0x1C
#define TF_a5       0x20
#define TF_a6       0x24
#define TF_a7       0x28
#define TF_t0       0x2C
#define TF_t1       0x30
#define TF_t2       0x34
#define TF_t3       0x38
#define TF_t4       0x3C
#define TF_t5       0x40
#define TF_t6       0x44
#define TF_t7       0x48
#define TF_t8       0x4C
#define TF_fp       0x50
#define TF_s0       0x54
#define TF_s1       0x58
#define TF_s2       0x5C
#define TF_s3       0x60
#define TF_s4       0x64
#define TF_s5       0x68
#define TF_s6       0x6C
#define TF_s7       0x70
#define TF_s8       0x74
#define TF_ESTAT    0x78
#define TF_ERA      0x7C

#endif
