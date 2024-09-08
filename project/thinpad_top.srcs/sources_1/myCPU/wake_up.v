/**
 * @file wake_up.v
 * @author ykykzq
 * @brief WakeUP检测源操作数是否准备好，控制是否唤醒当前指令。
 * @version 0.1
 * @date 2024-08-20
 *
 */
`include "myCPU.h"
module WakeUP(
	// 源操作数的控制信号与读取的寄存器号
	input  wire[ 1: 0]					sel_alu_src1,
	input  wire[ 2: 0]					sel_alu_src2,
	input  wire							sel_bu_src1,
	input  wire							sel_bu_src2,
	input  wire[ 4: 0]					RegFile_r_addr1,
	input  wire[ 4: 0]					RegFile_r_addr2,

	// 流水线数据交互
	input  wire[`BY_TO_WK_BUS_WD-1:0]	BY_to_WK_bus,
	
	// 输出源操作数可以获得信号
	output reg 							alu_src_1_ready,
	output reg							alu_src_2_ready,
	output reg 							bu_src_1_ready,
	output reg							bu_src_2_ready
    );
	// EXE
	wire [ 4: 0]	EXE_RegFile_w_addr	;
	wire 	EXE_sel_RF_w_data_valid		;
	wire	EXE_valid					;
	wire 	EXE_sel_rf_w_en				;

	// MEM
	wire [ 4: 0]MEM_RegFile_w_addr		;
	wire MEM_sel_RF_w_data_valid		;
	wire MEM_valid						;
	wire MEM_sel_rf_w_en				;

	// PMEM
	wire [ 4: 0]PMEM_RegFile_w_addr		;
	wire PMEM_sel_RF_w_data_valid		;
	wire PMEM_valid						;
	wire PMEM_sel_rf_w_en				;

	// WB
	wire [ 4: 0]	WB_RegFile_w_addr	;
	wire WB_sel_RF_w_data_valid			;
	wire WB_valid						;
	wire WB_sel_rf_w_en				 	;

	/////////////////////////////////////////////////////////////////
	/// 检测是否已经准备好

	// bu_src1
	always@(*)
	begin
		if(sel_bu_src1)
			if(RegFile_r_addr1==EXE_RegFile_w_addr && EXE_sel_rf_w_en && EXE_valid)
				if(EXE_sel_RF_w_data_valid)
					// 可以从EXE阶段旁路该值
					bu_src_1_ready<=1'b1;
				else 
					// 代表阻塞
					bu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==PMEM_RegFile_w_addr && PMEM_sel_rf_w_en && PMEM_valid)
				if(PMEM_sel_RF_w_data_valid)
					bu_src_1_ready<=1'b1;
				else
					bu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==MEM_RegFile_w_addr && MEM_sel_rf_w_en && MEM_valid)
				if(MEM_sel_RF_w_data_valid)
					bu_src_1_ready<=1'b1;
				else
					bu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==WB_RegFile_w_addr && WB_sel_rf_w_en && WB_valid)
				if(WB_sel_RF_w_data_valid)
					bu_src_1_ready<=1'b1;
				else
					bu_src_1_ready<=1'b0;
			else 
				// 如果后续流水级指令均不写入该寄存器，则从寄存器堆获得操作数
				bu_src_1_ready<=1'b1;
		else
			bu_src_1_ready<=1'b1;
	end
	// bu_src2
	always@(*)
	begin
		if(sel_bu_src2)
			if(RegFile_r_addr2==EXE_RegFile_w_addr && EXE_sel_rf_w_en && EXE_valid)
				if(EXE_sel_RF_w_data_valid)
					// 可以从EXE阶段旁路该值
					bu_src_2_ready<=1'b1;
				else 
					// 代表阻塞
					bu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==PMEM_RegFile_w_addr && PMEM_sel_rf_w_en && PMEM_valid)
				if(PMEM_sel_RF_w_data_valid)
					bu_src_2_ready<=1'b1;
				else
					bu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==MEM_RegFile_w_addr && MEM_sel_rf_w_en && MEM_valid)
				if(MEM_sel_RF_w_data_valid)
					bu_src_2_ready<=1'b1;
				else
					bu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==WB_RegFile_w_addr && WB_sel_rf_w_en && WB_valid)
				if(WB_sel_RF_w_data_valid)
					bu_src_2_ready<=1'b1;
				else
					bu_src_2_ready<=1'b0;
			else 
				// 如果后续流水级指令均不写入该寄存器，则从寄存器堆获得操作数
				bu_src_2_ready<=1'b1;
		else
			bu_src_2_ready<=1'b1;
	end


	// alu_src_1，当源操作数来自于寄存器，并且流水线中还没有该数据时，数据为未准备好状态
	always@(*)
	begin
		if(sel_alu_src1[1])
			if(RegFile_r_addr1==EXE_RegFile_w_addr && EXE_sel_rf_w_en && EXE_valid)
				if(EXE_sel_RF_w_data_valid)
					// 可以从EXE阶段旁路该值
					alu_src_1_ready<=1'b1;
				else 
					// 若EXE阶段还未产生写入数据，则无法通过旁路获得该值。
					alu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==PMEM_RegFile_w_addr && PMEM_sel_rf_w_en && PMEM_valid)
				if(PMEM_sel_RF_w_data_valid)
					alu_src_1_ready<=1'b1;
				else
					alu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==MEM_RegFile_w_addr && MEM_sel_rf_w_en && MEM_valid)
				if(MEM_sel_RF_w_data_valid)
					alu_src_1_ready<=1'b1;
				else
					alu_src_1_ready<=1'b0;
			else if(RegFile_r_addr1==WB_RegFile_w_addr && WB_sel_rf_w_en && WB_valid)
				if(WB_sel_rf_w_en)
					alu_src_1_ready<=1'b1;
				else
					alu_src_1_ready<=1'b0;
			else 
				// 如果后续阶段均不写入该寄存器，则从寄存器堆获得操作数，一定可以准备好
				alu_src_1_ready<=1'b1;
		else 
			// 如果操作数不来自于寄存器堆而是来自于指令PC，一定已经准备好
			alu_src_1_ready<=1'b1;
	end

	// alu_src_2，当源操作数来自于寄存器，并且流水线中还没有该数据时，数据为未准备好状态
	always@(*)
	begin
		if(sel_alu_src2[1])
			if(RegFile_r_addr2==EXE_RegFile_w_addr && EXE_sel_rf_w_en && EXE_valid)
				if(EXE_sel_RF_w_data_valid)
					// 可以从EXE阶段旁路该值
					alu_src_2_ready<=1'b1;
				else 
					// 若EXE阶段还未产生写入数据，则无法通过旁路获得该值。
					alu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==PMEM_RegFile_w_addr && PMEM_sel_rf_w_en && PMEM_valid)
				if(PMEM_sel_RF_w_data_valid)
					alu_src_2_ready<=1'b1;
				else
					alu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==MEM_RegFile_w_addr && MEM_sel_rf_w_en && MEM_valid)
				if(MEM_sel_RF_w_data_valid)
					alu_src_2_ready<=1'b1;
				else
					alu_src_2_ready<=1'b0;
			else if(RegFile_r_addr2==WB_RegFile_w_addr && WB_sel_rf_w_en && WB_valid)
				if(WB_sel_rf_w_en)
					alu_src_2_ready<=1'b1;
				else
					alu_src_2_ready<=1'b0;
			else 
				// 如果后续阶段均不写入该寄存器，则从寄存器堆获得操作数，一定可以准备好
				alu_src_2_ready<=1'b1;
		else 
			// 如果是PC+4，也一定可以准备好
			// 如果操作数不来自于寄存器堆而是来自于指令PC，一定已经准备好
			alu_src_2_ready<=1'b1;
	end

	/////////////////////////////////////////////////////////////////
	/// 流水线数据交互

	// BY_to_WK_bus中应该包括从ID阶段之后 所有阶段 的寄存器写入信息，包括：是否写入、写入寄存器号、是否已经准备好写入数据
	assign {
		// EXE阶段信号
		EXE_RegFile_w_addr			,//5
		EXE_sel_RF_w_data_valid		,//1
		EXE_valid					,//1
		EXE_sel_rf_w_en				,//1
		// PMEM阶段信号
		PMEM_RegFile_w_addr			,//5
		PMEM_sel_RF_w_data_valid	,//1
		PMEM_valid					,//1
		PMEM_sel_rf_w_en			,//1
		// MEM阶段信号
		MEM_RegFile_w_addr			,//5
		MEM_sel_RF_w_data_valid		,//1
		MEM_valid					,//1
		MEM_sel_rf_w_en				,//1
		// WB阶段信号		
		WB_RegFile_w_addr			,//5
		WB_sel_RF_w_data_valid		,//1
		WB_valid					,//1
		WB_sel_rf_w_en				 //1
	}=BY_to_WK_bus;
	
endmodule
