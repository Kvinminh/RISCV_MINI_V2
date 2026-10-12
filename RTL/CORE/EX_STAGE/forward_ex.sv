module forward_ex
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input riscv_reg_e rs1_addr_i,
    input riscv_reg_e rs2_addr_i,

    input for_info_t  for_info_mem_i,
    input for_info_t  for_info_wb_i,

    output forward_e  for_ex_a_o,
    output forward_e  for_ex_b_o
);

    // ============================================================
    // Operand A - rs1
    // ============================================================

    always_comb begin : sel_for_ex_a_o

        for_ex_a_o = RD_EX;

        if (rs1_addr_i != REG_ZERO) begin
            if (
                for_info_mem_i.reg_en &&
                (for_info_mem_i.rd_addr != REG_ZERO) &&
                (rs1_addr_i == for_info_mem_i.rd_addr)
            ) begin
                for_ex_a_o = RD_MEM;
            end

            else if (
                for_info_wb_i.reg_en &&
                (for_info_wb_i.rd_addr != REG_ZERO) &&
                (rs1_addr_i == for_info_wb_i.rd_addr)
            ) begin
                for_ex_a_o = RD_WB;
            end
        end
    end


    // ============================================================
    // Operand B - rs2
    // ============================================================

    always_comb begin : sel_for_ex_b_o
        for_ex_b_o = RD_EX;

        if (rs2_addr_i != REG_ZERO) begin

            if (
                for_info_mem_i.reg_en &&
                (for_info_mem_i.rd_addr != REG_ZERO) &&
                (rs2_addr_i == for_info_mem_i.rd_addr)
            ) begin
                for_ex_b_o = RD_MEM;
            end

            else if (
                for_info_wb_i.reg_en &&
                (for_info_wb_i.rd_addr != REG_ZERO) &&
                (rs2_addr_i == for_info_wb_i.rd_addr)
            ) begin
                for_ex_b_o = RD_WB;
            end
        end
    end
endmodule