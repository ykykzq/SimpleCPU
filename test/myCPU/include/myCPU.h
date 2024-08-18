`ifndef MYCPU_H
    `define MYCPU_H

	// 指令类型，用独热码区分不同指令
	`define INST_TYPE_WD		26

	// 流水线间数据通信
	`define IF_TO_IPD_BUS_WD 	64
    `define IPD_TO_ID_BUS_WD 	137
    `define ID_TO_EXE_BUS_WD 	150
    `define EXE_TO_MEM_BUS_WD	76
    `define MEM_TO_WB_BUS_WD 	108
	`define WB_to_ID_bus_WD 	38

	`define ID_TO_IF_BUS_WD  	33
	`define ID_TO_IPD_BUS_WD	33
    
	// 旁路与流水级通信
	`define EXE_TO_BY_BUS_WD	1
	`define MEM_TO_BY_BUS_WD	1
	`define WB_TO_BY_BUS_WD		1

	`define BY_TO_ID_BUS_WD		1
	
	// Wake UP与流水级通信
	`define BY_TO_WK_BUS_WD		1

`endif
