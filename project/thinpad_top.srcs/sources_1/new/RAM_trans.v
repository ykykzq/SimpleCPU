/*
    | 虚地址区间            | 说明           |
    | 0x80000000-0x800FFFFF | 监控程序代码   |
    | 0x80100000-0x803FFFFF | 用户代码空间   |
    | 0x80400000-0x807EFFFF | 用户数据空间   |
    | 0x807F0000-0x807FFFFF | 监控程序数据   |
    | 0xBFD003F8-0xBFD003FD | 串口数据及状态 |

    | 地址       | 位    | 说明                                               |
    | 0xBFD003F8 | [7:0] | 串口数据，读、写地址分别表示串口接收、发送一个字节 |
    | 0xBFD003FC | [0]   | 只读，为1时表示串口空闲，可发送数据                |
    | 0xBFD003FC | [1]   | 只读，为1时表示串口收到数据                        |
*/
`include "myCPU.h"
module RAM_trans(
	input wire			clk,
	input wire			reset,
	
	//处理mem写入或读取base_ram（即指令存储位置）造成的结构冒险
	input  				MEM_valid,
	output 				IF_ready_go_fromTR,

	//指令RAM
	input  wire			inst_sram_c_en,//片选使能
	input  wire			inst_sram_w_en,
	input  wire			inst_sram_r_en,
	input  wire[31:0]	inst_sram_addr,
	input  wire[ 3:0]	inst_sram_byte_en,
	output wire[31:0]	inst_sram_rdata,
	input  wire[31:0]	inst_sram_wdata,//实际上用不到指令RAM的写
    //数据RAM
	input  wire        	data_sram_c_en,
	input  wire 		data_sram_w_en,
	input  wire 		data_sram_r_en,
    input  wire [ 3:0] 	data_sram_b_en,
    input  wire [31:0] 	data_sram_addr,
    input  wire [31:0] 	data_sram_wdata,
    output wire [31:0] 	data_sram_rdata,
    
	
	//BaseRAM信号
    inout  wire[31:0] 	base_ram_data,		//BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] 	base_ram_addr, 		//BaseRAM地址
    output wire[3:0] 	base_ram_be_n,  	//BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire 		base_ram_ce_n, 		//BaseRAM片选，低有效
    output wire 		base_ram_oe_n,		//BaseRAM读使能，低有效
    output wire 		base_ram_we_n,		//BaseRAM写使能，低有效
	
    //ExtRAM信号	
    inout  wire[31:0] 	ext_ram_data,  		//ExtRAM数据
    output wire[19:0] 	ext_ram_addr, 		//ExtRAM地址
    output wire[ 3:0] 	ext_ram_be_n,  		//ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire 		ext_ram_ce_n,		//ExtRAM片选，低有效
    output wire 		ext_ram_oe_n, 		//ExtRAM读使能，低有效
    output wire 		ext_ram_we_n, 		//ExtRAM写使能，低有效
		
	//UART串口	
	output wire			TxD,				//串口发送端
	input  wire			RxD,				//串口接收端
	output wire[1:0]	SerialPort_state	//串口状态
);
	//串口
	wire[7:0] 	RxD_data;//接收到的数据
	wire[7:0] 	TxD_data;//要发送的数据
	wire 		RxD_data_ready;
	wire 		RxD_clear;
	
	wire 		TxD_busy;
	wire 		TxD_start;
	
	//两个队列
	wire 		RxD_FIFO_w_en;
	wire 		RxD_FIFO_full;
	wire 		RxD_FIFO_r_en;
	wire[7:0] 	RxD_FIFO_data_out;
	wire		RxD_FIFO_empty;
	
	wire 		TxD_FIFO_w_en;
	wire[7:0] 	TxD_FIFO_data_in;
	wire 		TxD_FIFO_full;
	wire 		TxD_FIFO_r_en;
	wire		TxD_FIFO_empty;
	

/////////////////////////////////////////////////////////////////////
//两个RAM
	//inst与MEM将要使用哪些模块
	wire	sel_mem_base;
	wire	sel_mem_ext;
	wire	sel_mem_sp_data;
	wire	sel_mem_sp_state;
	wire 	sel_inst_base;
	
	//data_ram是否将要读写base_ram、ext_ram、串口
	assign sel_mem_base=MEM_valid&(data_sram_addr>=32'h80000000)&&(data_sram_addr<32'h80400000);
	assign sel_mem_ext=MEM_valid&(data_sram_addr>=32'h80400000)&&(data_sram_addr<32'h80800000);
	assign sel_mem_sp_data=MEM_valid&(data_sram_addr==32'hbfd003f8);
	assign sel_mem_sp_state=MEM_valid&(data_sram_addr==32'hbfd003fc);
	
	//inst_ram是否将要读写base_ram
	assign sel_inst_base=(inst_sram_addr>=32'h80000000)&&(inst_sram_addr<32'h80400000);
	
	//BaseRAM信号
	//首先满足MEM阶段的读写请求
	assign base_ram_data=	(~base_ram_we_n)?data_sram_wdata:32'bz;
	assign base_ram_addr=sel_mem_base?data_sram_addr[21:2]:inst_sram_addr[21:2];
	assign base_ram_be_n=sel_mem_base?(~data_sram_b_en):4'b0000;//日后可以优化
	assign base_ram_ce_n=~((data_sram_c_en & sel_mem_base)|(inst_sram_c_en & sel_inst_base));
	assign base_ram_oe_n=base_ram_ce_n | (~base_ram_we_n);
	assign base_ram_we_n=base_ram_ce_n | (~(
											(
												data_sram_w_en 
													& 
												sel_mem_base
											)
												|
											(	
												inst_sram_w_en 
													&
												sel_inst_base
											)
										));
	
	//ExtRAM信号
	assign ext_ram_data=	(
								data_sram_w_en 
									&
								sel_mem_ext
							)?data_sram_wdata:
								32'bz;
	assign ext_ram_addr=sel_mem_ext?data_sram_addr[21:2]:32'b0;
	assign ext_ram_be_n=sel_mem_ext?(~data_sram_b_en):4'b0000;
	assign ext_ram_ce_n=~(data_sram_c_en & sel_mem_ext);
	assign ext_ram_oe_n=ext_ram_ce_n | (~ext_ram_we_n);
	assign ext_ram_we_n=ext_ram_ce_n | (~(
											data_sram_w_en 
												&
											sel_mem_ext
										));
	
	//输出
	assign data_sram_rdata=	sel_mem_base?base_ram_data:
							sel_mem_ext?ext_ram_data:
							sel_mem_sp_data?{24'b0,RxD_FIFO_data_out}:
							sel_mem_sp_state?{30'b0,SerialPort_state}:32'b0;
	
	assign inst_sram_rdata=	sel_inst_base?base_ram_data:
							32'b0;
	//处理冒险
	assign IF_ready_go_fromTR=(sel_mem_base & MEM_valid )?1'b0:1'b1;

////////////////////////////////////////////////////////////////////////
	
	
	//接收模块
	async_receiver #(.ClkFrequency(55000000),.Baud(9600)) //接收模块，9600无检验位
		ext_uart_r(
			.clk				(clk),
			.RxD				(RxD),//串口输入
			.RxD_data_ready		(RxD_data_ready),//数据接收到标志
			.RxD_clear			(RxD_clear),//清除接收标志
			.RxD_data			(RxD_data)//接收到的一字节数据
		);
	fifo_generator_0 RXD_FIFO (
		.rst		(reset),
		.clk		(clk),
		.wr_en		(RxD_FIFO_w_en),//写使能
		.din		(RxD_data),//接收到的数据
		.full		(RxD_FIFO_full),//判满标志
	
		.rd_en		(RxD_FIFO_r_en),//读使能
		.dout		(RxD_FIFO_data_out),//传递给mem阶段读出的数据
		.empty		(RxD_FIFO_empty)//判空标志
	);

	//发送模块
	fifo_generator_0 TXD_FIFO (
		.rst		(reset),
		.clk		(clk),
		.wr_en		(TxD_FIFO_w_en),//写使能
		.din		(TxD_FIFO_data_in),//需要发送的数据
		.full		(TxD_FIFO_full),//判满标志
	
		.rd_en		(TxD_FIFO_r_en),//读使能，为1时串口取出数据发送
		.dout		(TxD_data),//传递给串口待发送的数据
		.empty		(TxD_FIFO_empty)//判空标志
	);
	async_transmitter #(.ClkFrequency(55000000),.Baud(9600)) //发送模块，9600无检验位
		ext_uart_t(
			.clk		(clk),
			.TxD		(TxD),//串口输出
			.TxD_busy	(TxD_busy),//发送器忙状态指示
			.TxD_start	(TxD_start),//开始发送信号
			.TxD_data	(TxD_data)//待发送的数据
		);
		
	//串口的状态
	assign SerialPort_state={~RxD_FIFO_empty,~TxD_FIFO_full};
	
	//收到一字节数据、队列有空余，则下一周期即送入队列，因此设置清除标志
	assign RxD_clear = RxD_data_ready &(~RxD_FIFO_full); 	
	assign RxD_FIFO_w_en=RxD_data_ready;
	assign RxD_FIFO_r_en=	(data_sram_r_en 
								& 
							sel_mem_sp_data);
	
	assign TxD_start=(~TxD_busy)&(~TxD_FIFO_empty);
	assign TxD_FIFO_w_en=	(
							data_sram_w_en 
								&
							sel_mem_sp_data
							);
	assign TxD_FIFO_data_in=TxD_FIFO_w_en?data_sram_wdata[7:0]:8'b0;
	assign TxD_FIFO_r_en=TxD_start;

	
	
endmodule

