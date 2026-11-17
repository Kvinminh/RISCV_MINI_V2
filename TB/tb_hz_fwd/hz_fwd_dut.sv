module hz_fwd
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic                  clk,
    input logic                  rst_n,

    input riscv_reg_e            rs1_addr,
    input riscv_reg_e            rs2_addr,

    input logic                  rs1_used,
    input logic                  rs2_used,

    input logic                  jump_en,       // JAL || JALR từ decode
    input logic                  br_en,         // Branch từ decode
    input logic                  br_taken,      // Kết quả br_compare

    input for_info_t             for_info_ex,
    input for_info_t             for_info_mem,
    input for_info_t             for_info_wb,


    output for_sel_e             for_id_a,
    output for_sel_e             for_id_b,

    output forward_e             for_ex_a,
    output forward_e             for_ex_b,

    output hzd_ctrl_t            hzd_ctrl
);


    hazard u_hazard (
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .rs1_used_i(rs1_used),
        .rs2_used_i(rs2_used),
        .jump_en_i(jump_en),
        .br_en_i(br_en),
        .br_taken_i(br_taken),
        .for_info_ex_i(for_info_ex),
        .for_info_mem_i(for_info_mem),
        .hzd_ctrl_o(hzd_ctrl)
    );


    forward_id u_forward_id (
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .for_info_ex_i(for_info_ex),
        .for_info_mem_i(for_info_mem),
        .for_info_wb_i(for_info_wb),
        .for_id_a_o(for_id_a),
        .for_id_b_o(for_id_b)
    );

    forward_ex u_forward_ex(
        .rs1_addr_i(rs1_addr),
        .rs2_addr_i(rs2_addr),
        .for_info_mem_i(for_info_mem),
        .for_info_wb_i(for_info_wb),
        .for_ex_a_o(for_ex_a),
        .for_ex_b_o(for_ex_b)
    );

endmodule