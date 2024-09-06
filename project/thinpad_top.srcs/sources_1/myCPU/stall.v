`include "myCPU.h"
module Stall(
	input  wire[`ID_TO_ST_BUS_WD-1:0]	ID_to_ST_bus,
	input  wire[`EXE_TO_ST_BUS_WD-1:0]	EXE_to_ST_bus,
	
	output wire							ST_to_ID_bus
    );
	
	//from ID
	wire[4:0]	RegFile_r_addr1_fromID;
	wire		sel_RegFile_r_addr1_en;
	wire[4:0]	RegFile_r_addr2_fromID;
	wire		sel_RegFile_r_addr2_en;
	
	//from EXE
	wire[4:0]	RegFile_w_target_addr_fromEXE;
	wire		EXE_valid;
	wire		sel_MEM_gene;
	
	//to ID
	wire		ID_ready_go;
	
	
	
	wire		ID_not_ready_go;
	
	
	///////////////////////////////////////////////////////////
	//接收数据
	assign{
			sel_RegFile_r_addr1_en			,//11
			sel_RegFile_r_addr2_en			,//10
			RegFile_r_addr1_fromID			,//9:5
			RegFile_r_addr2_fromID			 //4:0
			}=ID_to_ST_bus;
			
	assign{	
			EXE_valid						,//6
			sel_MEM_gene		 			,//5
			RegFile_w_target_addr_fromEXE	 //4:0
			}=EXE_to_ST_bus;
			
			
	/////////////////////////////////////////////////////////////
	//计算过程
	assign ID_not_ready_go=	(EXE_valid)				&
							(sel_MEM_gene)			&
							(
								((RegFile_r_addr1_fromID==RegFile_w_target_addr_fromEXE)&sel_RegFile_r_addr1_en)
									|
								((RegFile_r_addr2_fromID==RegFile_w_target_addr_fromEXE)&sel_RegFile_r_addr2_en)
							);
						
	assign	ID_ready_go=~ID_not_ready_go;
	///////////////////////////////////////////////////////////////
	//传送数据
	assign ST_to_ID_bus={
							ID_ready_go
							};
endmodule
