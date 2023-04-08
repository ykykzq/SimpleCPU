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
	wire[31:0]					RegFile_r_data1;
	wire[31:0]					RegFile_r_data2;
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
	
	
	
	/////////////////////////////////////////////////////////////////
	//数据通路
	
	assign	{PC_plus_4,inst}=IF_to_ID_reg;
	
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
	//合并
	assign ID_to_PC_bus={
							Bne_Beq_PC	,//97:66
							Jal_PC		,//65:34
							Jr_PC		,//33:2
							sel_next_PC	 //1:0
							};
	
	//寄存器堆相关
	//写,wb
	assign {
			RegFile_w_data,
			RegFile_w_addr,
			RegFile_w_en
				}=WB_to_RF_bus;
	//读
	assign RegFile_r_addr1=inst[25:21];//rs
	assign RegFile_r_addr2=inst[20:16];//rt
	
	reg_file RegFile(
		.clk(clk),
		.r_addr1(RegFile_r_addr1),
		.r_addr2(RegFile_r_addr2),
		.r_data1(RegFile_r_data1),
		.r_data2(RegFile_r_data2),
		.w_data(RegFile_w_data),
		.w_addr(RegFile_w_addr),
		.w_en(RegFile_w_en)
	);
	
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
	assign data_ram_w_en=Lw_inst;
	assign sel_rf_w_data=Lw_inst?2'b10:
						Jal_inst?2'b01:
						(Sw_inst | Beq_inst | Bne_inst | Jr_inst)?2'b11:
						2'b00;
	assign sel_rf_w_en = ~(Sw_inst | Beq_inst | Bne_inst | Jr_inst);
	
	
	//////////////////////////////////////////////////////////////////////////
	//Stage间交互及流水线控制
	
	//IF_ID_reg
	always@(posedge clk)
	begin
		if(IF_to_ID_valid & ID_allow_in)
			IF_to_ID_reg<=IF_to_ID_bus;
		else
			IF_to_ID_reg<=IF_to_ID_reg;
	end
	
	//流水线控制
	assign ID_ready_go=1'b1;
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
	
	//发给IF的数据
	//sel_next_PC,Bne_Beq_PC,Jal_PC,Jr_PC均在前面
	
	
	//发给EXE的数据
	assign ID_to_EXE_bus={	PC_plus_4				,//147:116
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
							};
					
endmodule
