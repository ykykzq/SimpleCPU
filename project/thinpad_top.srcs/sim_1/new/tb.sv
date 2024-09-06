`timescale 1ns / 1ps
`include"myCPU.h"
module tb;

wire clk_50M, clk_11M0592;

reg clock_btn = 0;         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
reg reset_btn = 0;         //BTN6手动复位按钮开关，带消抖电路，按下时为1

reg[3:0]  touch_btn;  //BTN1~BTN4，按钮开关，按下时为1
reg[31:0] dip_sw;     //32位拨码开关，拨到“ON”时为1

wire[15:0] leds;       //16位LED，输出时1点亮
wire[7:0]  dpy0;       //数码管低位信号，包括小数点，输出1点亮
wire[7:0]  dpy1;       //数码管高位信号，包括小数点，输出1点亮

wire txd;  //直连串口发送端
wire rxd;  //直连串口接收端

wire[31:0] base_ram_data; //BaseRAM数据，低8位与CPLD串口控制器共享
wire[19:0] base_ram_addr; //BaseRAM地址
wire[3:0] base_ram_be_n;  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
wire base_ram_ce_n;       //BaseRAM片选，低有效
wire base_ram_oe_n;       //BaseRAM读使能，低有效
wire base_ram_we_n;       //BaseRAM写使能，低有效

wire[31:0] ext_ram_data; //ExtRAM数据
wire[19:0] ext_ram_addr; //ExtRAM地址
wire[3:0] ext_ram_be_n;  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
wire ext_ram_ce_n;       //ExtRAM片选，低有效
wire ext_ram_oe_n;       //ExtRAM读使能，低有效
wire ext_ram_we_n;       //ExtRAM写使能，低有效

wire [22:0]flash_a;      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
wire [15:0]flash_d;      //Flash数据
wire flash_rp_n;         //Flash复位信号，低有效
wire flash_vpen;         //Flash写保护信号，低电平时不能擦除、烧写
wire flash_ce_n;         //Flash片选信号，低有效
wire flash_oe_n;         //Flash读使能信号，低有效
wire flash_we_n;         //Flash写使能信号，低有效
wire flash_byte_n;       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

//Windows需要注意路径分隔符的转义，例如"D:\\foo\\bar.bin"
parameter BASE_RAM_INIT_FILE ="C:\\Users\\31230\\Desktop\\NSCSCC2023\\myCPU_latest\\thinpad_top.srcs\\sim_1\\labs\\lab1\\lab1.bin";
//"C:\\Users\\31230\\Desktop\\NSCSCC2023\\myCPU_latest\\thinpad_top.srcs\\sim_1\\labs\\supervisor_v2.01\\kernel\\kernel.bin";
parameter EXT_RAM_INIT_FILE = "/tmp/eram.bin";    //ExtRAM初始化文件，请修改为实际的绝对路径
parameter FLASH_INIT_FILE = "C:\\Users\\31230\\Desktop\\NSCSCC2023\\myCPU_latest\\thinpad_top.srcs\\sim_1\\labs\\supervisor_v2.01\\kernel\\kernel.elf";    //Flash初始化文件，请修改为实际的绝对路径


//串口测试
	wire 		TxD_busy;
	wire 		TxD_start;
	wire[7:0] 	TxD_data;//要发送的数据
	reg  		TxD_FIFO_w_en;
	reg[7:0] 	TxD_FIFO_data_in;
	wire 		TxD_FIFO_full;
	wire 		TxD_FIFO_r_en;
	wire		TxD_FIFO_empty;
