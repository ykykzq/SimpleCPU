/**
 * @file Bypassing.v
 * @author ykykzq
 * @brief 获得来自ID阶段之后的各阶段的写寄存器相关信息，并传送到ID阶段
 * @version 0.1
 * @date 2024-08-20
 *
 */
`include "myCPU.h"
module Bypassing(
	// 流水线数据交互，需要包括ID阶段之后所有阶段的信息
	input  wire[`EXE_TO_BY_BUS_WD-1:0]	EXE_to_BY_bus,
	input  wire[`MEM_TO_BY_BUS_WD-1:0]	MEM_to_BY_bus,
	input  wire[`WB_TO_BY_BUS_WD-1:0]	WB_to_BY_bus,
	
	// 告知WK是否可以从旁路读取该数据,该信号实际上是给ID信号的子集，故不需要重复定义
	//output wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_WK_bus,
	// 将旁路数据传输到ID阶段
	output wire[`BY_TO_ID_BUS_WD-1:0]	BY_to_ID_bus
    );
	
	// EXE
	wire [ 4: 0]	EXE_RegFile_W_addr	;
	wire [31: 0]	EXE_alu_result		;
	wire 	EXE_sel_RF_W_Data_valid		;
	wire 	EXE_sel_rf_w_en				;

	wire [31: 0]	EXE_RegFile_W_data	;

	// MEM
	wire [ 2: 0]	MEM_sel_RF_W_Data_Valid_Stage;
	wire [ 3: 0]	MEM_data_ram_b_en	;
	wire [ 4: 0]	MEM_RegFile_W_addr	;
	wire [31: 0]	MEM_data_ram_r_data	;
	wire [31: 0]	MEM_alu_result		;
	wire 	MEM_sel_RF_W_Data_valid		;
	wire 	MEM_sel_data_ram_wd			;
	wire 	MEM_sel_rf_w_en				;

	reg  [31: 0]	MEM_RegFile_W_data	;

	// WB
	wire [ 4: 0]	WB_RegFile_W_addr	;
	wire [31: 0]	WB_RegFile_W_data	;
	wire WB_sel_RF_W_Data_valid			;
	wire WB_sel_rf_w_en				 	;
	
	/////////////////////////////////////////////////////////
	/// 筛选
	
	// 通过筛选信号，提前把写入数据筛选出来
	assign EXE_RegFile_W_data=(EXE_RegFile_W_addr==5'b0)?32'b0:EXE_alu_result;

    // 处理半字读与字节读
    always@(*)
    begin
		if(MEM_RegFile_W_addr==5'b0_0000)
			MEM_RegFile_W_data<=32'b0;
		else if(MEM_sel_RF_W_Data_Valid_Stage[0])
			MEM_RegFile_W_data<=MEM_alu_result;
        else if(MEM_sel_data_ram_wd==1)
        begin
            if(MEM_data_ram_b_en==4'b0001)
                // 注意是符号扩展
                MEM_RegFile_W_data<={{24{MEM_data_ram_r_data[7]}},MEM_data_ram_r_data[7:0]};
            else if(MEM_data_ram_b_en==4'b0010)
                MEM_RegFile_W_data<={{24{MEM_data_ram_r_data[15]}},MEM_data_ram_r_data[15:8]};
            else if(MEM_data_ram_b_en==4'b0100)
                MEM_RegFile_W_data<={{24{MEM_data_ram_r_data[23]}},MEM_data_ram_r_data[23:16]};
            else if(MEM_data_ram_b_en==4'b1000)
                MEM_RegFile_W_data<={{24{MEM_data_ram_r_data[31]}},MEM_data_ram_r_data[31:24]};
            else 
                MEM_RegFile_W_data<=32'b0;
        end
        else 
            MEM_RegFile_W_data<=MEM_data_ram_r_data;
    end
	


	/////////////////////////////////////////////////////////////
	/// 流水线数据交互

	// 接收
	assign {
		// EXE阶段信号
		EXE_RegFile_W_addr			,//5
		EXE_alu_result				,//32
		EXE_sel_RF_W_Data_valid		,//1
		EXE_sel_rf_w_en				 //1
	}=EXE_to_BY_bus;

	assign {
		// MEM阶段信号
		MEM_sel_RF_W_Data_Valid_Stage	,//3
		MEM_data_ram_b_en				,//4
		MEM_RegFile_W_addr				,//5
		MEM_data_ram_r_data				,//32
		MEM_alu_result					,//32
		MEM_sel_RF_W_Data_valid			,//1
		MEM_sel_data_ram_wd				,//1
		MEM_sel_rf_w_en					 //1
	}=MEM_to_BY_bus;

	assign {
		// WB阶段信号		
		WB_RegFile_W_addr			,//5
		WB_RegFile_W_data			,//32
		WB_sel_RF_W_Data_valid		,//1
		WB_sel_rf_w_en				 //1
	}=WB_to_BY_bus;

	// 发送
	assign BY_to_ID_bus={
		// EXE阶段信号
		EXE_RegFile_W_addr			,//5
		EXE_RegFile_W_data			,//32
		EXE_sel_RF_W_Data_valid		,//1
		EXE_sel_rf_w_en				,//1
		// MEM阶段信号
		MEM_RegFile_W_addr			,//5
		MEM_RegFile_W_data			,//32
		MEM_sel_RF_W_Data_valid		,//1
		MEM_sel_rf_w_en				,//1
		// WB阶段信号		
		WB_RegFile_W_addr			,//5
		WB_RegFile_W_data			,//32
		WB_sel_RF_W_Data_valid		,//1
		WB_sel_rf_w_en				 //1
	};
	
endmodule
