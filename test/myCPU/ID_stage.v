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

	input  wire[`WB_TO_RF_BUS_WD-1:0]	WB_to_RF_bus,

	//流水线控制
	input  wire							EXE_allow_in,
	input  wire							IF_to_ID_valid,
	output wire							ID_allow_in,
	output wire							ID_to_EXE_valid
);

	
endmodule
