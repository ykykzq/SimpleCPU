`timescale 1ns / 1ps

`define W_OK    tlb_top.tlb_w_test_ok
`define R_OK    tlb_top.tlb_r_test_ok
`define S_OK    tlb_top.tlb_s_test_ok

`define R_CNT   tlb_top.tlb_r_cnt
`define S0_CNT  tlb_top.s0_test_id
`define S1_CNT  tlb_top.s1_test_id

`define TEST_ERROR  tlb_top.test_error

module tb_top();
reg resetn;
reg clk;

reg w_ok_r;
reg r_ok_r;
reg s_ok_r;

initial
begin
    clk = 1'b0;
    resetn = 1'b0;
    #2000;
    resetn = 1'b1;
end
always #5 clk=~clk;

tlb_top #
(
    .SIMULATION(1'b1)
)tlb_top(
    .resetn(resetn),
    .clk(clk));

always @(posedge clk)
begin
    w_ok_r <= `W_OK;
    r_ok_r <= `R_OK;
    s_ok_r <= `S_OK;
end

always @(posedge clk)
begin
    if(`W_OK && ~w_ok_r) begin
	    $display("OK!!!write");
    end
    if(`R_OK && ~r_ok_r) begin
	    $display("OK!!!read");
    end
    if(`S_OK && ~s_ok_r) begin
	    $display("OK!!!search");
    end
end

always @(posedge clk)
begin
    if(`W_OK && `R_OK && `S_OK) begin
	    $display("=========================================================");
	    $display("Test end!");
        $display("----PASS!!!");
	    $finish;
    end
    else if(`TEST_ERROR) begin
	    $display("=========================================================");
        $display("----FAIL!!!");
        $display("read_test_id is %d",`R_CNT);
        $display("s0_test_id is %d",`S0_CNT);
        $display("s1_test_id is %d",`S1_CNT);
	    $finish;
    end
end

endmodule
