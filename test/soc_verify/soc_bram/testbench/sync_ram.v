module sync_ram #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
   clk,
   address,
   rdata,
   wdata,
   we,
   en
);

localparam NUM_BYTES = DATA_WIDTH/8;

input wire                  clk;
input wire [ADDR_WIDTH-1:0] address;
input wire [ NUM_BYTES-1:0] we;
input wire                  en;

output reg  [DATA_WIDTH-1:0] rdata;
output wire [DATA_WIDTH-1:0] wdata;

reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

genvar i;
for (i = 0; i < NUM_BYTES; i = i + 1) begin
   always @(posedge clk) begin
	   if (we[i]) ram[address][i*8 +: 8] <= wdata[i*8 +: 8];
   end
end

always @(posedge clk) begin
        if (en)
            rdata <= ram[address];
end
endmodule

module inst_ram #(
	parameter ADDR_WIDTH = 18,
	parameter DATA_WIDTH = 32,
	parameter DEPTH = 1 << ADDR_WIDTH
)
(
	input  wire clka,
	input  wire ena,
        input  wire [3:0] wea,	
	input  wire [ADDR_WIDTH-1:0] addra,
	input  wire [DATA_WIDTH-1:0] dina,
	output wire [DATA_WIDTH-1:0] douta
);
	sync_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))
		sync_ram(
			.clk    (clka),
			.address(addra),
			.rdata  (douta),
			.wdata  (dina),
			.we     (wea),
			.en     (ena)
		);
		initial begin
			$readmemb("../../../../../../../../func/obj/inst_ram.mif", sync_ram.ram);
		end
endmodule

module data_ram #(
	parameter ADDR_WIDTH = 16,
	parameter DATA_WIDTH = 32,
	parameter DEPTH = 1 << ADDR_WIDTH
)
(
	input  wire clka,
	input  wire ena,
        input  wire [3:0] wea,	
	input  wire [ADDR_WIDTH-1:0] addra,
	input  wire [DATA_WIDTH-1:0] dina,
	output wire [DATA_WIDTH-1:0] douta
);
	sync_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))
		sync_ram(
			.clk    (clka),
			.address(addra),
			.rdata  (douta),
			.wdata  (dina),
			.we     (wea),
			.en     (ena)
		);
		initial begin
			$readmemb("../../../../../../../../func/obj/data_ram.mif", sync_ram.ram);
		end
endmodule
