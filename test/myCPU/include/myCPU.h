`ifndef MYCPU_H
    `define MYCPU_H

	// 流水线间数据通信
	`define IF_TO_IPD_BUS_WD 	1
    `define IPD_TO_ID_BUS_WD 	1+INST_TYPE_WD
    `define ID_TO_EXE_BUS_WD 	1
    `define EXE_TO_MEM_BUS_WD	1
    `define MEM_TO_WB_BUS_WD 	1

	`define ID_TO_IF_BUS_WD  	1
	`define ID_TO_IPD_BUS_WD	1
    `define WB_TO_RF_BUS_WD 	1
	
	// 旁路与流水级通信
	`define EXE_TO_BY_BUS_WD	1
	`define MEM_TO_BY_BUS_WD	1
	`define ID_TO_BY_BUS_WD		1
	`define BY_TO_ID_BUS_WD		1
	
	//阻塞与流水级通信
	`define ID_TO_ST_BUS_WD		1
	`define EXE_TO_ST_BUS_WD 	1
	`define ST_TO_ID_BUS_WD		1

	// 指令类型，用独热码区分不同指令
	`define INST_TYPE_WD		1
`endif
