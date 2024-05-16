`include "myCPU.h"
module MEM_stage(
	input  wire 						clk,
	input  wire							reset,
	
	//stage
	input  wire[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_bus,
	output wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,
	
	//BY
	output wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus,
	
	input  wire[31:0]					data_ram_r_data,
	
	//流水线控制
	input  wire							EXE_to_MEM_valid,
	output wire							MEM_allow_in,
	input  wire							WB_allow_in,
	output wire							MEM_to_WB_valid
    );
	wire						MEM_ready_go;
	reg							MEM_valid;
	
	//取出数据
	reg[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_reg;
	wire[31:0]					PC_plus_8;
	wire[31:0]					RegFile_w_data_fromEXE;
	wire[4:0]					RegFile_target_w_addr;
	wire[1:0]					sel_which_byte;
	wire[1:0]					sel_rf_w_data;
	wire						sel_rf_w_en;
	wire						sel_dm_width;
	
	wire[31:0]					RegFile_w_data;
	
	//LB/SB
	wire[31:0]					data_ram_r_data_byte;
	
	//////////////////////////////////////////////////////////////////////
	//流水线控制
	assign MEM_ready_go=1'b1;
	assign MEM_allow_in=(~MEM_valid)|(WB_allow_in & MEM_ready_go);
	assign MEM_to_WB_valid=MEM_valid & MEM_ready_go;
	
	always@(posedge clk)
	begin
		if(reset)
			MEM_valid<=1'b0;
		else if(MEM_allow_in)
			MEM_valid<=EXE_to_MEM_valid;
		else
			MEM_valid<=MEM_valid;
	end
	
	/////////////////////////////////////////////////////////////////////
	//stage间交互
	//取出数据
	always@(posedge clk)
	begin
		if(EXE_to_MEM_valid & MEM_allow_in)
			EXE_to_MEM_reg<=EXE_to_MEM_bus;
		else
			EXE_to_MEM_reg<=EXE_to_MEM_reg;
			
	end
	
	assign{	
			sel_dm_width			,//75
	        sel_rf_w_data			,//74:73
	        sel_rf_w_en				,//72
	        sel_MEM_gene			,//71
	        sel_which_byte			,//70:69,决定LB/SB使用哪一个字节
			PC_plus_8				,//68:37
			RegFile_w_data_fromEXE	,//36:5
			RegFile_target_w_addr	 //4:0
			}
					=EXE_to_MEM_reg;
		
	//LB为有符号扩展
	assign data_ram_r_data_byte=	(sel_which_byte==2'b11)?{{24{data_ram_r_data[31]}},data_ram_r_data[31:24]}:
									(sel_which_byte==2'b10)?{{24{data_ram_r_data[23]}},data_ram_r_data[23:16]}:
									(sel_which_byte==2'b01)?{{24{data_ram_r_data[15]}},data_ram_r_data[15: 8]}:
									(sel_which_byte==2'b00)?{{24{data_ram_r_data[ 7]}},data_ram_r_data[ 7: 0]}:
										32'b0;
	
	assign RegFile_w_data=	(sel_rf_w_data==2'b10 & sel_dm_width)?data_ram_r_data_byte:
							(sel_rf_w_data==2'b10 & (~sel_dm_width))?data_ram_r_data:
									RegFile_w_data_fromEXE;

	/////////////////////////////////////////////////////////////////////////
	//传给下一个阶段
	assign MEM_to_WB_bus={
							sel_rf_w_data			,//71:70
							sel_rf_w_en				,//69
							PC_plus_8				,//68:37
							RegFile_w_data			,//36:5
							RegFile_target_w_addr	 //4:0
						};
	
	
	//to BY
	assign MEM_to_BY_bus={
							sel_rf_w_en				,//38
							MEM_valid				,//37
							RegFile_target_w_addr	,//36:32
							RegFile_w_data			 //31:0
							};
endmodule
