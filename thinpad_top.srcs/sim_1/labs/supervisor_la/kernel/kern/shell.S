#include <regdef.h>
#include <shell.h>


    .section .bss.uregs
    .p2align 2
    .global uregs
uregs:
    .rept 32                            // 第31个为用户程序入口地址临时保存
    .long 0
    .endr

    .text
    .p2align 2
    .global SHELL

    /*
     *  SHELL: 监控程序交互模块
     * 
     *  用户空间寄存器：$r2-$r31依次保存在0x807F0000连续120字节
     *  用户程序入口临时存储：0x807F0078
     */
SHELL:
    la.global    t0,READSERIAL           // 读操作符
    jirl        ra,t0,0x0

    sub.w       a0,a0,zero
    ori         t0,zero,SH_OP_R
    beq         a0,t0,.OP_R
    ori         t0,zero,SH_OP_D
    beq         a0,t0,.OP_D
    ori         t0,zero,SH_OP_A
    beq         a0,t0,.OP_A
    ori         t0,zero,SH_OP_G
    beq         a0,t0,.OP_G
    b           .DONE                   // 错误的操作符，默认忽略


.OP_R:                                  // 操作 - 打印用户空间寄存器
    addi.w      sp,sp,-8                // 保存s0,s1
    st.w        s0,sp,0x0
    st.w        s1,sp,0x4

    la.local    s0,uregs
    ori         s1,zero,0x7C            // 计数器，打印124字节
.LC0:
    ld.b        a0,s0,0x0               // 读取字节
    addi.w      s1,s1,-1                // 滚动计数器
    la.global    t0,WRITESERIAL          // 写入串口
    jirl        ra,t0,0x0
    addi.w      s0,s0,0x1               // 移动打印指针
    bne         s1,zero,.LC0            // 打印循环

    ld.w        s0,sp,0x0               // 恢复s0,s1
    ld.w        s1,sp,0x4
    addi.w      sp,sp,0x8
    b           .DONE

.OP_D:                                  // 操作 - 打印内存num字节
    addi.w      sp,sp,-8                // 保存s0,s1
    st.w        s0,sp,0x0
    st.w        s1,sp,0x4

    la.global    t0,READSERIALWORD
    jirl        ra,t0,0x0
    or          s0,a0,zero              // 获得addr
    la.global    t0,READSERIALWORD
    jirl        ra,t0,0x0
    or          s1,a0,zero              // 获得num

.LC1:
    ld.b        a0,s0,0x0               // 读取字节
    addi.w      s1,s1,-1                // 滚动计数器
    la.global    t0,WRITESERIAL          // 写入串口
    jirl        ra,t0,0x0
    addi.w      s0,s0,0x1               // 移动打印指针
    bne         s1,zero,.LC1            // 打印循环

    ld.w        s0,sp,0x0               // 恢复s0,s1
    ld.w        s1,sp,0x4
    addi.w      sp,sp,0x8
    b           .DONE

.OP_A:                                  // 操作 - 写入内存num字节，num为4的倍数
    addi.w      sp,sp,-8                // 保存s0,s1
    st.w        s0,sp,0x0
    st.w        s1,sp,0x4

    la.global    t0,READSERIALWORD
    jirl        ra,t0,0x0
    or          s0,a0,zero              // 获得addr
    la.global    t0,READSERIALWORD
    jirl        ra,t0,0x0
    or          s1,a0,zero              // 获得num
    srli.w      s1,s1,2                 // num除4，获得字数
.LC2:                                   // 每次写入一字
    la.global    t0,READSERIALWORD       // 从串口读入一字
    jirl        ra,t0,0x0
    st.w        a0,s0,0x0               // 写内存一字
    addi.w      s1,s1,-1                // 滚动计数器
    addi.w      s0,s0,0x4               // 移动写指针
    bne         s1,zero,.LC2            // 写循环

    ld.w        s0,sp,0x0               // 恢复s0,s1
    ld.w        s1,sp,0x4
    addi.w      sp,sp,0x8
    b           .DONE

