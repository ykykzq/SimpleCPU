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
    // 用于判断是否跳转和计算next_PC
    input  wire[31:0]               BranchUnit_src1 ,
    input  wire                     src_1_ready     ,
    input  wire[31:0]               BranchUnit_src2 ,
    input  wire                     src_2_ready     ,
    input  wire[31:0]               offset          ,
    input  wire[31:0]               inst_PC         , 

    output reg [31:0]               next_PC,
    output wire                     br_taken_cancel
);
    assign{
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
    }=inst_type;

    // 计算真正的PC
    assign is_branch=(inst_jirl | inst_b | inst_beq | inst_bne | inst_bl | inst_bge | inst_bgeu | inst_blt | inst_bltu);
    always@(*)
    begin
        if(reset)
            next_PC<=32'b0;
        else if(inst_jirl)
            next_PC<=BranchUnit_src1+offset;
        else if(inst_b)
            next_PC<=inst_PC+offset;
        else if(inst_beq)
            if(src_1_ready & src_2_ready  && BranchUnit_src1==BranchUnit_src2)
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_bne)
            if(src_1_ready & src_2_ready  && BranchUnit_src1!=BranchUnit_src2)
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_bge)
            if(src_1_ready & src_2_ready  && $signed(BranchUnit_src1)>=$signed(BranchUnit_src2))
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_bgeu)
            if(src_1_ready & src_2_ready  && $unsigned(BranchUnit_src1)>=$unsigned(BranchUnit_src2))
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_blt)
            if(src_1_ready & src_2_ready  && $signed(BranchUnit_src1)<$signed(BranchUnit_src2))
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_bltu)
            if(src_1_ready & src_2_ready  && $unsigned(BranchUnit_src1)<$unsigned(BranchUnit_src2))
                next_PC<=inst_PC+offset;
            else 
                next_PC<=inst_PC+32'h0000_0004;
        else if(inst_bl)
            next_PC<=inst_PC+offset;
        else 
            // 如果不是分支指令
            next_PC<=inst_PC+32'h0000_0004;
    end
    // 检验预测正确性
    assign br_taken_cancel=reset?1'b0:is_branch&(~(pred_PC==next_PC));
endmodule