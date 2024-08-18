/**
 * @file wake_up.v
 * @author ykykzq
 * @brief WakeUP检测源操作数是否准备好，控制是否唤醒当前指令。
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include "myCPU.h"
module WakeUP(
	// 源操作数的控制信号与读取的寄存器号
	input  wire[ 1: 0]					sel_alu_src1,
	input  wire[ 1: 0]					sel_alu_src2,
	input  wire[ 4: 0]					RegFile_R_addr2,
	input  wire[ 4: 0]					RegFile_R_addr1,

	// 流水线数据交互
	input  wire[`BY_TO_WK_BUS_WD-1:0]	BY_to_WK_bus,
	
	// 输出源操作数可以获得信号
	output wire							src_1_ready,
	output wire							src_2_ready
    );
	

	/////////////////////////////////////////////////////////////////
	/// 检测是否已经准备好

	// src_1，当源操作数来自于寄存器，并且流水线中还没有该数据时，数据为未准备好状态

	// src_2，当源操作数来自于寄存器，并且流水线中还没有该数据时，数据为未准备好状态


	/////////////////////////////////////////////////////////////////
	/// 流水线数据交互

	// BY_to_WK_bus中应该包括从ID阶段之后 所有阶段 的寄存器写入信息，包括：是否写入、写入寄存器号、是否已经准备好写入数据
	
endmodule
