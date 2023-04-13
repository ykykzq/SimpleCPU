`include "myCPU.h"

module IF_stage(
	input 							clk,
	input 							reset,
	
	//从ID_Stage回来的数据，主要为PC的更新值及选择它们的选择信号
	input  wire[`ID_TO_PC_BUS_WD-1:0]ID_to_PC_bus,
	
	//ID发来的允许进入信号
	input  wire						ID_allow_in,
	//IF能传给ID数据的信号
	output wire						IF_to_ID_valid,
	
	//传给IF_TO_ID 寄存器的数据
	output wire[`IF_TO_ID_BUS_WD-1:0]	IF_to_ID_bus,
	
	//连接指令寄存器
	output wire						inst_ram_en,//(读)使能
	output wire[31:0]				inst_ram_addr,
	input  wire[31:0]				inst_ram_r_data,
	output wire[3:0]				inst_ram_w_en,
	output wire[31:0]				inst_ram_w_data//实际上用不到指令RAM的写
    );
	wire[31:0]	Bne_Beq_PC;
	wire[31:0]	Jal_PC;
	wire[31:0]	Jr_PC;
	wire[1:0]	sel_next_PC;
	
	reg	[31:0]	PC;
	wire[31:0]	next_PC;
	wire[31:0]	PC_plus_4;//PC+4,多次被用到
	
	wire[31:0]	inst;
	
	//与流水线控制有关的信号
	reg			IF_valid;//IF数据有效
	wire		IF_ready_go;//IF阶段数据处理好了，可以发送至ID
	wire		IF_allow_in;//IF允许数据进入
	wire		Pre_to_IF_valid;//Pre能传给IF数据的信号
	
	
	//////////////////////////////////////////////
	//维护与流水线控制有关的信号
	
	//IF_valid
	always@(posedge clk)//异步复位
	begin
		if(reset)
			IF_valid<=1'b0;//相当于清空有效数据
		else if(IF_allow_in)
			IF_valid<=Pre_to_IF_valid;
		else
			IF_valid<=IF_valid;
	end
	
	//控制流水线行为
	assign IF_ready_go=1'b1;//认为时序逻辑瞬间完成，因此总认为IF输出有效
	assign IF_allow_in=(~IF_valid) | (IF_ready_go & ID_allow_in);//后者加上IF_valid=1,相当于IF可以向ID发送数据(只含“发送”，不含“接收”)
	assign Pre_to_IF_valid=~reset;
	assign IF_to_ID_valid=IF_valid;//&IF_ready_go
	
	///////////////////////////////////////////////
	
	//来自ID的数据
	assign {
			Bne_Beq_PC		,//97:66
			Jal_PC			,//65:34
			Jr_PC			,//33:2
			sel_next_PC		 //1:0
						}=ID_to_PC_bus;
	//来自指令ram
	assign inst=inst_ram_r_data;
	
	///////////////////////////////////////////////////
	//数据通路
	
	//PC的更新
	always@(posedge clk )//异步复位
	begin
		if(reset)
			PC<=32'hbfbffffc;//0xbfc00000-4
		else if(IF_allow_in & Pre_to_IF_valid)//能接受且能输出
			PC<=next_PC;
		else
			PC<=PC;
	end
	
	//PC_plus_4
	assign PC_plus_4=PC+3'b100;
	
	//next_PC
	assign next_PC=(sel_next_PC==2'b11)?Jr_PC:
					(sel_next_PC==2'b01)?Bne_Beq_PC:
					(sel_next_PC==2'b10)?Jal_PC:
									PC_plus_4;//sel_next_PC==2'b00
									
	////////////////////////////////////////////////////
	//输出
	
	//指令RAM
	assign inst_ram_en=IF_allow_in&Pre_to_IF_valid;//为什么是这个逻辑？
	assign inst_ram_addr=next_PC;
	assign inst_ram_w_data=32'b0;//不写指令RAM
	assign inst_ram_w_en=4'b0;
	
	//传到IDreg的数据
	assign IF_to_ID_bus={PC_plus_4,inst};
	
endmodule
