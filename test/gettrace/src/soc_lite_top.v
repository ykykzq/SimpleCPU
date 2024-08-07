/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

//*************************************************************************
//   > File Name   : soc_top.v
//   > Description : SoC, included cpu, 2 x 3 bridge,
//                   inst ram, confreg, data ram
// 
//           -------------------------
//           |           cpu         |
//           -------------------------
//         inst|                  | data
//             |                  | 
//             |        ---------------------
//             |        |    1 x 2 bridge   |
//             |        ---------------------
//             |             |            |           
//             |             |            |           
//      -------------   -----------   -----------
//      | inst ram  |   | data ram|   | confreg |
//      -------------   -----------   -----------
//
//   > Author      : LOONGSON
//   > Date        : 2017-08-04
//*************************************************************************


`define INST_COE "../../../../../func/obj/inst_ram.mif"

module soc_lite_top #(parameter SIMULATION=1'b0)
(
    input  wire        resetn,
    input  wire        clk,

    //------gpio-------
    output wire [15:0] led,
    output wire [1 :0] led_rg0,
    output wire [1 :0] led_rg1,
    output wire [7 :0] num_csn,
    output wire [6 :0] num_a_g,
    input  wire [7 :0] switch,
    output wire [3 :0] btn_key_col,
    input  wire [3 :0] btn_key_row,
    input  wire [1 :0] btn_step
);
//debug signals
wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_wen;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;

//clk and resetn
reg cpu_resetn;
always @(posedge clk)
begin
    cpu_resetn <= resetn;
end

wire        data_sram_en;
wire [3 :0] data_sram_wen;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire [31:0] data_sram_rdata;

//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_wen;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;

wire        cpu_inst_en;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_rdata;

//conf
wire        conf_en;
wire [3 :0] conf_wen;
wire [31:0] conf_addr;
wire [31:0] conf_wdata;
wire [31:0] conf_rdata;

//cpu
SimpleLACoreWrapRAM cpu(
    .clock                   (clk   ),
    .reset                   (~cpu_resetn),  //low active

    .io_ipi                  (1'b0),
    .io_interrupt            (8'h00),

    .io_inst_en                ( cpu_inst_en     ),
    .io_inst_addr              ( cpu_inst_addr   ),
    .io_inst_rdata             ( cpu_inst_rdata  ),

    .io_data_en                ( cpu_data_en     ),
    .io_data_wen               ( cpu_data_wen    ),
    .io_data_addr              ( cpu_data_addr   ),
    .io_data_wdata             ( cpu_data_wdata  ),
    .io_data_rdata             ( cpu_data_rdata  ),
     
    //debug      
    .io_debug_pc             (debug_wb_pc      ),
    .io_debug_wen            (debug_wb_rf_wen  ),
    .io_debug_wnum           (debug_wb_rf_wnum ),
    .io_debug_wdata          (debug_wb_rf_wdata)
); 

bridge_1x2 bridge_1x2(
    .clk             ( clk         ), // i, 1                 
    .resetn          ( cpu_resetn      ), // i, 1                 

    .cpu_data_en     ( cpu_data_en     ), // i, 4                 
    .cpu_data_wen    ( cpu_data_wen    ), // i, 4                 
    .cpu_data_addr   ( cpu_data_addr   ), // i, 32                
    .cpu_data_wdata  ( cpu_data_wdata  ), // i, 32                
    .cpu_data_rdata  ( cpu_data_rdata  ), // o, 32                

    .data_sram_en    ( data_sram_en    ), // o, 4                 
    .data_sram_wen   ( data_sram_wen   ), // o, 4                 
    .data_sram_addr  ( data_sram_addr  ), // o, `DATA_RAM_ADDR_LEN
    .data_sram_wdata ( data_sram_wdata ), // o, 32                
    .data_sram_rdata ( data_sram_rdata ), // i, 32                

    .conf_en         ( conf_en         ), // o, 1                 
    .conf_wen        ( conf_wen        ), // o, 4                 
    .conf_addr       ( conf_addr       ), // o, 32                
    .conf_wdata      ( conf_wdata      ), // o, 32                
    .conf_rdata      ( conf_rdata      )  // i, 32                
);

wire data_sram_addr_need_highest_4bits;
assign data_sram_addr_need_highest_4bits = data_sram_addr[31:28] != 4'h0 &&
                                           data_sram_addr[31:28] != 4'h1 &&
                                           data_sram_addr[31:28] != 4'h7 &&
                                           data_sram_addr[31:28] != 4'hb;
wire [31:0] data_sram_addr_mapped;
assign data_sram_addr_mapped = data_sram_addr_need_highest_4bits ? {12'b0, 4'hf, data_sram_addr[31:28], data_sram_addr[11:0]} : data_sram_addr;

wire inst_sram_addr_need_highest_4bits;
assign inst_sram_addr_need_highest_4bits = cpu_inst_addr[31:28] != 4'h0 &&
                                           cpu_inst_addr[31:28] != 4'h1 &&
                                           cpu_inst_addr[31:28] != 4'h7 &&
                                           cpu_inst_addr[31:28] != 4'hb;
wire [31:0] inst_sram_addr_mapped;
assign inst_sram_addr_mapped = inst_sram_addr_need_highest_4bits ? {12'b0, 4'hf, cpu_inst_addr[31:28], cpu_inst_addr[11:0]} : cpu_inst_addr;

reg [31:0] data_ram [262144:0];
assign data_sram_rdata = data_sram_en ? data_ram[data_sram_addr_mapped[19:2]] : 32'h00000000;
assign cpu_inst_rdata = cpu_inst_en ? (data_ram[inst_sram_addr_mapped[19:2]]) : 32'h00000000;
always @(posedge clk)
if(data_sram_en && |data_sram_wen) data_ram[data_sram_addr_mapped[19:2]] <= {
    data_sram_wen[3] ? data_sram_wdata [31:24] : data_ram[data_sram_addr_mapped[19:2]][31:24],
    data_sram_wen[2] ? data_sram_wdata [23:16] : data_ram[data_sram_addr_mapped[19:2]][23:16],
    data_sram_wen[1] ? data_sram_wdata [15:8] : data_ram[data_sram_addr_mapped[19:2]][15:8],
    data_sram_wen[0] ? data_sram_wdata [7:0] : data_ram[data_sram_addr_mapped[19:2]][7:0]
};

initial begin
    $readmemb(`INST_COE, data_ram);
end


//confreg
confreg #(.SIMULATION(SIMULATION)) confreg
(
    .clk         ( clk        ),  // i, 1   
    .timer_clk   ( clk        ),  // i, 1   
    .resetn      ( cpu_resetn ),  // i, 1    
    .conf_en     ( conf_en    ),  // i, 1      
    .conf_wen    ( conf_wen   ),  // i, 4      
    .conf_addr   ( conf_addr  ),  // i, 32        
    .conf_wdata  ( conf_wdata ),  // i, 32         
    .conf_rdata  ( conf_rdata ),  // o, 32         
    .led         ( led        ),  // o, 16   
    .led_rg0     ( led_rg0    ),  // o, 2      
    .led_rg1     ( led_rg1    ),  // o, 2      
    .num_csn     ( num_csn    ),  // o, 8      
    .num_a_g     ( num_a_g    ),  // o, 7      
    .switch      ( switch     ),  // i, 8     
    .btn_key_col ( btn_key_col),  // o, 4          
    .btn_key_row ( btn_key_row),  // i, 4           
    .btn_step    ( btn_step   )   // i, 2   
);

endmodule

