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
	wire		sel_rf_w_en_fromEXE;//写回数据是否在EXE阶段已经计算完成
	wire		EXE_valid;

	//from MEM
	wire[4:0]	RegFile_w_target_addr_fromMEM;
	wire[31:0]	RegFile_w_data_fromMEM;
	wire		sel_rf_w_en_fromMEM;//写回数据是否在MEM阶段已经计算完成
	wire		MEM_valid;
	
	//from ID
	wire[4:0]	RegFile_r_addr1_fromID;
	wire		sel_RegFile_r_addr1_en;
	wire[4:0]	RegFile_r_addr2_fromID;
	wire		sel_RegFile_r_addr2_en;
	
	
	//to ID
	wire[31:0]	RegFile_r_data1;
	wire[31:0]	RegFile_r_data2;
	wire[1:0]	sel_RegFile_r_data;//01代表替代r_data1，10代表替代r_data2，00代表不旁路，11代表均旁路
	
	
	
	///////////////////////////////////////////////////////////////////
	//接收数据
	
	assign{
			RegFile_w_target_addr_fromEXE	,//38:34
			RegFile_w_data_fromEXE			,//33:2
			sel_rf_w_en_fromEXE				,//1
			EXE_valid						 //0
			}=EXE_to_BY_bus;
	
	assign{
			RegFile_w_target_addr_fromMEM	,//38:34
			RegFile_w_data_fromMEM			,//33:2
			sel_rf_w_en_fromMEM				,//1
			MEM_valid                        //0
			}=MEM_to_BY_bus;
	
	assign{
			RegFile_r_addr1_fromID			,//11:7
			sel_RegFile_r_addr1_en			,//6
			RegFile_r_addr2_fromID			,//5:1
			sel_RegFile_r_addr2_en			 //0
			}=ID_to_BY_bus;
	
	
	//////////////////////////////////////////////////////////////////////
	//处理
	assign RegFile_r_data1=		((RegFile_w_target_addr_fromEXE==RegFile_r_addr1_fromID  )
									& sel_rf_w_en_fromEXE & EXE_valid )?
									RegFile_w_data_fromEXE:
								((RegFile_w_target_addr_fromMEM==RegFile_r_addr1_fromID )
									& sel_rf_w_en_fromMEM & MEM_valid )?
									RegFile_w_data_fromMEM:
									32'b0;//不适用的情况
	
	assign RegFile_r_data2=		((RegFile_w_target_addr_fromEXE==RegFile_r_addr2_fromID )
									& sel_rf_w_en_fromEXE & EXE_valid)?
									RegFile_w_data_fromEXE:
								(( RegFile_w_target_addr_fromMEM==RegFile_r_addr2_fromID )
									& sel_rf_w_en_fromMEM & MEM_valid)?
									RegFile_w_data_fromMEM:
									32'b0;//不适用的情况
									
	assign	sel_RegFile_r_data=	{
									(
										( (RegFile_w_target_addr_fromEXE==RegFile_r_addr2_fromID) & sel_rf_w_en_fromEXE & EXE_valid) |
										( (RegFile_w_target_addr_fromMEM==RegFile_r_addr2_fromID) & sel_rf_w_en_fromMEM & MEM_valid)	 
									)
										,
									(
										( (RegFile_w_target_addr_fromEXE==RegFile_r_addr1_fromID) & sel_rf_w_en_fromEXE & EXE_valid)|
										( (RegFile_w_target_addr_fromMEM==RegFile_r_addr1_fromID) & sel_rf_w_en_fromMEM & MEM_valid)  
									)
								};
									
	
	//////////////////////////////////////////////////////////////////
	//发送数据
	assign BY_to_ID_bus={	RegFile_r_data1		,//65:34
							RegFile_r_data2		,//33:2
							sel_RegFile_r_data	 //1:0
							};
	
	
endmodule
