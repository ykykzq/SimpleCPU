module ALU(
    input [31:0]	alu_src1,
    input [31:0]    alu_src2,
    input [3:0]    	alu_op,
    output[31:0]	alu_res
    );
	
	wire[31:0] add_res;
	wire[31:0] sub_res;
	wire[31:0] slt_res;//比较器,大于
	wire[31:0] sltu_res;
	wire[31:0] and_res;
	wire[31:0] nor_res;
	wire[31:0] or_res;
	wire[31:0] xor_res;
	wire[31:0] sll_res;//左移
	wire[31:0] srl_res;
	wire[31:0] sra_res;//算数右移
	wire[31:0] lui_res;//无符号扩展
	
	wire 		carry_out;//加法器进位
	wire 		carry_in;
	wire [31:0] add_a,add_b;
	
	//加法器
	assign add_a=alu_src1;
	assign add_b=(alu_op==4'b0001 | alu_op==4'b0010 | alu_op==4'b0011)?~alu_src2:alu_src2;
	assign carry_in=(alu_op==4'b0001 | alu_op==4'b0010 | alu_op==4'b0011)?1'b1:1'b0;
	assign {carry_out,add_res}=add_a+add_b+carry_in;
	
	
	assign sub_res=add_res;
	
	
	assign slt_res[31:1]=31'b0;
	assign slt_res[0]=(alu_src1[31] & ~alu_src2[31])|
						(~(alu_src1[31]^alu_src2[31]) & add_res[31]);
					
	assign sltu_res[31:1]=31'b0;
	assign sltu_res[0]=~carry_out;
	
	assign and_res=alu_src1&alu_src2;
	assign nor_res=~or_res;
	assign or_res =alu_src1|alu_src2;
	assign xor_res=alu_src1^alu_src2;
	
	assign sll_res=alu_src2<<alu_src1[4:0];
	assign srl_res=alu_src2>>alu_src1[4:0];
	assign sra_res=($signed(alu_src2))>>>alu_src1[4:0];
	
	assign lui_res={alu_src2[15:0],16'b0};
	
	//筛选结果
	assign alu_res=  ({32{alu_op==4'b0000}} &  add_res)
					|({32{alu_op==4'b0001}} &  sub_res)
					|({32{alu_op==4'b0010}} &  slt_res)
					|({32{alu_op==4'b0011}} &  sltu_res)
					|({32{alu_op==4'b0100}} &  and_res)
					|({32{alu_op==4'b0101}} &  nor_res)
					|({32{alu_op==4'b0110}} &  or_res)
					|({32{alu_op==4'b0111}} &  xor_res)
					|({32{alu_op==4'b1000}} &  sll_res)
					|({32{alu_op==4'b1001}} &  srl_res)
					|({32{alu_op==4'b1010}}&  sra_res)
					|({32{alu_op==4'b1011}}&  lui_res);
	
				
	
	
endmodule
