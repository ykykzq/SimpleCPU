/**
 * @file BranchUnit.v
 * @author ykykzq
 * @brief 根据指令类型、nextPC、数据字段判断分支跳转是否正确
 * @version 0.1
 * @date 2024-08-12
 *
 */
`include"./include/myCPU.h"
module BranchUnit(
    input  wire[`INST_TYPE_WD-1:0]  inst_type,
    input  wire[31:0]               pred_PC,
    // 计算PC的值
    input  wire[31:0]               src1,
    input  wire[31:0]               src2,

    output wire[31:0]               next_PC,
    output wire                     br_taken_cancel
);

    // to do: 完成PC的计算
    assign next_PC=32'b0;

    assign br_taken_cancel=~(pred_PC==next_PC);
endmodule