.OP_G:
    la.global    t0,READSERIALWORD       // 获取addr
    jirl        ra,t0,0x0
    or          $r21,a0,zero

    ori         a0,zero,TIMERSET        // 写TIMERSET(0x06)信号
    la.global    t0,WRITESERIAL          // 告诉终端用户程序开始运行
    jirl        ra,t0,0x0

    la.local    ra,uregs                // 定位用户空间寄存器备份地址
    st.w        sp,ra,31<<2             // 保存栈指针
    ld.w        $r2,ra,1<<2             // 装入$r2-$r31
    ld.w        $r3,ra,2<<2  
    ld.w        $r4,ra,3<<2  
    ld.w        $r5,ra,4<<2  
    ld.w        $r6,ra,5<<2  
    ld.w        $r7,ra,6<<2  
    ld.w        $r8,ra,7<<2  
    ld.w        $r9,ra,8<<2  
    ld.w        $r10,ra,9<<2 
    ld.w        $r11,ra,10<<2 
    ld.w        $r12,ra,11<<2
    ld.w        $r13,ra,12<<2
    ld.w        $r14,ra,13<<2
    ld.w        $r15,ra,14<<2
    ld.w        $r16,ra,15<<2
    ld.w        $r17,ra,16<<2
    ld.w        $r18,ra,17<<2
    ld.w        $r19,ra,18<<2
    ld.w        $r20,ra,19<<2
    # ld.w        $r21,ra,20<<2
    ld.w        $r22,ra,21<<2
    ld.w        $r23,ra,22<<2
    ld.w        $r24,ra,23<<2
    ld.w        $r25,ra,24<<2
    ld.w        $r26,ra,25<<2
    ld.w        $r27,ra,26<<2
    ld.w        $r28,ra,27<<2
    ld.w        $r29,ra,28<<2
    ld.w        $r30,ra,29<<2
    ld.w        $r31,ra,30<<2

    jirl        ra,$r21,0x0
.USERRET2:
    la.local    ra,uregs                // 定位用户空间寄存器备份地址
    st.w        $r2,ra,1<<2             // 备份$r1-$r31
    st.w        $r3,ra,2<<2  
    st.w        $r4,ra,3<<2  
    st.w        $r5,ra,4<<2  
    st.w        $r6,ra,5<<2  
    st.w        $r7,ra,6<<2  
    st.w        $r8,ra,7<<2  
    st.w        $r9,ra,8<<2  
    st.w        $r10,ra,9<<2 
    st.w        $r11,ra,10<<2 
    st.w        $r12,ra,11<<2
    st.w        $r13,ra,12<<2
    st.w        $r14,ra,13<<2
    st.w        $r15,ra,14<<2
    st.w        $r16,ra,15<<2
    st.w        $r17,ra,16<<2
    st.w        $r18,ra,17<<2
    st.w        $r19,ra,18<<2
    st.w        $r20,ra,19<<2
    st.w        $r21,ra,20<<2
    st.w        $r22,ra,21<<2
    st.w        $r23,ra,22<<2
    st.w        $r24,ra,23<<2
    st.w        $r25,ra,24<<2
    st.w        $r26,ra,25<<2
    st.w        $r27,ra,26<<2
    st.w        $r28,ra,27<<2
    st.w        $r29,ra,28<<2
    st.w        $r30,ra,29<<2
    st.w        $r31,ra,30<<2
    la.local    a0,.USERRET2
    st.w        a0,ra,0<<2
    ld.w        sp,ra,31<<2
    
    ori         a0,zero,TIMETOKEN       // 发送TIMETOKEN(0x07)信号
    la.global    t0,WRITESERIAL          // 告诉终端用户程序结束运行
    jirl        ra,t0,0x0

    b           .DONE

.DONE:
    b           SHELL                   // 交互循环
