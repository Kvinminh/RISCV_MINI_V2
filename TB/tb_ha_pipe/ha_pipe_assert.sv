module ha_pipe_assert
    import isa_pkg::*;
    import core_pkg::*;
(
    input logic              clk,
    input logic              rst_n,

    // Input hazard
    input riscv_reg_e        rs1_addr,
    input riscv_reg_e        rs2_addr,
    input logic              rs1_used,
    input logic              rs2_used,
    input logic              jump_en,
    input logic              br_en,
    input logic              br_taken,
    input for_info_t         for_info_ex,
    input for_info_t         for_info_mem,

    // Input pipeline
    input logic [XLEN-1:0]   pc_next,
    input if_id_reg_t        if_reg,
    input id_ex_reg_t        id_reg,
    input ex_mem_reg_t       ex_reg,
    input mem_wb_reg_t       mem_reg,

    // Output DUT
    input hzd_ctrl_t         hzd_ctrl,
    input logic [XLEN-1:0]   pc_cur,
    input if_id_reg_t        reg_id,
    input id_ex_reg_t        reg_ex,
    input ex_mem_reg_t       reg_mem,
    input mem_wb_reg_t       reg_wb
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    //////////////////////////////////////////
    // AP: input hợp lệ
    //////////////////////////////////////////

    AP_F01_1: assert property (
        !$isunknown({rs1_addr, rs2_addr, rs1_used, rs2_used,
                     jump_en, br_en, br_taken, for_info_ex, for_info_mem})
    ) else $error("[AP-F01-1] input hazard co X/Z @%0t", $time);

    AP_F01_2: assert property (
        !$isunknown({pc_next, if_reg, id_reg, ex_reg, mem_reg})
    ) else $error("[AP-F01-2] input pipeline co X/Z @%0t", $time);

    AP_F01_3: assert property (
        !(jump_en && br_en)
    ) else $error("[AP-F01-3] jump_en va br_en cung = 1 @%0t", $time);

    //////////////////////////////////////////
    // VF-AS: stall / flush
    //////////////////////////////////////////

    // VF-AS-1: stall_pc, stall_if_id, flush_id_ex luôn cùng giá trị
    VF_AS_1: assert property (
        (hzd_ctrl.stall_pc == hzd_ctrl.stall_if_id) &&
        (hzd_ctrl.stall_pc == hzd_ctrl.flush_id_ex)
    ) else $error("[VF-AS-1] stall/flush_id_ex khong dong bo: %b @%0t",
                  hzd_ctrl, $time);

    // VF-AS-2: không stall IF/ID và flush IF/ID cùng lúc
    VF_AS_2: assert property (
        !(hzd_ctrl.flush_if_id && hzd_ctrl.stall_if_id)
    ) else $error("[VF-AS-2] flush_if_id va stall_if_id cung = 1 @%0t", $time);

    // VF-AS-3: flush_if_id chỉ xảy ra khi không có hazard
    VF_AS_3: assert property (
        hzd_ctrl.flush_if_id |-> !hzd_ctrl.stall_pc
    ) else $error("[VF-AS-3] flush_if_id=1 khi dang stall @%0t", $time);

    // VF-AS-4: hzd_ctrl không có X/Z
    VF_AS_4: assert property (
        !$isunknown(hzd_ctrl)
    ) else $error("[VF-AS-4] hzd_ctrl co X/Z: %b @%0t", hzd_ctrl, $time);

    // VF-AS-5: flush_if_id = take_jump && !stall (khớp công thức RTL)
    VF_AS_5: assert property (
        hzd_ctrl.flush_if_id ==
        ((jump_en || (br_taken && br_en)) && !hzd_ctrl.stall_pc)
    ) else $error("[VF-AS-5] flush_if_id sai cong thuc: flush=%b jump=%b br=%b brt=%b stall=%b @%0t",
                  hzd_ctrl.flush_if_id, jump_en, br_en, br_taken,
                  hzd_ctrl.stall_pc, $time);

    //////////////////////////////////////////
    // VF-R: thanh ghi pipeline sau cạnh clock
    // Điều kiện (rst_n && $past(rst_n)) để $past không lấy giá trị lúc reset
    //////////////////////////////////////////

    // Stall: PC giữ nguyên
    VF_R_01: assert property (
        (rst_n && $past(rst_n) && hzd_ctrl.stall_pc) |=> pc_cur == $past(pc_cur)
    ) else $error("[VF-R-01] stall nhung PC doi @%0t", $time);

    // Stall: IF/ID giữ nguyên
    VF_R_02: assert property (
        (rst_n && $past(rst_n) && hzd_ctrl.stall_if_id) |=> reg_id == $past(reg_id)
    ) else $error("[VF-R-02] stall nhung IF/ID doi @%0t", $time);

    // Không stall: PC nhận pc_next
    VF_R_03: assert property (
        (rst_n && $past(rst_n) && !hzd_ctrl.stall_pc) |=> pc_cur == $past(pc_next)
    ) else $error("[VF-R-03] pc_cur != pc_next truoc do @%0t", $time);

    // Flush ID/EX: về 0
    VF_R_04: assert property (
        (rst_n && $past(rst_n) && hzd_ctrl.flush_id_ex) |=> reg_ex == '0
    ) else $error("[VF-R-04] flush_id_ex nhung ID/EX khac 0 @%0t", $time);

    // Flush IF/ID: về 0
    VF_R_05: assert property (
        (rst_n && $past(rst_n) && hzd_ctrl.flush_if_id) |=> reg_id == '0
    ) else $error("[VF-R-05] flush_if_id nhung IF/ID khac 0 @%0t", $time);

    // Không stall, không flush: IF/ID nhận input
    VF_R_06: assert property (
        (rst_n && $past(rst_n) && !hzd_ctrl.stall_if_id && !hzd_ctrl.flush_if_id)
        |=> reg_id == $past(if_reg)
    ) else $error("[VF-R-06] IF/ID khong nhan input @%0t", $time);

    // Không flush ID/EX: ID/EX nhận input
    VF_R_07: assert property (
        (rst_n && $past(rst_n) && !hzd_ctrl.flush_id_ex) |=> reg_ex == $past(id_reg)
    ) else $error("[VF-R-07] ID/EX khong nhan input @%0t", $time);

    // EX/MEM và MEM/WB luôn nhận input, kể cả khi stall
    VF_R_08: assert property (
        (rst_n && $past(rst_n)) |=> reg_mem == $past(ex_reg)
    ) else $error("[VF-R-08] EX/MEM khong nhan input @%0t", $time);

    VF_R_09: assert property (
        (rst_n && $past(rst_n)) |=> reg_wb == $past(mem_reg)
    ) else $error("[VF-R-09] MEM/WB khong nhan input @%0t", $time);

    //////////////////////////////////////////
    // Cover: đảm bảo các kịch bản thực sự xảy ra
    //////////////////////////////////////////
    COV_STALL:        cover property (hzd_ctrl.stall_pc);
    COV_FLUSH_IF:     cover property (hzd_ctrl.flush_if_id);
    COV_STALL_JUMP:   cover property (hzd_ctrl.stall_pc &&
                                      (jump_en || (br_taken && br_en)));
    COV_STALL_THEN_RUN: cover property (hzd_ctrl.stall_pc ##1 !hzd_ctrl.stall_pc);

endmodule

bind ha_pipe ha_pipe_assert u_ha_pipe_assert (
    .clk        (clk),
    .rst_n      (rst_n),
    .rs1_addr   (rs1_addr),
    .rs2_addr   (rs2_addr),
    .rs1_used   (rs1_used),
    .rs2_used   (rs2_used),
    .jump_en    (jump_en),
    .br_en      (br_en),
    .br_taken   (br_taken),
    .for_info_ex  (for_info_ex),
    .for_info_mem (for_info_mem),
    .pc_next    (pc_next),
    .if_reg     (if_reg),
    .id_reg     (id_reg),
    .ex_reg     (ex_reg),
    .mem_reg    (mem_reg),
    .hzd_ctrl   (hzd_ctrl),
    .pc_cur     (pc_cur),
    .reg_id     (reg_id),
    .reg_ex     (reg_ex),
    .reg_mem    (reg_mem),
    .reg_wb     (reg_wb)
);