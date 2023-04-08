`include "myCPU.h"
module EXE_stage(
	input  wire							clk,
	input  wire							reset,
	
	//stage间数据交流
	input  wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus,
	output wire[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_bus,
	
	//流水线控制
	input  wire							MEM_allow_in,
	output wire							EXE_to_MEM_valid,
	input  wire							ID_to_EXE_valid,
	output wire							EXE_allow_in,
	
	
	//为构建同指令RAM一样的“伪.组合逻辑”，需在EXE阶段即给数据RAM地址等
	output wire[31:0]					data_ram_w_addr,
	output wire[31:0]					data_ram_r_addr,
	output wire[31:0]					data_ram_w_data,
	output wire							data_ram_w_en_4bit
    );
	//流水线控制
	wire						EXE_ready_go;
	reg 						EXE_valid;
	
	
	//寄存器
	reg[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_reg;
	
	//从寄存器中拿出的数据
	wire[31:0]					PC_plus_4;
	wire[31:0]					RegFile_r_data1;
	wire[31:0]					RegFile_r_data2;
	wire[4:0]					inst_sa;
	wire[31:0]					inst_offset_imm;
	wire[4:0]					RegFile_target_w_addr;
	
	wire						sel_alu_src_1;
	wire						sel_alu_src_2;
	wire[3:0]					sel_alu_op;
	wire[1:0]					sel_rf_w_data;
	wire 						sel_rf_w_en;
	
	//调用ALU
	wire[31:0]					alu_src_1;
	wire[31:0]					alu_src_2;
	wire[31:0]					alu_res;
	
	///////////////////////////////////////////////////////////////////
	//取出数据
	always@(posedge clk)
	begin
		if(EXE_allow_in & ID_to_EXE_valid)
			ID_to_EXE_reg<=ID_to_EXE_bus;
		else
			ID_to_EXE_reg<=ID_to_EXE_reg;
	end
	
	assign {	PC_plus_4				,//147:116
				RegFile_r_data1			,//115:84
				RegFile_r_data2			,//83:52
				inst_sa					,//51:47
				inst_offset_imm			,//46:15
				RegFile_target_w_addr	,//14:10
				sel_alu_src_1			,//9
				sel_alu_src_2			,//8
				sel_alu_op				,//7:4
				data_ram_w_en			,//3
				sel_rf_w_data			,//2:1
				sel_rf_w_en				 //0
				}
					=ID_to_EXE_reg;
	
	assign	data_ram_w_en_4bit={4{data_ram_w_en}};
	//////////////////////////////////////////////////////////////////////////
	//调用ALU
	assign alu_src_1=sel_alu_src_1?RegFile_r_data1:{27'b0,inst_sa};//无符号扩展
	assign alu_src_2=sel_alu_src_2?inst_offset_imm:RegFile_r_data2;
	
	ALU alu(
		.alu_src1(alu_src_1),
		.alu_src2(alu_src_2),
		.alu_op(sel_alu_op),
		.alu_res(alu_res)
		);
		
	//////////////////////////////////////////////////////////////////////////////
	//调用data_RAM
	assign data_ram_r_addr={{2{alu_res[31]}},alu_res[31:2]};
	assign data_ram_w_addr={{2{alu_res[31]}},alu_res[31:2]};
	assign data_ram_w_data=RegFile_r_data2;
	//data_ram_w_en在ID传来的数据中
	
	/////////////////////////////////////////////////////////////////////////////
	//流水线控制 及 数据传送
	always@(posedge clk)
	begin
		if(reset)
			EXE_valid<=1'b0;
		else if(EXE_allow_in)
			EXE_valid<=ID_to_EXE_valid;
		else
			EXE_valid<=EXE_valid;
	end
	assign EXE_ready_go=1'b1;
	assign EXE_to_MEM_valid=EXE_valid & EXE_ready_go;
	assign EXE_allow_in=(~EXE_valid)|(EXE_ready_go & MEM_allow_in);
	//数据传送
	assign EXE_to_MEM_bus={	PC_plus_4				,//71:40
							alu_res					,//39:8
							RegFile_target_w_addr	,//7:3
							sel_rf_w_data			,//2:1
							sel_rf_w_en				 //0
							};
	
endmodule
