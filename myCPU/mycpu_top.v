module myCPU_top(
	input         clk,
    input         resetn,
    //指令RAM
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,//恒0
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //数据RAM
    output        data_sram_en,//恒1
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug的接口
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );
	
	wire				reset;
	
	//IF
	wire[`ID_TO_PC_BUS_WD-1:0]	ID_to_PC_bus;
	wire						ID_allow_in;
	wire						IF_to_ID_valid;
	wire[`IF_TO_ID_BUS_WD-1:0]	IF_to_ID_bus;
	
	
	//ID
	wire[`ID_TO_EXE_BUS_WD-1:0]	ID_to_EXE_bus;
	wire[`WB_TO_RF_BUS_WD-1:0]	WB_to_RF_bus;
	wire						EXE_allow_in;
	wire						ID_to_EXE_valid;
	
	//EXE
	wire[`EXE_TO_MEM_BUS_WD-1:0]EXE_to_MEM_bus;
	wire						MEM_allow_in;
	wire						EXE_to_MEM_valid;
	
	//MEM
	wire[`MEM_TO_WB_BUS_WD-1:0]	MEM_to_WB_bus;
	wire						WB_allow_in;
	wire						MEM_to_WB_valid;
	
	//WB
	
	
	//BY & ST
	wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus;
	wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus;	
	wire[`ID_TO_BY_BUS_WD-1:0]	ID_to_BY_bus;	
	wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus;
		
	wire[`ID_TO_ST_BUS_WD-1:0]	ID_to_ST_bus;	
	wire[`EXE_TO_ST_BUS_WD-1:0]	EXE_to_ST_bus;
	wire						ST_to_ID_bus;
	
	
	
	
	
	//翻转reset信号
	assign reset=~resetn;
	
//IF	
	IF_stage IF_stage_top(
		.clk				(clk),
		.reset				(reset),

		.ID_to_PC_bus		(ID_to_PC_bus),
		
		.ID_allow_in		(ID_allow_in),
		.IF_to_ID_valid		(IF_to_ID_valid),
		.IF_to_ID_bus		(IF_to_ID_bus),

		.inst_ram_en		(inst_sram_en),//(读)使能
		.inst_ram_addr		(inst_sram_addr),
		.inst_ram_r_data	(inst_sram_rdata),
		.inst_ram_w_data	(inst_sram_wdata),//实际上用不到指令RAM的写
		.inst_ram_w_en		(inst_sram_wen)
	);

//ID	
	ID_stage ID_stage_top(
		.clk				(clk),
	    .reset				(reset),
	    
	    .IF_to_ID_bus		(IF_to_ID_bus),		
	    .ID_to_EXE_bus		(ID_to_EXE_bus),
	    
	    .ID_to_PC_bus		(ID_to_PC_bus),

	    .WB_to_RF_bus		(WB_to_RF_bus),
	//ST
		.ID_to_ST_bus		(ID_to_ST_bus),
	    .ST_to_ID_bus		(ST_to_ID_bus),
	//BY
		.ID_to_BY_bus		(ID_to_BY_bus),
		.BY_to_ID_bus		(BY_to_ID_bus),
	//流水线控制
	    .EXE_allow_in		(EXE_allow_in),
	    .IF_to_ID_valid		(IF_to_ID_valid),
	    .ID_allow_in		(ID_allow_in),
	    .ID_to_EXE_valid	(ID_to_EXE_valid)
	);
//EXE	
	EXE_stage EXE_stage_top(
		.clk				(clk),
		.reset				(reset),
	
	//stage间数据交流
		.ID_to_EXE_bus		(ID_to_EXE_bus),
		.EXE_to_MEM_bus		(EXE_to_MEM_bus),
	//ST
		.EXE_to_ST_bus		(EXE_to_ST_bus),
	//BY
		.EXE_to_BY_bus		(EXE_to_BY_bus),
		
	
	//流水线控制
		.MEM_allow_in		(MEM_allow_in),
		.EXE_to_MEM_valid	(EXE_to_MEM_valid),
		.ID_to_EXE_valid	(ID_to_EXE_valid),
		.EXE_allow_in		(EXE_allow_in),
	
	
	//为构建同指令RAM一样的“伪.组合逻辑”，需在EXE阶段即给数据RAM地址等
		.data_ram_addr		(data_sram_addr),
		.data_ram_w_data	(data_sram_wdata),
		.data_ram_w_en_4bit	(data_sram_wen),
		.data_ram_en		(data_sram_en)
    );
//MEM	
	MEM_stage MEM_stage_top(
		.clk				(clk),
		.reset				(reset),
	
		.EXE_to_MEM_bus		(EXE_to_MEM_bus),
		.MEM_to_WB_bus		(MEM_to_WB_bus),
	//BY
		.MEM_to_BY_bus		(MEM_to_BY_bus),
		
		.data_ram_r_data	(data_sram_rdata),
	
	//流水线控制
		.EXE_to_MEM_valid	(EXE_to_MEM_valid),
		.MEM_allow_in		(MEM_allow_in),
		.WB_allow_in		(WB_allow_in),
		.MEM_to_WB_valid	(MEM_to_WB_valid)
    );
//WB	
	WB_stage WB_stage_top(
		.clk				(clk),
		.reset				(reset),
	
	//来自MEM的数据
		.MEM_to_WB_bus		(MEM_to_WB_bus),
	//给rf	
		.WB_to_RF_bus		(WB_to_RF_bus),
	
	//debug的接口
		.debug_wb_pc		(debug_wb_pc),
		.debug_wb_rf_wen	(debug_wb_rf_wen),
		.debug_wb_rf_wnum	(debug_wb_rf_wnum),
		.debug_wb_rf_wdata	(debug_wb_rf_wdata),
	
	//流水线控制
		.MEM_to_WB_valid	(MEM_to_WB_valid),
		.WB_allow_in		(WB_allow_in)
    );
//BY	
	Bypassing Bypassing_top(
		.EXE_to_BY_bus		(EXE_to_BY_bus),
	    .MEM_to_BY_bus		(MEM_to_BY_bus),
	    .ID_to_BY_bus		(ID_to_BY_bus),
	    
	    .BY_to_ID_bus		(BY_to_ID_bus)
	);
//ST
	Stall Stall_top(
		.ID_to_ST_bus		(ID_to_ST_bus),
		.EXE_to_ST_bus		(EXE_to_ST_bus),
		
		.ST_to_ID_bus		(ST_to_ID_bus)
	);
	endmodule