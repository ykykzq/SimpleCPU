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
	wire[31:0]					Bne_Beq_PC;
	wire[31:0]					Jal_PC;
	wire[31:0]					Jr_PC;
	wire[1:0]					sel_next_PC;
	
	//IF_ID寄存器
	reg[`IF_TO_ID_BUS_WD-1:0]	IF_to_ID_reg;
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
	wire[1:0]					sel_rf_w_data;
	wire 						sel_rf_w_en;
	
	//用于by与st的控制信号
	wire						sel_rf_r_addr1_en;
	wire						sel_rf_r_addr2_en;
	//wire						sel_MEM_gene;
	
	wire						WB_valid;
	
	//来自by与st的数据
	//BY
	wire[31:0]					RegFile_r_data1_fromBY;
	wire[31:0]					RegFile_r_data2_fromBY;
	wire[1:0]					sel_RegFile_r_data;////01代表替代r_data1，10代表替代r_data2，00代表不旁路
	//ST
	
	
	//指令
	//如为对应操作，该信号为1，其他信号均为0
	wire						Addu_inst;
	wire						Addiu_inst;
	wire						Subu_inst;
	wire						Lw_inst;
	wire						Sw_inst;
	wire						Beq_inst;
	wire						Bne_inst;
	wire						Jal_inst;
	wire						Jr_inst;
	wire						Slt_inst;
	wire						Sltu_inst;
	wire						Sll_inst;
	wire						Srl_inst;
	wire						Sra_inst;
	wire						Lui_inst;
	wire						And_inst;
	wire						Or_inst;
	wire						Xor_inst;
	wire						Nor_inst;
	
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
	assign	inst_offset_imm={{16{inst[15]}},inst[15:0]};//16to32的有符号扩展
	assign	inst_inst_addr=inst[25:0];
	assign	inst_sa=inst[10:6];
	assign 	inst_opcode=inst[31:26];
	assign	inst_func=inst[5:0];

	//写入目标寄存器的地址
	assign RegFile_target_w_addr=sel_rf_target_w_addr[1]?5'b11111:
							(sel_rf_target_w_addr[0])?inst[15:11]:inst[20:16];//..?rd:rt
	
	//Bne_Beq_PC
	assign Bne_Beq_PC=PC_plus_4+{inst_offset_imm[29:0],2'b00};
	//Jal_PC
	assign Jal_PC={PC_plus_4[31:28],inst_inst_addr,2'b00};
	//Jr_PC
	assign Jr_PC=RegFile_r_data1;
	

	///////////////////////////////////////////////////////////////////////////////
	//正式译码，生成控制信号
	//后续考虑改为译码器＋独热码
	
	assign Addu_inst =inst_opcode==6'b000000 & inst_func==6'b100001;
	assign Addiu_inst=inst_opcode==6'b001001;
	assign Subu_inst =inst_opcode==6'b000000 & inst_func==6'b100011;
	assign Lw_inst   =inst_opcode==6'b100011;
	assign Sw_inst   =inst_opcode==6'b101011;
	assign Beq_inst  =inst_opcode==6'b000100;
	assign Bne_inst  =inst_opcode==6'b000101;
	assign Jal_inst  =inst_opcode==6'b000011;
	assign Jr_inst   =inst_opcode==6'b000000 & inst_func==6'b001000;
	assign Slt_inst  =inst_opcode==6'b000000 & inst_func==6'b101010;
	assign Sltu_inst =inst_opcode==6'b000000 & inst_func==6'b101011;
	assign Sll_inst  =inst_opcode==6'b000000 & inst_func==6'b000000;
	assign Srl_inst  =inst_opcode==6'b000000 & inst_func==6'b000010;
	assign Sra_inst  =inst_opcode==6'b000000 & inst_func==6'b000011;
	assign Lui_inst  =inst_opcode==6'b001111;
	assign And_inst  =inst_opcode==6'b000000 & inst_func==6'b100100;
	assign Or_inst   =inst_opcode==6'b000000 & inst_func==6'b100101;
	assign Xor_inst  =inst_opcode==6'b000000 & inst_func==6'b100110;
	assign Nor_inst  =inst_opcode==6'b000000 & inst_func==6'b100111;
	//////////////////
	//生成信号
	assign sel_next_PC=(~ID_valid)?2'b00://当ID无效时，其为0，这是为了第一次还未取指时的PC正确计算
						Jr_inst?2'b11:
						Jal_inst?2'b10:
						(Beq_inst & (RegFile_r_data1==RegFile_r_data2)) | ((Bne_inst) & (RegFile_r_data1!=RegFile_r_data2))?2'b01:
						2'b00;
	
	assign sel_rf_target_w_addr=Jal_inst?2'b10:
								(Addu_inst | Subu_inst | Slt_inst | Sltu_inst | Sll_inst | Srl_inst | Sra_inst | And_inst | Or_inst | Xor_inst | Nor_inst)?2'b01:
								2'b00;
	assign sel_alu_src_1=~(Sll_inst | Srl_inst | Sra_inst);
	assign sel_alu_src_2=Addiu_inst | Lw_inst | Sw_inst | Lui_inst;
	assign sel_alu_op=(Addu_inst | Addiu_inst | Lw_inst | Sw_inst | Jal_inst)?4'b0000:
						Subu_inst?4'b0001:
						Slt_inst?4'b0010:
						Sltu_inst?4'b0011:
						And_inst?4'b0100:
						Nor_inst?4'b0101:
						Or_inst?4'b0110:
						Xor_inst?4'b0111:
						Sll_inst?4'b1000:
						Srl_inst?4'b1001:
						Sra_inst?4'b1010:
						Lui_inst?4'b1011:
								4'b1111;
	assign data_ram_w_en=Sw_inst;
	assign sel_rf_w_data=Lw_inst?2'b10:
						Jal_inst?2'b01:
						(Sw_inst | Beq_inst | Bne_inst | Jr_inst)?2'b11:
						2'b00;
	assign sel_rf_w_en = ~(Sw_inst | Beq_inst | Bne_inst | Jr_inst);
	
	//st与by
	assign sel_rf_r_addr1_en=(Jal_inst | Sll_inst | Srl_inst | Sra_inst | Lui_inst)?1'b0:1'b1;
	assign sel_rf_r_addr2_en=(Addiu_inst | Lw_inst | Sw_inst | Jal_inst | Jr_inst | Lui_inst)?1'b0:1'b1;
	//assign sel_MEM_gene=Lw_inst;
	
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
	//sel_next_PC,Bne_Beq_PC,Jal_PC,Jr_PC均在前面
	//合并
	assign ID_to_PC_bus={
							Bne_Beq_PC	,//97:66
							Jal_PC		,//65:34
							Jr_PC		,//33:2
							sel_next_PC	 //1:0
							};
							
	
	//发给EXE的数据
	assign ID_to_EXE_bus={	
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
							RegFile_target_w_addr	 //4:0
							};
	
	//发给BY的数据
	assign ID_to_BY_bus={
							sel_rf_r_addr1_en   ,//11
							sel_rf_r_addr2_en   ,//10
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
