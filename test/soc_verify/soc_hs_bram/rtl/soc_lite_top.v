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

`default_nettype none

//for simulation:
//1. if define SIMU_USE_PLL = 1, will use clk_pll to generate cpu_clk/timer_clk,
//   and simulation will be very slow.
//2. usually, please define SIMU_USE_PLL=0 to speed up simulation by assign
//   cpu_clk/timer_clk = clk.
//   at this time, cpu_clk/timer_clk frequency are both 100MHz, same as clk.
`define SIMU_USE_PLL 0 //set 0 to speed up simulation

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
    output wire [31:0] num_data,
    input  wire [7 :0] switch, 
    output wire [3 :0] btn_key_col,
    input  wire [3 :0] btn_key_row,
    input  wire [1 :0] btn_step
);
//debug signals
wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_we;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;

//clk and resetn
wire cpu_clk;
wire timer_clk;
reg cpu_resetn;
always @(posedge cpu_clk)
begin
    cpu_resetn <= resetn;
end
generate if(SIMULATION && `SIMU_USE_PLL==0)
begin: speedup_simulation
    assign cpu_clk   = clk;
    assign timer_clk = clk;
end
else
begin: pll
    clk_pll clk_pll
    (
        .clk_in1 (clk),
        .cpu_clk (cpu_clk),
        .timer_clk (timer_clk)
    );
end
endgenerate

//cpu inst sram
wire        cpu_inst_req;
wire        cpu_inst_wr;
wire [1 :0] cpu_inst_size;
wire [3 :0] cpu_inst_wstrb;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire        cpu_inst_addr_ok;
wire        cpu_inst_data_ok;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_req;
wire        cpu_data_wr;
wire [1 :0] cpu_data_size;
wire [3 :0] cpu_data_wstrb;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire        cpu_data_addr_ok;
wire        cpu_data_data_ok;
wire [31:0] cpu_data_rdata;

//data sram
wire        data_sram_req;
wire        data_sram_wr;
wire [1 :0] data_sram_size;
wire [3 :0] data_sram_wstrb;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire        data_sram_addr_ok;
wire        data_sram_data_ok;
wire [31:0] data_sram_rdata;
//conf
wire        conf_req;
wire        conf_wr;
wire [1 :0] conf_size;
wire [3 :0] conf_wstrb;
wire [31:0] conf_addr;
wire [31:0] conf_wdata;
wire        conf_addr_ok;
wire        conf_data_ok;
wire [31:0] conf_rdata;

wire [4 :0] ram_random_mask;

//cpu
mycpu_top cpu(
    .clk              (cpu_clk   ),
    .resetn           (cpu_resetn),  //low active

    .inst_sram_req    (cpu_inst_req    ),
    .inst_sram_wr     (cpu_inst_wr     ),
    .inst_sram_size   (cpu_inst_size   ),
    .inst_sram_wstrb  (cpu_inst_wstrb  ),
    .inst_sram_addr   (cpu_inst_addr   ),
    .inst_sram_wdata  (cpu_inst_wdata  ),
    .inst_sram_addr_ok(cpu_inst_addr_ok),
    .inst_sram_data_ok(cpu_inst_data_ok),
    .inst_sram_rdata  (cpu_inst_rdata  ),
    
    .data_sram_req    (cpu_data_req    ),
    .data_sram_wr     (cpu_data_wr     ),
    .data_sram_size   (cpu_data_size   ),
    .data_sram_wstrb  (cpu_data_wstrb  ),
    .data_sram_addr   (cpu_data_addr   ),
    .data_sram_wdata  (cpu_data_wdata  ),
    .data_sram_addr_ok(cpu_data_addr_ok),
    .data_sram_data_ok(cpu_data_data_ok),
    .data_sram_rdata  (cpu_data_rdata  ),

    //debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_we   (debug_wb_rf_we   ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

wire        inst_ram_en   ;
wire [3 :0] inst_ram_we   ;
wire [31:0] inst_ram_addr ;
wire [31:0] inst_ram_wdata;
wire [31:0] inst_ram_rdata;
sram_wrap u_inst_sram_wrap(
    .clk              (cpu_clk   ),
    .resetn           (cpu_resetn),  //low active

    .req             (cpu_inst_req    ),
    .wr              (cpu_inst_wr     ),
    .size            (cpu_inst_size   ),
    .wstrb           (cpu_inst_wstrb  ),
    .addr            (cpu_inst_addr   ),
    .wdata           (cpu_inst_wdata  ),
    .addr_ok         (cpu_inst_addr_ok),
    .data_ok         (cpu_inst_data_ok),
    .rdata           (cpu_inst_rdata  ),

    //slave
    .ram_en          (inst_ram_en     ),
    .ram_we          (inst_ram_we     ),
    .ram_addr        (inst_ram_addr   ),
    .ram_wdata       (inst_ram_wdata  ),
    .ram_rdata       (inst_ram_rdata  ),
    //from confreg
    .ram_random_mask (ram_random_mask[1:0])
);
//inst ram
inst_ram inst_ram
(
    .clka  (cpu_clk            ),   
    .ena   (inst_ram_en        ),
    .wea   (inst_ram_we        ),   //3:0
    .addra (inst_ram_addr[19:2]),   //17:0
    .dina  (inst_ram_wdata     ),   //31:0
    .douta (inst_ram_rdata     )    //31:0
);

bridge_1x2 bridge_1x2(
    .clk             ( cpu_clk         ), // i, 1                 
    .resetn          ( cpu_resetn      ), // i, 1                 

    .cpu_data_req    ( cpu_data_req     ), // i, 1
    .cpu_data_wr     ( cpu_data_wr     ), // i, 1                 
    .cpu_data_size   ( cpu_data_size   ), // i, 2                 
    .cpu_data_wstrb  ( cpu_data_wstrb  ), // i, 4                 
    .cpu_data_addr   ( cpu_data_addr   ), // i, 32                
    .cpu_data_wdata  ( cpu_data_wdata  ), // i, 32                
    .cpu_data_addr_ok( cpu_data_addr_ok), // i, 1                
    .cpu_data_data_ok( cpu_data_data_ok), // i, 1                
    .cpu_data_rdata  ( cpu_data_rdata  ), // o, 32                

    .data_sram_req    ( data_sram_req    ), // o, 1
    .data_sram_wr     ( data_sram_wr     ), // o, 1                 
    .data_sram_size   ( data_sram_size   ), // o, 2                 
    .data_sram_wstrb  ( data_sram_wstrb  ), // o, 4                 
    .data_sram_addr   ( data_sram_addr   ), // o, 32                
    .data_sram_wdata  ( data_sram_wdata  ), // o, 32                
    .data_sram_addr_ok( data_sram_addr_ok), // o, 1                
    .data_sram_data_ok( data_sram_data_ok), // o, 1                
    .data_sram_rdata  ( data_sram_rdata  ), // i, 32                

    .conf_req    ( conf_req     ), // o, 1
    .conf_wr     ( conf_wr     ), // o, 1                 
    .conf_size   ( conf_size   ), // o, 2                 
    .conf_wstrb  ( conf_wstrb  ), // o, 4                 
    .conf_addr   ( conf_addr   ), // o, 32                
    .conf_wdata  ( conf_wdata  ), // o, 32                
    .conf_addr_ok( conf_addr_ok), // o, 1                
    .conf_data_ok( conf_data_ok), // o, 1                
    .conf_rdata  ( conf_rdata  )  // i, 32
 );

//data ram
wire        data_ram_en   ;
wire [3 :0] data_ram_we   ;
wire [31:0] data_ram_addr ;
wire [31:0] data_ram_wdata;
wire [31:0] data_ram_rdata;
sram_wrap u_data_sram_wrap(
    .clk             (cpu_clk          ),
    .resetn          (cpu_resetn       ),  //low active

    .req             (data_sram_req    ),
    .wr              (data_sram_wr     ),
    .size            (data_sram_size   ),
    .wstrb           (data_sram_wstrb  ),
    .addr            (data_sram_addr   ),
    .wdata           (data_sram_wdata  ),
    .addr_ok         (data_sram_addr_ok),
    .data_ok         (data_sram_data_ok),
    .rdata           (data_sram_rdata  ),

    //slave
    .ram_en          (data_ram_en     ),
    .ram_we          (data_ram_we     ),
    .ram_addr        (data_ram_addr   ),
    .ram_wdata       (data_ram_wdata  ),
    .ram_rdata       (data_ram_rdata  ),
    //from confreg
    .ram_random_mask (ram_random_mask[3:2])
);
data_ram data_ram
(
    .clka  (cpu_clk            ),   
    .ena   (data_ram_en        ),
    .wea   (data_ram_we        ),   //3:0
    .addra (data_ram_addr[17:2]),   //15:0
    .dina  (data_ram_wdata     ),   //31:0
    .douta (data_ram_rdata     )    //31:0
);

//confreg
confreg #(.SIMULATION(SIMULATION)) u_confreg
(
    .clk             ( cpu_clk       ),  // i, 1   
    .timer_clk       ( timer_clk     ),  // i, 1   
    .resetn          ( cpu_resetn    ),  // i, 1    
    .conf_req        ( conf_req      ),  // i, 1      
    .conf_wr         ( conf_wr       ),  // i, 1      
    .conf_size       ( conf_size     ),  // i, 2      
    .conf_wstrb      ( conf_wstrb    ),  // i, 4      
    .conf_addr       ( conf_addr     ),  // i, 32        
    .conf_wdata      ( conf_wdata    ),  // i, 32         
    .conf_addr_ok    ( conf_addr_ok  ),  // i, 1
    .conf_data_ok    ( conf_data_ok  ),  // i, 1
    .conf_rdata      ( conf_rdata    ),  // o, 32         
    .ram_random_mask (ram_random_mask),  // o, 5
    .led             ( led           ),  // o, 16   
    .led_rg0         ( led_rg0       ),  // o, 2      
    .led_rg1         ( led_rg1       ),  // o, 2      
    .num_csn         ( num_csn       ),  // o, 8      
    .num_a_g         ( num_a_g       ),  // o, 7      
    .num_data        ( num_data      ),  // o, 32
    .switch          ( switch        ),  // i, 8     
    .btn_key_col     ( btn_key_col   ),  // o, 4          
    .btn_key_row     ( btn_key_row   ),  // i, 4           
    .btn_step        ( btn_step      )   // i, 2   
);

endmodule

