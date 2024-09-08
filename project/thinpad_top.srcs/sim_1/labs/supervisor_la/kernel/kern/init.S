#include <regdef.h>
#include <exception.h>


    .section .bss
    .p2align 2
    .global TCBT                        // thread control block table
TCBT:
    .long 0
    .long 0
    .global current                     // current thread TCB address
current:
    .long 0

    .text
    .p2align 2
monitor_version:
    .asciz "MONITOR for Loongarch32 - initialized."


    /* start address for the .bss section. defined in linker script */
    .word   _sbss
    /* end address for the .bss section. defined in linker script */
    .word   _ebss
    .p2align 2
    .global START
START:                                  // kernel init
    la.local    t0,_sbss
    la.local    t1,_ebss
bss_init:
    beq         t0,t1,bss_init_done
    st.w        zero,t0,0x0
    addi.w      t0,t0,0x4
    b           bss_init

bss_init_done:
    la.global   sp,KERNEL_STACK_INIT    // 设置内核栈
    or          fp,sp,zero
    la.global   t0,USER_STACK_INIT      // 设置用户栈
    la.global   t1,uregs_sp             // 写入用户空间备份
    st.w        t0,t1,0x0
    la.global   t1,uregs_fp
    st.w        t0,t1,0x0

    /* init serial */
#ifdef MACH_QEMU                        // QEMU模拟器特有的串口初始化过程
#TODO
#endif

    ori         t0,zero,TF_SIZE/4       // 计数器 
.LC0:
    addi.w      t0,t0,-1                // 滚动计数器
    addi.w      sp,sp,-4                // 移动栈指针
    st.w        zero,sp,0x0             // 初始化栈空间
    bne         t0,zero,.LC0            // 初始化循环
    la.local    t0,TCBT                 // 载入TCBT地址
    st.w        sp,t0,0x0               // thread0(idle)的中断帧地址设置
    or          t6,sp,zero              // t6保存idle中断帧位置

    ori         t0,zero,TF_SIZE/4       // 计数器
.LC1:
    addi.w      t0,t0,-1                // 滚动计数器
    addi.w      sp,sp,-4                // 移动栈指针
    st.w        zero,sp,0x0             // 初始化栈空间
    bne         t0,zero,.LC1            // 初始化循环
    la.local    t0,TCBT                 // 载入TCBT地址
    st.w        sp,t0,0x4               // thread1(shell/user)的中断帧地址设置
    st.w        sp,t6,TF_sp             // 设置idle线程栈指针(调试用?)

    la.local    t2,TCBT+4
    ld.w        t2,t2,0x0               // 取得thread1的TCB地址
    la.local    t1,current
    st.w        t2,t1,0x0               // 设置当前线程为thread1

    b           WELCOME                 // 进入主线程



WELCOME:
    la.local    s0,monitor_version      // 装入启动信息
    ld.b        a0,s0,0x0
.Loop0:
    addi.w      s0,s0,0x1
    la.global    t0,WRITESERIAL          // 调用串口写函数
    jirl        ra,t0,0x0
    ld.b        a0,s0,0x0
    bne         a0,zero,.Loop0          // 打印循环至0结束符
    la.global    t0,SHELL                // 开始交互
    jirl        zero,t0,0x0
