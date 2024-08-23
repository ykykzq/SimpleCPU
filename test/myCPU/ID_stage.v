/**
 * @file ID_stage.v
 * @author ykykzq
 * @brief 流水线第三级，内含唤醒模块，决定是否阻塞，并获取ALU的源操作数；内含一Branch Unit，用于判断分支预测结果正确性
 * @version 0.2
 * @date 2024-08-20
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

	input  wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus,

	//流水线控制
	input  wire							EXE_allow_in,
	input  wire							IPD_to_ID_valid,
	output wire							ID_allow_in,
	output wire							ID_to_EXE_valid
);
	// 当前指令的PC
	wire [31: 0]	inst_PC;
	
	// 流水线控制信号
	wire ID_ready_go;
	reg  ID_valid;

	// IPD/ID REG
	reg [`IPD_TO_ID_BUS_WD-1:0]	IPD_to_ID_reg;

	// 寄存器访问相关
	wire [ 4: 0]	RegFile_R_addr2;
	wire [ 4: 0]	RegFile_R_addr1;
	wire 			w_en;
	wire [31: 0]	w_data;
	wire [ 4: 0]	w_addr;
	wire [31: 0]	RegFile_R_data1;
	wire [31: 0]	RegFile_R_data2;

	wire [ 4: 0]	RegFile_W_addr;//注意此值代表当前流水级（ID）正在处理的指令的目的寄存器，不代表这拍要写入(WB)的寄存器
	
	// 立即数
	wire [31: 0]	immediate;

	// ALU控制信号与源操作数
	wire [ 1: 0]	sel_alu_src1;
	wire [ 2: 0]	sel_alu_src2;
	reg  [31: 0]	alu_src1;
	reg  [31: 0]	alu_src2;
	wire [11: 0]	alu_op;

	// 数据RAM的相关控制信号
	wire		sel_data_ram_en;
	wire 		sel_data_ram_we;
	wire 		sel_data_ram_wd;
	wire [31:0]	data_ram_wdata;

	// WB阶段的控制信号
	wire 		sel_rf_w_en;
	wire		sel_rf_w_data;

	// 分支处理单元（BU）的控制信号
	wire [`INST_TYPE_WD-1: 0]	inst_type;
	wire [31: 0]	BranchUnit_src1;
	wire [31: 0] 	BranchUnit_src2;
	wire [31: 0] 	pred_PC;
	wire [31: 0]	PC_fromID;
	wire 	br_taken_cancel;

	// 唤醒（阻塞）模块的控制信号
	wire [`BY_TO_WK_BUS_WD-1:0]	BY_to_WK_bus	;
	wire [ 2: 0]				sel_RF_W_Data_Valid_Stage;
	wire 						alu_src_1_ready	;
	wire 						alu_src_2_ready	;

	// 指令类型
	//加减
    wire                        inst_addi_w     ;
    wire                        inst_add_w      ;
    wire                        inst_sub_w      ;
    wire                        inst_or         ;
    wire                        inst_ori        ;
    wire                        inst_nor        ;
    wire                        inst_andi       ;
    wire                        inst_and        ;
    wire                        inst_xor        ;
    wire                        inst_srli_w     ;
    wire                        inst_slli_w     ;
    wire                        inst_srai_w     ;
    wire                        inst_lu12i_w    ;
    wire                        inst_pcaddu12i  ;
    wire                        inst_slt        ;
    wire                        inst_sltu       ;
    // 乘除
    wire                        inst_mul_w      ;
    // 跳转   
    wire                        inst_jirl       ;
    wire                        inst_b          ;
    wire                        inst_beq        ;
    wire                        inst_bne        ;
    wire                        inst_bl         ;
    // 访存
    wire                        inst_st_w       ;
    wire                        inst_ld_w       ;
    wire                        inst_st_b       ;
    wire                        inst_ld_b       ;

	///////////////////////////////////////////////////////////
	/// 流水线行为控制

	// 两个操作数都准备好之后可以发射
    assign ID_ready_go=alu_src_1_ready&&alu_src_2_ready;
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
		//写信号，注意该信号来自当前时刻的WB阶段
		.w_data		(w_data	),
		.w_addr		(w_addr	),
		.w_en 		(w_en	)
    );

	//////////////////////////////////////////////////////////
	/// wakeUP模块

	assign BY_to_WK_bus={
		// EXE阶段信号
		EXE_RegFile_W_addr			,
		EXE_sel_RF_W_Data_valid		,
		EXE_sel_rf_w_en				,
		// MEM阶段信号
		MEM_RegFile_W_addr			,
		MEM_sel_RF_W_Data_valid		,
		MEM_sel_rf_w_en				,
		// WB阶段信号		
		WB_RegFile_W_addr			,
		WB_sel_RF_W_Data_valid		,
		WB_sel_rf_w_en		
	};

	WakeUP Wake_UP(
	// 源操作数的控制信号与读取的寄存器号
		.sel_alu_src1			(sel_alu_src1	),
		.sel_alu_src2			(sel_alu_src2	),
		.RegFile_R_addr1		(RegFile_R_addr1),
		.RegFile_R_addr2		(RegFile_R_addr2),

		// 流水线数据交互
		.BY_to_WK_bus			(BY_to_WK_bus	),

		// 输出源操作数可以获得信号
		.src_1_ready			(alu_src_1_ready),
		.src_2_ready			(alu_src_2_ready)
	);
	
	//////////////////////////////////////////////////////////
	/// 检验分支预测正确性

	assign {
            //加减
            inst_addi_w     ,
            inst_add_w      ,
            inst_sub_w      ,
            inst_or         ,
            inst_ori        ,
            inst_nor        ,
            inst_andi       ,
            inst_and        ,
            inst_xor        ,
            inst_srli_w     ,
            inst_slli_w     ,
            inst_srai_w     ,
            inst_lu12i_w    ,
            inst_pcaddu12i  ,
            inst_slt        ,
            inst_sltu       ,
            // 乘除
            inst_mul_w      ,
            // 跳转   
            inst_jirl       ,
            inst_b          ,
            inst_beq        ,
            inst_bne        ,
            inst_bl         ,
            // 访存
            inst_st_w       ,
            inst_ld_w       ,
            inst_st_b       ,
            inst_ld_b       
    }=inst_type;

	assign BranchUnit_src1=(inst_jirl | inst_beq | inst_bne)?RegFile_R_data1:
							(inst_b | inst_bl)?immediate:32'b0;
	assign BranchUnit_src2=(inst_jirl)?immediate:
							(inst_beq | inst_bne)?RegFile_R_data2:
							(inst_b | inst_bl)?inst_PC:32'b0;
	BranchUnit BU(
		.reset				(reset			),
		.inst_type			(inst_type		),
    	.pred_PC			(pred_PC		),
    	// 用于计算PC的值
    	.src1				(BranchUnit_src1),
    	.src2				(BranchUnit_src2),
	
    	.next_PC			(PC_fromID		),
    	.br_taken_cancel	(br_taken_cancel)
	);

	////////////////////////////////////////////////////////////
	/// 决定源操作数

	// src_1，当来自于寄存器时，应该从旁路或者寄存器堆得到；否则是当前指令的PC
	always@(*)
	begin
		if(sel_alu_src1[1])
			if(RegFile_R_addr1==EXE_RegFile_W_addr && EXE_sel_rf_w_en)
				if(EXE_sel_RF_W_Data_valid)
					// 可以从EXE阶段旁路该值
					alu_src1<=EXE_RegFile_W_data;
				else 
					// 代表阻塞
					alu_src1<=32'b0;
			else if(RegFile_R_addr1==MEM_RegFile_W_addr && MEM_sel_rf_w_en)
				if(MEM_sel_RF_W_Data_valid)
					alu_src1<=MEM_RegFile_W_data;
				else
					alu_src1<=32'b0;
			else if(RegFile_R_addr1==WB_RegFile_W_addr && WB_sel_rf_w_en)
				if(WB_sel_rf_w_en)
					alu_src1<=WB_RegFile_W_data;
				else
					alu_src1<=32'b0;
			else 
				// 如果后续阶段均不写入该寄存器，则从寄存器堆获得操作数，一定可以准备好
				alu_src1<=RegFile_R_data1;
		else if(sel_alu_src1[0])
			// 如果操作数不来自于寄存器堆而是来自于指令PC，一定已经准备好
			alu_src1<=inst_PC;
		else
			alu_src1<=32'b0;
	end

	// src_2，当来自于寄存器时，应该从旁路或者寄存器堆得到；否则是立即数
	always@(*)
	begin
		if(sel_alu_src2[1])
			if(RegFile_R_addr2==EXE_RegFile_W_addr && EXE_sel_rf_w_en)
				if(EXE_sel_RF_W_Data_valid)
					// 可以从EXE阶段旁路该值
					alu_src2<=EXE_RegFile_W_data;
				else 
					// 代表阻塞
					alu_src2<=32'b0;
			else if(RegFile_R_addr2==MEM_RegFile_W_addr && MEM_sel_rf_w_en)
				if(MEM_sel_RF_W_Data_valid)
					alu_src2<=MEM_RegFile_W_data;
				else
					alu_src2<=32'b0;
			else if(RegFile_R_addr2==WB_RegFile_W_addr && WB_sel_rf_w_en)
				if(WB_sel_rf_w_en)
					alu_src2<=WB_RegFile_W_data;
				else
					alu_src2<=32'b0;
			else 
				// 如果后续阶段均不写入该寄存器，则从寄存器堆获得操作数，一定可以准备好
				alu_src2<=RegFile_R_data2;
		else if(sel_alu_src2[2])
			// 特殊情况，BL指令计算PC+4
			alu_src2<=32'h0000_0004;
		else if(sel_alu_src2[0])
			// 如果操作数不来自于寄存器堆而是来自立即数，一定已经准备好
			alu_src2<=immediate;
		else
			alu_src2<=32'b0;
	end

	////////////////////////////////////////////////////////
	/// 决定Data RAM写回数据

	// 写数据。当写有效时为数据，否则全0
	assign data_ram_wdata=sel_data_ram_we?RegFile_R_data2:32'b0;
	
	//////////////////////////////////////////////////////////
	/// 流水级数据交互

	// 接收
	always@(posedge clk)
	begin
		if(reset)
			IPD_to_ID_reg<=0;
		else if(br_taken_cancel)
			//预测错误，flush掉
			IPD_to_ID_reg<=0;
		else if(IPD_to_ID_valid & ID_allow_in)
			IPD_to_ID_reg<=IPD_to_ID_bus;
		else
			IPD_to_ID_reg<=IPD_to_ID_reg;
	end
	assign {
			sel_RF_W_Data_Valid_Stage   ,//3
            sel_alu_src2                ,//2
            sel_alu_src1                ,//2
            sel_rf_w_en		            ,//1
		    sel_rf_w_data	            ,//1
		    sel_data_ram_wd	            ,//1
		    sel_data_ram_we	            ,//1
		    sel_data_ram_en	            ,//1
            inst_type                   ,//26
		    alu_op			            ,//12
            pred_PC                     ,//32
            inst_PC                     ,//32
            immediate                   ,//32
            RegFile_W_addr              ,//5
            RegFile_R_addr2             ,//5
            RegFile_R_addr1              //5
    } = IPD_to_ID_reg;

	// Bypassing旁路信号
	assign {
		// EXE阶段信号
		EXE_RegFile_W_addr			,//5
		EXE_RegFile_W_data			,//32
		EXE_sel_RF_W_Data_valid		,//1
		EXE_sel_rf_w_en				,//1
		// MEM阶段信号
		MEM_RegFile_W_addr			,//5
		MEM_RegFile_W_data			,//32
		MEM_sel_RF_W_Data_valid		,//1
		MEM_sel_rf_w_en				,//1
		// WB阶段信号		
		WB_RegFile_W_addr			,//5
		WB_RegFile_W_data			,//32
		WB_sel_RF_W_Data_valid		,//1
		WB_sel_rf_w_en				 //1
	}=BY_to_ID_bus;

	assign {
		w_en	    ,//37
		w_data		,//36:5
		w_addr	 	 //4:0
	}=WB_to_ID_bus;

	// 发送
	assign ID_to_IF_bus={
			br_taken_cancel	,//1
			PC_fromID		 //32		
	};

	assign ID_to_IPD_bus = {
			br_taken_cancel	,//1
			PC_fromID		 //32		
	};

	assign ID_to_EXE_bus ={
		sel_RF_W_Data_Valid_Stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//1
		sel_data_ram_we				,//1
		sel_data_ram_en				,//1
		data_ram_wdata				,//32
		RegFile_W_addr				,//5
		alu_op						,//12
		alu_src2					,//32
		alu_src1					,//32
		inst_PC						 //32
	};

	
endmodule
