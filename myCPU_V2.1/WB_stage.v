`include"myCPU.h"
module WB_stage(
	input  wire							clk,
	input  wire							reset,
	
	//来自MEM的数据
	input  wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus,
	
	//传给ID，用以写回
	output wire[`WB_TO_RF_BUS_WD-1:0]	WB_to_RF_bus,
	
	//debug的接口
	output [31:0] 						debug_wb_pc     ,
    output [3:0] 						debug_wb_rf_wen ,
    output [4:0] 						debug_wb_rf_wnum,
    output [31:0] 						debug_wb_rf_wdata,
	
	//流水线控制
	input  wire							MEM_to_WB_valid,
	output wire							WB_allow_in
    );
	wire						WB_ready_go;
	reg							WB_valid;		
	
	
	//数据交互
	reg[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_reg;
	
	wire[31:0]					RegFile_w_data;
	wire[4:0]					RegFile_w_addr;
	wire						RegFile_w_en;
	
	wire[31:0]					PC_plus_4;				
	wire[31:0]					alu_res;					
	wire[31:0]					data_ram_r_data;			
	wire[4:0]					RegFile_target_w_addr;	
	wire[1:0]					sel_rf_w_data;			
	wire						sel_rf_w_en;				
	
	
	
	
	
	////////////////////////////////////////////////////////////////
	//stage间交互 及 写回
	always@(posedge clk)
	begin
		if(MEM_to_WB_valid & WB_allow_in)
			MEM_to_WB_reg<=MEM_to_WB_bus;
		else
			MEM_to_WB_reg<=MEM_to_WB_reg;
	end
	
	assign{
			PC_plus_4				,//103:72
			alu_res					,//72:41
			data_ram_r_data			,//40:9
			RegFile_target_w_addr	,//8:3
			sel_rf_w_data			,//2:1
			sel_rf_w_en				 //0
					}=MEM_to_WB_reg;


	//发给RF的
	assign RegFile_w_data=	(sel_rf_w_data==2'b10)?data_ram_r_data:
							(sel_rf_w_data==2'b01)?PC_plus_4+4://PC+8,延迟槽的下一条
							(sel_rf_w_data==2'b11)?32'b0://例外情况，即不写入
								alu_res;
	assign RegFile_w_addr=RegFile_target_w_addr;
	assign RegFile_w_en=sel_rf_w_en;
	assign WB_to_RF_bus={
						RegFile_w_data	,//37:6
						RegFile_w_addr	,//5:1
						RegFile_w_en	 //0
					};
					
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
	
	
	
	
	
	/////////////////////////////////////////////////////////////////////////
	//debug接口
	assign debug_wb_pc       = PC_plus_4-4;//这里需要修正
	assign debug_wb_rf_wen   = {4{RegFile_w_en}};
	assign debug_wb_rf_wnum  = RegFile_w_addr;
	assign debug_wb_rf_wdata = RegFile_w_data;
endmodule
