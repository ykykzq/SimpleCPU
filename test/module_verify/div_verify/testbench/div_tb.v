`timescale 1ns / 1ps

module div_tb;

	// Inputs
	reg div_clk;
	reg resetn;
	wire div;
	reg div_signed;
	reg [31:0] x;
	reg [31:0] y;

	// Outputs
	wire [31:0] s;
	wire [31:0] r;
	wire complete;

	// Instantiate the Unit Under Test (UUT)
	div uut (
		.div_clk(div_clk), 
		.resetn(resetn), 
		.div(div), 
		.div_signed(div_signed), 
		.x(x), 
		.y(y), 
		.s(s), 
		.r(r), 
		.complete(complete)
	);

	initial begin
		// Initialize Inputs
		resetn = 0;
      #100;
		resetn = 1;
	end
initial
begin
    div_clk = 1'b0;
    forever
    begin
	     #5 div_clk = 1'b1;
	     #5 div_clk = 1'b0;
	 end
end	

//产生除法命令，正在进行除法
reg div_is_run;
integer wait_clk;
initial
begin
    div_is_run <= 1'b0;
    forever
    begin
	     @(posedge div_clk);
        if (!resetn || complete)
	     begin
	         div_is_run <= 1'b0;
		      wait_clk <= {$random}%4;
	     end
	     else
	     begin
	         repeat (wait_clk)@(posedge div_clk);
	         div_is_run <= 1'b1;
				wait_clk <= 0;
	     end
    end
end
//随机生成有符号除法控制信号以及被除数和除数
assign div = div_is_run;
always @(posedge div_clk)
begin
    if (!resetn || complete)
    begin
		  div_signed <= 1'b0;
		  x          <= 32'd0;
		  y          <= 32'd1;
    end
    else if (!div_is_run)
	 begin
		  div_signed <= {$random}%2; 
		  x          <= $random; 
		  y          <= $random;  //被除数随机产生0的概率很小，基本可忽略
	 end
end

//-----{计算参考结果}begin
//第一步，求x和y的绝对值，并判断商和余数的符号
wire x_signed = x[31] & div_signed;               //x的符号位，做无符号时认为是0
wire y_signed = y[31] & div_signed;               //y的符号位，做无符号时认为是0
wire [31:0] x_abs;
wire [31:0] y_abs;
assign x_abs = ({32{x_signed}}^x) + x_signed;     //此处异或运算必须加括号
assign y_abs = ({32{y_signed}}^y) + y_signed;     //因为verilog中+的优先级更高
wire s_ref_signed = (x[31]^y[31]) & div_signed;   //运算结果商  的符号位，做无符号时认为是0
wire r_ref_signed = x[31] & div_signed;           //运算结果余数的符号位，做无符号时认为是0

//第二步，求得商和余数的绝对值
reg [31:0] s_ref_abs;
reg [31:0] r_ref_abs;
always @(div_clk)
begin
    s_ref_abs <= x_abs/y_abs;
    r_ref_abs <= x_abs-s_ref_abs*y_abs; 
end

//第三步，依据商和余数的符号位调整
wire [31:0] s_ref;
wire [31:0] r_ref;
//此处异或运算必须加括号，因为verilog中+的优先级更高
assign s_ref = ({32{s_ref_signed}}^s_ref_abs) + {30'd0,s_ref_signed}; 
assign r_ref = ({32{r_ref_signed}}^r_ref_abs) + r_ref_signed;
//-----{计算参考结果}end

//判断结果是否正确
wire s_ok;
wire r_ok;
assign s_ok = s_ref==s;
assign r_ok = r_ref==r;
reg [5:0] time_out;

//输出结果,将各32位(不论是有符号还是无符号数)扩展成33位有符号数，以便以10进制形式打印
wire signed [32:0] x_d     = {div_signed&x[31],x};
wire signed [32:0] y_d     = {div_signed&y[31],y};
wire signed [32:0] s_d     = {div_signed&s[31],s};
wire signed [32:0] r_d     = {div_signed&r[31],r};
wire signed [32:0] s_ref_d = {div_signed&s_ref[31],s_ref};
wire signed [32:0] r_ref_d = {div_signed&r_ref[31],r_ref};
always @(posedge div_clk)
begin
    if (complete && div) //除法完成
    begin
	     if (s_ok && r_ok)
		  begin
		      $display("[time@%t]: x=%d, y=%d, signed=%d, s=%d, r=%d, s_OK=%b, r_OK=%b",
                      $time,x_d,y_d,div_signed,s_d,r_d,s_ok,r_ok);
		  end
		  else
		  begin
		      $display("[time@%t]Error: x=%d, y=%d, signed=%d, s=%d, r=%d, s_ref=%d, r_ref=%d, s_OK=%b, r_OK=%b",
                      $time,x_d,y_d,div_signed,s_d,r_d,s_ref_d,r_ref_d,s_ok,r_ok);
	         $finish;
		  end
    end
end
always @(posedge div_clk)
begin
    if (!resetn || !div_is_run || complete)
	 begin
	     time_out <= 6'd0;
	 end
    else
    begin
	     time_out <= time_out + 1'b1;
    end
end
always @(posedge div_clk)
begin	    
    if (time_out == 6'd34)
	 begin
		  $display("Error: div no end in 34 clk!");
		  $finish;
	 end
end
 
endmodule

