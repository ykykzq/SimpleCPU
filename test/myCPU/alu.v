module alu(
  input  wire [18:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result
);

wire op_add     ;   //add operation
wire op_sub     ;   //sub operation
wire op_slt     ;   //signed compared and set less than
wire op_sltu    ;  //unsigned compared and set less than
wire op_and     ;   //bitwise and
wire op_nor     ;   //bitwise nor
wire op_or      ;    //bitwise or
wire op_xor     ;   //bitwise xor
wire op_sll     ;   //logic left shift
wire op_srl     ;   //logic right shift
wire op_sra     ;   //arithmetic right shift
wire op_lui     ;   //Load Upper Immediate
wire op_mod_u   ;  
wire op_mod_s   ;
wire op_div_u   ;
wire op_div_s   ;
wire op_mul_u_h ;
wire op_mul_s_h ;
wire op_mul_s_l ;

// control code decomposition
assign op_add     = alu_op[ 0];
assign op_sub     = alu_op[ 1];
assign op_slt     = alu_op[ 2];
assign op_sltu    = alu_op[ 3];
assign op_and     = alu_op[ 4];
assign op_nor     = alu_op[ 5];
assign op_or      = alu_op[ 6];
assign op_xor     = alu_op[ 7];
assign op_sll     = alu_op[ 8];
assign op_srl     = alu_op[ 9];
assign op_sra     = alu_op[10];
assign op_lui     = alu_op[11];
assign op_mod_u   = alu_op[12];  
assign op_mod_s   = alu_op[13];
assign op_div_u   = alu_op[14];
assign op_div_s   = alu_op[15];
assign op_mul_u_h = alu_op[16];
assign op_mul_s_h = alu_op[17];
assign op_mul_s_l = alu_op[18];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;
wire [31:0] mod_u_result;
wire [31:0] mod_s_result;
wire [31:0] div_u_result;
wire [31:0] div_s_result;
wire [31:0] mul_u_h_result;
wire [31:0] mul_s_h_result;
wire [31:0] mul_s_l_result;


// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src2;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src1 : alu_src1;  //src2 - src1 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src2[31] & ~alu_src1[31])
                        | ((alu_src2[31] ^~ alu_src1[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << i5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];


// MUL result
wire [63:0] unsigned_prod, signed_prod;
assign unsigned_prod  =  alu_src1 * alu_src2;
assign signed_prod    =  $signed(alu_src1)*$signed(alu_src2);
 
assign mul_s_l_result =   signed_prod[31: 0];
assign mul_s_h_result =   signed_prod[63:31];
assign mul_u_h_result = unsigned_prod[63:31];

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mod_u     }} & mod_u_result)
                  | ({32{op_mod_s     }} & mod_s_result)
                  | ({32{op_div_u     }} & div_u_result)
                  | ({32{op_div_s     }} & div_s_result)
                  | ({32{op_mul_u_h   }} & mul_u_h_result)
                  | ({32{op_mul_s_h   }} & mul_s_h_result)
                  | ({32{op_mul_s_l   }} & mul_s_l_result);

endmodule
