`include "mul.h"
//32bit,signed
module mul_top(
	input  wire			mul_clk,
	input  wire			reset,
	input  wire[31:0]	src1,
	input  wire[31:0]	src2,
	output wire[63:0]	result
    );
	
	wire[`FI_TO_SE_BUS_WD-1:0]	FI_to_SE_bus;
	
	mul_stage1 stage1(
		.src1			(src1),
		.src2			(src2),
		.FI_to_SE_bus	(FI_to_SE_bus)
    );
	
	mul_stage2 stage2(
		.mul_clk		(mul_clk),	
		.reset			(reset),
		.FI_to_SE_bus	(FI_to_SE_bus),
		
		.result			(result)
    );
endmodule
