`ifndef MYCPU_H
    `define MYCPU_H

	// 指令类型，用独热码区分不同指令
	`define INST_TYPE_WD		46

	// 流水线间数据通信
	`define IF_TO_IPD_BUS_WD 	32
    `define IPD_TO_ID_BUS_WD 	159
    `define ID_TO_EXE_BUS_WD 	162
    `define EXE_TO_MEM_BUS_WD	81
    `define MEM_TO_WB_BUS_WD 	113
	`define WB_to_ID_bus_WD 	38

	`define ID_TO_IF_BUS_WD  	33
	`define ID_TO_IPD_BUS_WD	33
    
	// 旁路与流水级通信
	`define EXE_TO_BY_BUS_WD	40
	`define MEM_TO_BY_BUS_WD	82
	`define WB_TO_BY_BUS_WD		40

	`define BY_TO_ID_BUS_WD		120
	
	// Wake UP模块与流水级通信
	`define BY_TO_WK_BUS_WD		24

`endif
