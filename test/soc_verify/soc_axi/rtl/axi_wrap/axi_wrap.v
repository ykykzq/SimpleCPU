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

module axi_wrap(
  input  wire        m_aclk,
  input  wire        m_aresetn,
  //ar
  input  wire [3 :0] m_arid   ,
  input  wire [31:0] m_araddr ,
  input  wire [7 :0] m_arlen  ,
  input  wire [2 :0] m_arsize ,
  input  wire [1 :0] m_arburst,
  input  wire [1 :0] m_arlock ,
  input  wire [3 :0] m_arcache,
  input  wire [2 :0] m_arprot ,
  input  wire        m_arvalid,
  output wire        m_arready,
  //r
  output wire [3 :0] m_rid    ,
  output wire [31:0] m_rdata  ,
  output wire [1 :0] m_rresp  ,
  output wire        m_rlast  ,
  output wire        m_rvalid ,
  input  wire        m_rready ,
  //aw
  input  wire [3 :0] m_awid   ,
  input  wire [31:0] m_awaddr ,
  input  wire [7 :0] m_awlen  ,
  input  wire [2 :0] m_awsize ,
  input  wire [1 :0] m_awburst,
  input  wire [1 :0] m_awlock ,
  input  wire [3 :0] m_awcache,
  input  wire [2 :0] m_awprot ,
  input  wire        m_awvalid,
  output wire        m_awready,
  //w
  input  wire [3 :0] m_wid    ,
  input  wire [31:0] m_wdata  ,
  input  wire [3 :0] m_wstrb  ,
  input  wire        m_wlast  ,
  input  wire        m_wvalid ,
  output wire        m_wready ,
  //b
  output wire [3 :0] m_bid    ,
  output wire [1 :0] m_bresp  ,
  output wire        m_bvalid ,
  input  wire        m_bready ,

  output wire        s_aclk,
  output wire        s_aresetn,
  //ar
  output wire [3 :0] s_arid   ,
  output wire [31:0] s_araddr ,
  output wire [7 :0] s_arlen  ,
  output wire [2 :0] s_arsize ,
  output wire [1 :0] s_arburst,
  output wire [1 :0] s_arlock ,
  output wire [3 :0] s_arcache,
  output wire [2 :0] s_arprot ,
  output wire        s_arvalid,
  input  wire        s_arready,
  //r
  input  wire [3 :0] s_rid    ,
  input  wire [31:0] s_rdata  ,
  input  wire [1 :0] s_rresp  ,
  input  wire        s_rlast  ,
  input  wire        s_rvalid ,
  output wire        s_rready ,
  //aw
  output wire [3 :0] s_awid   ,
  output wire [31:0] s_awaddr ,
  output wire [7 :0] s_awlen  ,
  output wire [2 :0] s_awsize ,
  output wire [1 :0] s_awburst,
  output wire [1 :0] s_awlock ,
  output wire [3 :0] s_awcache,
  output wire [2 :0] s_awprot ,
  output wire        s_awvalid,
  input  wire        s_awready,
  //w
  output wire [3 :0] s_wid    ,
  output wire [31:0] s_wdata  ,
  output wire [3 :0] s_wstrb  ,
  output wire        s_wlast  ,
  output wire        s_wvalid ,
  input  wire        s_wready ,
  //b
  input  wire [3 :0] s_bid    ,
  input  wire [1 :0] s_bresp  ,
  input  wire        s_bvalid ,
  output wire        s_bready  
);
assign s_aclk    = m_aclk   ;
assign s_aresetn = m_aresetn;
//ar
assign s_arid    = m_arid   ;
assign s_araddr  = m_araddr ;
assign s_arlen   = m_arlen  ;
assign s_arsize  = m_arsize ;
assign s_arburst = m_arburst;
assign s_arlock  = m_arlock ;
assign s_arcache = m_arcache;
assign s_arprot  = m_arprot ;
assign s_arvalid = m_arvalid;
assign m_arready = s_arready;
//r
assign m_rid    = m_rvalid ? s_rid   :  4'd0 ;
assign m_rdata  = m_rvalid ? s_rdata : 32'd0 ;
assign m_rresp  = m_rvalid ? s_rresp :  2'd0 ;
assign m_rlast  = m_rvalid ? s_rlast :  1'd0 ;
assign m_rvalid = s_rvalid;
assign s_rready = m_rready;
//aw
assign s_awid    = m_awid   ;
assign s_awaddr  = m_awaddr ;
assign s_awlen   = m_awlen  ;
assign s_awsize  = m_awsize ;
assign s_awburst = m_awburst;
assign s_awlock  = m_awlock ;
assign s_awcache = m_awcache;
assign s_awprot  = m_awprot ;
assign s_awvalid = m_awvalid;
assign m_awready = s_awready;
//w
assign s_wid    = m_wid    ;
assign s_wdata  = m_wdata  ;
assign s_wstrb  = m_wstrb  ;
assign s_wlast  = m_wlast  ;
assign s_wvalid = m_wvalid ;
assign m_wready = s_wready ;
//b
assign m_bid    = m_bvalid ? s_bid   : 4'd0 ;
assign m_bresp  = m_bvalid ? s_bresp : 2'd0 ;
assign m_bvalid = s_bvalid ;
assign s_bready = m_bready ;
endmodule