initial begin 
    //在这里可以自定义测试输入序列，例如：
    dip_sw = 32'h2;
	TxD_FIFO_w_en=1'b0;
    touch_btn = 0;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    for (integer i = 0; i < 20; i = i+1) begin
        #100; //等待100ns
        clock_btn = 1; //按下手工时钟按钮
        #100; //等待100ns
        clock_btn = 0; //松开手工时钟按钮
    end
	/*
	//lab2
	#25
	TxD_FIFO_w_en=1'b1;
	TxD_FIFO_data_in="T";
	#25
	TxD_FIFO_w_en=1'b0;
	*/
	
	//lab3_supervisor
	#25
	TxD_FIFO_w_en=1'b1;
	TxD_FIFO_data_in="A";//A
	//ori $t0, $zero, 0x1
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h34;
	#25
	TxD_FIFO_data_in=8'h08;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h01;
	
	
	//ori $t1, $zero, 0x1
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h34;
	#25
	TxD_FIFO_data_in=8'h09;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h01;
	
	//xor $v0, $v0,   $v0
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h08;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h42;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h26;
	
	//ori $v1, $zero, 8 
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h0c;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h28;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h03;
	#25
	TxD_FIFO_data_in=8'h34;
	
	//lui $a0, 0x8040
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h3c;
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h80;
	#25
	TxD_FIFO_data_in=8'h40;
	
	//loop:
	//addu  $t2, $t0, $t1
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h14;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h01;
	#25
	TxD_FIFO_data_in=8'h09;
	#25
	TxD_FIFO_data_in=8'h50;
	#25
	TxD_FIFO_data_in=8'h21;
	//ori   $t0, $t1, 0x0 
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h18;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h35;
	#25
	TxD_FIFO_data_in=8'h28;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	//ori   $t1, $t2, 0x0
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h1c;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h35;
	#25
	TxD_FIFO_data_in=8'h49;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	//sw    $t1, 0($a0)
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h20;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'hac;
	#25
	TxD_FIFO_data_in=8'h89;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	//addiu $a0, $a0, 4 
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h24;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h24;
	#25
	TxD_FIFO_data_in=8'h84;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h04;
	//addiu $v0, $v0, 1  
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h28;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h24;
	#25
	TxD_FIFO_data_in=8'h42;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h01;
	//bne   $v0, $v1, loop
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h2c;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h14;
	#25
	TxD_FIFO_data_in=8'h43;
	#25
	TxD_FIFO_data_in=8'hff;
	#25
	TxD_FIFO_data_in=8'hf9;
	//ori   $zero, $zero, 0  # noop
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h30;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h34;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	// jr    $ra
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h34;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h03;
	#25
	TxD_FIFO_data_in=8'he0;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h08;
	//ori   $zero, $zero, 0  # noop
	#25
	TxD_FIFO_data_in="A";//A
	
	#25
	TxD_FIFO_data_in=8'h38;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	#25
	TxD_FIFO_data_in=8'h04;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	#25
	TxD_FIFO_data_in=8'h34;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	//D function
	#25
	TxD_FIFO_data_in="D";
	//0X80100000
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;
	
	//len(USER_PROGRAM)
	#25
	TxD_FIFO_data_in=8'h3c;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	
	//G function
	#25
	TxD_FIFO_data_in="G";
	//0X80100000
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h00;
	#25
	TxD_FIFO_data_in=8'h10;
	#25
	TxD_FIFO_data_in=8'h80;

	//R function
	#25
	TxD_FIFO_data_in="R";
	
	#25
	TxD_FIFO_w_en=1'b0;
	
end


//测试串口
	// PLL分频示例
	wire locked, clk_10M, clk_20M;
	pll_example clock_gen 
	(
	// Clock in ports
	.clk_in1(clk_50M),  // 外部时钟输入
	// Clock out ports
	.clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
	.clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
	// Status and control signals
	.reset(reset_btn), // PLL复位输入
	.locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
						// 后级电路复位信号应当由它生成（见下）
	);

	
