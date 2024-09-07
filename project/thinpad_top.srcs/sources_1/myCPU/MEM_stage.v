/**
 * @file MEM_stage.v
 * @author ykykzq
 * @brief 流水线第六级，完成访存行为
 * @version 0.1
 * @date 2024-08-13
 *
 */
`include "myCPU.h"
module MEM_stage(
    input  wire 						clk,
	input  wire							reset,
	
	// 流水级数据交互
	input  wire[`PMEM_TO_MEM_BUS_WD-1:0]PMEM_to_MEM_bus,
	output wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,

	output wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus,
	
	//流水线控制
	input  wire							PMEM_to_MEM_valid,
	output wire							MEM_allow_in,
	input  wire							WB_allow_in,
	output wire							MEM_to_WB_valid
    );
    // 当前指令的PC
	wire [31: 0]	inst_PC;

    // 流水线控制
	wire MEM_ready_go;
	reg  MEM_valid;

    // PMEM/MEM REG
    reg [`PMEM_TO_MEM_BUS_WD-1:0]    PMEM_to_MEM_reg;

	// 旁路所需控制信号
	wire [ 2: 0]    sel_rf_w_data_valid_stage;
	wire 			MEM_sel_rf_w_data_valid;
	
    // 写回阶段的数据与控制信号
	wire [31: 0]	data_ram_r_data;
    wire [31: 0]    alu_result;
    wire [ 4: 0]    RegFile_w_addr;
    wire [ 3: 0]	data_ram_b_en;
    wire [ 1: 0]	sel_data_ram_wd;
	wire 	sel_data_ram_extend;
    wire    sel_rf_w_data;
    wire    sel_rf_w_en;

    //////////////////////////////////////////////
    /// 流水线控制

    // 认为访存也能一周期完成
    assign MEM_ready_go=1'b1;
	assign MEM_allow_in=(~MEM_valid)|(WB_allow_in & MEM_ready_go);
	assign MEM_to_WB_valid=MEM_valid & MEM_ready_go;
	always@(posedge clk)
	begin
		if(reset)
			MEM_valid<=1'b0;
		else if(MEM_allow_in)
			MEM_valid<=PMEM_to_MEM_valid;
		else
			MEM_valid<=MEM_valid;
	end

	/////////////////////////////////////////////////
	/// 旁路信号生成

	assign MEM_sel_rf_w_data_valid = MEM_valid & MEM_ready_go & (sel_rf_w_data_valid_stage[0] | sel_rf_w_data_valid_stage[1]);

    /////////////////////////////////////////////////
    /// 流水级数据交互

    // 接收
    always@(posedge clk)
	begin
		if(reset)
			PMEM_to_MEM_reg<=0;
		else if(PMEM_to_MEM_valid & MEM_allow_in)
			PMEM_to_MEM_reg<=PMEM_to_MEM_bus;
		else
			PMEM_to_MEM_reg<=PMEM_to_MEM_bus;
	end
    assign {
		sel_rf_w_data_valid_stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//2
		sel_data_ram_extend			,//1
		data_ram_b_en				,//4
		data_ram_r_data				,//32
		RegFile_w_addr				,//5
		alu_result					,//32
		inst_PC						 //32
	}=PMEM_to_MEM_reg;

    // 发送
    assign MEM_to_WB_bus = {
		sel_rf_w_data_valid_stage	,//3
        sel_rf_w_en					,//1
		sel_rf_w_data				,//1
        sel_data_ram_wd 			,//2
		sel_data_ram_extend			,//1
		data_ram_b_en				,//4
        data_ram_r_data 			,//32
        RegFile_w_addr  			,//5
		alu_result					,//32
        inst_PC         			 //32
    };

	assign MEM_to_BY_bus={
		sel_rf_w_data_valid_stage	,//3
		data_ram_b_en				,//4
		RegFile_w_addr				,//5
		data_ram_r_data				,//32
		alu_result					,//32
		MEM_sel_rf_w_data_valid		,//1
		sel_data_ram_wd				,//2
		sel_data_ram_extend			,//1
		MEM_valid					,//1
		sel_rf_w_en					 //1
	};

endmodule
