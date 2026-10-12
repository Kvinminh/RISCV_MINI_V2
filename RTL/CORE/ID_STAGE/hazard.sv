module hazzard
import isa_pkg::*;
import core_pkg::*;
(
    input riscv_reg_e            rs1_addr_i,
    input riscv_reg_e            rs2_addr_i,

    input logic                  rs1_used_i,
    input logic                  rs2_used_i,

    input logic                  jump_en_i,       // JAL || JALR từ decode
    input logic                  br_en_i,         // Branch từ decode
    input logic                  br_taken_i,      // Kết quả br_compare

    input for_info_t             for_info_ex_i,
    input for_info_t             for_info_mem_i,

    output hzd_ctrl_t            hzd_ctrl_o
);

    // ============================================================
    // 1. Control-flow instruction
    // ============================================================

    logic take_jump;
    assign take_jump = jump_en_i || (br_taken_i && br_en_i);

    // ============================================================
    // 2. Detect dependency với instruction ở EX / MEM
    // ============================================================

    logic rs1_ex;
    logic rs2_ex;
    logic rs1_mem;
    logic rs2_mem;

    always_comb begin
        // -------------------------
        // Dependency với EX
        // -------------------------
        rs1_ex =
            rs1_used_i
            && for_info_ex_i.reg_en
            && (for_info_ex_i.rd_addr != REG_ZERO)
            && (for_info_ex_i.rd_addr == rs1_addr_i);

        rs2_ex =
            rs2_used_i
            && for_info_ex_i.reg_en
            && (for_info_ex_i.rd_addr != REG_ZERO)
            && (for_info_ex_i.rd_addr == rs2_addr_i);
        // -------------------------
        // Dependency với MEM
        // -------------------------
        rs1_mem =
            rs1_used_i
            && for_info_mem_i.reg_en
            && (for_info_mem_i.rd_addr != REG_ZERO)
            && (for_info_mem_i.rd_addr == rs1_addr_i);

        rs2_mem =
            rs2_used_i
            && for_info_mem_i.reg_en
            && (for_info_mem_i.rd_addr != REG_ZERO)
            && (for_info_mem_i.rd_addr == rs2_addr_i);
    end

    // ============================================================
    // 3. Branch dependency
    // ============================================================

    logic br2alu_ex;
    logic br2load_ex;
    logic br2load_mem;

    // Branch ở ID phụ thuộc vào ALU result ở EX
    assign br2alu_ex =
        (rs1_ex || rs2_ex)
        && br_en_i
        && !for_info_ex_i.mem_re;

    // Branch ở ID phụ thuộc vào LOAD ở EX
    assign br2load_ex =
        (rs1_ex || rs2_ex)
        && br_en_i
        && for_info_ex_i.mem_re;

    // Branch ở ID phụ thuộc vào LOAD ở MEM
    assign br2load_mem =
        (rs1_mem || rs2_mem)
        && br_en_i
        && for_info_mem_i.mem_re;

    // ============================================================
    // 4. Load-use hazard cho instruction thông thường
    // ============================================================

    logic alu2load;

    assign alu2load =
        (rs1_ex || rs2_ex)
        && for_info_ex_i.mem_re
        && !br_en_i;


    // ============================================================
    // 5. Quyết định STALL
    // ============================================================

    logic need_stall;

    assign need_stall = br2alu_ex || br2load_ex || br2load_mem || alu2load;


    // ============================================================
    // 6. Stall control
    // ============================================================

    assign hzd_ctrl_o.stall_pc    = need_stall;
    assign hzd_ctrl_o.stall_if_id = need_stall;

    // Insert bubble vào ID/EX
    assign hzd_ctrl_o.flush_id_ex = need_stall;


    // ============================================================
    // 7. Flush control cho control-flow change
    // ============================================================

    // Nếu vừa jump/branch taken vừa có hazard,
    // hiện tại ưu tiên STALL.
    assign hzd_ctrl_o.flush_if_id =
        take_jump && !need_stall;

endmodule