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
    output wire [31:0] inst_sram_rdata,
    // data sram interface
    input  wire        data_sram_en,
    input  wire [ 3:0] data_sram_we,
    input  wire [31:0] data_sram_addr,
    input  wire [31:0] data_sram_wdata,
    output wire [31:0] data_sram_rdata,

    // BaseRAM信号
    inout  wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output reg[19:0] base_ram_addr, //BaseRAM地址
    output reg[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce_n,       //BaseRAM片选，低有效
    output reg base_ram_oe_n,       //BaseRAM读使能，低有效
    output reg base_ram_we_n,       //BaseRAM写使能，低有效

    // ExtRAM信号
    inout  wire[31:0] ext_ram_data,  //ExtRAM数据
    output reg[19:0] ext_ram_addr, //ExtRAM地址
    output reg[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg ext_ram_ce_n,       //ExtRAM片选，低有效
    output reg ext_ram_oe_n,       //ExtRAM读使能，低有效
    output reg ext_ram_we_n,       //ExtRAM写使能，低有效

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
	
	// 接收队列
	wire 		RxD_FIFO_w_en;
	wire 		RxD_FIFO_full;
	wire 		RxD_FIFO_r_en;
	wire[7:0] 	RxD_FIFO_data_out;
	wire		RxD_FIFO_empty;
	// 发送队列
	wire 		TxD_FIFO_w_en;
	wire[7:0] 	TxD_FIFO_data_in;
	wire 		TxD_FIFO_full;
	wire 		TxD_FIFO_r_en;
	wire		TxD_FIFO_empty;


    // MEM读写数据来源
    wire[3:0]   sel_MEM_data_source;
    // IF读写数据来源
    wire[3:0]   sel_IF_data_source;

    /////////////////////////////////////////////////////////////////////
    /// 地址映射目标信号生成


    /*
    MEM阶段读取数据的来源
        +-------------+-------------------+
        | sel_MEM_data_source | Data Source       |
        +-------------+-------------------+
        | 4'b1000     | Serial Port State |
        | 4'b0100     | Serial Port Data  |
        | 4'b0010     | Base RAM          |
        | 4'b0001     | Ext RAM           |
        +-------------+-------------------+
    */
    assign sel_MEM_data_source[3] = data_sram_addr==32'hBFD0_03FC;
    assign sel_MEM_data_source[2] = data_sram_addr==32'hBFD0_03F8;
    assign sel_MEM_data_source[1] = (data_sram_addr>=32'h8000_0000)&(data_sram_addr<32'h8040_0000);
    assign sel_MEM_data_source[0] = (data_sram_addr>=32'h8040_0000)&(data_sram_addr<32'h8080_0000);

    /*
    IF阶段读取数据的来源
        +------------+-------------------+
        | sel_IF_data_source | Data Source       |
        +------------+-------------------+
        | 4'b1000    | Serial Port State |
        | 4'b0100    | Serial Port Data  |
        | 4'b0010    | Base RAM          |
        | 4'b0001    | Ext RAM           |
        +------------+-------------------+

    */
    assign sel_IF_data_source[3] = inst_sram_addr==32'hBFD0_03FC;
    assign sel_IF_data_source[2] = inst_sram_addr==32'hBFD0_03F8;
    assign sel_IF_data_source[1] = (inst_sram_addr>=32'h8000_0000)&(inst_sram_addr<32'h8040_0000);
    assign sel_IF_data_source[0] = (inst_sram_addr>=32'h8040_0000)&(inst_sram_addr<32'h8080_0000);


    /////////////////////////////////////////////////////////////////////////
    /// Base RAM信号生成


    // Base RAM读写数据
    always@(posedge clk)
    begin
        if(reset)
            base_ram_data<=32'bz;
        else if(sel_IF_data_source[1] & inst_sram_we!=4'b0 & inst_sram_en)
            base_ram_data<=inst_sram_wdata;
        else if(sel_MEM_data_source[1] & data_sram_we!=4'b0 & data_sram_en)
            base_ram_data<=data_sram_wdata;
        else 
            base_ram_data<=32'bz;
    end

    // Base RAM地址
    always@(posedge clk)
    begin
        if(reset)
            base_ram_addr<=32'b0;
        else if(sel_IF_data_source[1] & inst_sram_en)
            base_ram_addr<=inst_sram_addr[21:2];
        else if(sel_MEM_data_source[1] & data_sram_en)
            base_ram_addr<=data_sram_addr[21:2];
        else 
            base_ram_addr<=32'b0;
    end

    // Base RAM字节使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            base_ram_be_n <= 4'b0000;
        else if(sel_IF_data_source[1] & inst_sram_en)
            base_ram_be_n <= ~inst_sram_we;
        else if(sel_MEM_data_source[1] & data_sram_en)
            base_ram_be_n <= ~data_sram_we;
        else 
            base_ram_be_n <= 4'b0000;
    end

    // Base RAM片选信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            base_ram_ce_n <= 1'b1;
        else if(sel_IF_data_source[1] & inst_sram_en)
            base_ram_ce_n <= 1'b0;
        else if(sel_MEM_data_source[1] & data_sram_en)
            base_ram_ce_n <= 1'b0;
        else 
            base_ram_ce_n <= 1'b1;
    end

    // Base RAM读使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            base_ram_oe_n <= 1'b1;
        else if(sel_IF_data_source[1] & inst_sram_en)
            if(inst_sram_we==4'b0)
                base_ram_oe_n <= 1'b0;
            else 
                base_ram_oe_n <= 1'b1;
        else if(sel_MEM_data_source[1] & data_sram_en)
            if(data_sram_we==4'b0)
                base_ram_oe_n <= 1'b0;
            else
                base_ram_oe_n <= 1'b1;
        else 
            base_ram_oe_n <= 1'b1;
    end

    // Base RAM写使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            base_ram_we_n <= 1'b1;
        else if(sel_IF_data_source[1] & inst_sram_en)
            if(inst_sram_we==4'b0)
                base_ram_we_n <= 1'b0;
            else 
                base_ram_we_n <= 1'b1;
        else if(sel_MEM_data_source[1] & data_sram_en)
            if(data_sram_we==4'b0)
                base_ram_we_n <= 1'b0;
            else
                base_ram_we_n <= 1'b1;
        else 
            base_ram_we_n <= 1'b1;
    end

    ////////////////////////////////////////////////////////////////////////
    /// Ext RAM 控制信号生成

    // Ext RAM 读写数据
    always@(posedge clk)
    begin
        if(reset)
            ext_ram_data<=32'bz;
        else if(sel_IF_data_source[0] & inst_sram_we!=4'b0 & inst_sram_en)
            ext_ram_data<=inst_sram_wdata;
        else if(sel_MEM_data_source[0] & data_sram_we!=4'b0 & data_sram_en)
            ext_ram_data<=data_sram_wdata;
        else 
            ext_ram_data<=32'bz;
    end

    // Ext RAM 地址
    always@(posedge clk)
    begin
        if(reset)
            ext_ram_addr<=32'b0;
        else if(sel_IF_data_source[0] & inst_sram_en)
            ext_ram_addr<=inst_sram_addr[21:2];
        else if(sel_MEM_data_source[0] & data_sram_en)
            ext_ram_addr<=data_sram_addr[21:2];
        else 
            ext_ram_addr<=32'b0;
    end

    // Ext RAM 字节使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            ext_ram_be_n <= 4'b0000;
        else if(sel_IF_data_source[0] & inst_sram_en)
            ext_ram_be_n <= ~inst_sram_we;
        else if(sel_MEM_data_source[0] & data_sram_en)
            ext_ram_be_n <= ~data_sram_we;
        else 
            ext_ram_be_n <= 4'b0000;
    end

    // Ext RAM 片选信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            ext_ram_ce_n <= 1'b1;
        else if(sel_IF_data_source[0] & inst_sram_en)
            ext_ram_ce_n <= 1'b0;
        else if(sel_MEM_data_source[0] & data_sram_en)
            ext_ram_ce_n <= 1'b0;
        else 
            ext_ram_ce_n <= 1'b1;
    end

    // Ext RAM 读使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            base_ram_oe_n <= 1'b1;
        else if(sel_IF_data_source[1] & inst_sram_en)
            if(inst_sram_we==4'b0)
                base_ram_oe_n <= 1'b0;
            else 
                base_ram_oe_n <= 1'b1;
        else if(sel_MEM_data_source[1] & data_sram_en)
            if(data_sram_we==4'b0)
                base_ram_oe_n <= 1'b0;
            else
                base_ram_oe_n <= 1'b1;
        else 
            base_ram_oe_n <= 1'b1;
    end


    // Ext RAM 写使能信号，低电平有效
    always@(posedge clk)
    begin
        if(reset)
            ext_ram_we_n <= 1'b1;
        else if(sel_IF_data_source[0] & inst_sram_en)
            if(inst_sram_we==4'b0)
                ext_ram_we_n <= 1'b0;
            else 
                ext_ram_we_n <= 1'b1;
        else if(sel_MEM_data_source[0] & data_sram_en)
            if(data_sram_we==4'b0)
                ext_ram_we_n <= 1'b0;
            else
                ext_ram_we_n <= 1'b1;
        else 
            ext_ram_we_n <= 1'b1;
    end

    ///////////////////////////////////////////////////////////////////////
    /// 处理Data RAM与Inst RAM读取内容；处理结构冒险

    always@(*)
    begin
        if(sel_MEM_data_source[3])
            data_sram_rdata <= {30'b0,SerialPort_state};
        else if(sel_MEM_data_source[2])
            data_sram_rdata <= {24'b0,RxD_FIFO_data_out};
        else if(sel_MEM_data_source[1])
            data_sram_rdata <= base_ram_data;
        else if(sel_MEM_data_source[0])
            data_sram_rdata <= ext_ram_data;
        else
            data_sram_rdata <=0;
    end

     always@(*)
    begin
        if(sel_IF_data_source[3])
            inst_sram_rdata <= {30'b0,SerialPort_state};
        else if(sel_IF_data_source[2])
            inst_sram_rdata <= {24'b0,RxD_FIFO_data_out};
        else if(sel_IF_data_source[1])
            inst_sram_rdata <= base_ram_data;
        else if(sel_IF_data_source[0])
            inst_sram_rdata <= ext_ram_data;
        else
            inst_sram_rdata <= 32'b0;
    end

    // 处理结构冒险
    assign sel_strcture_hazard = sel_IF_data_source==sel_MEM_data_source;

    //////////////////////////////////////////////////////////////////////
    /// 串口收发
    //接收模块
	async_receiver #(.ClkFrequency(10_000_000),.Baud(9600)) //接收模块，9600无检验位
		ext_uart_r(
			.clk				(clk            ),
			.RxD				(RxD)           ,//串口输入
			.RxD_data_ready		(RxD_data_ready),//数据接收到标志
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
	async_transmitter #(.ClkFrequency(55000000),.Baud(9600)) //发送模块，9600无检验位
		ext_uart_t(
			.clk		(clk        ),
			.TxD		(TxD        ),//串口输出
			.TxD_busy	(TxD_busy   ),//发送器忙状态指示
			.TxD_start	(TxD_start  ),//开始发送信号
			.TxD_data	(TxD_data   )//待发送的数据
		);
		
	// 串口的状态
	assign SerialPort_state={~RxD_FIFO_empty,~TxD_FIFO_full};
	
    // 串口接收端口逻辑
	assign RxD_clear = RxD_data_ready &(~RxD_FIFO_full); 	
	assign RxD_FIFO_w_en=RxD_data_ready;

    always@(posedge clk)
    begin
        if(reset)
            RxD_FIFO_r_en <= 1'b0;
       else if(sel_IF_data_source[2] & inst_sram_en)
            if(inst_sram_we==4'b0)
                RxD_FIFO_r_en <= 1'b1;
            else 
                RxD_FIFO_r_en <= 1'b0;
        else if(sel_MEM_data_source[2] & data_sram_en)
            if(data_sram_we==4'b0)
                RxD_FIFO_r_en <= 1'b1;
            else
                RxD_FIFO_r_en <= 1'b0;
        else 
            RxD_FIFO_r_en <= 1'b0;
    end 
	
    // 串口发送端口逻辑
	assign TxD_start=(~TxD_busy)&(~TxD_FIFO_empty);
    always@(posedge clk)
    begin
        if(reset)
            TxD_FIFO_w_en <= 1'b0;
       else if(sel_IF_data_source[2] & inst_sram_en)
            if(inst_sram_we==4'b0)
                TxD_FIFO_w_en <= 1'b0;
            else 
                TxD_FIFO_w_en <= 1'b1;
        else if(sel_MEM_data_source[2] & data_sram_en)
            if(data_sram_we==4'b0)
                TxD_FIFO_w_en <= 1'b0;
            else
                TxD_FIFO_w_en <= 1'b1;
        else 
            TxD_FIFO_w_en <= 1'b0;
    end 

    always@(posedge clk)
    begin
        if(reset)
            TxD_FIFO_data_in <= 8'b0;
       else if(sel_IF_data_source[2] & inst_sram_en)
            if(inst_sram_we==4'b0)
                TxD_FIFO_data_in <= 8'b0;
            else 
                TxD_FIFO_data_in <= data_sram_wdata[7:0];
        else if(sel_MEM_data_source[2] & data_sram_en)
            if(data_sram_we==4'b0)
                TxD_FIFO_data_in <= 8'b0;
            else
                TxD_FIFO_data_in <= data_sram_wdata[7:0];
        else 
            TxD_FIFO_data_in <= 8'b0;
    end 
	assign TxD_FIFO_r_en=TxD_start;
	


endmodule