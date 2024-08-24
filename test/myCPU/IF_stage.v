/**
 * @file IF_stage.v
 * @author ykykzq
 * @brief 流水线第一级，主要完成PC的维护与Inst RAM取指。
 * @brief 分支预测：静态分支预测，预测不跳转（pred_PC=PC+4）
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include "./include/myCPU.h"

module IF_stage(
	input 								clk,
	input 								reset,

	//流水线数据传输
	input  wire[`ID_TO_IF_BUS_WD-1:0]	ID_to_IF_bus,
	output wire[`IF_TO_IPD_BUS_WD-1:0]	IF_to_IPD_bus,
	
	//连接指令RAM
	output wire							inst_ram_en,//(读)使能
	output wire[31:0]					inst_ram_addr,
	output wire[3:0]					inst_ram_w_en,
	output wire[31:0]					inst_ram_w_data,//实际上用不到指令RAM的写
    
	//流水线控制
	input  wire							IPD_allow_in,
	output wire							IF_to_IPD_valid
);
	// PC相关
	wire [31: 0]		PC_plus_4		;
	reg  [31: 0]		PC				;
	wire [31: 0]		next_PC			;
	wire				br_taken_cancel	;
	wire [31: 0]		PC_fromID		;
	
	//分支预测的PC
	wire [31: 0]		pred_PC			;

	// 流水线行为控制
	wire				IF_ready_go		;
	reg 				IF_valid		;

	//////////////////////////////////////////////
	///维护与流水线控制有关的信号
	
	// IF_valid
	always@(posedge clk)//同步复位
	begin
		if(reset)
			IF_valid<=1'b0;//相当于清空有效数据
		else if(IF_allow_in)
			IF_valid<=Pre_to_IF_valid;
		else if(br_taken_cancel)
			// flush掉当前指令
			IF_valid<=1'b0;
		else
			IF_valid<=IF_valid;
	end
	
	// 控制流水线行为
	assign IF_ready_go=1'b1;// 当前取指在一周期内一定能完成
	assign IF_allow_in=(~IF_valid) | (IF_ready_go & IPD_allow_in);
	assign Pre_to_IF_valid=~reset;
	assign IF_to_IPD_valid=IF_valid & IF_ready_go;
	
	/////////////////////////////////////////////////
	/// 分支预测

	// 静态分支预测：始终预测分支不发生
	assign pred_PC=PC_plus_4;

	///////////////////////////////////////////////
	/// 控制PC
	always@(posedge clk)
	begin
		if(reset)
			PC<=32'h1c000000-4'b1000;// 考虑到rst后第一周期无效，再加上给Inst RAM的是next_PC，故-8
		else if(IF_allow_in & Pre_to_IF_valid)
			PC<=next_PC;
		else 
			PC<=PC;
	end

	assign PC_plus_4=PC+3'b100;
	// 若之前的指令预测失败，从正确的位置(PC_fromID)重新开始取指
	assign next_PC=br_taken_cancel?PC_fromID:pred_PC;

	///////////////////////////////////////////////
	/// 取INST

	assign inst_ram_en=1'b1;
	assign inst_ram_addr=IF_allow_in?next_PC:PC;
	// 不写Inst RAM
	assign inst_ram_w_data=32'b0;
	assign inst_ram_w_en=4'b0;

	///////////////////////////////////////////////
	/// 流水线数据交互
	assign {
		br_taken_cancel	,//32
		PC_fromID		 //32	
	}=ID_to_IF_bus;

	assign IF_to_IPD_bus={
			pred_PC		,//32
			next_PC		 //32
						 //32
		};

endmodule
