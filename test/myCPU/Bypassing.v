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
	
	
	
	/////////////////////////////////////////////////////////
	/// 筛选
	
	// 通过筛选信号，提前把写入数据筛选出来
	assign EXE_RegFile_W_data=alu_result;

    // 处理半字读与字节读
    always@(*)
    begin
        if(sel_data_ram_wd==1)
        begin
            if(data_ram_b_en==4'b0001)
                // 注意是符号扩展
                MEM_RegFile_W_data<={{24{data_ram_r_data[7]}},data_ram_r_data[7:0]};
            else if(data_ram_b_en==4'b0010)
                MEM_RegFile_W_data<={{24{data_ram_r_data[15]}},data_ram_r_data[15:8]};
            else if(data_ram_b_en==4'b0100)
                MEM_RegFile_W_data<={{24{data_ram_r_data[23]}},data_ram_r_data[23:16]};
            else if(data_ram_b_en==4'b1000)
                MEM_RegFile_W_data<={{24{data_ram_r_data[31]}},data_ram_r_data[31:24]};
            else 
                MEM_RegFile_W_data<=32'b0;
        end
        else 
            MEM_RegFile_W_data<=data_ram_r_data;
    end
	


	/////////////////////////////////////////////////////////////
	/// 流水线数据交互

	// 接收
	assign {
		// EXE阶段信号
		EXE_RegFile_W_addr			,
		alu_result					,
		EXE_sel_RF_W_Data_valid		,
		EXE_sel_rf_w_en				
	}=EXE_to_BY_bus;

	assign {
		// MEM阶段信号
		sel_data_ram_wd				,
		MEM_RegFile_W_addr			,
		data_ram_r_data				,
		MEM_sel_RF_W_Data_valid		,
		MEM_sel_rf_w_en				
	}=MEM_to_BY_bus;

	assign {
		// WB阶段信号		
		WB_RegFile_W_addr			,
		WB_RegFile_W_data			,
		WB_sel_RF_W_Data_valid		,
		WB_sel_rf_w_en		
	}=WB_to_BY_bus;

	// 发送
	assign BY_to_ID_bus={
		// EXE阶段信号
		EXE_RegFile_W_addr			,
		EXE_RegFile_W_data			,
		EXE_sel_RF_W_Data_valid		,
		EXE_sel_rf_w_en				,
		// MEM阶段信号
		MEM_RegFile_W_addr			,
		MEM_RegFile_W_data			,
		MEM_sel_RF_W_Data_valid		,
		MEM_sel_rf_w_en				,
		// WB阶段信号		
		WB_RegFile_W_addr			,
		WB_RegFile_W_data			,
		WB_sel_RF_W_Data_valid		,
		WB_sel_rf_w_en		
	};
	
endmodule
