/**
 * @file IF_stage.v
 * @author ykykzq
 * @brief 流水线第一级，主要完成PC的维护与Inst RAM取指
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
	input  wire[31:0]					inst_ram_r_data,
	output wire[3:0]					inst_ram_w_en,
	output wire[31:0]					inst_ram_w_data,//实际上用不到指令RAM的写
    
	//流水线控制
	input  wire							ID_allow_in,
	output wire							IF_to_IPD_valid
	);


	//////////////////////////////////////////////
	///维护与流水线控制有关的信号
	
	//IF_valid
	always@(posedge clk)//异步复位
	begin
		if(reset)
			IF_valid<=1'b0;//相当于清空有效数据
		else if(IF_allow_in)
			IF_valid<=Pre_to_IF_valid;
		else
			IF_valid<=IF_valid;
	end
	
	//控制流水线行为
	assign IF_ready_go=1'b1;//总认为一周期内能完成
	assign IF_allow_in=(~IF_valid) | (IF_ready_go & ID_allow_in);//后者加上IF_valid=1,相当于IF可以向ID发送数据(只含“发送”，不含“接收”)
	assign Pre_to_IF_valid=~reset;
	assign IF_to_IPD_valid=IF_valid;//&IF_ready_go
	

	///////////////////////////////////////////////
	/// 控制PC
	always@(posedge clk)
	begin
		if(reset)
			PC<=32'h1c000000;
		else if(IF_allow_in & Pre_to_IF_valid)
			PC<=next_PC;
		else 
			PC<=PC;
	end

	assign PC_plus_4=PC+3'b100;

	assign next_PC=br_taken_cancel?PC_fromID:PC_plus_4;

	///////////////////////////////////////////////
	/// 取INST

	assign inst_ram_en=1'b1;
	assign inst_ram_addr=next_PC;
	//不写RAM
	assign inst_ram_w_data=32'b0;
	assign inst_ram_w_en=4'b0;

	///////////////////////////////////////////////
	/// 流水线数据交互
	assign {
		br_taken_cancel	,//32
		PC_fromID		 //31:0			
					}=ID_to_IF_bus;

	assign IF_to_IPD_bus={PC_plus_4,inst};

endmodule