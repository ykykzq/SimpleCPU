`include "myCPU.h"
module ID_stage(
	input								clk,
	input								reset,

	input  wire[`IF_TO_ID_BUS_WD-1:0]	IF_to_ID_bus,
	output wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus,
	
	//传回IF阶段
	output wire[`ID_TO_PC_BUS_WD-1:0]	ID_to_PC_bus,
	
	//用于WB阶段写回RF
	input  wire[`WB_TO_RF_BUS_WD-1:0]	WB_to_RF_bus,
	
	//Stall
	output wire[`ID_TO_ST_BUS_WD-1:0]	ID_to_ST_bus,
	input  wire/*WD==1*/				ST_to_ID_bus,
	
	//Bypassing
	output wire[`ID_TO_BY_BUS_WD-1:0]	ID_to_BY_bus,
	input  wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus,
	
	//流水线控制
	input  wire							EXE_allow_in,
	input  wire							IF_to_ID_valid,
	output wire							ID_allow_in,
	output wire							ID_to_EXE_valid
    );
	wire						ID_ready_go;
	reg							ID_valid;
	
	//用于处理以下情况：当IF阶段阻塞(IF_to_ID_valid==0)，而ID阶段为有效的跳转时，将会导致PC无法更新。
	//因此将ID阶段的有效性加以区分，加上一个标志sel_nextPC是否有效的信号
	reg 						ID_PC_valid;
	
	//寄存器堆
	wire[4:0]					RegFile_r_addr1;
	wire[4:0]					RegFile_r_addr2;
	wire[31:0]					RegFile_r_data1_fromRF;
	wire[31:0]					RegFile_r_data2_fromRF;
	wire[31:0]					RegFile_w_data;
	wire[4:0]					RegFile_w_addr;
	wire						RegFile_w_en;
	
	wire[4:0]					RegFile_target_w_addr;
	
	//传回IF(PC)的数据
	wire[31:0]					BNE_BEQ_BGEZ_BLEZ_PC;
	wire[31:0]					JAL_J_PC;
	wire[31:0]					JR_JALR_PC;
	wire[31:0]					PC_fromID;
	wire						sel_next_PC;
	
	//IF_ID寄存器
	reg[`IF_TO_ID_BUS_WD-1:0]	IF_to_ID_reg;
	wire						IF_allow_in;
	wire[31:0]					PC_plus_4;
	wire[31:0]					inst;
	wire[31:0]					RegFile_r_data1;
	wire[31:0]					RegFile_r_data2;
	
	//指令的各部
	wire[31:0]					inst_offset_imm;
	wire[25:0]					inst_inst_addr;
	wire[4:0]					inst_sa;
	wire[5:0]					inst_opcode;
	wire[5:0]					inst_func;
	
	//控制信号
	wire[1:0]					sel_rf_target_w_addr;//需要写入哪一个寄存器
	wire						sel_alu_src_1;
	wire						sel_alu_src_2;
	wire[3:0]					sel_alu_op;
	wire						data_ram_w_en;
	wire						data_ram_r_en;
	wire[1:0]					sel_rf_w_data;
	wire 						sel_rf_w_en;
	wire						sel_imm_sign;
	wire						sel_dm_width;
	
	//用于by与st的控制信号
	wire						sel_rf_r_addr1_en;
	wire						sel_rf_r_addr2_en;
	wire						sel_MEM_gene;
	
	wire						WB_valid;
	
	//来自by与st的数据
	//BY
	wire[31:0]					RegFile_r_data1_fromBY;
	wire[31:0]					RegFile_r_data2_fromBY;
	wire[1:0]					sel_RegFile_r_data;////01代表替代r_data1，10代表替代r_data2，00代表不旁路
	//ST
	
	
	//指令
	//如为对应操作，该信号为1，其他信号均为0
	wire						ADDU_inst;
	wire						ADDIU_inst;
	
	wire						ADD_inst;
	wire						ADDI_inst;
	wire						SUB_inst;
	wire						SLT_inst;
	wire						MUL_inst;
	wire						MULT_inst;	//////////////////////////
	wire						MULTU_inst;	//						//
	wire						MFHI_inst;	//						//
	wire						MFIO_inst;	//		不在34之内		//
	wire						MTHI_inst;	//						//
	wire						MTIO_inst;	//						//
	wire						SUBU_inst;	//////////////////////////
	wire						LW_inst;	
	wire						SW_inst;
	wire						LB_inst;
	wire						SB_inst;
	wire						BEQ_inst;
	wire						BNE_inst;
	wire						JAL_inst;
	wire						JR_inst;
	wire						J_inst;
	wire						JALR_inst;
	wire						BGEZ_inst;
	wire						BGTZ_inst;
	wire						BLEZ_inst;
	wire						BLTZ_inst;
	wire						SLTU_inst;
	wire						SLL_inst;
	wire						SRL_inst;
	wire						SRA_inst;
	wire						SLLV_inst;
	wire						SRAV_inst;
	wire						SRLV_inst;
	wire						LUI_inst;
	wire						AND_inst;
	wire						OR_inst;
	wire						XOR_inst;
	wire						NOR_inst;
	wire						XORI_inst;
	wire						ORI_inst;
	wire						ANDI_inst;
	
	//////////////////////////////////////////////////////////////////
	//流水线控制
	assign ID_ready_go=ST_to_ID_bus;
	assign ID_allow_in=(~ID_valid)|(ID_ready_go & EXE_allow_in);
	assign ID_to_EXE_valid=ID_ready_go&ID_valid;
	always@(posedge clk)
	begin	
		if(reset)
			ID_valid<=1'b0;
		else if(ID_allow_in)//采用判断ID_allow_in且IF_to_ID_valid是否可行呢？
			ID_valid<=IF_to_ID_valid;
		else
			ID_valid<=ID_valid;
	end
	
	always@(posedge clk)
	begin	
		if(reset)
			ID_PC_valid<=1'b0;
		else if(IF_to_ID_valid==1'b0)
			ID_PC_valid<=ID_PC_valid;
		else
			ID_PC_valid<=ID_valid;
	end
	/////////////////////////////////////////////////////////////////////
	//接收数据
	//BY
	assign {	
				sel_RegFile_r_data	 	,//65:64
				RegFile_r_data1_fromBY	,//63:32
				RegFile_r_data2_fromBY	 //31:0
				}=BY_to_ID_bus;
	//ST
	//仅影响流水线控制中的ready_go
	
	
	//stage间数据传送
	//IF_ID_reg
	always@(posedge clk)
	begin
		if(IF_to_ID_valid & ID_allow_in)
			IF_to_ID_reg<=IF_to_ID_bus;
		else
			IF_to_ID_reg<=IF_to_ID_reg;
	end
	
	
	assign	{	PC_plus_4	,
				inst		}	
								=IF_to_ID_reg;
	
	/////////////////////////////////////////////////////////////////
	//数据通路
	
	//指令
	assign	inst_offset_imm=sel_imm_sign?{{16{inst[15]}},inst[15:0]}:{16'b0,inst[15:0]};//16to32的有符号扩展
	assign	inst_inst_addr=inst[25:0];
	assign	inst_sa=inst[10:6];
	assign 	inst_opcode=inst[31:26];
	assign	inst_func=inst[5:0];

	//写入目标寄存器的地址
	assign RegFile_target_w_addr=sel_rf_target_w_addr[1]?5'b11111:
							(sel_rf_target_w_addr[0])?inst[15:11]:inst[20:16];//..?rd:rt
	
	//BNE_BEQ_BGEZ_BLEZ_PC
	assign BNE_BEQ_BGEZ_BLEZ_PC=PC_plus_4+{inst_offset_imm[29:0],2'b00};
	//JAL_J_PC
	assign JAL_J_PC={PC_plus_4[31:28],inst_inst_addr,2'b00};
	//JR_JALR_PC
	assign JR_JALR_PC=RegFile_r_data1;
	
	assign PC_fromID=	(JR_inst |JALR_inst)?JR_JALR_PC:
						(JAL_inst | J_inst)?JAL_J_PC:
						(
							( BEQ_inst & (RegFile_r_data1==RegFile_r_data2)) 
								| 
							( BNE_inst & (RegFile_r_data1!=RegFile_r_data2))
								|
							( BGEZ_inst& ( ~RegFile_r_data1[31]))
								|
							(BGTZ_inst & (RegFile_r_data1[31]==1'b0) & (RegFile_r_data1!=32'b0))
								|
							( BLEZ_inst& (RegFile_r_data1[31] | (RegFile_r_data1==32'b0) ))
								|
							( BLTZ_inst& (RegFile_r_data1[31]))
						)?BNE_BEQ_BGEZ_BLEZ_PC:
						32'b0;//不跳转的情况

	///////////////////////////////////////////////////////////////////////////////
	//正式译码，生成控制信号
	//后续考虑改为译码器＋独热码
	
	assign ADDU_inst =inst_opcode==6'b000000 & inst_func==6'b100001;
	assign ADDIU_inst=inst_opcode==6'b001001;
	assign SUBU_inst =inst_opcode==6'b000000 & inst_func==6'b100011;
	assign ADD_inst	 =inst_opcode==6'b000000 & inst_func==6'b100000;
	assign ADDI_inst =inst_opcode==6'b001000;
	assign SUB_inst  =inst_opcode==6'b000000 & inst_func==6'b100010;
	assign MUL_inst  =inst_opcode==6'b011100 & inst_func==6'b000010;
	assign MULT_inst =inst_opcode==6'b000000 & inst_func==6'b011000;	////////////////////////////不在34之内
	assign MULTU_inst=inst_opcode==6'b000000 & inst_func==6'b011001;	//						////
	assign MFHI_inst =inst_opcode==6'b000000 & inst_func==6'b010000;	//						////
	assign MFIO_inst =inst_opcode==6'b000000 & inst_func==6'b010010;	//		不在34之内		////
	assign MTHI_inst =inst_opcode==6'b000000 & inst_func==6'b010001;	//						////
	assign MTIO_inst =inst_opcode==6'b000000 & inst_func==6'b010011;	////////////////////////////
	assign LW_inst   =inst_opcode==6'b100011;
	assign SW_inst   =inst_opcode==6'b101011;
	assign LB_inst	 =inst_opcode==6'b100000;
	assign SB_inst	 =inst_opcode==6'b101000;
	assign BEQ_inst  =inst_opcode==6'b000100;
	assign BNE_inst  =inst_opcode==6'b000101;
	assign JAL_inst  =inst_opcode==6'b000011;
	assign JR_inst   =inst_opcode==6'b000000 & inst_func==6'b001000;
	assign J_inst	 =inst_opcode==6'b000010;
	assign JALR_inst =inst_opcode==6'b000000 & inst_func==6'b001001;
	assign BGEZ_inst =inst_opcode==6'b000001 & inst[20:16]==5'b00001;
	assign BGTZ_inst =inst_opcode==6'b000111 & inst[20:16]==5'b00000;
	assign BLEZ_inst =inst_opcode==6'b000110;
	assign BLTZ_inst =inst_opcode==6'b000001 & inst[20:16]==5'b00000;
	assign SLT_inst  =inst_opcode==6'b000000 & inst_func==6'b101010;
	assign SLTU_inst =inst_opcode==6'b000000 & inst_func==6'b101011;
	assign SLL_inst  =inst_opcode==6'b000000 & inst_func==6'b000000;
	assign SRL_inst  =inst_opcode==6'b000000 & inst_func==6'b000010;
	assign SRA_inst  =inst_opcode==6'b000000 & inst_func==6'b000011;
	assign SLLV_inst =inst_opcode==6'b000000 & inst_func==6'b000100;
	assign SRAV_inst =inst_opcode==6'b000000 & inst_func==6'b000111;
	assign SRLV_inst =inst_opcode==6'b000000 & inst_func==6'b000110;
	assign LUI_inst  =inst_opcode==6'b001111;
	assign AND_inst  =inst_opcode==6'b000000 & inst_func==6'b100100;
	assign OR_inst   =inst_opcode==6'b000000 & inst_func==6'b100101;
	assign XOR_inst  =inst_opcode==6'b000000 & inst_func==6'b100110;
	assign NOR_inst  =inst_opcode==6'b000000 & inst_func==6'b100111;
	assign XORI_inst =inst_opcode==6'b001110;
	assign ORI_inst	 =inst_opcode==6'b001101;
	assign ANDI_inst =inst_opcode==6'b001100;
	//////////////////
	//生成信号
	assign sel_next_PC=	(ID_PC_valid | ID_valid)&		//当ID无效时，其为0，这是为了第一次还未取指时的PC正确计算
						(
							JR_inst 
								| 
							JAL_inst 
								|
							JALR_inst
								|
							J_inst
								|
							(BEQ_inst & (RegFile_r_data1==RegFile_r_data2)) 
								| 
							(BNE_inst & (RegFile_r_data1!=RegFile_r_data2))
								|
							(BGEZ_inst& ( ~RegFile_r_data1[31]) )
								|
							(BGTZ_inst & (RegFile_r_data1[31]==1'b0) & (RegFile_r_data1!=32'b0))
								|
							(BLEZ_inst& (RegFile_r_data1[31] | (RegFile_r_data1==32'b0) ))
								|
							(BLTZ_inst& (RegFile_r_data1[31]))
						);
					
	
	assign sel_rf_target_w_addr=JAL_inst?2'b10:
								(ADDU_inst | SUBU_inst | ADD_inst | SUB_inst | MUL_inst | SLT_inst | SLTU_inst | SLL_inst | SRL_inst | SRA_inst | SLLV_inst | SRAV_inst | SRLV_inst | AND_inst | OR_inst | XOR_inst | NOR_inst | JALR_inst)?2'b01:
								2'b00;
	assign sel_alu_src_1=SLL_inst | SRL_inst | SRA_inst;
	assign sel_alu_src_2=ADDI_inst | ADDIU_inst | LW_inst | SW_inst | LB_inst | SB_inst | LUI_inst | ORI_inst | XORI_inst | ANDI_inst;
	assign sel_alu_op=	(ADD_inst | ADDU_inst | ADDIU_inst | LW_inst | SW_inst | LB_inst | SB_inst | JAL_inst | ADDI_inst)?4'b0000:
						(SUBU_inst | SUB_inst)?4'b0001:
						SLT_inst?4'b0010:
						SLTU_inst?4'b0011:
						(AND_inst  | ANDI_inst)?4'b0100:
						NOR_inst?4'b0101:
						(OR_inst | ORI_inst)?4'b0110:
						(XOR_inst | XORI_inst)?4'b0111:
						(SLL_inst | SLLV_inst)?4'b1000:
						(SRL_inst | SRLV_inst)?4'b1001:
						(SRA_inst | SRAV_inst)?4'b1010:
						LUI_inst?4'b1011:
						MUL_inst?4'b1100:
								4'b1111;
								
	assign data_ram_r_en=LW_inst | LB_inst;
	assign data_ram_w_en=SW_inst | SB_inst;
	assign sel_rf_w_data=	//(MUL_inst)?2'b11:
							(LW_inst | LB_inst)?2'b10:
							(JAL_inst | JALR_inst)?2'b01:
							(SW_inst | SB_inst | BEQ_inst | BNE_inst | JR_inst)?2'b11:
							2'b00;
	assign sel_rf_w_en = ~(SW_inst | SB_inst | BEQ_inst | BNE_inst | BGEZ_inst | BGTZ_inst | BLEZ_inst | BLTZ_inst | JR_inst | J_inst);
	assign sel_imm_sign=(ADDIU_inst | ADDI_inst | LW_inst | SW_inst | LB_inst | SB_inst | BEQ_inst | BNE_inst | BGEZ_inst | BGTZ_inst | BLEZ_inst | BLTZ_inst);
	assign sel_dm_width=LB_inst |SB_inst;
	
	//st与by
	assign sel_rf_r_addr1_en=~(JAL_inst | J_inst | SLL_inst | SRL_inst | SRA_inst | LUI_inst);
	assign sel_rf_r_addr2_en=~(ADDIU_inst | ADDI_inst | LW_inst |/* SW_inst |*/ LB_inst | /*SB_inst |*/ JAL_inst | J_inst | JR_inst | BGEZ_inst | BGTZ_inst | BLEZ_inst | BLTZ_inst | JALR_inst | LUI_inst | ORI_inst | ANDI_inst);
	
	assign sel_MEM_gene=/*MUL_inst | */LB_inst | LW_inst;
	//////////////////
	//寄存器堆相关
	//写,wb
	assign {		
			WB_valid		,//38
			RegFile_w_en	,//37
			RegFile_w_data	,//36:5
			RegFile_w_addr	 //4:0
				}=WB_to_RF_bus;
	//读
	assign RegFile_r_addr1=inst[25:21];//rs
	assign RegFile_r_addr2=inst[20:16];//rt
	
	reg_file RegFile(
		.clk(clk),
		.r_addr1(RegFile_r_addr1),
		.r_addr2(RegFile_r_addr2),
		.r_data1(RegFile_r_data1_fromRF),
		.r_data2(RegFile_r_data2_fromRF),
		.w_data(RegFile_w_data),
		.w_addr(RegFile_w_addr),
		.w_en(RegFile_w_en)
	);
	//旁路
	assign	RegFile_r_data1=(sel_RegFile_r_data[0])?RegFile_r_data1_fromBY:
							(
								(RegFile_w_addr==RegFile_r_addr1) & RegFile_w_en & WB_valid//相当于WB旁路
							)?RegFile_w_data:
								RegFile_r_data1_fromRF;//01
								
	assign	RegFile_r_data2=(sel_RegFile_r_data[1])?RegFile_r_data2_fromBY:
							(
								(RegFile_w_addr==RegFile_r_addr2) & RegFile_w_en & WB_valid//相当于WB旁路
							)?RegFile_w_data:
								RegFile_r_data2_fromRF;//10
	//////////////////////////////////////////////////////////////////////////
	
	//发给IF的数据
	//sel_next_PC,BNE_BEQ_BGEZ_BLEZ_PC,JAL_J_PC,JR_JALR_PC均在前面
	//合并
	assign ID_to_PC_bus={
							PC_fromID		,//32:1
							sel_next_PC		 //0
							};
							
	
	//发给EXE的数据
	assign ID_to_EXE_bus={	
							sel_MEM_gene			,//150
							sel_dm_width			,//149
							sel_alu_src_1			,//148
							sel_alu_src_2			,//147
							sel_alu_op				,//146:143
							data_ram_r_en			,//142
							data_ram_w_en			,//141
							sel_rf_w_data			,//140:139
							sel_rf_w_en				,//138
							PC_plus_4				,//137:106
							RegFile_r_data1			,//105:74
							RegFile_r_data2			,//73:42
							inst_sa					,//41:37
							inst_offset_imm			,//36:5
							RegFile_target_w_addr	 //4:0
							};
	
	//发给BY的数据
	assign ID_to_BY_bus={
							RegFile_r_addr1		,//9:5
							RegFile_r_addr2      //4:0
							};
	
	//发给ST的数据
	assign ID_to_ST_bus={	
							sel_rf_r_addr1_en   ,//11
							sel_rf_r_addr2_en   ,//10
							RegFile_r_addr1		,//9:5
							RegFile_r_addr2      //4:0
							};
	
endmodule