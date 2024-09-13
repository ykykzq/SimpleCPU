#include <regdef.h>

    .p2align 2
    .text
    .global WRITESERIAL
    .global READSERIAL
    .global READSERIALWORD

WRITESERIAL:                            // 写串口：将a0的低八位写入串口
#ifdef MACH_FPGA
    la.global    t1,SerialStat
.TESTW:
    ld.b        t0,t1,0x0               // 查看串口状态
    andi        t0,t0,0x001             // 截取写状态位
    bne         t0,zero,.WSERIAL        // 状态位非零可写进入写
    b           .TESTW                  // 检测验证，忙等待
.WSERIAL:
    la.global    t1,SerialData
    st.b        a0,t1,0x0               // 写入
    jirl        zero,ra,0x0
#else                               // QEMU模拟器上的写串口操作
#TODO
#endif

READSERIAL:                             // 读串口：将读到的数据写入a0低八位
#ifdef MACH_FPGA
    la.global    t1,SerialStat
.TESTR:
    ld.b        t0,t1,0x0               // 查看串口状态
    andi        t0,t0,0x002             // 截取读状态位
    bne         t0,zero,.RSERIAL        // 状态位非零可读进入读
    b           .TESTR                  // 检测验证
.RSERIAL:
    la.global    t1,SerialData
    ld.b        a0,t1,0x0               // 读出
    jirl        zero,ra,0x0
#else //ifdef MACH_FPGA             // QEMU模拟器上的读串口操作
#TODO
#endif //ifdef MACH_FPGA

READSERIALWORD:
    addi.w      sp,sp,-0x14             // 保存ra,s0
    st.w        ra,sp,0x0
    st.w        s0,sp,0x4
    st.w        s1,sp,0x8
    st.w        s2,sp,0xC
    st.w        s3,sp,0x10

    bl          READSERIAL
    or          s0,zero,a0
    bl          READSERIAL
    or          s1,zero,a0
    bl          READSERIAL
    or          s2,zero,a0
    bl          READSERIAL
    or          s3,zero,a0

    andi        s0,s0,0x0FF             // 截取低八位
    andi        s3,s3,0x0FF
    andi        s2,s2,0x0FF
    andi        s1,s1,0x0FF
    or          a0,zero,s3
    slli.w      a0,a0,8
    or          a0,a0,s2
    slli.w      a0,a0,8
    or          a0,a0,s1
    slli.w      a0,a0,8
    or          a0,a0,s0  

    ld.w        ra,sp,0x0
    ld.w        s0,sp,0x4
    ld.w        s1,sp,0x8
    ld.w        s2,sp,0xC
    ld.w        s3,sp,0x10
    addi.w      sp,sp,0x14
    jirl        zero,ra,0x0
