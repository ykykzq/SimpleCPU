`include"myCPU.h"
module WB_stage(
	input  wire							clk,
	input  wire							reset,
	
	//来自MEM的数据
	input  wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,
	
	//传给ID，用以写回
	output wire[`WB_TO_RF_BUS_WD-1:0]	WB_to_RF_bus,
	
	//流水线控制
	input  wire							MEM_to_WB_valid,
	output wire							WB_allow_in
    );
	wire						WB_ready_go;
	reg							WB_valid;		
	
	
	//数据交互
	
	//from MEM
	reg[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_reg;
	
	wire[31:0]					RegFile_w_data;
	wire[4:0]					RegFile_w_addr;
	wire						RegFile_w_en;
	
	wire[31:0]					PC_plus_8;						
	wire[4:0]					RegFile_target_w_addr;	
	wire[1:0]					sel_rf_w_data;			
	wire						sel_rf_w_en;				
	
	
	/////////////////////////////////////////////////////////////////////
	//流水线控制
	assign WB_ready_go=1'b1;
	assign WB_allow_in=(~WB_valid)|(WB_ready_go);//认为RF始终allow in
	always@(posedge clk)
	begin
		if(reset)
			WB_valid<=1'b0;
		else if(WB_allow_in)
			WB_valid<=MEM_to_WB_valid;
		else
			WB_valid<=WB_valid;
	end
	
	
	////////////////////////////////////////////////////////////////
	//接收数据
	always@(posedge clk)
	begin
		if(MEM_to_WB_valid & WB_allow_in)
			MEM_to_WB_reg<=MEM_to_WB_bus;
		else
			MEM_to_WB_reg<=MEM_to_WB_reg;
	end
	
	assign{
			sel_rf_w_data			,//71:70
			sel_rf_w_en				,//69
			PC_plus_8				,//68:37
			RegFile_w_data			,//36:5
			RegFile_target_w_addr	 //4:0
					}=MEM_to_WB_reg;

	//////////////////////////////////////////////////////////////////
	//发给RF的
	//RegFile_w_data在前面
	assign RegFile_w_addr=RegFile_target_w_addr;
	assign RegFile_w_en=sel_rf_w_en & WB_valid;
	
	/////////////////////////////////////////////////////////////////////////
	//输出
	//to RF
	assign WB_to_RF_bus={
						WB_valid		,//38,实际上用于旁路
						RegFile_w_en	,//37
						RegFile_w_data	,//36:5
						RegFile_w_addr	 //4:0
					};
	
endmodule
