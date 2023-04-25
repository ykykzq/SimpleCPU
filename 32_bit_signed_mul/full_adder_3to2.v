module full_adder_3to2(
	input	x,
	input	y,
	input	z,
	output	C,
	output	S
    );
	
	wire 	C1;
	wire 	C2;
	
	wire	sum1;
	half_adder half_adder1(
			.A(x),
			.B(y),
			.C(C1),
			.sum(sum1)
		);
	half_adder half_adder2(
			.A(sum1),
			.B(z),
			.C(C2),
			.sum(S)
		);
	assign C=C1^C2;
endmodule
