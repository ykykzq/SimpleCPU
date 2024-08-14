/**
 * @file IPD_stage.v
 * @author ykykzq
 * @brief 流水线第二级，完成：pre-decoder，包括判断指令类型，决定源操作寄存器号
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include"./include/myCPU.h"
module IPreD_stage(
    input								clk,
	input								reset,

    //流水线数据传输
	input  wire[`IF_TO_IPD_BUS_WD-1:0]	IF_to_IPD_bus,
	output wire[`ID_TO_EXE_BUS_WD-1:0]	IPD_to_ID_bus,
    input  wire[`ID_TO_IPD_BUS_WD-1:0]  ID_to_IPD_bus,
    //inst RAM
    input  wire[31:0]					inst_ram_r_data,
	
	//流水线控制
	input  wire							ID_allow_in,
	input  wire							IF_to_IPD_valid,
	output wire							IPD_allow_in,
	output wire							IPD_to_ID_valid
);
    // 当前指令的PC
	wire [31: 0]	inst_PC;

    // 流水线控制信号
    wire						IPD_ready_go    ;
	reg							IPD_valid       ;

    // IF/IPD REG
    reg [`IF_TO_IPD_BUS_WD-1:0] IF_to_IPD_reg   ;

    // PC与分支预测相关
    wire                        br_taken_cancel ;
    wire [31: 0]                PC_fromID       ;
    wire [31: 0]                pred_PC       ;

    // 指令类型
    wire [`INST_TYPE_WD-1: 0]	inst_type;
    //加减
    wire    inst_addi_w     ;
    wire    inst_add_w      ;
    wire    inst_sub_w      ;
    wire    inst_or         ;
    wire    inst_ori        ;
    wire    inst_nor        ;
    wire    inst_andi       ;
    wire    inst_and        ;
    wire    inst_xor        ;
    wire    inst_srli_w     ;
    wire    inst_slli_w     ;
    wire    inst_srai_w     ;
    wire    inst_lu12i_w    ;
    wire    inst_pcaddu12i  ;
    wire    inst_slt        ;
    wire    inst_sltu       ;
    // 乘除
    wire    inst_mul_w      ;
    // 跳转   
    wire    inst_jirl       ;
    wire    inst_b          ;
    wire    inst_beq        ;
    wire    inst_bne        ;
    wire    inst_bl         ;
    // 访存
    wire    inst_st_w       ;
    wire    inst_ld_w       ;
    wire    inst_st_b       ;
    wire    inst_ld_b       ;

    // 三寄存器号与立即数
    wire [ 4: 0]                RegFile_R_addr1 ;
    wire [ 4: 0]                RegFile_R_addr2 ;
    wire [ 4: 0]                RegFile_W_addr  ;
    wire [31: 0]                immediate       ;

    // 指令与指令字段
    wire [31: 0]                inst            ;
    wire [ 4: 0]                rk              ;
    wire [ 4: 0]                rj              ;
    wire [ 4: 0]                rd              ;
    wire [21: 0]                opcode_22b      ;
    wire [16: 0]                opcode_17b      ;
    wire [ 9: 0]                opcode_10b      ;
    wire [ 7: 0]                opcode_08b      ;
    wire [ 6: 0]                opcode_07b      ;
    wire [ 5: 0]                opcode_06b      ;

    ////////////////////////////////////////
    ///流水线控制

    // 认为一周期内必能完成pre-decode
    assign IPD_ready_go=1'b1;
	assign IPD_allow_in=(~IPD_valid)|(IPD_ready_go & ID_allow_in);
	assign IPD_to_ID_valid=IPD_ready_go&IPD_valid;
    always@(posedge clk)
    begin
        if(reset)
            IPD_valid<=1'b0;
        // else if(br_taken_cancel)
        //     // 分支预测失败，flush
        //     IPD_valid<=1'b0;
        else if(IPD_allow_in)
            IPD_valid<=IF_to_IPD_valid;
        else 
            IPD_valid<=IPD_valid;
    end

    ////////////////////////////////////////
    /// 判断指令类型

    assign inst=inst_ram_r_data;

    assign rk=inst[14:10];
    assign rj=inst[ 9: 5];
    assign rd=inst[ 4: 0];
    assign opcode_22b=inst[31:10];
    assign opcode_17b=inst[31:15];
    assign opcode_10b=inst[31:22];
    assign opcode_08b=inst[31:24];
    assign opcode_07b=inst[31:25];
    assign opcode_06b=inst[31:26];

    //算数逻辑运算
    assign inst_addi_w      = opcode_10b==10'b000_0000_1010;
    assign inst_add_w       = opcode_17b==17'b0_0000_0000_0010_0000;
    assign inst_sub_w       = opcode_17b==17'b0_0000_0000_0010_0010;
    assign inst_or          = opcode_17b==17'b0_0000_0000_0010_1010;
    assign inst_ori         = opcode_10b==10'b00_0000_1110;
    assign inst_nor         = opcode_17b==17'b0_0000_0000_0010_1000;
    assign inst_andi        = opcode_10b==10'b00_0000_1101;
    assign inst_and         = opcode_17b==17'b0_0000_0000_0010_1001;
    assign inst_xor         = opcode_17b==17'b0_0000_0000_0010_1011;
    assign inst_srli_w      = opcode_17b==17'b0_0000_0000_1000_1001;
    assign inst_slli_w      = opcode_17b==17'b0_0000_0000_1000_0001;
    assign inst_srai_w      = opcode_17b==17'b0_0000_0000_1001_0001;
    assign inst_lu12i_w     = opcode_07b==6'b000_1010;
    assign inst_pcaddu12i   = opcode_07b==6'b000_1110;
    assign inst_slt         = opcode_17b==17'b0_0000_0000_0010_0100;
    assign inst_sltu        = opcode_17b==17'b0_0000_0000_0010_0101;
    //乘除             
    assign inst_mul_w       = opcode_17b==17'b0_0000_0000_0011_1000;
    //分支跳转                
    assign inst_jirl        = opcode_06b==6'b01_0011;
    assign inst_b           = opcode_06b==6'b01_0100;
    assign inst_beq         = opcode_06b==6'b01_0110;
    assign inst_bne         = opcode_06b==6'b01_0111;
    assign inst_bl          = opcode_06b==6'b01_0101;
    //访存
    assign inst_st_w        = opcode_10b==10'b00_1010_0110;
    assign inst_ld_w        = opcode_10b==10'b00_1010_0010;
    assign inst_st_b        = opcode_10b==10'b00_1010_0100;
    assign inst_ld_b        = opcode_10b==10'b00_1010_0000;


    assign inst_type        ={
            //加减
            inst_addi_w     ,
            inst_add_w      ,
            inst_sub_w      ,
            inst_or         ,
            inst_ori        ,
            inst_nor        ,
            inst_andi       ,
            inst_and        ,
            inst_xor        ,
            inst_srli_w     ,
            inst_slli_w     ,
            inst_srai_w     ,
            inst_lu12i_w    ,
            inst_pcaddu12i  ,
            inst_slt        ,
            inst_sltu       ,
            // 乘除
            inst_mul_w      ,
            // 跳转   
            inst_jirl       ,
            inst_b          ,
            inst_beq        ,
            inst_bne        ,
            inst_bl         ,
            // 访存
            inst_st_w       ,
            inst_ld_w       ,
            inst_st_b       ,
            inst_ld_b       
    };
    ///////////////////////////////////////////
    /// 决定读写寄存器号

    /*
    指令与用到的寄存器列表
        +------------+----+----+----+
        | inst       | rk | rj | rd |
        +------------+----+----+----+
        | addi.w     |    | R  | W  |
        | add.w      | R  | R  | W  |
        | sub.w      | R  | R  | W  |
        | mul.w      | R  | R  | W  |
        | or         | R  | R  | W  |
        | ori        |    | R  | W  |
        | nor        | R  | R  | W  |
        | andi       |    | R  | W  |
        | and        | R  | R  | W  |
        | xor        | R  | R  | W  |
        | srli.w     |    | R  | W  |
        | slli.w     |    | R  | W  |
        | srai.w     |    | R  | W  |
        | lu12i.w    |    |    | W  |
        | pcaddu12i  |    |    | W  |
        | slt        | R  | R  | W  |
        | sltu       | R  | R  | W  |
        | jirl       |    | R  | W  |
        | b          |    |    |    |
        | beq        |    | R  | R  |
        | bne        |    | R  | R  |
        | bl         |    |    |    |
        | st.w       |    | R  | R  |
        | ld.w       |    | R  | W  |
        | st.b       |    | R  | R  |
        | ld.b       |    | R  | W  |
        +------------+----+----+----+

    */
    //如果读rk、rj，则分别为1、2。如果读rj、rd，则这俩为1、2。
    assign RegFile_R_addr1=(inst_add_w | inst_sub_w | inst_mul_w | inst_or | inst_nor | inst_and 
                                | inst_xor | inst_slt | inst_sltu)?rk:
                            (    inst_addi_w | inst_ori | inst_andi | inst_srli_w | inst_slli_w | inst_srai_w
                                | inst_jirl | inst_beq | inst_bne | inst_st_w | inst_ld_w | inst_st_b | inst_ld_b)?rj:5'b0;
    assign RegFile_R_addr2=(inst_add_w | inst_sub_w | inst_mul_w | inst_or | inst_nor | inst_and 
                                | inst_xor | inst_slt | inst_sltu)?rj:
                            (inst_beq | inst_bne | inst_st_w)?rd:5'b0;
    assign RegFile_W_addr=(inst_addi_w | inst_add_w | inst_sub_w | inst_or | inst_ori | inst_nor      
                                | inst_andi | inst_and | inst_xor | inst_srli_w | inst_slli_w | inst_srai_w   
                                | inst_lu12i_w | inst_pcaddu12i | inst_slt | inst_sltu | inst_mul_w | inst_jirl     
                                | inst_ld_w | inst_ld_b)?rd
                                    :5'b0;
    ///////////////////////////////////////////
    /// 决定立即数

    /*
        立即数扩展方式依次是：
        SignExtend(si12, 32)
        ZeroExtend(ui12, 32)
        ZeroExtend(ui5, 32)
        {si20, 12'b0}
        SignExtend({offs16, 2'b0}, 32)
        SignExtend({offs26, 2'b0}, 32)
    */
    assign immediate =  (inst_addi_w | inst_st_w | inst_ld_w | inst_st_b | inst_ld_b)?{{20{inst[21]}},inst[21:10]}:
                        (inst_ori | inst_andi )?{20'b0,inst[21:10]}:
                        (inst_srli_w | inst_slli_w | inst_srai_w)?{27'b0,inst[14:10]}:
                        (inst_lu12i_w | inst_pcaddu12i)?{inst[24: 5],12'b0}:
                        (inst_jirl | inst_beq | inst_bne)?{{14{inst[25]}},inst[25:10],2'b0}:
                        (inst_b | inst_bl)?{{4{inst[9]}},inst[ 9: 0],inst[25:10],2'b0}:32'b0;


    ////////////////////////////////////////
    /// 流水级间数据交互

    // 接收
    always@(posedge clk)
	begin
        if(reset)
            IF_to_IPD_reg<=0;
		else if(IF_to_IPD_valid & IPD_allow_in)
			IF_to_IPD_reg<=IF_to_IPD_bus;
        else if(br_taken_cancel)
			//预测错误，flush掉
            IF_to_IPD_reg<=0;
		else
			IF_to_IPD_reg<=IF_to_IPD_reg;
	end
    assign {
        pred_PC		,//95:64
		inst_PC 	 //63:32
		    		 //31:0 预占据inst的位置
    } = IF_to_IPD_reg;

    assign inst=inst_ram_r_data;

    assign {
		br_taken_cancel	,//32
		PC_fromID		 //31:0			
					}=ID_to_IPD_bus;

    // 发送
    assign IPD_to_ID_bus={
            inst_type           ,// xx:111
            pred_PC             ,//110: 79
            inst_PC             ,// 78: 47
            immediate           ,// 46: 15
            RegFile_W_addr      ,// 14: 10
            RegFile_R_addr2     ,//  9:  5
            RegFile_R_addr1      //  4:  0
    };
endmodule
