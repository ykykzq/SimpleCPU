/**
 * @file EXE_stage.v
 * @author ykykzq
 * @brief 流水线第四级，完成ALU的计算
 * @version 0.1
 * @date 2024-08-13
 *
 */
`include "myCPU.h"
module EXE_stage(
	input  wire							clk,
	input  wire							reset,
	
	// 流水线数据传送
	input  wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus,
	output wire[`EXE_TO_MEM_BUS_WD-1:0]	EXE_to_MEM_bus,

	output wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus,
	
	// 流水线控制
	input  wire							MEM_allow_in,
	output wire							EXE_to_MEM_valid,
	input  wire							ID_to_EXE_valid,
	output wire							EXE_allow_in,
	
	// 连接Data RAM
	output wire							data_ram_en,
	output wire[31:0]					data_ram_addr,
	output wire[3:0]					data_ram_w_en,
	output wire[31:0]					data_ram_w_data
    );
	
	// 当前指令的PC
	wire [31: 0]	inst_PC;

	// 流水线控制
	wire EXE_ready_go;
	reg  EXE_valid;

	// ID/EXE REG
	reg [`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_reg;

	// ALU操作数与运算类型
	wire [11: 0]	alu_op;
	wire [31: 0]	alu_bu_src1;
	wire [31: 0]	alu_bu_src2;
	wire [31: 0]	alu_result;

	// Data RAM控制信号
	wire sel_data_ram_en;
	wire sel_data_ram_we;
	wire [ 1: 0]	sel_data_ram_wd;
	reg  [ 3: 0]	data_ram_b_en;
	wire [31: 0]	data_ram_wdata;

	// 旁路阶段所需控制信号
	wire [ 2: 0]    sel_rf_w_data_valid_stage;
	wire 			EXE_sel_rf_w_data_valid;

	// 写回（WB）阶段用到的控制信号
	wire [ 4: 0]	RegFile_w_addr;
	wire	sel_rf_w_data;
	wire 	sel_rf_w_en;


	////////////////////////////////////////////////////////
	/// 流水线控制

	// 目前的运算均能在一周期内完成
    assign EXE_ready_go=1'b1;
	assign EXE_allow_in=(~EXE_valid)|(EXE_ready_go & MEM_allow_in);
	assign EXE_to_MEM_valid=EXE_ready_go&EXE_valid;
    always@(posedge clk)
    begin
        if(reset)
            EXE_valid<=1'b0;
        else if(EXE_allow_in)
            EXE_valid<=ID_to_EXE_valid;
        else 
            EXE_valid<=EXE_valid;
    end

	/////////////////////////////////////////////////////
	/// 调用ALU

	alu ALU(
  		.alu_op			(alu_op 	),
  		.alu_src1		(alu_bu_src1),
  		.alu_src2		(alu_bu_src2),
  		.alu_result		(alu_result	)
	);


	/////////////////////////////////////////////////////
	/// 旁路信号生成

	assign EXE_sel_rf_w_data_valid = EXE_ready_go & EXE_valid & sel_rf_w_data_valid_stage[0];
	/////////////////////////////////////////////////////
	/// 生成Data RAM信号

	assign data_ram_en=sel_data_ram_en;
	assign data_ram_addr=alu_result;

	// 字节使能
	always@(*)
	begin
		if(sel_data_ram_wd)
			begin
				if(data_ram_addr[1:0]==2'b00)
					data_ram_b_en<=4'b0001;
				else if(data_ram_addr[1:0]==2'b01)
					data_ram_b_en<=4'b0010;
				else if(data_ram_addr[1:0]==2'b10)
					data_ram_b_en<=4'b0100;
				else if(data_ram_addr[1:0]==2'b11)
					data_ram_b_en<=4'b1000;
				else 
					data_ram_b_en<=4'b0000;//不会走到的分支
			end
		else 
			data_ram_b_en=4'b1111;// 若是写入一个word(32bit)
	end
	// 若是不读Data RAM，全0即可
	assign data_ram_w_en = sel_data_ram_we?data_ram_b_en:4'b0000;
	// 写回的数据
	assign data_ram_w_data = data_ram_wdata;

	///////////////////////////////////////////////////////
	/// 流水级数据交互

	// 接收
	always@(posedge clk)
	begin
		if(reset)
			ID_to_EXE_reg<=0;
		else if(ID_to_EXE_valid & EXE_allow_in)
			ID_to_EXE_reg<=ID_to_EXE_bus;
		else
			ID_to_EXE_reg<=ID_to_EXE_reg;
	end
	assign  {
		sel_rf_w_data_valid_stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//2
		sel_data_ram_we				,//1
		sel_data_ram_en				,//1
		data_ram_wdata				,//32
		RegFile_w_addr				,//5
		alu_op						,//12
		alu_bu_src2					,//32
		alu_bu_src1					,//32
		inst_PC						 //32
	}=ID_to_EXE_reg;
	
	// 发送
	assign EXE_to_MEM_bus = {
		sel_rf_w_data_valid_stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//2
		data_ram_b_en				,//4
		RegFile_w_addr				,//5
		alu_result					,//32
		inst_PC						 //32
	};

	assign EXE_to_BY_bus={
		RegFile_w_addr				,//5
		alu_result					,//32
		EXE_sel_rf_w_data_valid		,//1
		EXE_valid					,//1
		sel_rf_w_en					 //1
	};
	
endmodule
