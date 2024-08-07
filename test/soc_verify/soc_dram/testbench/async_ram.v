module async_ram #(
    parameter ADDR_WIDTH = 15,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
	clk,
   address,
   rdata,
   wdata,
   we
);

input                  clk;
input [ADDR_WIDTH-1:0] address;
input                  we;

output [DATA_WIDTH-1:0] rdata;
output [DATA_WIDTH-1:0] wdata;

reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
reg [DATA_WIDTH-1:0] data_out;

assign rdata = (!we) ? data_out : {DATA_WIDTH{1'bz}};

always @(posedge clk)
begin : MEM_WRITE
    if (we) begin
        ram[address] <= wdata;
    end
end


always @* 
begin : MEM_READ
    if (!we) begin
        data_out = ram[address];
    end
end
endmodule

module inst_ram #(
	parameter ADDR_WIDTH = 15,
	parameter DATA_WIDTH = 32,
	parameter DEPTH = 1 << ADDR_WIDTH
)
(
	input  wire clk,
	input  wire we,
	input  wire [ADDR_WIDTH-1:0] a,
	input  wire [DATA_WIDTH-1:0] d,
	output wire [DATA_WIDTH-1:0] spo
);
	async_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))
		async_ram(
			.clk    (clk),
			.address(a),
			.rdata(spo),
			.wdata(d),
			.we(we)
		);
		initial begin
			$readmemb("../../../../../../../../func/obj/inst_ram.mif", async_ram.ram);
		end
endmodule

module data_ram #(
	parameter ADDR_WIDTH = 15,
	parameter DATA_WIDTH = 32,
	parameter DEPTH = 1 << ADDR_WIDTH
)
(
	input  wire clk,
	input  wire we,
	input  wire [ADDR_WIDTH-1:0] a,
	input  wire [DATA_WIDTH-1:0] d,
	output wire [DATA_WIDTH-1:0] spo
);
	async_ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))
		async_ram(
			.clk    (clk),
			.address(a),
			.rdata(spo),
			.wdata(d),
			.we(we)
		);
		initial begin
			$readmemb("../../../../../../../../func/obj/data_ram.mif", async_ram.ram);
		end
endmodule
