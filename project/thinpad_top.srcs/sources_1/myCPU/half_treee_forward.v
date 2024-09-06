module half_treee_forward(
	input  wire[15:0]	x,
	input  wire[6:0]	cin,
	output wire[1:0]	res,
	output wire[3:0]	c_to_next_stage,//c,10:7
	output wire[6:0]	c_to_next_tree
    );
	
	//第一层的输出
	wire	[10:0]	FI_floor_out;
	
	//第二层的输出
	wire	[7:0]	SE_floor_out;
	
	//第三层的输出
	wire	[3:0]	TH_floor_out;
	////////////////////////////////////////////////
	//第一层
	assign FI_floor_out[0]=x[0];
	full_adder_3to2 full_adder_1_floor_1(.x(x[ 3]),.y(x[ 2]),.z(x[ 1]),.C(FI_floor_out[ 2]),.S(FI_floor_out[1]));
	full_adder_3to2 full_adder_1_floor_2(.x(x[ 6]),.y(x[ 5]),.z(x[ 4]),.C(FI_floor_out[ 4]),.S(FI_floor_out[3]));
	full_adder_3to2 full_adder_1_floor_3(.x(x[ 9]),.y(x[ 8]),.z(x[ 7]),.C(FI_floor_out[ 6]),.S(FI_floor_out[5]));
	full_adder_3to2 full_adder_1_floor_4(.x(x[12]),.y(x[11]),.z(x[10]),.C(FI_floor_out[ 8]),.S(FI_floor_out[7]));
	full_adder_3to2 full_adder_1_floor_5(.x(x[15]),.y(x[14]),.z(x[13]),.C(FI_floor_out[10]),.S(FI_floor_out[9]));
	
	
	//第二层
	half_adder      half_adder_2_floor_1(.A(cin[1]),.B(cin[0]),                                      .C(SE_floor_out[1]),.sum(SE_floor_out[0]));
	full_adder_3to2 full_adder_2_floor_1(.x(cin[4]),.y(cin[3]),.z(cin[2]),.C(SE_floor_out[3]), .S(SE_floor_out[2]));
	full_adder_3to2 full_adder_2_floor_2(.x(FI_floor_out[3]),.y(FI_floor_out[1]),.z(FI_floor_out[0]),.C(SE_floor_out[5]), .S(SE_floor_out[4]));
	full_adder_3to2 full_adder_2_floor_3(.x(FI_floor_out[9]),.y(FI_floor_out[7]),.z(FI_floor_out[5]),.C(SE_floor_out[7]), .S(SE_floor_out[6]));
	
	
	//第三层
	full_adder_3to2 full_adder_3_floor_1(.x(SE_floor_out[0]),.y(cin[6]),         .z(cin[5]),         .C(TH_floor_out[1]), .S(TH_floor_out[0]));
	full_adder_3to2 full_adder_3_floor_2(.x(SE_floor_out[6]),.y(SE_floor_out[4]),.z(SE_floor_out[2]),.C(TH_floor_out[3]), .S(TH_floor_out[2]));
	
	/////////////////////////////////////////////////////////////////////////
	//合并各层引出的线
	assign res				={TH_floor_out[2],TH_floor_out[0]};
	assign c_to_next_stage	={TH_floor_out[3],TH_floor_out[1],SE_floor_out[ 7],SE_floor_out[5]};
	assign c_to_next_tree	={SE_floor_out[3],SE_floor_out[1],FI_floor_out[10],FI_floor_out[8],FI_floor_out[6],FI_floor_out[4],FI_floor_out[2]};
endmodule