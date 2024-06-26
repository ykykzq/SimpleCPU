`include "myCPU.h"
module EXE_stage(
	input  wire							clk,
	input  wire							reset,
	
	//stage间数据交流
	input  wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus,
	output wire[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_bus,
	
	//ST
	output wire[`EXE_TO_ST_BUS_WD-1:0]	EXE_to_ST_bus,
	
	//BY
	output wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus,
	
	//流水线控制
	input  wire							MEM_allow_in,
	output wire							EXE_to_MEM_valid,
	input  wire							ID_to_EXE_valid,
	output wire							EXE_allow_in,
	
	
	//为构建同指令RAM一样的“伪.组合逻辑”，需在EXE阶段即给数据RAM地址等
	output wire[31:0]					data_ram_addr,
	output wire[31:0]					data_ram_w_data,
	output wire							data_ram_en,
	output wire[3:0]					data_ram_w_en_4bit
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
	//LB/SB
	wire						sel_dm_width;
	wire[31:0]					data_ram_w_data_byte;
	
	wire						sel_MEM_gene;
	
	//调用ALU
	wire[31:0]					alu_src_1;
	wire[31:0]					alu_src_2;
	wire[31:0]					alu_res;
	
	//to MEM
	wire[31:0]					PC_plus_8;
	wire[1:0]					sel_which_byte;
	
	//to BY
	wire[31:0]					RegFile_w_data_fromEXE;
	
	//////////////////////////////////////////////////////////////////////
	//流水线控制
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
	
	
	///////////////////////////////////////////////////////////////////
	//取出数据
	always@(posedge clk)
	begin
		if(EXE_allow_in & ID_to_EXE_valid)
			ID_to_EXE_reg<=ID_to_EXE_bus;
		else
			ID_to_EXE_reg<=ID_to_EXE_reg;
	end
	
	assign {	
				sel_dm_width			,//148
				sel_alu_src_1			,//147
				sel_alu_src_2			,//146
				sel_alu_op				,//145:142
				data_ram_w_en			,//141
				sel_rf_w_data			,//140:139
				sel_rf_w_en				,//138
				//sel_MEM_gene			,//138
				PC_plus_4				,//137:106
				RegFile_r_data1			,//105:74
				RegFile_r_data2			,//73:42
				inst_sa					,//41:37
				inst_offset_imm			,//36:5
				RegFile_target_w_addr	///4:0
				}
					=ID_to_EXE_reg;
	
	
	//////////////////////////////////////////////////////////////////////////
	//数据处理
	assign RegFile_w_data_fromEXE =	(sel_rf_w_data==2'b00)?alu_res:
										PC_plus_8;//PC+8,延迟槽的下一条
									//(sel_rf_w_data==2'b01)?PC_plus_8://PC+8,延迟槽的下一条
									//	32'b0;//例外情况,实际上是load或不写入
	assign sel_which_byte=data_ram_addr[1:0];
	
	assign data_ram_w_data_byte=	(sel_which_byte==2'b11)?{      RegFile_r_data2[ 7: 0],24'b0}:
									(sel_which_byte==2'b10)?{8'b0 ,RegFile_r_data2[ 7: 0],16'b0}:
									(sel_which_byte==2'b01)?{16'b0,RegFile_r_data2[ 7: 0],8'b0}:
									(sel_which_byte==2'b00)?{24'b0,RegFile_r_data2[ 7: 0]}:
										32'b0;
	//调用ALU
	assign alu_src_1=sel_alu_src_1?{27'b0,inst_sa}:RegFile_r_data1;//无符号扩展
	assign alu_src_2=sel_alu_src_2?inst_offset_imm:RegFile_r_data2;
	
	ALU alu(
		.alu_src1(alu_src_1),
		.alu_src2(alu_src_2),
		.alu_op(sel_alu_op),
		.alu_res(alu_res)
		);
	
	assign PC_plus_8=PC_plus_4+32'b100;
	
	assign	sel_MEM_gene=(sel_rf_w_data[1])&(~sel_rf_w_data[0]);//sel_rf_w_data==2'b10
	//////////////////////////////////////////////////////////////////////////////
	//输出
	
	//调用data_RAM
	assign data_ram_addr=alu_res;
	assign data_ram_w_data=(sel_dm_width)?data_ram_w_data_byte:
											RegFile_r_data2;
	assign data_ram_w_en_4bit=	(sel_dm_width & data_ram_w_en)?
										{
											  sel_which_byte[1] &  sel_which_byte[0]  ,
											  sel_which_byte[1] &(~sel_which_byte[0] ),
											(~sel_which_byte[1])&  sel_which_byte[0]  ,
											(~sel_which_byte[1])&(~sel_which_byte[0])
										}:
								{4{data_ram_w_en}};
	assign data_ram_en=1'b1;
	
	//数据传送
	assign EXE_to_MEM_bus={	
							sel_dm_width			,//75
							sel_rf_w_data			,//74:73
							sel_rf_w_en				,//72
							sel_MEM_gene			,//71
							sel_which_byte			,//70:69,决定LB/SB使用哪一个字节
							PC_plus_8				,//68:37
							RegFile_w_data_fromEXE	,//36:5
							RegFile_target_w_addr	 //4:0
							};
	
	//to ST
	assign EXE_to_ST_bus={	
							EXE_valid				,//6
							sel_MEM_gene			,//5
							RegFile_target_w_addr	 //4:0
							};
	//to BY
	assign EXE_to_BY_bus={
							sel_rf_w_en				,//38
							EXE_valid				,//37
							RegFile_target_w_addr	,//36:32
							RegFile_w_data_fromEXE	 //31:0
							};
	
	
endmodule
