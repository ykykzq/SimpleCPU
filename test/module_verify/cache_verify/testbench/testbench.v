`timescale 1ns / 1ps

`define REPLACE_WRONG  cache_top.replace_wrong
`define CACHERES_WRONG  cache_top.cacheres_wrong
`define TEST_INDEX  cache_top.test_index
`define ROUND_FINISH cache_top.read_round_finish
module tb_top();
reg resetn;
reg clk;

initial
begin
    clk = 1'b0;
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
end
always #5 clk=~clk;

cache_top #(
    .SIMULATION(1'b1)
) cache_top(
    .resetn(resetn),
    .clk(clk)
    );

always @(posedge clk)
begin
    if(`ROUND_FINISH) begin
	    $display("index %x finished",`TEST_INDEX);
        if(`TEST_INDEX==8'hff) begin
	        $display("=========================================================");
	        $display("Test end!");
            $display("----PASS!!!");
	        $finish;
        end
    end
    else if(`REPLACE_WRONG) begin
	    $display("replace wrong at index %x",`TEST_INDEX);
	    $display("=========================================================");
	    $display("Test end!");
        $display("----FAIL!!!");
	    $finish;
    end
    else if(`CACHERES_WRONG) begin
	    $display("cacheres wrong at index %x",`TEST_INDEX);
	    $display("=========================================================");
	    $display("Test end!");
        $display("----FAIL!!!");
	    $finish;
    end
end

endmodule
