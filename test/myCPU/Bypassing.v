`include "myCPU.h"
module Bypassing(
	// 流水线数据交互，需要包括ID阶段之后所有阶段的信息
	input  wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus,
	input  wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus,
	input  wire[`WB_TO_BY_BUS_WD-1:0]	WB_to_BY_bus,
	
	// 告知WK是否可以从旁路读取该数据
	output wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_WK_bus,
	// 将旁路数据传输到ID阶段
	output wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus
    );
	
	
	/////////////////////////////////////////////////////////
	/// 筛选
	
endmodule
