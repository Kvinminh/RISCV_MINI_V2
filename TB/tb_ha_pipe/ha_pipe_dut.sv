module ha_pipe
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic  clk,
    input logic rst_n,

    input riscv_reg_e            rs1_addr,
    input riscv_reg_e            rs2_addr,

    input logic                  rs1_used,
    input logic                  rs2_used,

    input logic                  jump_en,       // JAL || JALR từ decode
    input logic                  br_en,         // Branch từ decode
    input logic                  br_taken,      // Kết quả br_compare

    input for_info_t             for_info_ex_i,
    input for_info_t             for_info_mem_i,


    // pc 
    //input logic stall_pc,
    input logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc_cur,

    // ifd 
    // input  logic       ifd_stall
    // input  logic       ifd_flush,

    input  if_id_reg_t if_reg,
    output if_id_reg_t reg_id,


    // input  logic       id_ex_flush,

    input  id_ex_reg_t id_reg,
    output id_ex_reg_t reg_ex,


    // ex_mem 
    input ex_mem_reg_t       ex_reg,
    output ex_mem_reg_t      reg_mem,
    // mem_wb
    input mem_wb_reg_t mem_reg,
    output mem_wb_reg_t reg_wb

);

    hzd_ctrl_t hzd_ctrl;


    hazard u_hazard (
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .rs1_used_i(rs1_used),
        .rs2_used_i(rs2_used),
        .jump_en_i(jump_en),
        .br_en_i(br_en),
        .br_taken_i(br_taken),
        .for_info_ex_i(for_info_ex_i),
        .for_info_mem_i(for_info_mem_i),
        .hzd_ctrl_o(hzd_ctrl)
    );

    pc u_pc(
        .clk(clk),
        .rst_n(rst_n),
        .stall_pc_i(hzd_ctrl.stall_pc),
        .pc_next_i(pc_next),
        .pc_cur_o(pc_cur)
    );

    if_id_reg u_if_id_reg(
        .clk(clk),
        .rst_n(rst_n),
        .if_id_stall_i(hzd_ctrl.stall_if_id),
        .if_id_flush_i(hzd_ctrl.flush_if_id),
        .if_reg_i(if_reg),
        .reg_id_o(reg_id)
    );


    id_ex_reg u_id_ex_reg(
        .clk(clk),
        .rst_n(rst_n),
        .id_ex_flush_i(hzd_ctrl.flush_id_ex),
        .id_reg_i(id_reg),
        .reg_ex_o(reg_ex)
    );

    ex_mem_reg u_ex_mem_reg(
        .clk(clk),
        .rst_n(rst_n),
        .ex_reg_i(ex_reg),
        .reg_mem_o(reg_mem)
    );

    mem_wb_reg u_mem_wb_reg (
        .clk(clk),
        .rst_n(rst_n),
        .mem_reg_i(mem_reg),
        .reg_wb_o(reg_wb)
    );


endmodule










