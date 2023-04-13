module reg_file(
	input  wire			clk,
	input  wire[4:0]	r_addr1,
	input  wire[4:0]	r_addr2,
	output wire[31:0]	r_data1,
	output wire[31:0]	r_data2,
	input  wire[31:0]	w_data,
	input  wire[4:0]	w_addr,
	input  wire			w_en 
    );
	
	reg[31:0]	RegFile[31:0];
	
	always@(posedge clk)
	begin
		if(w_en)
			RegFile[w_addr]<=w_data;
	end
	
	assign r_data1=(r_addr1==32'b0)?32'b0:RegFile[r_addr1];
	assign r_data2=(r_addr2==32'b0)?32'b0:RegFile[r_addr2];
endmodule
