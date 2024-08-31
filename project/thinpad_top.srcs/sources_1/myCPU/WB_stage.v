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

    output wire[`WB_TO_BY_BUS_WD-1:0]	WB_to_BY_bus,
	
	// 使用golden_trace工具debug的接口
	output [31:0] 						debug_wb_pc     ,
    output [3:0] 						debug_wb_rf_wen ,
    output [4:0] 						debug_wb_rf_wnum,
    output [31:0] 						debug_wb_rf_wdata,
	
	// 流水线控制
	input  wire							MEM_to_WB_valid,
	output wire							WB_allow_in
    );
    // 当前指令的PC
	wire [31: 0]	inst_PC;

    // 流水线控制
	wire WB_ready_go;
    wire WB_to_RF_valid;
	reg  WB_valid;

    // MEM/WB REG
    reg [`MEM_TO_WB_BUS_WD-1:0] MEM_to_WB_reg;

    // 写回数据与目的寄存器号
    wire [31: 0]	RF_w_data_from_ALU;
    reg  [31: 0]	RF_w_data_from_RAM;
    wire [31: 0]	data_ram_r_data;
    wire [31: 0]	alu_result;
    wire [ 4: 0]	RegFile_w_addr;
    wire [31: 0]    RegFile_w_data;
    wire [ 3: 0]    data_ram_b_en;
    wire    sel_rf_w_data;
    wire [ 1: 0]    sel_data_ram_wd;
    wire    sel_data_ram_extend;

    // 旁路所需控制信号
    wire [ 2: 0]    sel_rf_w_data_valid_stage;

    // 写回使能信号
    wire RegFile_w_en;
    wire sel_rf_w_en;

    //////////////////////////////////////////////
    /// 流水线控制
    assign WB_ready_go=1'b1;
	assign WB_allow_in=(~WB_valid)|(WB_ready_go);//认为RF始终allow in
    assign WB_to_RF_valid = WB_valid & WB_ready_go;
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

    assign RegFile_w_en = WB_to_RF_valid & sel_rf_w_en;
    assign RF_w_data_from_ALU=alu_result;

    // 处理半字读与字节读
    always@(*)
    begin
        if(sel_data_ram_wd[1]==1)
            // byte
            if(data_ram_b_en==4'b0001)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={24'b0,data_ram_r_data[ 7: 0]};
                else 
                    RF_w_data_from_RAM<={{24{data_ram_r_data[7]}},data_ram_r_data[ 7: 0]};
            else if(data_ram_b_en==4'b0010)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={24'b0,data_ram_r_data[15:8]};
                else 
                    RF_w_data_from_RAM<={{24{data_ram_r_data[15]}},data_ram_r_data[15:8]};
            else if(data_ram_b_en==4'b0100)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={24'b0,data_ram_r_data[23:16]};
                else
                    RF_w_data_from_RAM<={{24{data_ram_r_data[23]}},data_ram_r_data[23:16]};
            else if(data_ram_b_en==4'b1000)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={24'b0,data_ram_r_data[31:24]};
                else
                    RF_w_data_from_RAM<={{24{data_ram_r_data[31]}},data_ram_r_data[31:24]};
            else 
                RF_w_data_from_RAM<=32'b0;
        else if(sel_data_ram_wd[0]==1)
            // half-word
            if(data_ram_b_en==4'b0011)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={16'b0,data_ram_r_data[15: 0]};
                else
                    RF_w_data_from_RAM<={{16{data_ram_r_data[15]}},data_ram_r_data[15: 0]};
            else if(data_ram_b_en==4'b1100)
                if(sel_data_ram_extend)
                    RF_w_data_from_RAM<={16'b0,data_ram_r_data[31:16]};
                else
                    RF_w_data_from_RAM<={{16{data_ram_r_data[31]}},data_ram_r_data[31:16]};
            else 
                RF_w_data_from_RAM<=32'b0;
        else 
            RF_w_data_from_RAM<=data_ram_r_data;
    end

    // 如果写回寄存器号0则丢弃写回值,避免读取GR[0]时从旁路中错误的读取到非32'b0数据
    assign RegFile_w_data = (RegFile_w_addr==5'b0_0000)?32'b0:sel_rf_w_data?RF_w_data_from_RAM:RF_w_data_from_ALU;

    ///////////////////////////////////////////////
    /// 旁路信号

    // 写回数据在当前（WB）阶段是否已经准备好
    assign WB_sel_rf_w_data_valid = WB_valid & WB_ready_go 
                & ( sel_rf_w_data_valid_stage[0] | sel_rf_w_data_valid_stage[1] | sel_rf_w_data_valid_stage[2]);

    ///////////////////////////////////////////////
    /// 流水级数据交互

    // 接收
    always@(posedge clk)
	begin
        if(reset)
            MEM_to_WB_reg<=0;
		else if(MEM_to_WB_valid & WB_allow_in)
			MEM_to_WB_reg<=MEM_to_WB_bus;
		else
			MEM_to_WB_reg<=MEM_to_WB_reg;
	end
	
	assign{
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
    }=MEM_to_WB_reg;

    // 发送
    assign WB_to_ID_bus={
		RegFile_w_en        ,//1
		RegFile_w_data	    ,//32
		RegFile_w_addr	     //5
	};

    assign WB_to_BY_bus={
        // WB阶段信号		
		RegFile_w_addr			,//5
		RegFile_w_data			,//32
		WB_sel_rf_w_data_valid	,//1
        WB_valid                ,//1
		sel_rf_w_en 		     //1
    };

    ////////////////////////////////////////////
    /// Debug接口

    assign debug_wb_pc          = inst_PC;
    assign debug_wb_rf_wen      = {4{RegFile_w_en}};
    assign debug_wb_rf_wnum     = RegFile_w_addr;
    assign debug_wb_rf_wdata    = RegFile_w_data;
	
endmodule