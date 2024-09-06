`include "mul.h"
module mul_stage1(
	input  wire[31:0]					src1,
	input  wire[31:0]					src2,
	output wire[`FI_TO_SE_BUS_WD-1:0]	FI_to_SE_bus
    );
	
	wire[63:0]		src1_64;
	wire[31:0]		src2_32;
	
	//（1）的输出
	wire[63:0]		P[15:0];
	//wire[63:0]		P_sh[15:0];//对P移位
	wire[15:0]		c;
	
	//Switch的输出
	wire[15:0]		Input[63:0];
	
	//树间通讯
	wire[6:0]		c_between_tree[62:0];
	//废料
	wire[6:0]		waste1;//废料
	wire[3:0]		waste2;
	
	///////////////////////////////////////////////////
	//(1)扩展后计算部分积
	
	assign src1_64	={{32{src1[31]}},src1};
	assign src2_32	=src2;
	
	//16组
	Booth_2_bit B01(.x(src1_64    ),.y({src2_32[ 1: 0],1'b0} ),.P(P[ 0]),.c(c[ 0]));
	Booth_2_bit B02(.x(src1_64<< 2),.y( src2_32[ 3: 1]       ),.P(P[ 1]),.c(c[ 1]));
	Booth_2_bit B03(.x(src1_64<< 4),.y( src2_32[ 5: 3]       ),.P(P[ 2]),.c(c[ 2]));
	Booth_2_bit B04(.x(src1_64<< 6),.y( src2_32[ 7: 5]       ),.P(P[ 3]),.c(c[ 3]));
	Booth_2_bit B05(.x(src1_64<< 8),.y( src2_32[ 9: 7]       ),.P(P[ 4]),.c(c[ 4]));
	Booth_2_bit B06(.x(src1_64<<10),.y( src2_32[11: 9]       ),.P(P[ 5]),.c(c[ 5]));
	Booth_2_bit B07(.x(src1_64<<12),.y( src2_32[13:11]       ),.P(P[ 6]),.c(c[ 6]));
	Booth_2_bit B08(.x(src1_64<<14),.y( src2_32[15:13]       ),.P(P[ 7]),.c(c[ 7]));
	Booth_2_bit B09(.x(src1_64<<16),.y( src2_32[17:15]       ),.P(P[ 8]),.c(c[ 8]));
	Booth_2_bit B10(.x(src1_64<<18),.y( src2_32[19:17]       ),.P(P[ 9]),.c(c[ 9]));
	Booth_2_bit B11(.x(src1_64<<20),.y( src2_32[21:19]       ),.P(P[10]),.c(c[10]));
	Booth_2_bit B12(.x(src1_64<<22),.y( src2_32[23:21]       ),.P(P[11]),.c(c[11]));
	Booth_2_bit B13(.x(src1_64<<24),.y( src2_32[25:23]       ),.P(P[12]),.c(c[12]));
	Booth_2_bit B14(.x(src1_64<<26),.y( src2_32[27:25]       ),.P(P[13]),.c(c[13]));
	Booth_2_bit B15(.x(src1_64<<28),.y( src2_32[29:27]       ),.P(P[14]),.c(c[14]));
	Booth_2_bit B16(.x(src1_64<<30),.y( src2_32[31:29]       ),.P(P[15]),.c(c[15]));
	
	
	/* assign P_sh[ 0]=P[ 0]    ;
	assign P_sh[ 1]=P[ 1]<< 2;
	assign P_sh[ 2]=P[ 2]<< 4;
	assign P_sh[ 3]=P[ 3]<< 6;
	assign P_sh[ 4]=P[ 4]<< 8;
	assign P_sh[ 5]=P[ 5]<<10;
	assign P_sh[ 6]=P[ 6]<<12;
	assign P_sh[ 7]=P[ 7]<<14;
	assign P_sh[ 8]=P[ 8]<<16;
	assign P_sh[ 9]=P[ 9]<<18;
	assign P_sh[10]=P[10]<<20;
	assign P_sh[11]=P[11]<<22;
	assign P_sh[12]=P[12]<<24;
	assign P_sh[13]=P[13]<<26;
	assign P_sh[14]=P[14]<<28;
	assign P_sh[15]=P[15]<<30; */
	///////////////////////////////////////////////////////////
	//(2),switch,即转置为每一位（总计64位）中16个数字相加的过程
	
	
	assign Input[ 0]={P[15][ 0],P[14][ 0],P[13][ 0],P[12][ 0],P[11][ 0],P[10][ 0],P[9][ 0],P[8][ 0],P[7][ 0],P[6][ 0],P[5][ 0],P[4][ 0],P[3][ 0],P[2][ 0],P[1][ 0],P[0][ 0]};
	assign Input[ 1]={P[15][ 1],P[14][ 1],P[13][ 1],P[12][ 1],P[11][ 1],P[10][ 1],P[9][ 1],P[8][ 1],P[7][ 1],P[6][ 1],P[5][ 1],P[4][ 1],P[3][ 1],P[2][ 1],P[1][ 1],P[0][ 1]};       
	assign Input[ 2]={P[15][ 2],P[14][ 2],P[13][ 2],P[12][ 2],P[11][ 2],P[10][ 2],P[9][ 2],P[8][ 2],P[7][ 2],P[6][ 2],P[5][ 2],P[4][ 2],P[3][ 2],P[2][ 2],P[1][ 2],P[0][ 2]};
	assign Input[ 3]={P[15][ 3],P[14][ 3],P[13][ 3],P[12][ 3],P[11][ 3],P[10][ 3],P[9][ 3],P[8][ 3],P[7][ 3],P[6][ 3],P[5][ 3],P[4][ 3],P[3][ 3],P[2][ 3],P[1][ 3],P[0][ 3]};       
	assign Input[ 4]={P[15][ 4],P[14][ 4],P[13][ 4],P[12][ 4],P[11][ 4],P[10][ 4],P[9][ 4],P[8][ 4],P[7][ 4],P[6][ 4],P[5][ 4],P[4][ 4],P[3][ 4],P[2][ 4],P[1][ 4],P[0][ 4]};
	assign Input[ 5]={P[15][ 5],P[14][ 5],P[13][ 5],P[12][ 5],P[11][ 5],P[10][ 5],P[9][ 5],P[8][ 5],P[7][ 5],P[6][ 5],P[5][ 5],P[4][ 5],P[3][ 5],P[2][ 5],P[1][ 5],P[0][ 5]};       
	assign Input[ 6]={P[15][ 6],P[14][ 6],P[13][ 6],P[12][ 6],P[11][ 6],P[10][ 6],P[9][ 6],P[8][ 6],P[7][ 6],P[6][ 6],P[5][ 6],P[4][ 6],P[3][ 6],P[2][ 6],P[1][ 6],P[0][ 6]};       
	assign Input[ 7]={P[15][ 7],P[14][ 7],P[13][ 7],P[12][ 7],P[11][ 7],P[10][ 7],P[9][ 7],P[8][ 7],P[7][ 7],P[6][ 7],P[5][ 7],P[4][ 7],P[3][ 7],P[2][ 7],P[1][ 7],P[0][ 7]};
	assign Input[ 8]={P[15][ 8],P[14][ 8],P[13][ 8],P[12][ 8],P[11][ 8],P[10][ 8],P[9][ 8],P[8][ 8],P[7][ 8],P[6][ 8],P[5][ 8],P[4][ 8],P[3][ 8],P[2][ 8],P[1][ 8],P[0][ 8]};       
	assign Input[ 9]={P[15][ 9],P[14][ 9],P[13][ 9],P[12][ 9],P[11][ 9],P[10][ 9],P[9][ 9],P[8][ 9],P[7][ 9],P[6][ 9],P[5][ 9],P[4][ 9],P[3][ 9],P[2][ 9],P[1][ 9],P[0][ 9]};
	assign Input[10]={P[15][10],P[14][10],P[13][10],P[12][10],P[11][10],P[10][10],P[9][10],P[8][10],P[7][10],P[6][10],P[5][10],P[4][10],P[3][10],P[2][10],P[1][10],P[0][10]};
	assign Input[11]={P[15][11],P[14][11],P[13][11],P[12][11],P[11][11],P[10][11],P[9][11],P[8][11],P[7][11],P[6][11],P[5][11],P[4][11],P[3][11],P[2][11],P[1][11],P[0][11]};
	assign Input[12]={P[15][12],P[14][12],P[13][12],P[12][12],P[11][12],P[10][12],P[9][12],P[8][12],P[7][12],P[6][12],P[5][12],P[4][12],P[3][12],P[2][12],P[1][12],P[0][12]};
	assign Input[13]={P[15][13],P[14][13],P[13][13],P[12][13],P[11][13],P[10][13],P[9][13],P[8][13],P[7][13],P[6][13],P[5][13],P[4][13],P[3][13],P[2][13],P[1][13],P[0][13]};
	assign Input[14]={P[15][14],P[14][14],P[13][14],P[12][14],P[11][14],P[10][14],P[9][14],P[8][14],P[7][14],P[6][14],P[5][14],P[4][14],P[3][14],P[2][14],P[1][14],P[0][14]};
	assign Input[15]={P[15][15],P[14][15],P[13][15],P[12][15],P[11][15],P[10][15],P[9][15],P[8][15],P[7][15],P[6][15],P[5][15],P[4][15],P[3][15],P[2][15],P[1][15],P[0][15]};
	assign Input[16]={P[15][16],P[14][16],P[13][16],P[12][16],P[11][16],P[10][16],P[9][16],P[8][16],P[7][16],P[6][16],P[5][16],P[4][16],P[3][16],P[2][16],P[1][16],P[0][16]};
	assign Input[17]={P[15][17],P[14][17],P[13][17],P[12][17],P[11][17],P[10][17],P[9][17],P[8][17],P[7][17],P[6][17],P[5][17],P[4][17],P[3][17],P[2][17],P[1][17],P[0][17]};
	assign Input[18]={P[15][18],P[14][18],P[13][18],P[12][18],P[11][18],P[10][18],P[9][18],P[8][18],P[7][18],P[6][18],P[5][18],P[4][18],P[3][18],P[2][18],P[1][18],P[0][18]};
	assign Input[19]={P[15][19],P[14][19],P[13][19],P[12][19],P[11][19],P[10][19],P[9][19],P[8][19],P[7][19],P[6][19],P[5][19],P[4][19],P[3][19],P[2][19],P[1][19],P[0][19]};
	assign Input[20]={P[15][20],P[14][20],P[13][20],P[12][20],P[11][20],P[10][20],P[9][20],P[8][20],P[7][20],P[6][20],P[5][20],P[4][20],P[3][20],P[2][20],P[1][20],P[0][20]};
	assign Input[21]={P[15][21],P[14][21],P[13][21],P[12][21],P[11][21],P[10][21],P[9][21],P[8][21],P[7][21],P[6][21],P[5][21],P[4][21],P[3][21],P[2][21],P[1][21],P[0][21]};
	assign Input[22]={P[15][22],P[14][22],P[13][22],P[12][22],P[11][22],P[10][22],P[9][22],P[8][22],P[7][22],P[6][22],P[5][22],P[4][22],P[3][22],P[2][22],P[1][22],P[0][22]};
	assign Input[23]={P[15][23],P[14][23],P[13][23],P[12][23],P[11][23],P[10][23],P[9][23],P[8][23],P[7][23],P[6][23],P[5][23],P[4][23],P[3][23],P[2][23],P[1][23],P[0][23]};
	assign Input[24]={P[15][24],P[14][24],P[13][24],P[12][24],P[11][24],P[10][24],P[9][24],P[8][24],P[7][24],P[6][24],P[5][24],P[4][24],P[3][24],P[2][24],P[1][24],P[0][24]};
	assign Input[25]={P[15][25],P[14][25],P[13][25],P[12][25],P[11][25],P[10][25],P[9][25],P[8][25],P[7][25],P[6][25],P[5][25],P[4][25],P[3][25],P[2][25],P[1][25],P[0][25]};
	assign Input[26]={P[15][26],P[14][26],P[13][26],P[12][26],P[11][26],P[10][26],P[9][26],P[8][26],P[7][26],P[6][26],P[5][26],P[4][26],P[3][26],P[2][26],P[1][26],P[0][26]};
	assign Input[27]={P[15][27],P[14][27],P[13][27],P[12][27],P[11][27],P[10][27],P[9][27],P[8][27],P[7][27],P[6][27],P[5][27],P[4][27],P[3][27],P[2][27],P[1][27],P[0][27]};
	assign Input[28]={P[15][28],P[14][28],P[13][28],P[12][28],P[11][28],P[10][28],P[9][28],P[8][28],P[7][28],P[6][28],P[5][28],P[4][28],P[3][28],P[2][28],P[1][28],P[0][28]};
	assign Input[29]={P[15][29],P[14][29],P[13][29],P[12][29],P[11][29],P[10][29],P[9][29],P[8][29],P[7][29],P[6][29],P[5][29],P[4][29],P[3][29],P[2][29],P[1][29],P[0][29]};
	assign Input[30]={P[15][30],P[14][30],P[13][30],P[12][30],P[11][30],P[10][30],P[9][30],P[8][30],P[7][30],P[6][30],P[5][30],P[4][30],P[3][30],P[2][30],P[1][30],P[0][30]};
	assign Input[31]={P[15][31],P[14][31],P[13][31],P[12][31],P[11][31],P[10][31],P[9][31],P[8][31],P[7][31],P[6][31],P[5][31],P[4][31],P[3][31],P[2][31],P[1][31],P[0][31]};
	assign Input[32]={P[15][32],P[14][32],P[13][32],P[12][32],P[11][32],P[10][32],P[9][32],P[8][32],P[7][32],P[6][32],P[5][32],P[4][32],P[3][32],P[2][32],P[1][32],P[0][32]};
	assign Input[33]={P[15][33],P[14][33],P[13][33],P[12][33],P[11][33],P[10][33],P[9][33],P[8][33],P[7][33],P[6][33],P[5][33],P[4][33],P[3][33],P[2][33],P[1][33],P[0][33]};
	assign Input[34]={P[15][34],P[14][34],P[13][34],P[12][34],P[11][34],P[10][34],P[9][34],P[8][34],P[7][34],P[6][34],P[5][34],P[4][34],P[3][34],P[2][34],P[1][34],P[0][34]};
	assign Input[35]={P[15][35],P[14][35],P[13][35],P[12][35],P[11][35],P[10][35],P[9][35],P[8][35],P[7][35],P[6][35],P[5][35],P[4][35],P[3][35],P[2][35],P[1][35],P[0][35]};
	assign Input[36]={P[15][36],P[14][36],P[13][36],P[12][36],P[11][36],P[10][36],P[9][36],P[8][36],P[7][36],P[6][36],P[5][36],P[4][36],P[3][36],P[2][36],P[1][36],P[0][36]};
	assign Input[37]={P[15][37],P[14][37],P[13][37],P[12][37],P[11][37],P[10][37],P[9][37],P[8][37],P[7][37],P[6][37],P[5][37],P[4][37],P[3][37],P[2][37],P[1][37],P[0][37]};
	assign Input[38]={P[15][38],P[14][38],P[13][38],P[12][38],P[11][38],P[10][38],P[9][38],P[8][38],P[7][38],P[6][38],P[5][38],P[4][38],P[3][38],P[2][38],P[1][38],P[0][38]};
	assign Input[39]={P[15][39],P[14][39],P[13][39],P[12][39],P[11][39],P[10][39],P[9][39],P[8][39],P[7][39],P[6][39],P[5][39],P[4][39],P[3][39],P[2][39],P[1][39],P[0][39]};
	assign Input[40]={P[15][40],P[14][40],P[13][40],P[12][40],P[11][40],P[10][40],P[9][40],P[8][40],P[7][40],P[6][40],P[5][40],P[4][40],P[3][40],P[2][40],P[1][40],P[0][40]};
	assign Input[41]={P[15][41],P[14][41],P[13][41],P[12][41],P[11][41],P[10][41],P[9][41],P[8][41],P[7][41],P[6][41],P[5][41],P[4][41],P[3][41],P[2][41],P[1][41],P[0][41]};
	assign Input[42]={P[15][42],P[14][42],P[13][42],P[12][42],P[11][42],P[10][42],P[9][42],P[8][42],P[7][42],P[6][42],P[5][42],P[4][42],P[3][42],P[2][42],P[1][42],P[0][42]};
	assign Input[43]={P[15][43],P[14][43],P[13][43],P[12][43],P[11][43],P[10][43],P[9][43],P[8][43],P[7][43],P[6][43],P[5][43],P[4][43],P[3][43],P[2][43],P[1][43],P[0][43]};
	assign Input[44]={P[15][44],P[14][44],P[13][44],P[12][44],P[11][44],P[10][44],P[9][44],P[8][44],P[7][44],P[6][44],P[5][44],P[4][44],P[3][44],P[2][44],P[1][44],P[0][44]};
	assign Input[45]={P[15][45],P[14][45],P[13][45],P[12][45],P[11][45],P[10][45],P[9][45],P[8][45],P[7][45],P[6][45],P[5][45],P[4][45],P[3][45],P[2][45],P[1][45],P[0][45]};
	assign Input[46]={P[15][46],P[14][46],P[13][46],P[12][46],P[11][46],P[10][46],P[9][46],P[8][46],P[7][46],P[6][46],P[5][46],P[4][46],P[3][46],P[2][46],P[1][46],P[0][46]};
	assign Input[47]={P[15][47],P[14][47],P[13][47],P[12][47],P[11][47],P[10][47],P[9][47],P[8][47],P[7][47],P[6][47],P[5][47],P[4][47],P[3][47],P[2][47],P[1][47],P[0][47]};
	assign Input[48]={P[15][48],P[14][48],P[13][48],P[12][48],P[11][48],P[10][48],P[9][48],P[8][48],P[7][48],P[6][48],P[5][48],P[4][48],P[3][48],P[2][48],P[1][48],P[0][48]};
	assign Input[49]={P[15][49],P[14][49],P[13][49],P[12][49],P[11][49],P[10][49],P[9][49],P[8][49],P[7][49],P[6][49],P[5][49],P[4][49],P[3][49],P[2][49],P[1][49],P[0][49]};
	assign Input[50]={P[15][50],P[14][50],P[13][50],P[12][50],P[11][50],P[10][50],P[9][50],P[8][50],P[7][50],P[6][50],P[5][50],P[4][50],P[3][50],P[2][50],P[1][50],P[0][50]};
	assign Input[51]={P[15][51],P[14][51],P[13][51],P[12][51],P[11][51],P[10][51],P[9][51],P[8][51],P[7][51],P[6][51],P[5][51],P[4][51],P[3][51],P[2][51],P[1][51],P[0][51]};
	assign Input[52]={P[15][52],P[14][52],P[13][52],P[12][52],P[11][52],P[10][52],P[9][52],P[8][52],P[7][52],P[6][52],P[5][52],P[4][52],P[3][52],P[2][52],P[1][52],P[0][52]};
	assign Input[53]={P[15][53],P[14][53],P[13][53],P[12][53],P[11][53],P[10][53],P[9][53],P[8][53],P[7][53],P[6][53],P[5][53],P[4][53],P[3][53],P[2][53],P[1][53],P[0][53]};
	assign Input[54]={P[15][54],P[14][54],P[13][54],P[12][54],P[11][54],P[10][54],P[9][54],P[8][54],P[7][54],P[6][54],P[5][54],P[4][54],P[3][54],P[2][54],P[1][54],P[0][54]};
	assign Input[55]={P[15][55],P[14][55],P[13][55],P[12][55],P[11][55],P[10][55],P[9][55],P[8][55],P[7][55],P[6][55],P[5][55],P[4][55],P[3][55],P[2][55],P[1][55],P[0][55]};
	assign Input[56]={P[15][56],P[14][56],P[13][56],P[12][56],P[11][56],P[10][56],P[9][56],P[8][56],P[7][56],P[6][56],P[5][56],P[4][56],P[3][56],P[2][56],P[1][56],P[0][56]};
	assign Input[57]={P[15][57],P[14][57],P[13][57],P[12][57],P[11][57],P[10][57],P[9][57],P[8][57],P[7][57],P[6][57],P[5][57],P[4][57],P[3][57],P[2][57],P[1][57],P[0][57]};
	assign Input[58]={P[15][58],P[14][58],P[13][58],P[12][58],P[11][58],P[10][58],P[9][58],P[8][58],P[7][58],P[6][58],P[5][58],P[4][58],P[3][58],P[2][58],P[1][58],P[0][58]};
	assign Input[59]={P[15][59],P[14][59],P[13][59],P[12][59],P[11][59],P[10][59],P[9][59],P[8][59],P[7][59],P[6][59],P[5][59],P[4][59],P[3][59],P[2][59],P[1][59],P[0][59]};
	assign Input[60]={P[15][60],P[14][60],P[13][60],P[12][60],P[11][60],P[10][60],P[9][60],P[8][60],P[7][60],P[6][60],P[5][60],P[4][60],P[3][60],P[2][60],P[1][60],P[0][60]};
	assign Input[61]={P[15][61],P[14][61],P[13][61],P[12][61],P[11][61],P[10][61],P[9][61],P[8][61],P[7][61],P[6][61],P[5][61],P[4][61],P[3][61],P[2][61],P[1][61],P[0][61]};
	assign Input[62]={P[15][62],P[14][62],P[13][62],P[12][62],P[11][62],P[10][62],P[9][62],P[8][62],P[7][62],P[6][62],P[5][62],P[4][62],P[3][62],P[2][62],P[1][62],P[0][62]};
	assign Input[63]={P[15][63],P[14][63],P[13][63],P[12][63],P[11][63],P[10][63],P[9][63],P[8][63],P[7][63],P[6][63],P[5][63],P[4][63],P[3][63],P[2][63],P[1][63],P[0][63]};

	///////////////////////////////////////////////////////////////////
	//(3)_1，华莱士树前三层
	
	//half_treee_forward tree_node1(.x(Input[0]),.cin(c_between_tree[ -1 ]),.res(FI_to_SE_bus[ 1 : 0 ]),.c_to_next_stage(FI_to_SE_bus[ 5 : 2 ]),.c_to_next_tree(c_between_tree[0 ]));
	
	half_treee_forward tree_node01(.x(Input[ 0]),.cin(c[6:0]            ),.res(FI_to_SE_bus[  1:  0]),.c_to_next_stage(FI_to_SE_bus[  5:  2]),.c_to_next_tree(c_between_tree[ 0]));
	half_treee_forward tree_node02(.x(Input[ 1]),.cin(c_between_tree[ 0]),.res(FI_to_SE_bus[  7:  6]),.c_to_next_stage(FI_to_SE_bus[ 11:  8]),.c_to_next_tree(c_between_tree[ 1]));
	half_treee_forward tree_node03(.x(Input[ 2]),.cin(c_between_tree[ 1]),.res(FI_to_SE_bus[ 13: 12]),.c_to_next_stage(FI_to_SE_bus[ 17: 14]),.c_to_next_tree(c_between_tree[ 2]));
	half_treee_forward tree_node04(.x(Input[ 3]),.cin(c_between_tree[ 2]),.res(FI_to_SE_bus[ 19: 18]),.c_to_next_stage(FI_to_SE_bus[ 23: 20]),.c_to_next_tree(c_between_tree[ 3]));
	half_treee_forward tree_node05(.x(Input[ 4]),.cin(c_between_tree[ 3]),.res(FI_to_SE_bus[ 25: 24]),.c_to_next_stage(FI_to_SE_bus[ 29: 26]),.c_to_next_tree(c_between_tree[ 4]));
	half_treee_forward tree_node06(.x(Input[ 5]),.cin(c_between_tree[ 4]),.res(FI_to_SE_bus[ 31: 30]),.c_to_next_stage(FI_to_SE_bus[ 35: 32]),.c_to_next_tree(c_between_tree[ 5]));
	half_treee_forward tree_node07(.x(Input[ 6]),.cin(c_between_tree[ 5]),.res(FI_to_SE_bus[ 37: 36]),.c_to_next_stage(FI_to_SE_bus[ 41: 38]),.c_to_next_tree(c_between_tree[ 6]));
	half_treee_forward tree_node08(.x(Input[ 7]),.cin(c_between_tree[ 6]),.res(FI_to_SE_bus[ 43: 42]),.c_to_next_stage(FI_to_SE_bus[ 47: 44]),.c_to_next_tree(c_between_tree[ 7]));
	half_treee_forward tree_node09(.x(Input[ 8]),.cin(c_between_tree[ 7]),.res(FI_to_SE_bus[ 49: 48]),.c_to_next_stage(FI_to_SE_bus[ 53: 50]),.c_to_next_tree(c_between_tree[ 8]));
	half_treee_forward tree_node10(.x(Input[ 9]),.cin(c_between_tree[ 8]),.res(FI_to_SE_bus[ 55: 54]),.c_to_next_stage(FI_to_SE_bus[ 59: 56]),.c_to_next_tree(c_between_tree[ 9]));
	half_treee_forward tree_node11(.x(Input[10]),.cin(c_between_tree[ 9]),.res(FI_to_SE_bus[ 61: 60]),.c_to_next_stage(FI_to_SE_bus[ 65: 62]),.c_to_next_tree(c_between_tree[10]));
	half_treee_forward tree_node12(.x(Input[11]),.cin(c_between_tree[10]),.res(FI_to_SE_bus[ 67: 66]),.c_to_next_stage(FI_to_SE_bus[ 71: 68]),.c_to_next_tree(c_between_tree[11]));
	half_treee_forward tree_node13(.x(Input[12]),.cin(c_between_tree[11]),.res(FI_to_SE_bus[ 73: 72]),.c_to_next_stage(FI_to_SE_bus[ 77: 74]),.c_to_next_tree(c_between_tree[12]));
	half_treee_forward tree_node14(.x(Input[13]),.cin(c_between_tree[12]),.res(FI_to_SE_bus[ 79: 78]),.c_to_next_stage(FI_to_SE_bus[ 83: 80]),.c_to_next_tree(c_between_tree[13]));
	half_treee_forward tree_node15(.x(Input[14]),.cin(c_between_tree[13]),.res(FI_to_SE_bus[ 85: 84]),.c_to_next_stage(FI_to_SE_bus[ 89: 86]),.c_to_next_tree(c_between_tree[14]));
	half_treee_forward tree_node16(.x(Input[15]),.cin(c_between_tree[14]),.res(FI_to_SE_bus[ 91: 90]),.c_to_next_stage(FI_to_SE_bus[ 95: 92]),.c_to_next_tree(c_between_tree[15]));
	half_treee_forward tree_node17(.x(Input[16]),.cin(c_between_tree[15]),.res(FI_to_SE_bus[ 97: 96]),.c_to_next_stage(FI_to_SE_bus[101: 98]),.c_to_next_tree(c_between_tree[16]));
	half_treee_forward tree_node18(.x(Input[17]),.cin(c_between_tree[16]),.res(FI_to_SE_bus[103:102]),.c_to_next_stage(FI_to_SE_bus[107:104]),.c_to_next_tree(c_between_tree[17]));
	half_treee_forward tree_node19(.x(Input[18]),.cin(c_between_tree[17]),.res(FI_to_SE_bus[109:108]),.c_to_next_stage(FI_to_SE_bus[113:110]),.c_to_next_tree(c_between_tree[18]));
	half_treee_forward tree_node20(.x(Input[19]),.cin(c_between_tree[18]),.res(FI_to_SE_bus[115:114]),.c_to_next_stage(FI_to_SE_bus[119:116]),.c_to_next_tree(c_between_tree[19]));
	half_treee_forward tree_node21(.x(Input[20]),.cin(c_between_tree[19]),.res(FI_to_SE_bus[121:120]),.c_to_next_stage(FI_to_SE_bus[125:122]),.c_to_next_tree(c_between_tree[20]));
	half_treee_forward tree_node22(.x(Input[21]),.cin(c_between_tree[20]),.res(FI_to_SE_bus[127:126]),.c_to_next_stage(FI_to_SE_bus[131:128]),.c_to_next_tree(c_between_tree[21]));
	half_treee_forward tree_node23(.x(Input[22]),.cin(c_between_tree[21]),.res(FI_to_SE_bus[133:132]),.c_to_next_stage(FI_to_SE_bus[137:134]),.c_to_next_tree(c_between_tree[22]));
	half_treee_forward tree_node24(.x(Input[23]),.cin(c_between_tree[22]),.res(FI_to_SE_bus[139:138]),.c_to_next_stage(FI_to_SE_bus[143:140]),.c_to_next_tree(c_between_tree[23]));
	half_treee_forward tree_node25(.x(Input[24]),.cin(c_between_tree[23]),.res(FI_to_SE_bus[145:144]),.c_to_next_stage(FI_to_SE_bus[149:146]),.c_to_next_tree(c_between_tree[24]));
	half_treee_forward tree_node26(.x(Input[25]),.cin(c_between_tree[24]),.res(FI_to_SE_bus[151:150]),.c_to_next_stage(FI_to_SE_bus[155:152]),.c_to_next_tree(c_between_tree[25]));
	half_treee_forward tree_node27(.x(Input[26]),.cin(c_between_tree[25]),.res(FI_to_SE_bus[157:156]),.c_to_next_stage(FI_to_SE_bus[161:158]),.c_to_next_tree(c_between_tree[26]));
	half_treee_forward tree_node28(.x(Input[27]),.cin(c_between_tree[26]),.res(FI_to_SE_bus[163:162]),.c_to_next_stage(FI_to_SE_bus[167:164]),.c_to_next_tree(c_between_tree[27]));
	half_treee_forward tree_node29(.x(Input[28]),.cin(c_between_tree[27]),.res(FI_to_SE_bus[169:168]),.c_to_next_stage(FI_to_SE_bus[173:170]),.c_to_next_tree(c_between_tree[28]));
	half_treee_forward tree_node30(.x(Input[29]),.cin(c_between_tree[28]),.res(FI_to_SE_bus[175:174]),.c_to_next_stage(FI_to_SE_bus[179:176]),.c_to_next_tree(c_between_tree[29]));
	half_treee_forward tree_node31(.x(Input[30]),.cin(c_between_tree[29]),.res(FI_to_SE_bus[181:180]),.c_to_next_stage(FI_to_SE_bus[185:182]),.c_to_next_tree(c_between_tree[30]));
	half_treee_forward tree_node32(.x(Input[31]),.cin(c_between_tree[30]),.res(FI_to_SE_bus[187:186]),.c_to_next_stage(FI_to_SE_bus[191:188]),.c_to_next_tree(c_between_tree[31]));
	half_treee_forward tree_node33(.x(Input[32]),.cin(c_between_tree[31]),.res(FI_to_SE_bus[193:192]),.c_to_next_stage(FI_to_SE_bus[197:194]),.c_to_next_tree(c_between_tree[32]));
	half_treee_forward tree_node34(.x(Input[33]),.cin(c_between_tree[32]),.res(FI_to_SE_bus[199:198]),.c_to_next_stage(FI_to_SE_bus[203:200]),.c_to_next_tree(c_between_tree[33]));
	half_treee_forward tree_node35(.x(Input[34]),.cin(c_between_tree[33]),.res(FI_to_SE_bus[205:204]),.c_to_next_stage(FI_to_SE_bus[209:206]),.c_to_next_tree(c_between_tree[34]));
	half_treee_forward tree_node36(.x(Input[35]),.cin(c_between_tree[34]),.res(FI_to_SE_bus[211:210]),.c_to_next_stage(FI_to_SE_bus[215:212]),.c_to_next_tree(c_between_tree[35]));
	half_treee_forward tree_node37(.x(Input[36]),.cin(c_between_tree[35]),.res(FI_to_SE_bus[217:216]),.c_to_next_stage(FI_to_SE_bus[221:218]),.c_to_next_tree(c_between_tree[36]));
	half_treee_forward tree_node38(.x(Input[37]),.cin(c_between_tree[36]),.res(FI_to_SE_bus[223:222]),.c_to_next_stage(FI_to_SE_bus[227:224]),.c_to_next_tree(c_between_tree[37]));
	half_treee_forward tree_node39(.x(Input[38]),.cin(c_between_tree[37]),.res(FI_to_SE_bus[229:228]),.c_to_next_stage(FI_to_SE_bus[233:230]),.c_to_next_tree(c_between_tree[38]));
	half_treee_forward tree_node40(.x(Input[39]),.cin(c_between_tree[38]),.res(FI_to_SE_bus[235:234]),.c_to_next_stage(FI_to_SE_bus[239:236]),.c_to_next_tree(c_between_tree[39]));
	half_treee_forward tree_node41(.x(Input[40]),.cin(c_between_tree[39]),.res(FI_to_SE_bus[241:240]),.c_to_next_stage(FI_to_SE_bus[245:242]),.c_to_next_tree(c_between_tree[40]));
	half_treee_forward tree_node42(.x(Input[41]),.cin(c_between_tree[40]),.res(FI_to_SE_bus[247:246]),.c_to_next_stage(FI_to_SE_bus[251:248]),.c_to_next_tree(c_between_tree[41]));
	half_treee_forward tree_node43(.x(Input[42]),.cin(c_between_tree[41]),.res(FI_to_SE_bus[253:252]),.c_to_next_stage(FI_to_SE_bus[257:254]),.c_to_next_tree(c_between_tree[42]));
	half_treee_forward tree_node44(.x(Input[43]),.cin(c_between_tree[42]),.res(FI_to_SE_bus[259:258]),.c_to_next_stage(FI_to_SE_bus[263:260]),.c_to_next_tree(c_between_tree[43]));
	half_treee_forward tree_node45(.x(Input[44]),.cin(c_between_tree[43]),.res(FI_to_SE_bus[265:264]),.c_to_next_stage(FI_to_SE_bus[269:266]),.c_to_next_tree(c_between_tree[44]));
	half_treee_forward tree_node46(.x(Input[45]),.cin(c_between_tree[44]),.res(FI_to_SE_bus[271:270]),.c_to_next_stage(FI_to_SE_bus[275:272]),.c_to_next_tree(c_between_tree[45]));
	half_treee_forward tree_node47(.x(Input[46]),.cin(c_between_tree[45]),.res(FI_to_SE_bus[277:276]),.c_to_next_stage(FI_to_SE_bus[281:278]),.c_to_next_tree(c_between_tree[46]));
	half_treee_forward tree_node48(.x(Input[47]),.cin(c_between_tree[46]),.res(FI_to_SE_bus[283:282]),.c_to_next_stage(FI_to_SE_bus[287:284]),.c_to_next_tree(c_between_tree[47]));
	half_treee_forward tree_node49(.x(Input[48]),.cin(c_between_tree[47]),.res(FI_to_SE_bus[289:288]),.c_to_next_stage(FI_to_SE_bus[293:290]),.c_to_next_tree(c_between_tree[48]));
	half_treee_forward tree_node50(.x(Input[49]),.cin(c_between_tree[48]),.res(FI_to_SE_bus[295:294]),.c_to_next_stage(FI_to_SE_bus[299:296]),.c_to_next_tree(c_between_tree[49]));
	half_treee_forward tree_node51(.x(Input[50]),.cin(c_between_tree[49]),.res(FI_to_SE_bus[301:300]),.c_to_next_stage(FI_to_SE_bus[305:302]),.c_to_next_tree(c_between_tree[50]));
	half_treee_forward tree_node52(.x(Input[51]),.cin(c_between_tree[50]),.res(FI_to_SE_bus[307:306]),.c_to_next_stage(FI_to_SE_bus[311:308]),.c_to_next_tree(c_between_tree[51]));
	half_treee_forward tree_node53(.x(Input[52]),.cin(c_between_tree[51]),.res(FI_to_SE_bus[313:312]),.c_to_next_stage(FI_to_SE_bus[317:314]),.c_to_next_tree(c_between_tree[52]));
	half_treee_forward tree_node54(.x(Input[53]),.cin(c_between_tree[52]),.res(FI_to_SE_bus[319:318]),.c_to_next_stage(FI_to_SE_bus[323:320]),.c_to_next_tree(c_between_tree[53]));
	half_treee_forward tree_node55(.x(Input[54]),.cin(c_between_tree[53]),.res(FI_to_SE_bus[325:324]),.c_to_next_stage(FI_to_SE_bus[329:326]),.c_to_next_tree(c_between_tree[54]));
	half_treee_forward tree_node56(.x(Input[55]),.cin(c_between_tree[54]),.res(FI_to_SE_bus[331:330]),.c_to_next_stage(FI_to_SE_bus[335:332]),.c_to_next_tree(c_between_tree[55]));
	half_treee_forward tree_node57(.x(Input[56]),.cin(c_between_tree[55]),.res(FI_to_SE_bus[337:336]),.c_to_next_stage(FI_to_SE_bus[341:338]),.c_to_next_tree(c_between_tree[56]));
	half_treee_forward tree_node58(.x(Input[57]),.cin(c_between_tree[56]),.res(FI_to_SE_bus[343:342]),.c_to_next_stage(FI_to_SE_bus[347:344]),.c_to_next_tree(c_between_tree[57]));
	half_treee_forward tree_node59(.x(Input[58]),.cin(c_between_tree[57]),.res(FI_to_SE_bus[349:348]),.c_to_next_stage(FI_to_SE_bus[353:350]),.c_to_next_tree(c_between_tree[58]));
	half_treee_forward tree_node60(.x(Input[59]),.cin(c_between_tree[58]),.res(FI_to_SE_bus[355:354]),.c_to_next_stage(FI_to_SE_bus[359:356]),.c_to_next_tree(c_between_tree[59]));
	half_treee_forward tree_node61(.x(Input[60]),.cin(c_between_tree[59]),.res(FI_to_SE_bus[361:360]),.c_to_next_stage(FI_to_SE_bus[365:362]),.c_to_next_tree(c_between_tree[60]));
	half_treee_forward tree_node62(.x(Input[61]),.cin(c_between_tree[60]),.res(FI_to_SE_bus[367:366]),.c_to_next_stage(FI_to_SE_bus[371:368]),.c_to_next_tree(c_between_tree[61]));
	half_treee_forward tree_node63(.x(Input[62]),.cin(c_between_tree[61]),.res(FI_to_SE_bus[373:372]),.c_to_next_stage(FI_to_SE_bus[377:374]),.c_to_next_tree(c_between_tree[62]));
	half_treee_forward tree_node64(.x(Input[63]),.cin(c_between_tree[62]),.res(FI_to_SE_bus[379:378]),.c_to_next_stage(waste2               ),.c_to_next_tree(waste1            ));
	
	assign FI_to_SE_bus[388:380]=c[15:7];
	
endmodule           
