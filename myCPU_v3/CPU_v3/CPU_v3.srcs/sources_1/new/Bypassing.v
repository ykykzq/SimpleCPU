`include "myCPU.h"
module Bypassing(
	input  wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus,
	input  wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus,
	input  wire[`ID_TO_BY_BUS_WD-1:0]	ID_to_BY_bus,
	
	output wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus
    );
	
	//from EXE
	wire[4:0]	RegFile_w_target_addr_fromEXE;
	wire[31:0]	RegFile_w_data_fromEXE;
	wire		sel_EXE_gene;//写回数据是否在EXE阶段已经计算完成

	//from MEM
	wire[31:0]	RegFile_w_target_addr_fromMEM;
	wire[4:0]	RegFile_w_data_fromMEM;
	wire		sel_MEM_gene;//写回数据是否在MEM阶段已经计算完成
	
	//from ID
	wire[4:0]	RegFile_r_addr1_fromID;
	wire		sel_RegFile_r_addr1_en;
	wire[4:0]	RegFile_r_addr2_fromID;
	wire		sel_RegFile_r_addr2_en;
	
	
	//to ID
	wire[31:0]	RegFile_r_data;
	wire[1:0]	sel_RegFile_r_data;//01代表替代r_data1，10代表替代r_data2，00代表不旁路
	
	
	
	///////////////////////////////////////////////////////////////////
	//接收数据
	
	assign{
			RegFile_w_target_addr_fromEXE	,//37:33
			RegFile_w_data_fromEXE			,//32:1
			sel_EXE_gene					 //0
			}=EXE_to_BY_bus;
	
	assign{
			RegFile_w_target_addr_fromMEM	,//37:33
			RegFile_w_data_fromMEM			,//32:1
			sel_MEM_gene					 //0
			}=MEM_to_BY_bus;
	
	assign{
			RegFile_r_addr1_fromID			,//11:7
			sel_RegFile_r_addr1_en			,//6
			RegFile_r_addr2_fromID			,//5:1
			sel_RegFile_r_addr2_en			 //0
			}=ID_to_BY_bus;
	
	
	//////////////////////////////////////////////////////////////////////
	//处理
	assign RegFile_r_data=		(((RegFile_w_target_addr_fromEXE==RegFile_r_addr1_fromID) | (RegFile_w_target_addr_fromEXE==RegFile_r_addr2_fromID) )
									& sel_EXE_gene )?
									RegFile_w_data_fromEXE:
								(((RegFile_w_target_addr_fromMEM==RegFile_r_addr1_fromID) | (RegFile_w_target_addr_fromMEM==RegFile_r_addr2_fromID) )
									& sel_MEM_gene )?
									RegFile_w_data_fromMEM:
									32'b0;//不适用的情况
									
	assign	sel_RegFile_r_data=	(((RegFile_w_target_addr_fromEXE==RegFile_r_addr1_fromID)|
								  (RegFile_w_target_addr_fromMEM==RegFile_r_addr1_fromID) ) &
										sel_MEM_gene)?
									2'b01:
								(((RegFile_w_target_addr_fromEXE==RegFile_r_addr2_fromID) |
								  (RegFile_w_target_addr_fromMEM==RegFile_r_addr2_fromID) )		&
										sel_EXE_gene)?
									2'b10:
									2'b00;
	
	//////////////////////////////////////////////////////////////////
	//发送数据
	assign BY_to_ID_bus={
							RegFile_r_data		,//33:2
							sel_RegFile_r_data	 //1:0
							};
	
	
endmodule
