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
//   > File Name   : bridge_1x2.v
//   > Description : bridge between cpu_data and data ram, confreg
//   
//     master:    cpu_data
//                   |  \
//     1 x 2         |   \  
//     bridge:       |    \                    
//                   |     \       
//     slave:   data_ram  confreg
//
//   > Author      : LOONGSON
//   > Date        : 2020-04-14
//*************************************************************************
`define CONF_ADDR_BASE 32'h1faf_0000
`define CONF_ADDR_MASK 32'h1fff_0000 //for bfaf or 1faf
module bridge_1x2(                                 
    input  wire                          clk,          // clock 
    input  wire                          resetn,       // reset, active low
    // master : cpu data
    input  wire                          cpu_data_req     , // cpu data access enable
    input  wire                          cpu_data_wr      , // cpu data access is write
    input  wire [1                   :0] cpu_data_size    , // cpu data access size
    input  wire [3                   :0] cpu_data_wstrb   , // cpu data write strobe
    input  wire [31                  :0] cpu_data_addr    , // cpu data address
    input  wire [31                  :0] cpu_data_wdata   , // cpu data write data
    output wire                          cpu_data_addr_ok , // cpu data access address is received.
    output wire                          cpu_data_data_ok , // cpu data access data return.
    output wire [31                  :0] cpu_data_rdata   , // cpu data read data
    // slave : data ram 
    output wire                          data_sram_req    , // access enable
    output wire                          data_sram_wr     , // access is write
    output wire [1                   :0] data_sram_size   , // access size
    output wire [3                   :0] data_sram_wstrb  , // write strobe
    output wire [31                  :0] data_sram_addr   , // address
    output wire [31                  :0] data_sram_wdata  , // write data
    input  wire                          data_sram_addr_ok, // access address is received.
    input  wire                          data_sram_data_ok, // access data return.
    input  wire [31                  :0] data_sram_rdata  , // read data
    // slave : confreg 
    output wire                          conf_req         , // access enable
    output wire                          conf_wr          , // access is write
    output wire [1                   :0] conf_size        , // access size
    output wire [3                   :0] conf_wstrb       , // write strobe
    output wire [31                  :0] conf_addr        , // address
    output wire [31                  :0] conf_wdata       , // write data
    input  wire                          conf_addr_ok     , // access address is received.
    input  wire                          conf_data_ok     , // access data return.
    input  wire [31                  :0] conf_rdata         // read data
);
    reg  sel_conf_reg;
    wire sel_sram;  // cpu data is from data ram
    wire sel_conf;  // cpu data is from confreg
    wire   hit_conf = (cpu_data_addr & `CONF_ADDR_MASK) == `CONF_ADDR_BASE;
    assign sel_conf = hit_conf && (!is_doing || sel_conf_reg);
    assign sel_sram =!hit_conf && (!is_doing ||!sel_conf_reg);

    //is doing
    reg  [3:0] do_cnt;
    wire       is_doing = do_cnt!=4'd0;
    wire       is_full  = do_cnt==4'hf;
    always @ (posedge clk)
    begin
        if (!resetn)
        begin
            do_cnt <= 4'd0;
        end
        else
        begin
            do_cnt <= do_cnt + (cpu_data_req&&cpu_data_addr_ok) - (is_doing && cpu_data_data_ok);
        end
        
        if (!resetn)
        begin
            sel_conf_reg <= 1'b0;
        end
        else if(cpu_data_req&&cpu_data_addr_ok)
        begin
            sel_conf_reg <= sel_conf;
        end
    end

    // data sram
    assign data_sram_req   = cpu_data_req && sel_sram && !is_full;
    assign data_sram_wr    = cpu_data_wr ;
    assign data_sram_size  = cpu_data_size;
    assign data_sram_wstrb = cpu_data_wstrb;
    assign data_sram_addr  = cpu_data_addr;
    assign data_sram_wdata = cpu_data_wdata;

    // confreg
    assign conf_req   = cpu_data_req && sel_conf && !is_full;
    assign conf_wr    = cpu_data_wr  ;
    assign conf_size  = cpu_data_size;
    assign conf_wstrb = cpu_data_wstrb;
    assign conf_addr  = cpu_data_addr;
    assign conf_wdata = cpu_data_wdata;

    //addr_ok 
    assign cpu_data_addr_ok = (!is_full&&sel_conf&&conf_addr_ok     ) ||
                              (!is_full&&sel_sram&&data_sram_addr_ok);
    //addr_ok 
    assign cpu_data_data_ok = sel_conf_reg ? conf_data_ok : data_sram_data_ok;

    //rdata
    assign cpu_data_rdata   = sel_conf_reg ? conf_rdata : data_sram_rdata;
endmodule

