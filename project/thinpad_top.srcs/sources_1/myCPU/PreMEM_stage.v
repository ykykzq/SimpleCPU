/**
 * @file MEM_stage.v
 * @author ykykzq
 * @brief 流水线第五级，预先计算地址
 * @version 0.1
 * @date 2024-08-13
 *
 */

module PreMEM_stage(
    input  wire 						clk,
	input  wire							reset,

    // 流水级数据交互
	input  wire[`EXE_TO_PMEM_BUS_WD-1:0]EXE_to_PMEM_bus,
	output wire[`PMEM_TO_MEM_BUS_WD-1:0]PMEM_to_MEM_bus,

	output wire[`PMEM_TO_BY_BUS_WD-1:0]	PMEM_to_BY_bus,

    //流水线控制
	input  wire							EXE_to_PMEM_valid,
	output wire							PMEM_allow_in,
	input  wire							MEM_allow_in,
	output wire							PMEM_to_MEM_valid,

    // 连接Data RAM
	output wire							data_ram_en,
	output wire[31:0]					data_ram_addr,
	output wire[3:0]					data_ram_w_en,
	input  wire[31:0]					data_ram_r_data,
	output reg [31:0]					data_ram_w_data
	
);
	// 当前指令的PC
	wire [31: 0]	inst_PC;

    // 流水线控制
	wire PMEM_ready_go;
	reg  PMEM_valid;

	// EXE计算结果
	wire [31: 0]	alu_result;

    // Data RAM控制信号
	wire sel_data_ram_en;
	wire sel_data_ram_we;
	wire sel_data_ram_extend;
	wire [ 1: 0]	sel_data_ram_wd;
	reg  [ 3: 0]	data_ram_b_en;
	wire [31: 0]	data_ram_wdata;
	wire [31: 0]	data_ram_addr_from_alu;

    // 旁路信号
    wire [ 2: 0]    sel_rf_w_data_valid_stage;
	wire 			PMEM_sel_rf_w_data_valid;

	// 写回（WB）阶段用到的控制信号
	wire [ 4: 0]	RegFile_w_addr;
	wire	sel_rf_w_data;
	wire 	sel_rf_w_en;

	// EXE/PMEM REG
	reg [`EXE_TO_PMEM_BUS_WD-1:0]	EXE_to_PMEM_reg;

    /////////////////////////////////////////////////////////
    /// 流水级控制

    // 认为访存也能一周期完成
    assign PMEM_ready_go=1'b1;
	assign PMEM_allow_in=(~PMEM_valid)|(MEM_allow_in & PMEM_ready_go);
	assign PMEM_to_MEM_valid=PMEM_valid & PMEM_ready_go;
	always@(posedge clk)
	begin
		if(reset)
			PMEM_valid<=1'b0;
		else if(PMEM_allow_in)
			PMEM_valid<=EXE_to_PMEM_valid;
		else
			PMEM_valid<=PMEM_valid;
	end

    /////////////////////////////////////////////////
	/// 旁路信号生成

	assign PMEM_sel_rf_w_data_valid = PMEM_valid & PMEM_ready_go & sel_rf_w_data_valid_stage[0];

    /////////////////////////////////////////////////////
	/// 生成Data RAM信号

	assign data_ram_en=sel_data_ram_en;
	assign data_ram_addr=data_ram_addr_from_alu;

	assign data_ram_addr_from_alu=alu_result;

	// 字节使能
	always@(*)
	begin
		if(sel_data_ram_wd[1])
			begin
				// 如果长度为byte(8bit)
				if(data_ram_addr_from_alu[1:0]==2'b00)
					data_ram_b_en<=4'b0001;
				else if(data_ram_addr_from_alu[1:0]==2'b01)
					data_ram_b_en<=4'b0010;
				else if(data_ram_addr_from_alu[1:0]==2'b10)
					data_ram_b_en<=4'b0100;
				else if(data_ram_addr_from_alu[1:0]==2'b11)
					data_ram_b_en<=4'b1000;
				else 
					data_ram_b_en<=4'b0000;//不会走到的分支
			end
		else if(sel_data_ram_wd[0])
			begin
				// 如果长度为half-word(16bit)
				if(data_ram_addr_from_alu[1:0]==2'b00)
					data_ram_b_en<=4'b0011;
				else if(data_ram_addr_from_alu[1:0]==2'b01)
					data_ram_b_en<=4'b1100;
				else if(data_ram_addr_from_alu[1:0]==2'b10)
					data_ram_b_en<=4'b1100;
				else if(data_ram_addr_from_alu[1:0]==2'b11)
					data_ram_b_en<=4'b1100;
				else 
					data_ram_b_en<=4'b0000;//不会走到的分支
			end
		else 
			data_ram_b_en<=4'b1111;// 若是一个word(32bit)
	end
	// 若是不读Data RAM，全0即可
	assign data_ram_w_en = sel_data_ram_we?data_ram_b_en:4'b0000;

	// 写回的数据
	always@(*)
	begin
		if(sel_data_ram_wd[1])
			begin
				// 如果长度为byte(8bit)
				if(data_ram_addr_from_alu[1:0]==2'b00)
					data_ram_w_data<={24'b0,data_ram_wdata[7:0]};
				else if(data_ram_addr_from_alu[1:0]==2'b01)
					data_ram_w_data<={16'b0,data_ram_wdata[7:0],8'b0};
				else if(data_ram_addr_from_alu[1:0]==2'b10)
					data_ram_w_data<={8'b0,data_ram_wdata[7:0],16'b0};
				else if(data_ram_addr_from_alu[1:0]==2'b11)
					data_ram_w_data<={data_ram_wdata[7:0],24'b0};
				else 
					data_ram_w_data<=32'b0;//不会走到的分支
			end
		else if(sel_data_ram_wd[0])
			begin
				// 如果长度为half-word(16bit)
				if(data_ram_addr_from_alu[1:0]==2'b00)
					data_ram_w_data<={16'b0,data_ram_wdata[15:0]};
				else if(data_ram_addr_from_alu[1:0]==2'b01)
					data_ram_w_data<={data_ram_wdata[15:0],16'b0};
				else if(data_ram_addr_from_alu[1:0]==2'b10)
					data_ram_w_data<={data_ram_wdata[15:0],16'b0};
				else if(data_ram_addr_from_alu[1:0]==2'b11)
					data_ram_w_data<={data_ram_wdata[15:0],16'b0};
				else 
					data_ram_w_data<=32'b0;//不会走到的分支
			end
		else 
			data_ram_w_data<=data_ram_wdata;// 若是一个word(32bit)
	end


    ////////////////////////////////////////////////////////////
    /// 流水级数据交互

    // 接收
    always@(posedge clk)
	begin
		if(reset)
			EXE_to_PMEM_reg<=0;
		else if(EXE_to_PMEM_valid & PMEM_allow_in)
			EXE_to_PMEM_reg<=EXE_to_PMEM_bus;
		else
			EXE_to_PMEM_reg<=EXE_to_PMEM_reg;
	end
    assign {
		sel_rf_w_data_valid_stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//2
		sel_data_ram_extend			,//1
        sel_data_ram_we				,//1
        sel_data_ram_en				,//1
        data_ram_wdata				,//32
		RegFile_w_addr				,//5
		alu_result					,//32
		inst_PC						 //32
	}=EXE_to_PMEM_reg;

    // 发送
    assign PMEM_to_MEM_bus = {
		sel_rf_w_data_valid_stage	,//3
		sel_rf_w_en					,//1
		sel_rf_w_data				,//1
		sel_data_ram_wd				,//2
		sel_data_ram_extend			,//1
		data_ram_b_en				,//4
		data_ram_r_data				,//32
		RegFile_w_addr				,//5
		alu_result					,//32
		inst_PC						 //32
    };

	assign PMEM_to_BY_bus={
		sel_rf_w_data_valid_stage	,//3
		RegFile_w_addr				,//5
		alu_result					,//32
		PMEM_sel_rf_w_data_valid	,//1
		PMEM_valid					,//1
		sel_rf_w_en					 //1
	};

endmodule