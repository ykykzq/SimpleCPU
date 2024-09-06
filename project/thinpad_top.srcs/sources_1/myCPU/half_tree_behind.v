module half_tree_behind(
	input  wire[1:0]	x,
	input  wire[6:0]	cin,
	output wire			C,
	output wire			S,
	output wire[2:0]	c_to_next_tree
    );
	
	//第一层输出
	wire[3:0]	FI_floor_out;
	
	//第二层输出
	wire[1:0]	SE_floor_out;
	
	//////////////////////////////////////////
	//第一层
	full_adder_3to2 full_adder_1_floor_1(.x(cin[ 2]),.y(cin[ 1]),.z(cin[ 0]),.C(FI_floor_out[ 1]),.S(FI_floor_out[0]));
	full_adder_3to2 full_adder_1_floor_2(.x(  x[ 1]),.y(  x[ 0]),.z(cin[ 3]),.C(FI_floor_out[ 3]),.S(FI_floor_out[2]));
	
	//第二层
	full_adder_3to2 full_adder_2_floor_1(.x(FI_floor_out[2]),.y(FI_floor_out[0]),.z(cin[4]),.C(SE_floor_out[1]),.S(SE_floor_out[0]));
	
	//第三层
	full_adder_3to2 full_adder_3_floor_1(.x(SE_floor_out[0]),.y(cin[6]),.z(cin[5]),.C(C),.S(S));

	///////////////////////////////////////////////
	//合并信号
	assign c_to_next_tree={SE_floor_out[1],FI_floor_out[3],FI_floor_out[1]};
endmodule
