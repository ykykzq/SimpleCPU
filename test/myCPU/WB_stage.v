/**
 * @file WB_stage.v
 * @author ykykzq
 * @brief 流水线第六级，完成寄存器堆的写回行为
 * @version 0.1
 * @date 2024-08-13
 *
 */
`include"myCPU.h"
module WB_stage(
	input  wire							clk,
	input  wire							reset,
	
	// 流水级数据交互
	input  wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,

	output wire[`WB_to_ID_bus_WD-1:0]	WB_to_ID_bus,
	
	//debug的接口
	output [31:0] 						debug_wb_pc     ,
    output [3:0] 						debug_wb_rf_wen ,
    output [4:0] 						debug_wb_rf_wnum,
    output [31:0] 						debug_wb_rf_wdata,
	
	//流水线控制
	input  wire							MEM_to_WB_valid,
	output wire							WB_allow_in
    );
    // 当前指令的PC
	wire [31: 0]	inst_PC;

    // 流水线控制
	wire WB_ready_go;
	reg  WB_valid;

    // MEM/WB REG
    reg [`MEM_TO_WB_BUS_WD-1:0] MEM_to_WB_reg;

    // 写回数据与目的寄存器号
    wire [31: 0]	RF_w_data_From_ALU;
    reg  [31: 0]	RF_w_data_From_RAM;
    wire [31: 0]	data_ram_r_data;
    wire [31: 0]	alu_result;
    wire [ 4: 0]	RegFile_w_addr;
    wire [ 3: 0]    data_ram_b_en;
    wire    sel_rf_w_data;
    wire    sel_data_ram_wd;

    // 写回使能信号
    wire sel_rf_w_en;

    //////////////////////////////////////////////
    /// 流水线控制
    assign WB_ready_go=1'b1;
	assign WB_allow_in=(~WB_valid)|(WB_ready_go);//认为RF始终allow in
	always@(posedge clk)
	begin
		if(reset)
			WB_valid<=1'b0;
		else if(WB_allow_in)
			WB_valid<=MEM_to_WB_valid;
		else
			WB_valid<=WB_valid;
	end

    ///////////////////////////////////////////////
    /// 选择写回的数据

    assign RF_w_data_From_ALU=alu_result;

    // 处理半字读与字节读
    always@(*)
    begin
        if(sel_data_ram_wd==1)
        begin
            if(data_ram_b_en==4'b0001)
                // 注意是符号扩展
                RF_w_data_From_RAM<={{24{data_ram_r_data[7]}},data_ram_r_data[7:0]};
            else if(data_ram_b_en==4'b0010)
                RF_w_data_From_RAM<={{24{data_ram_r_data[15]}},data_ram_r_data[15:8]};
            else if(data_ram_b_en==4'b0100)
                RF_w_data_From_RAM<={{24{data_ram_r_data[23]}},data_ram_r_data[23:16]};
            else if(data_ram_b_en==4'b1000)
                RF_w_data_From_RAM<={{24{data_ram_r_data[31]}},data_ram_r_data[31:24]};
            else 
                RF_w_data_From_RAM<=32'b0;
        end
        else 
            RF_w_data_From_RAM<=data_ram_r_data;
    end

    assign RegFile_w_data = sel_rf_w_data?RF_w_data_From_RAM:RF_w_data_From_ALU;

    ///////////////////////////////////////////////
    /// 流水级数据交互

    // 接收
    always@(posedge clk)
	begin
		if(MEM_to_WB_valid & WB_allow_in)
			MEM_to_WB_reg<=MEM_to_WB_bus;
		else
			MEM_to_WB_reg<=MEM_to_WB_reg;
	end
	
	assign{
        sel_rf_w_en		,
		sel_rf_w_data	,
        sel_data_ram_wd ,
		data_ram_b_en	,
        data_ram_r_data ,
        RegFile_w_addr  ,
		alu_result		,
        inst_PC          //31:0
    }=MEM_to_WB_reg;

    // 发送
    assign WB_to_ID_bus={
		sel_rf_w_en	    ,//37
		RegFile_w_data	,//36:5
		RegFile_w_addr	 //4:0
	};

    ////////////////////////////////////////////
    /// Debug接口

    assign debug_wb_pc          = inst_PC;
    assign debug_wb_rf_wen      = {4{sel_rf_w_en}};
    assign debug_wb_rf_wnum     = RegFile_w_addr;
    assign debug_wb_rf_wdata    = RegFile_w_data;
	
endmodule