/**
 * @file IPD_stage.v
 * @author ykykzq
 * @brief 流水线第二级，完成pre-decoder，准备好ID阶段需要的立即数与寄存器号信息；生成ID、EXE、MEM、WB阶段用到的控制信号
 * @version 0.2
 * @date 2024-08-20
 *
 */
`include"./include/myCPU.h"
module IPreD_stage(
    input								clk,
	input								reset,

    //流水线数据传输
	input  wire[`IF_TO_IPD_BUS_WD-1:0]	IF_to_IPD_bus,
	output wire[`IPD_TO_ID_BUS_WD-1:0]	IPD_to_ID_bus,

    input  wire[`ID_TO_IPD_BUS_WD-1:0]  ID_to_IPD_bus,

    output  wire[31:0]                  IPD_to_BU_bus,
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
    wire			IPD_ready_go    ;
	reg				IPD_valid       ;

    // IF/IPD REG
    reg [`IF_TO_IPD_BUS_WD-1:0] IF_to_IPD_reg   ;

    wire            br_taken_cancel ;
    wire [31: 0]    PC_fromID       ;

    // 指令类型
    wire [`INST_TYPE_WD-1: 0]	inst_type;
    // 常规算数运算
    wire    inst_addi_w     ;
    wire    inst_add_w      ;
    wire    inst_sub_w      ;
    wire    inst_or         ;
    wire    inst_ori        ;
    wire    inst_nor        ;
    wire    inst_andi       ;
    wire    inst_and        ;
    wire    inst_xor        ;
    wire    inst_xori       ;
    wire    inst_srl_w      ;
    wire    inst_srli_w     ;
    wire    inst_sll_w      ;
    wire    inst_slli_w     ;
    wire    inst_sra_w      ;
    wire    inst_srai_w     ;
    wire    inst_lu12i_w    ;
    wire    inst_pcaddu12i  ;
    wire    inst_slt        ;
    wire    inst_slti       ;
    wire    inst_sltu       ;
    wire    inst_sltui      ;
    // 乘除
    wire    inst_mul_w      ;
    wire    inst_mulh_w     ;
    wire    inst_mulh_wu    ;
    wire    inst_div_w      ;
    wire    inst_mod_w      ;
    wire    inst_div_wu     ;
    wire    inst_mod_wu     ;
    // 跳转   
    wire    inst_jirl       ;
    wire    inst_b          ;
    wire    inst_beq        ;
    wire    inst_bne        ;
    wire    inst_bge        ;
    wire    inst_bgeu       ;
    wire    inst_bl         ;
    wire    inst_blt        ;
    wire    inst_bltu       ;
    // 访存
    wire    inst_st_w       ;
    wire    inst_ld_w       ;
    wire    inst_st_h       ;
    wire    inst_ld_h       ;
    wire    inst_st_b       ;
    wire    inst_ld_b       ;
    wire    inst_ld_bu      ;
    wire    inst_ld_hu      ;

    // 三寄存器号与立即数
    wire [ 4: 0]                RegFile_r_addr1 ;
    wire [ 4: 0]                RegFile_r_addr2 ;
    wire [ 4: 0]                RegFile_w_addr  ;
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


    // 控制信号-ID
    wire [ 1: 0]                sel_alu_bu_src1    ;
    wire [ 2: 0]                sel_alu_bu_src2    ;

    wire [ 1: 0]                sel_rf_r_addr_1    ;
    wire [ 1: 0]                sel_rf_r_addr_2    ;
    wire [ 1: 0]                sel_rf_w_addr      ;
    
    // 控制信号-EXE
    wire [18: 0]                alu_op          ;
    wire    op_mul_s_l;
    wire    op_mul_s_h;
    wire    op_mul_u_h;
    wire    op_div_s  ;
    wire    op_div_u  ;
    wire    op_mod_s  ;
    wire    op_mod_u  ;
    wire    op_lui;
    wire    op_sra;
    wire    op_srl;
    wire    op_sll;
    wire    op_xor;
    wire    op_or ;
    wire    op_nor;
    wire    op_and;
    wire    op_sltu;
    wire    op_slt;
    wire    op_sub;
    wire    op_add;
    // 控制信号-MEM
    wire            sel_data_ram_we ;
    wire            sel_data_ram_en ;
    wire            sel_data_ram_extend ;
    wire[ 1: 0]     sel_data_ram_wd ;
    // 控制信号-WB
    wire    sel_rf_w_en     ;
    wire    sel_rf_w_data   ;  
    // 控制信号-BY＆WK
    wire [ 2: 0]    sel_rf_w_data_valid_stage;

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
        // 此处不需要flush的原因：next_PC可以在ID发现分支预测失败的那拍直接被纠正，因此下一拍IF的数据实际上是有效的，无需flush掉IF阶段传入的inst
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

    // 算数逻辑运算
    assign inst_addi_w      = opcode_10b==10'b000_0000_1010;
    assign inst_add_w       = opcode_17b==17'b0_0000_0000_0010_0000;
    assign inst_sub_w       = opcode_17b==17'b0_0000_0000_0010_0010;
    assign inst_or          = opcode_17b==17'b0_0000_0000_0010_1010;
    assign inst_ori         = opcode_10b==10'b00_0000_1110;
    assign inst_nor         = opcode_17b==17'b0_0000_0000_0010_1000;
    assign inst_andi        = opcode_10b==10'b00_0000_1101;
    assign inst_and         = opcode_17b==17'b0_0000_0000_0010_1001;
    assign inst_xor         = opcode_17b==17'b0_0000_0000_0010_1011;
    assign inst_xori        = opcode_10b==10'b00_0000_1111;
    assign inst_srl_w       = opcode_17b==17'b0_0000_0000_0010_1111;
    assign inst_srli_w      = opcode_17b==17'b0_0000_0000_1000_1001;
    assign inst_sll_w       = opcode_17b==17'b0_0000_0000_0010_1110;
    assign inst_slli_w      = opcode_17b==17'b0_0000_0000_1000_0001;
    assign inst_sra_w       = opcode_17b==17'b0_0000_0000_0011_0000;
    assign inst_srai_w      = opcode_17b==17'b0_0000_0000_1001_0001;
    assign inst_lu12i_w     = opcode_07b==6'b000_1010;
    assign inst_pcaddu12i   = opcode_07b==6'b000_1110;
    assign inst_slt         = opcode_17b==17'b0_0000_0000_0010_0100;
    assign inst_slti        = opcode_10b==10'b00_0000_1000;
    assign inst_sltu        = opcode_17b==17'b0_0000_0000_0010_0101;
    assign inst_sltui       = opcode_10b==10'b00_0000_1001;
    // 乘除             
    assign inst_mul_w       = opcode_17b==17'b0_0000_0000_0011_1000;
    assign inst_mulh_w      = opcode_17b==17'b0_0000_0000_0011_1001;
    assign inst_mulh_wu     = opcode_17b==17'b0_0000_0000_0011_1010;
    assign inst_div_w       = opcode_17b==17'b0_0000_0000_0100_0000;
    assign inst_mod_w       = opcode_17b==17'b0_0000_0000_0100_0001;
    assign inst_div_wu      = opcode_17b==17'b0_0000_0000_0100_0010;
    assign inst_mod_wu      = opcode_17b==17'b0_0000_0000_0100_0011;
    // 分支跳转                
    assign inst_jirl        = opcode_06b==6'b01_0011;
    assign inst_b           = opcode_06b==6'b01_0100;
    assign inst_beq         = opcode_06b==6'b01_0110;
    assign inst_bne         = opcode_06b==6'b01_0111;
    assign inst_bge         = opcode_06b==6'b01_1001;
    assign inst_bgeu        = opcode_06b==6'b01_1011;
    assign inst_bl          = opcode_06b==6'b01_0101;
    assign inst_blt         = opcode_06b==6'b01_1000;
    assign inst_bltu        = opcode_06b==6'b01_1010;
    // 访存
    assign inst_st_w        = opcode_10b==10'b00_1010_0110;
    assign inst_ld_w        = opcode_10b==10'b00_1010_0010;
    assign inst_st_h        = opcode_10b==10'b00_1010_0101;
    assign inst_ld_h        = opcode_10b==10'b00_1010_0001;
    assign inst_st_b        = opcode_10b==10'b00_1010_0100;
    assign inst_ld_b        = opcode_10b==10'b00_1010_0000;
    assign inst_ld_bu       = opcode_10b==10'b00_1010_1000;
    assign inst_ld_hu       = opcode_10b==10'b00_1010_1001;


    assign inst_type        ={
            // 常规算数运算
            inst_addi_w     ,
            inst_add_w      ,
            inst_sub_w      ,
            inst_or         ,
            inst_ori        ,
            inst_nor        ,
            inst_andi       ,
            inst_and        ,
            inst_xor        ,
            inst_xori       ,
            inst_srl_w      ,
            inst_srli_w     ,
            inst_sll_w      ,
            inst_slli_w     ,
            inst_sra_w      ,
            inst_srai_w     ,
            inst_lu12i_w    ,
            inst_pcaddu12i  ,
            inst_slt        ,
            inst_slti       ,
            inst_sltu       ,
            inst_sltui      ,
            // 乘除
            inst_mul_w      ,
            inst_mulh_w     ,
            inst_mulh_wu    ,
            inst_div_w      ,
            inst_mod_w      ,
            inst_div_wu     ,
            inst_mod_wu     ,
            // 跳转   
            inst_jirl       ,
            inst_b          ,
            inst_beq        ,
            inst_bne        ,
            inst_bge        ,
            inst_bgeu       ,
            inst_bl         ,
            inst_blt        ,
            inst_bltu       ,
            // 访存
            inst_st_w       ,
            inst_ld_w       ,
            inst_st_h       ,
            inst_ld_h       ,
            inst_st_b       ,
            inst_ld_b       ,
            inst_ld_bu      ,
            inst_ld_hu      
    };
    ////////////////////////////////////////////////
    /// 决定读写寄存器号


    /*
        +-----------------+------------+
        | sel_rf_r_addr_1 | r_addr_1   |
        +-----------------+------------+
        | 2'b10           | undefined  |
        | 2'b01           | rj         |
        | 2'b00           | 0(default) |
        +-----------------+------------+
    */
    assign sel_rf_r_addr_1[1] = 1'b0;
    assign sel_rf_r_addr_1[0] = inst_add_w | inst_addi_w | inst_sub_w 
                                | inst_mul_w | inst_mulh_w | inst_mulh_wu
                                | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
                                | inst_or | inst_ori | inst_nor | inst_and | inst_andi | inst_xor | inst_xori
                                | inst_srl_w | inst_sll_w | inst_sra_w 
                                | inst_srli_w | inst_slli_w | inst_srai_w
                                | inst_slt | inst_sltu | inst_slti | inst_sltui
                                | inst_jirl | inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu 
                                | inst_st_w | inst_st_h | inst_st_b | inst_ld_w | inst_ld_h | inst_ld_b
                                | inst_ld_bu | inst_ld_hu;
    assign RegFile_r_addr1    = sel_rf_r_addr_1[0]?rj:5'b0;

    /*
        +-----------------+------------+
        | sel_rf_r_addr_2 | r_addr_2   |
        +-----------------+------------+
        | 2'b10           | rk         |
        | 2'b01           | rd         |
        | 2'b00           | 0(default) |
        +-----------------+------------+
    */
    assign sel_rf_r_addr_2[1] =  inst_add_w | inst_sub_w 
                                | inst_mul_w | inst_mulh_w | inst_mulh_wu 
                                | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
                                | inst_or | inst_nor | inst_and | inst_xor 
                                | inst_srl_w | inst_sll_w | inst_sra_w
                                | inst_slt | inst_sltu;
    assign sel_rf_r_addr_2[0] = inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu
                                | inst_st_w | inst_st_h | inst_st_b;
    assign RegFile_r_addr2    = sel_rf_r_addr_2[1]?rk:
                                sel_rf_r_addr_2[0]?rd:5'b0;

    /*
        +---------------+------------+
        | sel_rf_w_addr | w_addr     |
        +---------------+------------+
        | 2'b10         | rd         |
        | 2'b01         | GR[1]      |
        | 2'b00         | 0(default) |
        +---------------+------------+
    */
    assign sel_rf_w_addr[1] = inst_addi_w | inst_add_w | inst_sub_w | inst_mul_w | inst_mulh_w | inst_mulh_wu 
                                | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
                                | inst_or | inst_ori | inst_nor | inst_andi | inst_and | inst_xor | inst_xori
                                | inst_srl_w | inst_srli_w | inst_sll_w | inst_slli_w | inst_sra_w | inst_srai_w   
                                | inst_lu12i_w | inst_pcaddu12i 
                                | inst_slt | inst_slti | inst_sltu | inst_sltui | inst_jirl     
                                | inst_ld_w | inst_ld_h | inst_ld_b | inst_ld_bu | inst_ld_hu;
    assign sel_rf_w_addr[0] = inst_bl;
    assign RegFile_w_addr   = sel_rf_w_addr[1]?rd:
                            sel_rf_w_addr[0]?5'b0_0001:5'b0;
                            
    /////////////////////////////////////////////////////////////
    /// 决定立即数
    /// 立即数在ALU(imm)或BranchUnit(offset)模块中用到

    /*
        立即数扩展方式依次是：
        SignExtend(si12, 32)
        ZeroExtend(ui12, 32)
        ZeroExtend(ui5, 32)
        {si20, 12'b0}
        SignExtend({offs16, 2'b0}, 32)
        SignExtend({offs26, 2'b0}, 32)
    */
    assign immediate =  (inst_addi_w | inst_st_w | inst_ld_w | inst_st_h | inst_ld_h | inst_st_b | inst_ld_b | inst_ld_bu | inst_ld_hu | inst_slti | inst_sltui)?{{20{inst[21]}},inst[21:10]}:
                        (inst_ori | inst_andi | inst_xori)?{20'b0,inst[21:10]}:
                        (inst_srli_w | inst_slli_w | inst_srai_w)?{27'b0,inst[14:10]}:
                        (inst_lu12i_w | inst_pcaddu12i)?{inst[24: 5],12'b0}:
                        (inst_jirl | inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu)?{{14{inst[25]}},inst[25:10],2'b0}:
                        (inst_b | inst_bl)?{{4{inst[9]}},inst[ 9: 0],inst[25:10],2'b0}:32'b0;

    //////////////////////////////////////////////////////////
	/// ALU源操作数选择信号（从立即数、寄存器值、inst_PC等中选择）
    /// 同时该源操作数也是BranchUnit的源操作数

	// ALU执行的计算类型
    assign op_mul_s_l  = inst_mul_w;
    assign op_mul_s_h  = inst_mulh_w;
	assign op_mul_u_h  = inst_mulh_wu;
	assign op_div_s    = inst_div_w;
	assign op_div_u    = inst_div_wu;
	assign op_mod_s    = inst_mod_w;
	assign op_mod_u    = inst_mod_wu;
	assign op_lui      = inst_lu12i_w;
	assign op_sra      = inst_srai_w | inst_sra_w;
	assign op_srl      = inst_srli_w | inst_srl_w;
	assign op_sll      = inst_slli_w | inst_sll_w;
	assign op_xor      = inst_xor | inst_xori;
	assign op_or       = inst_or | inst_ori;
	assign op_nor      = inst_nor;
	assign op_and      = inst_and | inst_andi;
	assign op_sltu     = inst_sltu | inst_sltui; 
	assign op_slt      = inst_slt | inst_slti;
	assign op_sub      = inst_sub_w;
	assign op_add      = inst_addi_w | inst_add_w 
					    | inst_jirl | inst_bl
					    | inst_st_w | inst_ld_w | inst_st_h | inst_ld_h | inst_st_b | inst_ld_b 
					    | inst_ld_bu | inst_ld_hu
                        | inst_pcaddu12i;

	assign alu_op  = {
        op_mul_s_l  ,
        op_mul_s_h  ,
        op_mul_u_h  ,
        op_div_s    ,
        op_div_u    ,
        op_mod_s    ,
        op_mod_u    ,
		op_lui	    ,
		op_sra	    ,
		op_srl	    ,
		op_sll	    ,
		op_xor	    ,
		op_or 	    ,
		op_nor	    ,
		op_and	    ,
		op_sltu	    ,
		op_slt	    ,
		op_sub	    ,
		op_add	
	};

	/*
		// 决定源操作数 （one-hot）
		+-----------------+-----------------+
		| sel_alu_bu_src1 | alu_bu_src1     |
		+-----------------+-----------------+
		| 2'b10           | RegFile_R_data1 |
		| 2'b01           | inst_PC         |
		| 2'b00           | 32'b0           |
		+-----------------+-----------------+

	*/
	assign sel_alu_bu_src1[1] =  inst_addi_w | inst_add_w | inst_sub_w
                            | inst_mul_w | inst_mulh_w | inst_mulh_wu 
                            | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
							| inst_or | inst_nor| inst_and | inst_xor 
                            | inst_ori | inst_andi | inst_xori
							| inst_srli_w | inst_slli_w | inst_srai_w 
                            | inst_srl_w | inst_sll_w |inst_sra_w
							| inst_slt | inst_sltu | inst_slti | inst_sltui
							| inst_jirl | inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu
							| inst_st_w | inst_st_h | inst_st_b
                            | inst_ld_w | inst_ld_h | inst_ld_b
                            | inst_ld_bu | inst_ld_hu;
	assign sel_alu_bu_src1[0] = inst_pcaddu12i | inst_bl;

    /*
		// 决定源操作数 one-hot
		+-----------------+-----------------+
		| sel_alu_bu_src2 | alu_bu_src2     |
		+-----------------+-----------------+
		| 3'b100          | SPECIAL:32'h4   |
        | 3'b010          | RegFile_R_data2 |
		| 3'b001          | immediate       |
		| 3'b000          | 32'b0		    |
		+-----------------+-----------------+
	*/
    assign sel_alu_bu_src2[2] = inst_bl;
	assign sel_alu_bu_src2[1] =  inst_add_w | inst_sub_w | inst_mul_w | inst_mulh_w | inst_mulh_wu 
                            | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
							| inst_or | inst_nor | inst_and | inst_xor
                            | inst_srl_w | inst_sll_w | inst_sra_w
							| inst_slt | inst_sltu
                            | inst_beq | inst_bne | inst_bge | inst_bgeu | inst_blt | inst_bltu; 
	assign sel_alu_bu_src2[0]=   inst_addi_w | inst_ori | inst_andi | inst_xori
                            | inst_srli_w | inst_slli_w | inst_srai_w
                            | inst_slti | inst_sltui
							| inst_lu12i_w | inst_pcaddu12i | inst_jirl
							| inst_st_w | inst_st_h |  inst_st_b
                            | inst_ld_w | inst_ld_h | inst_ld_b
                            | inst_ld_bu | inst_ld_hu;


	///////////////////////////////////////////////////////////
	/// 数据RAM的相关控制信号生成

	// 写使能
	assign sel_data_ram_we = inst_st_b | inst_st_w | inst_st_h;

	// Data RAM使能信号
	assign sel_data_ram_en =  inst_st_b | inst_st_w | inst_st_h
							| inst_ld_b | inst_ld_w | inst_ld_h
                            | inst_ld_bu | inst_ld_hu;


    /*
        +---------------------+---------------+
        | sel_data_ram_extend | how-to-extend |
        +---------------------+---------------+
        | 1'b1                | ZeroExtend    |
        | 1'b0                | SignExtend    |
        +---------------------+---------------+
    */
    assign sel_data_ram_extend = inst_ld_bu | inst_ld_hu;

	/*
    字节使能，表示写入/读取数据的宽度 one-hot
		+-----------------+-------------+
		| sel_data_ram_wd | 长度        |
		+-----------------+-------------+
        | 2'b10           | byte(8bit)  |
		| 2'b01           | half(16bit) |
		| 0(default)      | word(32bit) |
		+-----------------+-------------+

	*/
	assign sel_data_ram_wd[1]= inst_st_b | inst_ld_b | inst_ld_bu;
    assign sel_data_ram_wd[0]= inst_st_h | inst_ld_h | inst_ld_hu;

	///////////////////////////////////////////////////////////
	/// 生成WB阶段控制信号

	// 是否写回寄存器
	assign sel_rf_w_en =      inst_addi_w | inst_add_w | inst_sub_w 
                            | inst_mul_w | inst_mulh_w | inst_mulh_wu
                            | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
							| inst_or | inst_and | inst_xor | inst_nor
                            | inst_ori | inst_andi | inst_xori
							| inst_srli_w | inst_slli_w | inst_srai_w | 
                            | inst_srl_w | inst_sll_w | inst_sra_w
							| inst_lu12i_w | inst_pcaddu12i
                            | inst_slt | inst_sltu
                            | inst_slti | inst_sltui
                            | inst_jirl | inst_bl
                            | inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_hu | inst_ld_bu;

	/* 
	控制写入数据来源 one-hot
		+---------------+----------+
		| sel_rf_w_data | 数据来源 |
		+---------------+----------+
		| 1             | RAM      |
		| 0(default)    | ALU      |
		+---------------+----------+
	*/
	assign sel_rf_w_data = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;

    //////////////////////////////////////////////////////////
    /// 与旁路及唤醒（阻塞）有关的控制信号生成

    /*
    表明一条写回寄存器的指令，其写回数据从哪一流水级开始有效
        +---------------------------+-------------------+
        | sel_rf_w_data_valid_stage | 写数据开始有效阶段 |
        +---------------------------+-------------------+
        | 3'b100                    |  WB               |
        | 3'b010                    |  MEM              |
        | 3'b001                    |  EXE              |
        | 3'b000                    |  \                |
        +---------------------------+-------------------+
    */

    assign sel_rf_w_data_valid_stage[2] = 1'b0;//所有指令均可在WB阶段前得到信号
    assign sel_rf_w_data_valid_stage[1] = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_hu | inst_ld_bu;
    assign sel_rf_w_data_valid_stage[0] = inst_addi_w | inst_add_w | inst_sub_w 
                                        | inst_mul_w | inst_mulh_w | inst_mulh_wu
                                        | inst_div_w | inst_div_wu | inst_mod_w | inst_mod_wu
                                        | inst_or  | inst_and | inst_xor | inst_nor 
                                        | inst_ori | inst_andi | inst_xori
                                        | inst_srli_w | inst_slli_w | inst_srai_w 
                                        | inst_srl_w | inst_sll_w | inst_sra_w
                                        | inst_lu12i_w | inst_pcaddu12i
                                        | inst_slt | inst_sltu
                                        | inst_slti | inst_sltui
                                        | inst_jirl | inst_bl;


    /////////////////////////////////////////////////////////
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
		inst_PC 	 //32
		    		 //
    } = IF_to_IPD_reg;

    assign {
		br_taken_cancel	,//32
		PC_fromID		 //33	
	}=ID_to_IPD_bus;

    // 发送
    assign IPD_to_ID_bus={
            sel_rf_w_data_valid_stage   ,//3
            sel_alu_bu_src2             ,//3
            sel_alu_bu_src1             ,//2
            sel_rf_w_en		            ,//1
		    sel_rf_w_data	            ,//1
		    sel_data_ram_wd	            ,//2
            sel_data_ram_extend         ,//1
		    sel_data_ram_we	            ,//1
		    sel_data_ram_en	            ,//1
            inst_type                   ,//46
		    alu_op			            ,//19
            inst_PC                     ,//32
            immediate                   ,//32
            RegFile_w_addr              ,//5
            RegFile_r_addr2             ,//5
            RegFile_r_addr1              //5
    };

    assign IPD_to_BU_bus=inst_PC;
endmodule
