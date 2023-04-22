`ifndef MYCPU_H
    `define MYCPU_H

    `define IF_TO_ID_BUS_WD 	64
	`define ID_TO_PC_BUS_WD  	33
    `define ID_TO_EXE_BUS_WD 	149
    `define EXE_TO_MEM_BUS_WD	76
    `define MEM_TO_WB_BUS_WD 	72
    `define WB_TO_RF_BUS_WD 	39
	
	`define EXE_TO_BY_BUS_WD	39
	`define MEM_TO_BY_BUS_WD	39
	`define ID_TO_BY_BUS_WD		12
	`define BY_TO_ID_BUS_WD		66
	
	`define ID_TO_ST_BUS_WD		12
	`define EXE_TO_ST_BUS_WD 	7
	`define ST_TO_ID_BUS_WD		1
`endif
