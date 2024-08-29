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

endmodule