//发送模块
	fifo_generator_0 TXD_FIFO (
		.rst		(reset_btn),
		.clk		(clk_10M),
		.wr_en		(TxD_FIFO_w_en),//写使能
		.din		(TxD_FIFO_data_in),//需要发送的数据
		.full		(TxD_FIFO_full),//判满标志
	
		.rd_en		(TxD_FIFO_r_en),//读使能，为1时串口取出数据发送
		.dout		(TxD_data),//传递给串口待发送的数据
		.empty		(TxD_FIFO_empty)//判空标志
	);
	async_transmitter #(.ClkFrequency(40000000),.Baud(960000)) //发送模块，9600无检验位
		test_rxd(
			.clk		(clk_10M),
			.TxD		(rxd),//串口输出
			.TxD_busy	(TxD_busy),//发送器忙状态指示
			.TxD_start	(TxD_start),//开始发送信号
			.TxD_data	(TxD_data)//待发送的数据
		);
	assign TxD_start=(~TxD_busy)&(~TxD_FIFO_empty);
	assign TxD_FIFO_r_en=TxD_start;



// 待测试用户设计
thinpad_top dut(
    .clk_50M(clk_50M),
    .clk_11M0592(clk_11M0592),
    .clock_btn(clock_btn),
    .reset_btn(reset_btn),
    .touch_btn(touch_btn),
    .dip_sw(dip_sw),
    .leds(leds),
    .dpy1(dpy1),
    .dpy0(dpy0),
    .txd(txd),
    .rxd(rxd),
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .base_ram_be_n(base_ram_be_n),
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .ext_ram_be_n(ext_ram_be_n),
    .flash_d(flash_d),
    .flash_a(flash_a),
    .flash_rp_n(flash_rp_n),
    .flash_vpen(flash_vpen),
    .flash_oe_n(flash_oe_n),
    .flash_ce_n(flash_ce_n),
    .flash_byte_n(flash_byte_n),
    .flash_we_n(flash_we_n)
);
// 时钟源
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M    (clk_50M)
);

// BaseRAM 仿真模型
sram_model base1(/*autoinst*/
            .DataIO(base_ram_data[15:0]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[0]),
            .UB_n(base_ram_be_n[1]));
sram_model base2(/*autoinst*/
            .DataIO(base_ram_data[31:16]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[2]),
            .UB_n(base_ram_be_n[3]));
// ExtRAM 仿真模型
sram_model ext1(/*autoinst*/
            .DataIO(ext_ram_data[15:0]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[0]),
            .UB_n(ext_ram_be_n[1]));
sram_model ext2(/*autoinst*/
            .DataIO(ext_ram_data[31:16]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[2]),
            .UB_n(ext_ram_be_n[3]));
// Flash 仿真模型
x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
    .A(flash_a[1+:22]), 
    .DQ(flash_d), 
    .W_N(flash_we_n),    // Write Enable 
    .G_N(flash_oe_n),    // Output Enable
    .E_N(flash_ce_n),    // Chip Enable
    .L_N(1'b0),    // Latch Enable
    .K(1'b0),      // Clock
    .WP_N(flash_vpen),   // Write Protect
    .RP_N(flash_rp_n),   // Reset/Power-Down
    .VDD('d3300), 
    .VDDQ('d3300), 
    .VPP('d1800), 
    .Info(1'b1));

initial begin 
    wait(flash_byte_n == 1'b0);
    $display("8-bit Flash interface is not supported in simulation!");
    $display("Please tie flash_byte_n to high");
    $stop;
end

// 从文件加载 BaseRAM
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open BaseRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        base1.mem_array0[i] = tmp_array[i][24+:8];
        base1.mem_array1[i] = tmp_array[i][16+:8];
        base2.mem_array0[i] = tmp_array[i][8+:8];
        base2.mem_array1[i] = tmp_array[i][0+:8];
    end
end

// 从文件加载 ExtRAM
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open ExtRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        ext1.mem_array0[i] = tmp_array[i][24+:8];
        ext1.mem_array1[i] = tmp_array[i][16+:8];
        ext2.mem_array0[i] = tmp_array[i][8+:8];
        ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
end
endmodule
