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
    input 							reset,
    input  wire[`INST_TYPE_WD-1:0]  inst_type,
    input  wire[31:0]               pred_PC,
    // 用于计算PC的值
    input  wire[31:0]               src1,
    input  wire[31:0]               src2,

    output wire[31:0]               next_PC,
    output wire                     br_taken_cancel
);
    assign{
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
    }=inst_type;

    // 计算真正的PC
    assign is_branch=(inst_jirl | inst_b | inst_beq | inst_bne | inst_bl);
    assign next_PC=reset?32'b0:is_branch?src1+src2:32'b0;
    // 检验预测正确性
    assign br_taken_cancel=reset?1'b0:is_branch&(~(pred_PC==next_PC));
endmodule