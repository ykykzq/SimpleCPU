/**
 * @file myCPU_top.v
 * @author ykykzq
 * @brief 微处理器顶层模块，将Core与MMU连接起来，构成一个完整系统
 * @version 0.1
 * @date 2024-08-29
 *
 */

module myCPU_top (
    input  wire        clk,
    input  wire        reset,

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd   //直连串口接收端
);

    // inst sram interface
    wire        inst_sram_en        ;
    wire [ 3:0] inst_sram_we        ;
    wire [31:0] inst_sram_addr      ;
    wire [31:0] inst_sram_wdata     ;
    wire [31:0] inst_sram_rdata     ;
    // data sram interface
    wire        data_sram_en        ;
    wire [ 3:0] data_sram_we        ;
    wire [31:0] data_sram_addr      ;
    wire [31:0] data_sram_wdata     ;
    wire [31:0] data_sram_rdata     ;
    // trace debug interface
    wire [31:0] debug_wb_pc         ;
    wire [ 3:0] debug_wb_rf_we      ;
    wire [ 4:0] debug_wb_rf_wnum    ;
    wire [31:0] debug_wb_rf_wdata   ;

    // 发生结构冒险控制信号
    wire    sel_strcture_hazard;

////////////////////////////////////////////////////////////
/// 处理器核
    YK_Core YK_Core(
        .clk                 (clk               ),
        .reset               (reset             ),
        // inst sram interface
        .inst_sram_en        (inst_sram_en      ),
        .inst_sram_we        (inst_sram_we      ),
        .inst_sram_addr      (inst_sram_addr    ),
        .inst_sram_wdata     (inst_sram_wdata   ),
        .inst_sram_rdata     (inst_sram_rdata   ),
        // data sram interface
        .data_sram_en        (data_sram_en      ),
        .data_sram_we        (data_sram_we      ),
        .data_sram_addr      (data_sram_addr    ),
        .data_sram_wdata     (data_sram_wdata   ),
        .data_sram_rdata     (data_sram_rdata   ),
        // 发生结构冒险控制信号
        .sel_strcture_hazard(sel_strcture_hazard)
);

//////////////////////////////////////////////////////////////
/// MMU

    MMU MMU(
        .clk                 (clk               ),
        .reset               (reset             ),
        // inst sram interface
        .inst_sram_en        (inst_sram_en      ),
        .inst_sram_we        (inst_sram_we      ),
        .inst_sram_addr      (inst_sram_addr    ),
        .inst_sram_wdata     (inst_sram_wdata   ),
        .inst_sram_rdata     (inst_sram_rdata   ),
        // data sram interface
        .data_sram_en        (data_sram_en      ),
        .data_sram_we        (data_sram_we      ),
        .data_sram_addr      (data_sram_addr    ),
        .data_sram_wdata     (data_sram_wdata   ),
        .data_sram_rdata     (data_sram_rdata   ),

        // BaseRAM信号
        .base_ram_data      (base_ram_data      ),
        .base_ram_addr      (base_ram_addr      ),
        .base_ram_be_n      (base_ram_be_n      ),
        .base_ram_ce_n      (base_ram_ce_n      ),
        .base_ram_oe_n      (base_ram_oe_n      ),
        .base_ram_we_n      (base_ram_we_n      ),

        // ExtRAM信号   
        .ext_ram_data       (ext_ram_data       ),
        .ext_ram_addr       (ext_ram_addr       ),
        .ext_ram_be_n       (ext_ram_be_n       ),
        .ext_ram_ce_n       (ext_ram_ce_n       ),
        .ext_ram_oe_n       (ext_ram_oe_n       ),
        .ext_ram_we_n       (ext_ram_we_n       ),

        // 直连串口信号 
        .txd                (txd                ),
        .rxd                (rxd                ),

        // 发生结构冒险控制信号
        .sel_strcture_hazard(sel_strcture_hazard)
    );


endmodule