module Booth_2_bit(
	input  [63:0]	x,
	input  [2:0]	y,
	output [63:0]	P,
	output 			c
    );
	
	wire[4:0]	sel;//one hot
	wire[63:0]	not_x;
	wire[63:0]	x_2;
	wire[63:0]	not_x_2;
	
	assign sel=	{
					~(
					(y[0]^y[1])
						|
					(y[2]^y[1])	
					),//0
					
					(y[1]^y[0])
						&
					(~y[2])
					,//x
					
					(y[1]^y[0])
						&
					(y[2])
					,//~x
					
					(~(y[0]^y[1]))
						&
					y[2],//2[~x]
					
					(~(y[0]^y[1]))
						&
					(~y[2])//2x
				}; 
				
	assign not_x=~x;
	assign x_2={x[62:0],1'b0};
	assign not_x_2=~x_2;
	assign P=	sel[4]?64'b0:
				sel[3]?x:
				sel[2]?not_x:
				sel[1]?not_x_2:
				sel[0]? x_2:
				63'b1;
				
				
	assign c=y[2] & ( ~(y[1] & y[0]) );
endmodule
