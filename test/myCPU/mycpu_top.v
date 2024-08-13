
`include"./include/myCPU.h"
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    // 时钟信号与复位信号
    assign reset=~resetn;

    // 流水级控制
    wire            IPD_allow_in    ;
    wire            IF_to_IPD_valid ;

    wire            ID_allow_in     ;
    wire            IPD_to_ID_valid ;

    wire            EXE_allow_in    ;
    wire            ID_to_EXE_valid ;

    wire            MEM_allow_in    ;    
    wire            EXE_to_MEM_valid;    

    wire            WB_allow_in     ;
    wire            MEM_to_WB_valid ;

    // 流水级数据交互
    wire [`IF_TO_IPD_BUS_WD-1:0]    IF_to_IPD_bus   ;
    wire [`IPD_TO_ID_BUS_WD-1:0]    IPD_to_ID_bus   ;
    wire [`ID_TO_EXE_BUS_WD-1:0]    ID_to_EXE_bus   ;
    wire [`EXE_TO_MEM_BUS_WD-1:0]   EXE_to_MEM_bus  ;
    wire [`MEM_TO_WB_BUS_WD-1:0]    MEM_to_WB_bus   ;
    wire [`WB_to_ID_bus_WD-1:0]     WB_to_ID_bus    ;
    
    wire [`ID_TO_IF_BUS_WD-1:0]     ID_to_IF_bus    ;
    wire [`ID_TO_IPD_BUS_WD-1:0]    ID_to_IPD_bus   ;


    IF_stage IF_stage(
	    .clk                (clk),
	    .reset              (reset),

	    //流水线数据传输
	    .ID_to_IF_bus       (ID_to_IF_bus),
	    .IF_to_IPD_bus      (IF_to_IPD_bus),
	
	    //连接指令RAM()
	    .inst_ram_en        (inst_sram_en),//(读)使能
	    .inst_ram_addr      (inst_sram_addr),
	    .inst_ram_w_en      (inst_sram_we),
	    .inst_ram_w_data    (inst_sram_wdata),//实际上用不到指令RAM的写
    
	    //流水线控制
	    .IPD_allow_in       (IPD_allow_in),
	    .IF_to_IPD_valid    (IF_to_IPD_valid)
    );

    IPreD_stage IPreD_stage(
        .clk                (clk),
	    .reset              (reset),

        //流水线数据传输
	    .IF_to_IPD_bus      (IF_to_IPD_bus),
	    .IPD_to_ID_bus      (IPD_to_ID_bus),
        .ID_to_IPD_bus      (ID_to_IPD_bus),
        //inst RAM
        .inst_ram_r_data    (inst_sram_rdata),
	
	    //流水线控制
	    .ID_allow_in        (ID_allow_in),
	    .IF_to_IPD_valid    (IF_to_IPD_valid),
	    .IPD_allow_in       (IPD_allow_in),
	    .IPD_to_ID_valid    (IPD_to_ID_valid)
    );

    ID_stage ID_stage(
	    .clk                (clk),
	    .reset              (reset),

	    //流水线数据传输
        .IPD_to_ID_bus      (IPD_to_ID_bus),
	    .ID_to_EXE_bus      (ID_to_EXE_bus),
    
	    .ID_to_IF_bus       (ID_to_IF_bus),  
        .ID_to_IPD_bus      (ID_to_IPD_bus),
    
	    .WB_to_ID_bus       (WB_to_ID_bus),  

	    //流水线控制
	    .EXE_allow_in       (EXE_allow_in),
	    .IPD_to_ID_valid    (IPD_to_ID_valid),
	    .ID_allow_in        (ID_allow_in),
	    .ID_to_EXE_valid    (ID_to_EXE_valid)
    );

    EXE_stage EXE_stage(
	    .clk                (clk),
	    .reset              (reset),
	
	    // 流水线数据传送
	    .ID_to_EXE_bus      (ID_to_EXE_bus),
	    .EXE_to_MEM_bus     (EXE_to_MEM_bus),
    
	    // 流水线控制
	    .MEM_allow_in       (MEM_allow_in),
	    .EXE_to_MEM_valid   (EXE_to_MEM_valid),
	    .ID_to_EXE_valid    (ID_to_EXE_valid),
	    .EXE_allow_in       (EXE_allow_in),
	
	    // 连接Data RAM
	    .data_ram_en        (data_sram_en),
	    .data_ram_addr      (data_sram_addr),
	    .data_ram_w_en      (data_sram_we),
	    .data_ram_w_data    (data_sram_wdata)
    );

    MEM_stage MEM_stage(
        .clk                (clk),
	    .reset              (reset),
	
	// 流水级数据交互
	    .EXE_to_MEM_bus     (EXE_to_MEM_bus),
	    .MEM_to_WB_bus      (MEM_to_WB_bus),
	
    // 来自Data RAM的数据
	    .data_ram_r_data    (data_sram_rdata),
	
	//流水线控制
	    .EXE_to_MEM_valid   (EXE_to_MEM_valid),
	    .MEM_allow_in       (MEM_allow_in),
	    .WB_allow_in        (WB_allow_in),
	    .MEM_to_WB_valid    (MEM_to_WB_valid)
    );

    WB_stage WB_stage(
	    .clk                (clk),
	    .reset              (reset),
	
	// 流水级数据交互
	    .MEM_to_WB_bus      (MEM_to_WB_bus),

	    .WB_to_ID_bus       (WB_to_ID_bus),
	
	//debug的接口
	    .debug_wb_pc        (debug_wb_pc),
        .debug_wb_rf_wen    (debug_wb_rf_we),
        .debug_wb_rf_wnum   (debug_wb_rf_wnum),
        .debug_wb_rf_wdata  (debug_wb_rf_wdata),
	//流水线控制
	    .MEM_to_WB_valid    (MEM_to_WB_valid),
	    .WB_allow_in        (WB_allow_in)
    );
    

endmodule
