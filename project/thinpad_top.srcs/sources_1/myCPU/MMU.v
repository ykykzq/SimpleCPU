/**
 * @file MMU.v
 * @author ykykzq
 * @brief 负责完成CPU核心发出的访存指令中地址向物理地址的映射
 * @version 0.1
 * @date 2024-08-29
 *
 */

module MMU(
    input  wire        clk,
    input  wire        reset,
    // inst sram interface
    input  wire        inst_sram_en,
    input  wire [ 3:0] inst_sram_we,
    input  wire [31:0] inst_sram_addr,
    input  wire [31:0] inst_sram_wdata,
    output reg  [31:0] inst_sram_rdata,
    // data sram interface
    input  wire        data_sram_en,
    input  wire [ 3:0] data_sram_we,
    input  wire [31:0] data_sram_addr,
    input  wire [31:0] data_sram_wdata,
    output reg  [31:0] data_sram_rdata,

    // BaseRAM信号
    inout  wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    // ExtRAM信号
    inout  wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    // 直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    // 发生结构冒险控制信号
    output wire sel_strcture_hazard
);

    // 串口控制信号
    wire[7:0] 	RxD_data;//接收到的数据
	wire 		RxD_data_ready;
	wire 		RxD_clear;
	
    wire[7:0] 	TxD_data;//要发送的数据
	wire 		TxD_busy;
	wire 		TxD_start;

    wire[1:0]   SerialPort_state;
	
	// 接收队列
	wire 		RxD_FIFO_w_en;
	wire 		RxD_FIFO_full;
	wire  		RxD_FIFO_r_en;
	wire[7:0] 	RxD_FIFO_data_out;
	wire		RxD_FIFO_empty;
	// 发送队列
	wire  		TxD_FIFO_w_en;
	wire [7:0] 	TxD_FIFO_data_in;
	wire 		TxD_FIFO_full;
	wire 		TxD_FIFO_r_en;
	wire		TxD_FIFO_empty;


    // MEM读写数据来源
    wire[3:0]   sel_MEM_data_source;
    // IF读写数据来源
    wire[3:0]   sel_IF_data_source;

    // 两个物理RAM的写数据缓存
    wire[31:0]   base_ram_w_data;
    wire[31:0]   ext_ram_w_data;
    // 两个物理RAM的读数据筛选
    wire[31:0]  base_ram_r_data;
    wire[31:0]  ext_ram_r_data;

    /////////////////////////////////////////////////////////////////////
    /// 地址映射目标信号生成


    /*
    MEM阶段读取数据的来源
        +---------------------+-------------------+
        | sel_MEM_data_source | Data Source       |
        +---------------------+-------------------+
        | 4'b1000             | Serial Port State |
        | 4'b0100             | Serial Port Data  |
        | 4'b0010             | Base RAM          |
        | 4'b0001             | Ext RAM           |
        +---------------------+-------------------+
    */
    assign sel_MEM_data_source[3] = data_sram_addr==32'hBFD0_03FC;
    assign sel_MEM_data_source[2] = data_sram_addr==32'hBFD0_03F8;
    assign sel_MEM_data_source[1] = (data_sram_addr>=32'h8000_0000)&(data_sram_addr<32'h8040_0000);
    assign sel_MEM_data_source[0] = (data_sram_addr>=32'h8040_0000)&(data_sram_addr<32'h8080_0000);

    /*
    IF阶段读取数据的来源
        +--------------------+-------------------+
        | sel_IF_data_source | Data Source       |
        +--------------------+-------------------+
        | 4'b1000            | Serial Port State |
        | 4'b0100            | Serial Port Data  |
        | 4'b0010            | Base RAM          |
        | 4'b0001            | Ext RAM           |
        +--------------------+-------------------+

    */
    assign sel_IF_data_source[3] = inst_sram_addr==32'hBFD0_03FC;
    assign sel_IF_data_source[2] = inst_sram_addr==32'hBFD0_03F8;
    assign sel_IF_data_source[1] = (inst_sram_addr>=32'h8000_0000)&(inst_sram_addr<32'h8040_0000);
    assign sel_IF_data_source[0] = (inst_sram_addr>=32'h8040_0000)&(inst_sram_addr<32'h8080_0000);


    /////////////////////////////////////////////////////////////////////////
    /// Base RAM信号生成


    // Base RAM写数据
    assign base_ram_w_data =    (sel_MEM_data_source[1] & data_sram_we!=4'b0 & data_sram_en)?data_sram_wdata:
                                (sel_IF_data_source[1] & inst_sram_we!=4'b0 & inst_sram_en)?inst_sram_wdata:32'b0;

    assign base_ram_data = base_ram_we_n?32'bz:base_ram_w_data;

    // Base RAM地址
    assign base_ram_addr =  (sel_MEM_data_source[1] & data_sram_en)?data_sram_addr[21:2]:
                            (sel_IF_data_source[1] & inst_sram_en)?inst_sram_addr[21:2]:20'b0;

    // Base RAM字节使能信号，低电平有效
    assign base_ram_be_n =  (sel_MEM_data_source[1] & data_sram_en & data_sram_we!=4'b0000)?~data_sram_we:
                            (sel_IF_data_source[1] & inst_sram_en & inst_sram_we!=4'b0000)?~inst_sram_we:4'b0000;

    // Base RAM片选信号，低电平有效
    assign base_ram_ce_n =  (sel_MEM_data_source[1] & data_sram_en)?1'b0:
                            (sel_IF_data_source[1] & inst_sram_en)?1'b0:1'b1;

    // Base RAM读使能信号，低电平有效
    assign base_ram_oe_n =  (sel_MEM_data_source[1] & data_sram_en & data_sram_we==4'b0000)?1'b0:
                            (sel_IF_data_source[1] & inst_sram_en & inst_sram_we==4'b0000)?1'b0:1'b1;

    // Base RAM写使能信号，低电平有效
    assign base_ram_we_n =  (sel_MEM_data_source[1] & data_sram_en & data_sram_we!=4'b0000)?1'b0:
                            (sel_IF_data_source[1] & inst_sram_en & inst_sram_we!=4'b0000)?1'b0:1'b1;

    ////////////////////////////////////////////////////////////////////////
    /// Ext RAM 控制信号生成

    // Ext RAM 写数据
    assign ext_ram_w_data =     (sel_MEM_data_source[0] & data_sram_we!=4'b0 & data_sram_en)?data_sram_wdata:
                                (sel_IF_data_source[0] & inst_sram_we!=4'b0 & inst_sram_en)?inst_sram_wdata:32'b0;

    assign ext_ram_data=ext_ram_we_n?32'bz:ext_ram_w_data;

    // Ext RAM 地址
    assign ext_ram_addr =   (sel_MEM_data_source[0] & data_sram_en)?data_sram_addr[21:2]:
                            (sel_IF_data_source[0] & inst_sram_en)?inst_sram_addr[21:2]:20'b0;

    // Ext RAM 字节使能信号，低电平有效
    assign ext_ram_be_n =   (sel_MEM_data_source[0] & data_sram_en & data_sram_we!=4'b0000)?~data_sram_we:
                            (sel_IF_data_source[0] & inst_sram_en & inst_sram_we!=4'b0000)?~inst_sram_we:4'b0;

    // Ext RAM 片选信号，低电平有效
    assign ext_ram_ce_n =   (sel_MEM_data_source[0] & data_sram_en)?1'b0:
                            (sel_IF_data_source[0] & inst_sram_en)?1'b0:1'b1;

    // Ext RAM 读使能信号，低电平有效
    assign ext_ram_oe_n =   (sel_MEM_data_source[0] & data_sram_en & data_sram_we==4'b0000)?1'b0:
                            (sel_IF_data_source[0] & inst_sram_en & inst_sram_we==4'b0000)?1'b0:1'b1;


    // Ext RAM 写使能信号，低电平有效
    assign ext_ram_we_n =   (sel_MEM_data_source[0] & data_sram_en & data_sram_we!=4'b0000)?1'b0:
                            (sel_IF_data_source[0] & inst_sram_en & inst_sram_we!=4'b0000)?1'b0:1'b1;

    ///////////////////////////////////////////////////////////////////////
    /// 处理Data RAM与Inst RAM读取内容；处理结构冒险

    assign base_ram_r_data = base_ram_oe_n?32'b0:base_ram_data;
    assign ext_ram_r_data  = ext_ram_oe_n?32'b0:ext_ram_data;


    always@(*)
    begin
        if(sel_IF_data_source[3])
            inst_sram_rdata <= {30'b0,SerialPort_state};
        else if(sel_IF_data_source[2])
            inst_sram_rdata <= {24'b0,RxD_FIFO_data_out};
        else if(sel_IF_data_source[1])
            inst_sram_rdata <= base_ram_r_data;
        else if(sel_IF_data_source[0])
            inst_sram_rdata <= ext_ram_r_data;
        else
            inst_sram_rdata <= 32'b0;
    end
    
    always@(*)
    begin
        if(sel_MEM_data_source[3])
            data_sram_rdata <= {30'b0,SerialPort_state};
        else if(sel_MEM_data_source[2])
            data_sram_rdata <= {24'b0,RxD_FIFO_data_out};
        else if(sel_MEM_data_source[1])
            data_sram_rdata <= base_ram_r_data;
        else if(sel_MEM_data_source[0])
            data_sram_rdata <= ext_ram_r_data;
        else
            data_sram_rdata <=0;
    end

    

    // 处理结构冒险
    assign sel_strcture_hazard =    ( (sel_IF_data_source[3]&sel_MEM_data_source[3])
                                    | (sel_IF_data_source[2]&sel_MEM_data_source[2])
                                    | (sel_IF_data_source[1]&sel_MEM_data_source[1])
                                    | (sel_IF_data_source[0]&sel_MEM_data_source[0]) )
                                    & (inst_sram_en & data_sram_en);

    //////////////////////////////////////////////////////////////////////
    /// 串口收发
    //接收模块
	async_receiver #(.ClkFrequency(40_000_000),.Baud(9600)) //接收模块，9600无检验位
		ext_uart_r(
			.clk				(clk            ),
			.RxD				(rxd            ),//串口输入
			.RxD_data_ready		(RxD_data_ready ),//数据接收到标志
			.RxD_clear			(RxD_clear      ),//清除接收标志
			.RxD_data			(RxD_data       )//接收到的一字节数据
		);
	fifo_generator_0 RXD_FIFO (
		.rst		(reset              ),
		.clk		(clk                ),
		.wr_en		(RxD_FIFO_w_en      ),//写使能
		.din		(RxD_data           ),//接收到的数据
		.full		(RxD_FIFO_full      ),//判满标志
	
		.rd_en		(RxD_FIFO_r_en      ),//读使能
		.dout		(RxD_FIFO_data_out  ),//传递给mem阶段读出的数据
		.empty		(RxD_FIFO_empty     )//判空标志
	);

	//发送模块
	fifo_generator_0 TXD_FIFO (
		.rst		(reset              ),
		.clk		(clk                ),
		.wr_en		(TxD_FIFO_w_en      ),//写使能
		.din		(TxD_FIFO_data_in   ),//需要发送的数据
		.full		(TxD_FIFO_full      ),//判满标志
	
		.rd_en		(TxD_FIFO_r_en      ),//读使能，为1时串口取出数据发送
		.dout		(TxD_data           ),//传递给串口待发送的数据
		.empty		(TxD_FIFO_empty     )//判空标志
	);
	async_transmitter #(.ClkFrequency(40_000_000),.Baud(9600)) //发送模块，9600无检验位
		ext_uart_t(
			.clk		(clk        ),
			.TxD		(txd        ),//串口输出
			.TxD_busy	(TxD_busy   ),//发送器忙状态指示
			.TxD_start	(TxD_start  ),//开始发送信号
			.TxD_data	(TxD_data   )//待发送的数据
		);
		
	// 串口的状态
	assign SerialPort_state={~RxD_FIFO_empty,~TxD_FIFO_full};
	
    // 串口接收端口逻辑
	assign RxD_clear = RxD_data_ready &(~RxD_FIFO_full); 	
	assign RxD_FIFO_w_en=RxD_data_ready;

    assign RxD_FIFO_r_en =  (sel_IF_data_source[2] & inst_sram_en & inst_sram_we==4'b0000)?1'b1:
                            (sel_MEM_data_source[2] & data_sram_en & data_sram_we==4'b0000)?1'b1:1'b0;
	
    // 串口发送端口逻辑
	assign TxD_start=(~TxD_busy)&(~TxD_FIFO_empty);

    assign TxD_FIFO_w_en =  (sel_IF_data_source[2] & inst_sram_en & inst_sram_we!=4'b0000)?1'b1:
                            (sel_MEM_data_source[2] & data_sram_en & data_sram_we!=4'b0000)?1'b1:1'b0;

    assign TxD_FIFO_data_in =   (sel_IF_data_source[2] & inst_sram_en & inst_sram_we!=4'b0000)?inst_sram_wdata[7:0]:
                                (sel_MEM_data_source[2] & data_sram_en & data_sram_we!=4'b0000)?data_sram_wdata[7:0]:8'b0;

	assign TxD_FIFO_r_en=TxD_start;
	


endmodule