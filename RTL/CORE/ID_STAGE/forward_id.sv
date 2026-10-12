module forward_id
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input riscv_reg_e rs1_addr_i,
    input riscv_reg_e rs2_addr_i,

    input for_info_t  for_info_ex_i,
    input for_info_t  for_info_mem_i,

    output for_sel_e  for_id_a_o,
    output for_sel_e  for_id_b_o
);

    always_comb begin : sel_for_id_a_o
        for_id_a_o = RS1_DATA_ID;
        if (rs1_addr_i != REG_ZERO) begin
            if (
                for_info_ex_i.reg_en &&
                (for_info_ex_i.rd_addr != REG_ZERO) &&
                (rs1_addr_i == for_info_ex_i.rd_addr)
            ) begin
                for_id_a_o = RD_DATA_EX;
            end

            else if (
                for_info_mem_i.reg_en &&
                (for_info_mem_i.rd_addr != REG_ZERO) &&
                (rs1_addr_i == for_info_mem_i.rd_addr)
            ) begin
                for_id_a_o = RD_DATA_MEM;
            end
        end
    end


    always_comb begin : sel_for_id_b_o
        for_id_b_o = RS2_DATA_ID;
        if (rs2_addr_i != REG_ZERO) begin
            if (
                for_info_ex_i.reg_en &&
                (for_info_ex_i.rd_addr != REG_ZERO) &&
                (rs2_addr_i == for_info_ex_i.rd_addr)
            ) begin
                for_id_b_o = RD_DATA_EX;
            end

            else if (
                for_info_mem_i.reg_en &&
                (for_info_mem_i.rd_addr != REG_ZERO) &&
                (rs2_addr_i == for_info_mem_i.rd_addr)
            ) begin
                for_id_b_o = RD_DATA_MEM;
            end
        end
    end
endmodule