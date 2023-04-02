`include "myCPU.h"
module MEM_stage(
	input  wire 						clk,
	input  wire							reset,
	
	input  wire[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_bus,
	output wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,
	
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
	wire[31:0]					PC_plus_4;
	wire[31:0]					alu_res;
	wire[4:0]					RegFile_target_w_addr;
	wire[1:0]					sel_rf_w_data;
	wire						sel_rf_w_en;
	
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
	
	assign{	PC_plus_4				,//72:41
			alu_res					,//40:9
			RegFile_target_w_addr	,//8:3
			sel_rf_w_data			,//2:1
			sel_rf_w_en				 //0
			}=EXE_to_MEM_reg;
			
	/////////////////////////////////////////////////////////////////////////
	//传给下一个阶段
	assign MEM_to_WB_bus={
							PC_plus_4				,//103:72
							alu_res					,//71:40
							data_ram_r_data			,//38:8
							RegFile_target_w_addr	,//7:3
							sel_rf_w_data			,//2:1
							sel_rf_w_en				 //0
						};
	
	
	
endmodule
