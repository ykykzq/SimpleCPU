/**
 * @file IPD_stage.v
 * @author ykykzq
 * @brief 流水线第二级，完成：pre-decoder，包括判断指令类型，决定源操作寄存器号
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include"./include/myCPU.h"
module IPreD_top(
    input								clk,
	input								reset,

    //流水线数据传输
	input  wire[`IF_TO_IPD_BUS_WD-1:0]	IF_to_IPD_bus,
	output wire[`ID_TO_EXE_BUS_WD-1:0]	IPD_to_ID_bus,
    input  wire[`ID_TO_IPD_BUS_WD-1:0]  ID_to_IPD_bus,
	
	//流水线控制
	input  wire							ID_allow_in,
	input  wire							IF_to_IPD_valid,
	output wire							IPD_allow_in,
	output wire							IPD_to_ID_valid
    );

    // 流水线控制信号
    wire						IPD_ready_go;
	reg							IPD_valid;

    ////////////////////////////////////////
    ///流水线控制

    // 认为一周期内必能完成pre-decode
    assign IPD_ready_go=1'b1;
	assign IPD_allow_in=(~IPD_valid)|(IPD_ready_go & EXE_allow_in);
	assign IPD_to_EXE_valid=IPD_ready_go&IPD_valid;
    always@(posedge clk)
    begin
        if(reset)
            IPD_valid<=1'b0;
        else if(IPD_allow_in)
            IPD_valid<=IF_to_IPD_valid;
        else if(br_taken_cancel)
            IPD_valid<=1'b0;
        else 
            IPD_valid<=IPD_valid;
    end

    ////////////////////////////////////////
    /// 流水级间数据交互

    // 接收
    assign {PC_plus_4,inst}=
endmodule
