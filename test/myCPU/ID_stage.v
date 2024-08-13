/**
 * @file ID_stage.v
 * @author ykykzq
 * @brief 流水线第三级，决定ALU的源操作数；内含一Branch Unit，用于判断分支预测成功与否
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include "myCPU.h"
module ID_stage(
	input								clk,
	input								reset,

	//流水线数据传输
    input  wire[`IPD_TO_ID_BUS_WD-1:0]	IPD_to_ID_bus,
	output wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus,

	output wire[`ID_TO_IF_BUS_WD-1:0]	ID_to_IF_bus,
    output wire[`ID_TO_IPD_BUS_WD-1:0]  ID_to_IPD_bus,

	input  wire[`WB_to_ID_bus_WD-1:0]	WB_to_ID_bus,

	//流水线控制
	input  wire							EXE_allow_in,
	input  wire							IPD_to_ID_valid,
	output wire							ID_allow_in,
	output wire							ID_to_EXE_valid
);
	// ALU控制信号与源操作数
	wire op_lui;   //Load Upper Immediate
	wire op_sra;   //arithmetic right shift
	wire op_srl;   //logic right shift
	wire op_sll;   //logic left shift
	wire op_xor;   //bitwise xor
	wire op_or;    //bitwise or
	wire op_nor;   //bitwise nor
	wire op_and;   //bitwise and
	wire op_sltu;  //unsigned compared and set less than
	wire op_slt;   //signed compared and set less than
	wire op_sub;   //sub operation
	wire op_add;   //add operation

	///////////////////////////////////////////////////////////
	/// 流水线行为控制

	// 认为一周期内必能完成decode
    assign ID_ready_go=1'b1;
	assign ID_allow_in=(~ID_valid)|(ID_ready_go & EXE_allow_in);
	assign ID_to_EXE_valid=ID_ready_go&ID_valid;
    always@(posedge clk)
    begin
        if(reset)
            ID_valid<=1'b0;
        else if(ID_allow_in)
            ID_valid<=IPD_to_ID_valid;
        else if(br_taken_cancel)
            // 分支预测失败，flush
            ID_valid<=1'b0;
        else 
            ID_valid<=ID_valid;
    end

	////////////////////////////////////////////////////////////
	/// 寄存器访问
	RegFile RF(
		.clk		(				clk),
		.r_addr1	(	RegFile_R_addr1),
		.r_addr2	(	RegFile_R_addr2),
		.r_data1	(	RegFile_R_data1),
		.r_data2	(	RegFile_R_data2),
		//写信号
		.w_data		(w_data),
		.w_addr		(w_addr),
		.w_en 		(w_en)
    );

	//////////////////////////////////////////////////////////
	/// ALU源操作数决定（立即数、寄存器值、旁路网络）

	// 计算类型
	assign op_lui  = (inst_lu12i_w);
	assign op_sra  = (inst_srai_w);
	assign op_srl  = (inst_srli_w);
	assign op_sll  = (inst_slli_w);
	assign op_xor  = (inst_xor);
	assign op_or   = (inst_or | inst_ori);
	assign op_nor  = (inst_nor);
	assign op_and  = (inst_and | inst_andi);
	assign op_sltu = (inst_sltu); 
	assign op_slt  = (inst_slt);
	assign op_sub  = (inst_sub_w);
	assign op_add  = (    inst_add_w | inst_add_w 
						| inst_jirl 
						| inst_st_w | inst_ld_w | inst_st_b | inst_ld_b 
						| inst_pcaddu12i);

	assign alu_op  = {
		op_lui	,
		op_sra	,
		op_srl	,
		op_sll	,
		op_xor	,
		op_or 	,
		op_nor	,
		op_and	,
		op_slt	,
		op_slt	,
		op_sub	,
		op_add	
	};

	/*
		// 决定源操作数 one-hot
		+--------------+-----------------+
		| sel_alu_src1 | alu_src1        |
		+--------------+-----------------+
		| 2            | RegFile_R_data1 |
		| 1            | inst_PC         |
		| 0            | 32'b0           |
		+--------------+-----------------+

	*/
	assign sel_alu_src1[1] =  inst_addi_w | inst_add_w | inst_sub_w | inst_mul_w
							| inst_or | inst_ori | inst_nor | inst_andi | inst_and | inst_xor 
							| inst_srli_w | inst_slli_w | inst_srai_w
							| inst_slt | inst_sltu
							| inst_jirl
							| inst_st_w | inst_ld_w | inst_st_b | inst_ld_b;
	assign sel_alu_src1[0] = inst_pcaddu12i;

    /*
		// 决定源操作数 one-hot
		+--------------+-----------------+
		| sel_alu_src2 | alu_src2        |
		+--------------+-----------------+
		| 2            | RegFile_R_data2 |
		| 1            | immediate       |
		| 0            | 32'b0		     |
		+--------------+-----------------+
	*/
	assign sel_alu_src2[1] =  inst_add_w | inst_sub_w | inst_mul_w
							| inst_or | inst_nor | inst_and | inst_xor
							| inst_slt | inst_sltu; 
	assign sel_alu_src2[0]=   inst_addi_w | inst_ori | inst_andi | inst_srli_w | inst_slli_w | inst_srai_w
							| inst_lu12i_w | inst_pcaddu12i | inst_jirl
							| inst_st_w | inst_ld_w | inst_st_b | inst_ld_b;

	assign alu_src1 = sel_alu_src1[1]?RegFile_R_data1:
						sel_alu_src1[0]?inst_PC:32'b0;
	assign alu_src2 = sel_alu_src2[1]?RegFile_R_data2:
						sel_alu_src2[0]?immediate:32'b0;

	///////////////////////////////////////////////////////////
	/// 数据RAM的相关控制信号生成

	// 写使能
	assign sel_data_ram_we=(inst_st_b | inst_st_w);
	// 写数据。当写有效时为数据，否则全0
	assign data_ram_wdata=data_sram_we?RegFile_R_data2:32'b0;

	// Data RAM使能信号
	assign sel_data_ram_en=(  inst_st_b | inst_st_w
							| inst_ld_b | inst_ld_w);

	// 字节使能
	/*
		+-----------------+-------------+
		| sel_data_ram_wd | 长度        |
		+-----------------+-------------+
		| 1               | byte(8bit)  |
		| 0               | word(32bit) |
		+-----------------+-------------+

	*/
	assign sel_data_ram_wd=(inst_st_b | inst_ld_b);

	///////////////////////////////////////////////////////////
	/// 生成WB阶段控制信号

	// 是否写回寄存器
	assign sel_rf_w_en =      inst_addi_w | inst_add_w | inst_sub_w | inst_mul_w
							| inst_or | inst_ori | inst_nor | inst_andi | inst_and | inst_xor
							| inst_srli_w | inst_slli_w | inst_srai_w | 
							| inst_lu12i_w | inst_pcaddu12i;

	/* 
		控制写入数据来源
		+---------------+----------+
		| sel_rf_w_data | 数据来源 |
		+---------------+----------+
		| 1             | RAM      |
		| 0             | ALU      |
		+---------------+----------+
	*/
	assign sel_rf_w_data = inst_ld_w | inst_ld_b;
	
	//////////////////////////////////////////////////////////
	/// 检验分支预测正确性

	assign BranchUnit_src1=(inst_jirl | inst_beq | inst_bne)?RegFile_R_data1:
							(inst_b | inst_bl)?immediate:32'b0;
	assign BranchUnit_src2=(inst_jirl)?immediate:
							(inst_beq | inst_bne)?RegFile_R_data2:
							(inst_b | inst_bl)?32'b0:32'b0;
	BranchUnit BU(
		.inst_type			(inst_type		),
    	.pred_PC			(pred_PC		),
    	// 用于计算PC的值
    	.src1				(BranchUnit_src1),
    	.src2				(BranchUnit_src2),
	
    	.next_PC			(PC_fromID		),
    	.br_taken_cancel	(br_taken_cancel)
	);

	//////////////////////////////////////////////////////////
	/// 流水级数据交互

	// 接收
	always@(posedge clk)
	begin
		if(IPD_to_ID_valid & ID_allow_in)
			IPD_to_ID_reg<=IPD_to_ID_bus;
		else
			IPD_to_ID_reg<=IPD_to_ID_reg;
	end
	assign{
            inst_type           ,// xx:111
            pred_PC             ,//110: 79
            inst_PC             ,// 78: 47
            immediate           ,// 46: 15
            RegFile_W_addr      ,// 14: 10
            RegFile_R_addr2     ,//  9:  5
            RegFile_R_addr1      //  4:  0
    } = IPD_to_ID_reg;


	assign {
		w_en	    ,//37
		w_data		,//36:5
		w_addr	 	 //4:0
	}=WB_to_ID_bus;

	// 发送
	assign ID_to_IF_bus={
			br_taken_cancel	,//32
			PC_fromID		 //31:0			
	};

	assign ID_to_IPD_bus = {
			br_taken_cancel	,//32
			PC_fromID		 //31:0			
	};

	assign ID_to_EXE_bus ={
		sel_rf_w_en		,
		sel_rf_w_data	,
		sel_data_ram_wd	,
		sel_data_ram_we	,
		sel_data_ram_en	,
		data_ram_wdata	,
		RegFile_W_addr	,
		alu_op			,
		alu_src2		,
		alu_src1		, 
		inst_PC			 //31:0
	};

	
endmodule
