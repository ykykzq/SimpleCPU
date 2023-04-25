`include "mul.h"
module mul_stage2(
	input  wire							mul_clk,
	input  wire							resetn,
	input  wire[`FI_TO_SE_BUS_WD-1:0]	FI_to_SE_bus,
	
	output wire[63:0]					result
    );
	reg	[`FI_TO_SE_BUS_WD-1:0]	FI_to_SE_reg;
	
	
	//树间通讯
	wire[2:0]	c_between_tree[62:0];
	
	//垃圾
	wire[2:0]	waste;
	
	//64位加法器的两个操作数
	wire[63:0]	adder_C;
	wire[63:0]	adder_S;
	
	////////////////////////////////////////////////////
	//接收数据
	always@(posedge mul_clk)
	begin
		if(!resetn)
			FI_to_SE_reg<=`FI_TO_SE_BUS_WD'b0;
		else
			FI_to_SE_reg<=FI_to_SE_bus;
	end
	
	///////////////////////////////////////////////////
	//(3)_2,华莱士树的后半段
	half_tree_behind tree_node01(.x(FI_to_SE_reg[  1:  0]),.cin(FI_to_SE_reg[386:380]),                     .C(adder_C[ 0]),.S(adder_S[ 0]),.c_to_next_tree(c_between_tree[ 0]));
	half_tree_behind tree_node02(.x(FI_to_SE_reg[  7:  6]),.cin({c_between_tree[ 0],FI_to_SE_reg[   5: 2]}),.C(adder_C[ 1]),.S(adder_S[ 1]),.c_to_next_tree(c_between_tree[ 1]));
	half_tree_behind tree_node03(.x(FI_to_SE_reg[ 13: 12]),.cin({c_between_tree[ 1],FI_to_SE_reg[ 11:  8]}),.C(adder_C[ 2]),.S(adder_S[ 2]),.c_to_next_tree(c_between_tree[ 2]));
	half_tree_behind tree_node04(.x(FI_to_SE_reg[ 19: 18]),.cin({c_between_tree[ 2],FI_to_SE_reg[ 17: 14]}),.C(adder_C[ 3]),.S(adder_S[ 3]),.c_to_next_tree(c_between_tree[ 3]));
	half_tree_behind tree_node05(.x(FI_to_SE_reg[ 25: 24]),.cin({c_between_tree[ 3],FI_to_SE_reg[ 23: 20]}),.C(adder_C[ 4]),.S(adder_S[ 4]),.c_to_next_tree(c_between_tree[ 4]));
	half_tree_behind tree_node06(.x(FI_to_SE_reg[ 31: 30]),.cin({c_between_tree[ 4],FI_to_SE_reg[ 29: 26]}),.C(adder_C[ 5]),.S(adder_S[ 5]),.c_to_next_tree(c_between_tree[ 5]));
	half_tree_behind tree_node07(.x(FI_to_SE_reg[ 37: 36]),.cin({c_between_tree[ 5],FI_to_SE_reg[ 35: 32]}),.C(adder_C[ 6]),.S(adder_S[ 6]),.c_to_next_tree(c_between_tree[ 6]));
	half_tree_behind tree_node08(.x(FI_to_SE_reg[ 43: 42]),.cin({c_between_tree[ 6],FI_to_SE_reg[ 41: 38]}),.C(adder_C[ 7]),.S(adder_S[ 7]),.c_to_next_tree(c_between_tree[ 7]));
	half_tree_behind tree_node09(.x(FI_to_SE_reg[ 49: 48]),.cin({c_between_tree[ 7],FI_to_SE_reg[ 47: 44]}),.C(adder_C[ 8]),.S(adder_S[ 8]),.c_to_next_tree(c_between_tree[ 8]));
	half_tree_behind tree_node10(.x(FI_to_SE_reg[ 55: 54]),.cin({c_between_tree[ 8],FI_to_SE_reg[ 53: 50]}),.C(adder_C[ 9]),.S(adder_S[ 9]),.c_to_next_tree(c_between_tree[ 9]));
	half_tree_behind tree_node11(.x(FI_to_SE_reg[ 61: 60]),.cin({c_between_tree[ 9],FI_to_SE_reg[ 59: 56]}),.C(adder_C[10]),.S(adder_S[10]),.c_to_next_tree(c_between_tree[10]));
	half_tree_behind tree_node12(.x(FI_to_SE_reg[ 67: 66]),.cin({c_between_tree[10],FI_to_SE_reg[ 65: 62]}),.C(adder_C[11]),.S(adder_S[11]),.c_to_next_tree(c_between_tree[11]));
	half_tree_behind tree_node13(.x(FI_to_SE_reg[ 73: 72]),.cin({c_between_tree[11],FI_to_SE_reg[ 71: 68]}),.C(adder_C[12]),.S(adder_S[12]),.c_to_next_tree(c_between_tree[12]));
	half_tree_behind tree_node14(.x(FI_to_SE_reg[ 79: 78]),.cin({c_between_tree[12],FI_to_SE_reg[ 77: 74]}),.C(adder_C[13]),.S(adder_S[13]),.c_to_next_tree(c_between_tree[13]));
	half_tree_behind tree_node15(.x(FI_to_SE_reg[ 85: 84]),.cin({c_between_tree[13],FI_to_SE_reg[ 83: 80]}),.C(adder_C[14]),.S(adder_S[14]),.c_to_next_tree(c_between_tree[14]));
	half_tree_behind tree_node16(.x(FI_to_SE_reg[ 91: 90]),.cin({c_between_tree[14],FI_to_SE_reg[ 89: 86]}),.C(adder_C[15]),.S(adder_S[15]),.c_to_next_tree(c_between_tree[15]));
	half_tree_behind tree_node17(.x(FI_to_SE_reg[ 97: 96]),.cin({c_between_tree[15],FI_to_SE_reg[ 95: 92]}),.C(adder_C[16]),.S(adder_S[16]),.c_to_next_tree(c_between_tree[16]));
	half_tree_behind tree_node18(.x(FI_to_SE_reg[103:102]),.cin({c_between_tree[16],FI_to_SE_reg[101: 98]}),.C(adder_C[17]),.S(adder_S[17]),.c_to_next_tree(c_between_tree[17]));
	half_tree_behind tree_node19(.x(FI_to_SE_reg[109:108]),.cin({c_between_tree[17],FI_to_SE_reg[107:104]}),.C(adder_C[18]),.S(adder_S[18]),.c_to_next_tree(c_between_tree[18]));
	half_tree_behind tree_node20(.x(FI_to_SE_reg[115:114]),.cin({c_between_tree[18],FI_to_SE_reg[113:110]}),.C(adder_C[19]),.S(adder_S[19]),.c_to_next_tree(c_between_tree[19]));
	half_tree_behind tree_node21(.x(FI_to_SE_reg[121:120]),.cin({c_between_tree[19],FI_to_SE_reg[119:116]}),.C(adder_C[20]),.S(adder_S[20]),.c_to_next_tree(c_between_tree[20]));
	half_tree_behind tree_node22(.x(FI_to_SE_reg[127:126]),.cin({c_between_tree[20],FI_to_SE_reg[125:122]}),.C(adder_C[21]),.S(adder_S[21]),.c_to_next_tree(c_between_tree[21]));
	half_tree_behind tree_node23(.x(FI_to_SE_reg[133:132]),.cin({c_between_tree[21],FI_to_SE_reg[131:128]}),.C(adder_C[22]),.S(adder_S[22]),.c_to_next_tree(c_between_tree[22]));
	half_tree_behind tree_node24(.x(FI_to_SE_reg[139:138]),.cin({c_between_tree[22],FI_to_SE_reg[137:134]}),.C(adder_C[23]),.S(adder_S[23]),.c_to_next_tree(c_between_tree[23]));
	half_tree_behind tree_node25(.x(FI_to_SE_reg[145:144]),.cin({c_between_tree[23],FI_to_SE_reg[143:140]}),.C(adder_C[24]),.S(adder_S[24]),.c_to_next_tree(c_between_tree[24]));
	half_tree_behind tree_node26(.x(FI_to_SE_reg[151:150]),.cin({c_between_tree[24],FI_to_SE_reg[149:146]}),.C(adder_C[25]),.S(adder_S[25]),.c_to_next_tree(c_between_tree[25]));
	half_tree_behind tree_node27(.x(FI_to_SE_reg[157:156]),.cin({c_between_tree[25],FI_to_SE_reg[155:152]}),.C(adder_C[26]),.S(adder_S[26]),.c_to_next_tree(c_between_tree[26]));
	half_tree_behind tree_node28(.x(FI_to_SE_reg[163:162]),.cin({c_between_tree[26],FI_to_SE_reg[161:158]}),.C(adder_C[27]),.S(adder_S[27]),.c_to_next_tree(c_between_tree[27]));
	half_tree_behind tree_node29(.x(FI_to_SE_reg[169:168]),.cin({c_between_tree[27],FI_to_SE_reg[167:164]}),.C(adder_C[28]),.S(adder_S[28]),.c_to_next_tree(c_between_tree[28]));
	half_tree_behind tree_node30(.x(FI_to_SE_reg[175:174]),.cin({c_between_tree[28],FI_to_SE_reg[173:170]}),.C(adder_C[29]),.S(adder_S[29]),.c_to_next_tree(c_between_tree[29]));
	half_tree_behind tree_node31(.x(FI_to_SE_reg[181:180]),.cin({c_between_tree[29],FI_to_SE_reg[179:176]}),.C(adder_C[30]),.S(adder_S[30]),.c_to_next_tree(c_between_tree[30]));
	half_tree_behind tree_node32(.x(FI_to_SE_reg[187:186]),.cin({c_between_tree[30],FI_to_SE_reg[185:182]}),.C(adder_C[31]),.S(adder_S[31]),.c_to_next_tree(c_between_tree[31]));
	half_tree_behind tree_node33(.x(FI_to_SE_reg[193:192]),.cin({c_between_tree[31],FI_to_SE_reg[191:188]}),.C(adder_C[32]),.S(adder_S[32]),.c_to_next_tree(c_between_tree[32]));
	half_tree_behind tree_node34(.x(FI_to_SE_reg[199:198]),.cin({c_between_tree[32],FI_to_SE_reg[197:194]}),.C(adder_C[33]),.S(adder_S[33]),.c_to_next_tree(c_between_tree[33]));
	half_tree_behind tree_node35(.x(FI_to_SE_reg[205:204]),.cin({c_between_tree[33],FI_to_SE_reg[203:200]}),.C(adder_C[34]),.S(adder_S[34]),.c_to_next_tree(c_between_tree[34]));
	half_tree_behind tree_node36(.x(FI_to_SE_reg[211:210]),.cin({c_between_tree[34],FI_to_SE_reg[209:206]}),.C(adder_C[35]),.S(adder_S[35]),.c_to_next_tree(c_between_tree[35]));
	half_tree_behind tree_node37(.x(FI_to_SE_reg[217:216]),.cin({c_between_tree[35],FI_to_SE_reg[215:212]}),.C(adder_C[36]),.S(adder_S[36]),.c_to_next_tree(c_between_tree[36]));
	half_tree_behind tree_node38(.x(FI_to_SE_reg[223:222]),.cin({c_between_tree[36],FI_to_SE_reg[221:218]}),.C(adder_C[37]),.S(adder_S[37]),.c_to_next_tree(c_between_tree[37]));
	half_tree_behind tree_node39(.x(FI_to_SE_reg[229:228]),.cin({c_between_tree[37],FI_to_SE_reg[227:224]}),.C(adder_C[38]),.S(adder_S[38]),.c_to_next_tree(c_between_tree[38]));
	half_tree_behind tree_node40(.x(FI_to_SE_reg[235:234]),.cin({c_between_tree[38],FI_to_SE_reg[233:230]}),.C(adder_C[39]),.S(adder_S[39]),.c_to_next_tree(c_between_tree[39]));
	half_tree_behind tree_node41(.x(FI_to_SE_reg[241:240]),.cin({c_between_tree[39],FI_to_SE_reg[239:236]}),.C(adder_C[40]),.S(adder_S[40]),.c_to_next_tree(c_between_tree[40]));
	half_tree_behind tree_node42(.x(FI_to_SE_reg[247:246]),.cin({c_between_tree[40],FI_to_SE_reg[245:242]}),.C(adder_C[41]),.S(adder_S[41]),.c_to_next_tree(c_between_tree[41]));
	half_tree_behind tree_node43(.x(FI_to_SE_reg[253:252]),.cin({c_between_tree[41],FI_to_SE_reg[251:248]}),.C(adder_C[42]),.S(adder_S[42]),.c_to_next_tree(c_between_tree[42]));
	half_tree_behind tree_node44(.x(FI_to_SE_reg[259:258]),.cin({c_between_tree[42],FI_to_SE_reg[257:254]}),.C(adder_C[43]),.S(adder_S[43]),.c_to_next_tree(c_between_tree[43]));
	half_tree_behind tree_node45(.x(FI_to_SE_reg[265:264]),.cin({c_between_tree[43],FI_to_SE_reg[263:260]}),.C(adder_C[44]),.S(adder_S[44]),.c_to_next_tree(c_between_tree[44]));
	half_tree_behind tree_node46(.x(FI_to_SE_reg[271:270]),.cin({c_between_tree[44],FI_to_SE_reg[269:266]}),.C(adder_C[45]),.S(adder_S[45]),.c_to_next_tree(c_between_tree[45]));
	half_tree_behind tree_node47(.x(FI_to_SE_reg[277:276]),.cin({c_between_tree[45],FI_to_SE_reg[275:272]}),.C(adder_C[46]),.S(adder_S[46]),.c_to_next_tree(c_between_tree[46]));
	half_tree_behind tree_node48(.x(FI_to_SE_reg[283:282]),.cin({c_between_tree[46],FI_to_SE_reg[281:278]}),.C(adder_C[47]),.S(adder_S[47]),.c_to_next_tree(c_between_tree[47]));
	half_tree_behind tree_node49(.x(FI_to_SE_reg[289:288]),.cin({c_between_tree[47],FI_to_SE_reg[287:284]}),.C(adder_C[48]),.S(adder_S[48]),.c_to_next_tree(c_between_tree[48]));
	half_tree_behind tree_node50(.x(FI_to_SE_reg[295:294]),.cin({c_between_tree[48],FI_to_SE_reg[293:290]}),.C(adder_C[49]),.S(adder_S[49]),.c_to_next_tree(c_between_tree[49]));
	half_tree_behind tree_node51(.x(FI_to_SE_reg[301:300]),.cin({c_between_tree[49],FI_to_SE_reg[299:296]}),.C(adder_C[50]),.S(adder_S[50]),.c_to_next_tree(c_between_tree[50]));
	half_tree_behind tree_node52(.x(FI_to_SE_reg[307:306]),.cin({c_between_tree[50],FI_to_SE_reg[305:302]}),.C(adder_C[51]),.S(adder_S[51]),.c_to_next_tree(c_between_tree[51]));
	half_tree_behind tree_node53(.x(FI_to_SE_reg[313:312]),.cin({c_between_tree[51],FI_to_SE_reg[311:308]}),.C(adder_C[52]),.S(adder_S[52]),.c_to_next_tree(c_between_tree[52]));
	half_tree_behind tree_node54(.x(FI_to_SE_reg[319:318]),.cin({c_between_tree[52],FI_to_SE_reg[317:314]}),.C(adder_C[53]),.S(adder_S[53]),.c_to_next_tree(c_between_tree[53]));
	half_tree_behind tree_node55(.x(FI_to_SE_reg[325:324]),.cin({c_between_tree[53],FI_to_SE_reg[323:320]}),.C(adder_C[54]),.S(adder_S[54]),.c_to_next_tree(c_between_tree[54]));
	half_tree_behind tree_node56(.x(FI_to_SE_reg[331:330]),.cin({c_between_tree[54],FI_to_SE_reg[329:326]}),.C(adder_C[55]),.S(adder_S[55]),.c_to_next_tree(c_between_tree[55]));
	half_tree_behind tree_node57(.x(FI_to_SE_reg[337:336]),.cin({c_between_tree[55],FI_to_SE_reg[335:332]}),.C(adder_C[56]),.S(adder_S[56]),.c_to_next_tree(c_between_tree[56]));
	half_tree_behind tree_node58(.x(FI_to_SE_reg[343:342]),.cin({c_between_tree[56],FI_to_SE_reg[341:338]}),.C(adder_C[57]),.S(adder_S[57]),.c_to_next_tree(c_between_tree[57]));
	half_tree_behind tree_node59(.x(FI_to_SE_reg[349:348]),.cin({c_between_tree[57],FI_to_SE_reg[347:344]}),.C(adder_C[58]),.S(adder_S[58]),.c_to_next_tree(c_between_tree[58]));
	half_tree_behind tree_node60(.x(FI_to_SE_reg[355:354]),.cin({c_between_tree[58],FI_to_SE_reg[353:350]}),.C(adder_C[59]),.S(adder_S[59]),.c_to_next_tree(c_between_tree[59]));
	half_tree_behind tree_node61(.x(FI_to_SE_reg[361:360]),.cin({c_between_tree[59],FI_to_SE_reg[359:356]}),.C(adder_C[60]),.S(adder_S[60]),.c_to_next_tree(c_between_tree[60]));
	half_tree_behind tree_node62(.x(FI_to_SE_reg[367:366]),.cin({c_between_tree[60],FI_to_SE_reg[365:362]}),.C(adder_C[61]),.S(adder_S[61]),.c_to_next_tree(c_between_tree[61]));
	half_tree_behind tree_node63(.x(FI_to_SE_reg[373:372]),.cin({c_between_tree[61],FI_to_SE_reg[371:368]}),.C(adder_C[62]),.S(adder_S[62]),.c_to_next_tree(c_between_tree[62]));
	half_tree_behind tree_node64(.x(FI_to_SE_reg[379:378]),.cin({c_between_tree[62],FI_to_SE_reg[377:374]}),.C(adder_C[63]),.S(adder_S[63]),.c_to_next_tree(waste             ));
                                                                                                 //383:380]
	//////////////////////////////////////////////////////////
	//加法器
	assign result={adder_C[62:0],FI_to_SE_reg[387]}+adder_S+FI_to_SE_reg[388];

endmodule
