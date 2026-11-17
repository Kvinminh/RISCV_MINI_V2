// // Ép về 64 bit trước khi so sánh, tránh WIDTHEXPAND
// `define HZ_CMP(stage, fld, a, e) cmp(stage, fld, 64'(a), 64'(e))

// class hz_fwd_sb;
//     hz_fwd_ref ref_m;
//     mailbox #(hz_fwd_txn) mon2sb;
//     int num_txn;

//     int pass;
//     int fail;
//     int txn_err;       // số lỗi của transaction hiện tại
//     event done;

//     function new(mailbox #(hz_fwd_txn) mon2sb, int num_txn);
//         this.mon2sb  = mon2sb;
//         this.num_txn = num_txn;
//         this.ref_m   = new();
//         this.pass    = 0;
//         this.fail    = 0;
//         this.txn_err = 0;
//     endfunction

//     // ============================================================
//     // So sánh giá trị số
//     // ============================================================
//     function void cmp(string stage, string fld,
//                       longint unsigned act, longint unsigned exp_v);
//         if (act !== exp_v) begin
//             txn_err++;
//             $error("[SB][FAIL][%s] %-10s ACTUAL=%0h  EXPECTED=%0h",
//                    stage, fld, act, exp_v);
//         end
//     endfunction

//     // So sánh enum, in tên để dễ đọc (hai enum khác kiểu nên tách hàm)
//     function void cmp_for_id(string stage, string fld,
//                              for_sel_e act, for_sel_e exp_v);
//         if (act !== exp_v) begin
//             txn_err++;
//             $error("[SB][FAIL][%s] %-10s ACTUAL=%s  EXPECTED=%s",
//                    stage, fld, act.name(), exp_v.name());
//         end
//     endfunction

//     function void cmp_for_ex(string stage, string fld,
//                              forward_e act, forward_e exp_v);
//         if (act !== exp_v) begin
//             txn_err++;
//             $error("[SB][FAIL][%s] %-10s ACTUAL=%s  EXPECTED=%s",
//                    stage, fld, act.name(), exp_v.name());
//         end
//     endfunction

//     // ============================================================
//     // Kiểm tra stall / flush
//     // ============================================================
//     function void chk_hzd(hzd_ctrl_t a, hzd_ctrl_t e);
//         `HZ_CMP("HZD", "stall_pc",    a.stall_pc,    e.stall_pc);
//         `HZ_CMP("HZD", "stall_if_id", a.stall_if_id, e.stall_if_id);
//         `HZ_CMP("HZD", "flush_if_id", a.flush_if_id, e.flush_if_id);
//         `HZ_CMP("HZD", "flush_id_ex", a.flush_id_ex, e.flush_id_ex);
//     endfunction

//     // ============================================================
//     // Kiểm tra forwarding (ID và EX)
//     // ============================================================
//     function void chk_fwd(hz_fwd_txn t);
//         cmp_for_id("FWD_ID", "for_id_a", t.for_id_a, t.exp_for_id_a);
//         cmp_for_id("FWD_ID", "for_id_b", t.for_id_b, t.exp_for_id_b);
//         cmp_for_ex("FWD_EX", "for_ex_a", t.for_ex_a, t.exp_for_ex_a);
//         cmp_for_ex("FWD_EX", "for_ex_b", t.for_ex_b, t.exp_for_ex_b);
//     endfunction

//     // ============================================================
//     // In input, kết quả phân loại của ref, DUT và expected để debug
//     // ============================================================
//     task dump_txn(hz_fwd_txn t);
//         hz_fwd_ref::dep_t  d;
//         hz_fwd_ref::case_t c;

//         $display("  ---- INPUT ----");
//         $display("  rs1_addr=%0d rs1_used=%0b  rs2_addr=%0d rs2_used=%0b",
//                  t.rs1_addr, t.rs1_used, t.rs2_addr, t.rs2_used);
//         $display("  ex_rs1=%0d ex_rs2=%0d", t.ex_rs1_addr, t.ex_rs2_addr);
//         $display("  jump_en=%0b  br_en=%0b  br_taken=%0b",
//                  t.jump_en, t.br_en, t.br_taken);
//         $display("  for_info_ex : rd=%0d mem_re=%0b reg_en=%0b",
//                  t.for_info_ex.rd_addr, t.for_info_ex.mem_re, t.for_info_ex.reg_en);
//         $display("  for_info_mem: rd=%0d mem_re=%0b reg_en=%0b",
//                  t.for_info_mem.rd_addr, t.for_info_mem.mem_re, t.for_info_mem.reg_en);
//         $display("  for_info_wb : rd=%0d mem_re=%0b reg_en=%0b",
//                  t.for_info_wb.rd_addr, t.for_info_wb.mem_re, t.for_info_wb.reg_en);

//         d = ref_m.dau_hieu_stall(t);
//         c = ref_m.case_stall(t, d);
//         $display("  ---- HAZARD REF ----");
//         $display("  rs1_ex=%0b rs2_ex=%0b rs1_mem=%0b rs2_mem=%0b",
//                  d.rs1_ex, d.rs2_ex, d.rs1_mem, d.rs2_mem);
//         $display("  br2alu_ex=%0b br2load_ex=%0b br2load_mem=%0b alu2load=%0b",
//                  c.br2alu_ex, c.br2load_ex, c.br2load_mem, c.alu2load);

//         $display("  ---- HAZARD DUT ----");
//         $display("  stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b",
//                  t.hzd_ctrl.stall_pc, t.hzd_ctrl.stall_if_id,
//                  t.hzd_ctrl.flush_if_id, t.hzd_ctrl.flush_id_ex);
//         $display("  ---- HAZARD EXP ----");
//         $display("  stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b",
//                  t.exp_hz.stall_pc, t.exp_hz.stall_if_id,
//                  t.exp_hz.flush_if_id, t.exp_hz.flush_id_ex);

//         $display("  ---- FORWARD DUT / EXP ----");
//         $display("  for_id_a=%s / %s  for_id_b=%s / %s",
//                  t.for_id_a.name(), t.exp_for_id_a.name(),
//                  t.for_id_b.name(), t.exp_for_id_b.name());
//         $display("  for_ex_a=%s / %s  for_ex_b=%s / %s",
//                  t.for_ex_a.name(), t.exp_for_ex_a.name(),
//                  t.for_ex_b.name(), t.exp_for_ex_b.name());
//     endtask

//     // ============================================================
//     // Vòng lặp chính
//     // ============================================================
//     task run();
//         hz_fwd_txn txn;

//         repeat (num_txn) begin
//             mon2sb.get(txn);
//             txn_err = 0;

//             // Ref không có state, chỉ tính expected và ghi vào txn
//             if (txn.rst_n) begin
//                 void'(ref_m.predict(txn));

//                 chk_hzd(txn.hzd_ctrl, txn.exp_hz);
//                 chk_fwd(txn);
//             end

//             if (txn_err == 0) begin
//                 pass++;
//             end
//             else begin
//                 fail++;
//                 $display("[SB] Transaction #%0d FAIL (%0d lỗi), dump:",
//                          pass + fail, txn_err);
//                 dump_txn(txn);
//             end
//         end

//         -> done;
//     endtask

//     function void report();
//         $display(
//             "\n[SB] HZ_FWD PASS=%0d FAIL=%0d RESULT=%s",
//             pass, fail, (fail == 0) ? "PASS" : "FAIL"
//         );
//     endfunction
// endclass










`define HZ_CMP(stage, fld, a, e) cmp(stage, fld, 64'(a), 64'(e))

class hz_fwd_sb;
    hz_fwd_ref             ref_m;
    mailbox #(hz_fwd_txn)  mon2sb;
    int                    num_txn;

    int                    pass;
    int                    fail;
    int                    txn_err;   // số lỗi của transaction hiện tại
    event                  done;

    function new(mailbox #(hz_fwd_txn) mon2sb, int num_txn);
        this.mon2sb  = mon2sb;
        this.num_txn = num_txn;
        this.ref_m   = new();
        this.pass    = 0;
        this.fail    = 0;
        this.txn_err = 0;
    endfunction

    // ============================================================
    // Hàm so sánh
    // ============================================================
    function void cmp(string stage, string fld,
                      longint unsigned act, longint unsigned exp_v);
        if (act !== exp_v) begin
            txn_err++;
            $error("[SB][FAIL][%s] %-12s ACTUAL=%0h  EXPECTED=%0h",
                   stage, fld, act, exp_v);
        end
    endfunction

    function void cmp_for_id(string stage, string fld,
                             for_sel_e act, for_sel_e exp_v);
        if (act !== exp_v) begin
            txn_err++;
            $error("[SB][FAIL][%s] %-12s ACTUAL=%s  EXPECTED=%s",
                   stage, fld, act.name(), exp_v.name());
        end
    endfunction

    function void cmp_for_ex(string stage, string fld,
                             forward_e act, forward_e exp_v);
        if (act !== exp_v) begin
            txn_err++;
            $error("[SB][FAIL][%s] %-12s ACTUAL=%s  EXPECTED=%s",
                   stage, fld, act.name(), exp_v.name());
        end
    endfunction

    // ============================================================
    // 1. Phát hiện phụ thuộc (tầng đầu tiên)
    // ============================================================
    function void chk_dep(hz_dep_t a, hz_dep_t e);
        `HZ_CMP("DEP", "rs1_ex",  a.rs1_ex,  e.rs1_ex);
        `HZ_CMP("DEP", "rs2_ex",  a.rs2_ex,  e.rs2_ex);
        `HZ_CMP("DEP", "rs1_mem", a.rs1_mem, e.rs1_mem);
        `HZ_CMP("DEP", "rs2_mem", a.rs2_mem, e.rs2_mem);
    endfunction

    // ============================================================
    // 2. Điều kiện stall (tầng thứ hai)
    // ============================================================
    function void chk_stall_cond(hz_stall_t a, hz_stall_t e);
        `HZ_CMP("STL", "br2alu_ex",   a.br2alu_ex,   e.br2alu_ex);
        `HZ_CMP("STL", "br2load_ex",  a.br2load_ex,  e.br2load_ex);
        `HZ_CMP("STL", "br2load_mem", a.br2load_mem, e.br2load_mem);
        `HZ_CMP("STL", "alu2load",    a.alu2load,    e.alu2load);
    endfunction

    // ============================================================
    // 3. Stall / flush ra ngoài (tầng thứ ba)
    // ============================================================
    function void chk_hzd(hzd_ctrl_t a, hzd_ctrl_t e);
        `HZ_CMP("HZD", "stall_pc",    a.stall_pc,    e.stall_pc);
        `HZ_CMP("HZD", "stall_if_id", a.stall_if_id, e.stall_if_id);
        `HZ_CMP("HZD", "flush_if_id", a.flush_if_id, e.flush_if_id);
        `HZ_CMP("HZD", "flush_id_ex", a.flush_id_ex, e.flush_id_ex);
    endfunction

    // ============================================================
    // 4. Forwarding (ID và EX)
    // ============================================================
    function void chk_fwd(hz_fwd_txn t);
        cmp_for_id("FWD_ID", "for_id_a", t.for_id_a, t.expected_for_id_a);
        cmp_for_id("FWD_ID", "for_id_b", t.for_id_b, t.expected_for_id_b);
        cmp_for_ex("FWD_EX", "for_ex_a", t.for_ex_a, t.expected_for_ex_a);
        cmp_for_ex("FWD_EX", "for_ex_b", t.for_ex_b, t.expected_for_ex_b);
    endfunction

    // ============================================================
    // In khi FAIL: chỉ in giá trị đã có trong txn, không gọi lại ref
    // ============================================================
    task dump_txn(hz_fwd_txn t);
        $display("  ---- INPUT ----");
        $display("  rs1_addr=%0d used=%0b | rs2_addr=%0d used=%0b",
                 t.rs1_addr, t.rs1_used, t.rs2_addr, t.rs2_used);
        $display("  jump_en=%0b br_en=%0b br_taken=%0b",
                 t.jump_en, t.br_en, t.br_taken);
        $display("  for_info_ex : rd=%0d mem_re=%0b reg_en=%0b",
                 t.for_info_ex.rd_addr, t.for_info_ex.mem_re, t.for_info_ex.reg_en);
        $display("  for_info_mem: rd=%0d mem_re=%0b reg_en=%0b",
                 t.for_info_mem.rd_addr, t.for_info_mem.mem_re, t.for_info_mem.reg_en);
        $display("  for_info_wb : rd=%0d mem_re=%0b reg_en=%0b",
                 t.for_info_wb.rd_addr, t.for_info_wb.mem_re, t.for_info_wb.reg_en);

        $display("  ---- DEP (DUT / EXP) ----");
        $display("  rs1_ex=%0b/%0b  rs2_ex=%0b/%0b",
                 t.dep.rs1_ex,  t.exp_dep.rs1_ex,
                 t.dep.rs2_ex,  t.exp_dep.rs2_ex);
        $display("  rs1_mem=%0b/%0b rs2_mem=%0b/%0b",
                 t.dep.rs1_mem, t.exp_dep.rs1_mem,
                 t.dep.rs2_mem, t.exp_dep.rs2_mem);

        $display("  ---- STALL_COND (DUT / EXP) ----");
        $display("  br2alu_ex=%0b/%0b  br2load_ex=%0b/%0b",
                 t.stall_cond.br2alu_ex,   t.exp_stall_cond.br2alu_ex,
                 t.stall_cond.br2load_ex,  t.exp_stall_cond.br2load_ex);
        $display("  br2load_mem=%0b/%0b alu2load=%0b/%0b",
                 t.stall_cond.br2load_mem, t.exp_stall_cond.br2load_mem,
                 t.stall_cond.alu2load,    t.exp_stall_cond.alu2load);

        $display("  ---- HZD (DUT / EXP) ----");
        $display("  stall_pc=%0b/%0b stall_if_id=%0b/%0b",
                 t.hzd_ctrl.stall_pc,    t.expected_hzd_ctrl.stall_pc,
                 t.hzd_ctrl.stall_if_id, t.expected_hzd_ctrl.stall_if_id);
        $display("  flush_if_id=%0b/%0b flush_id_ex=%0b/%0b",
                 t.hzd_ctrl.flush_if_id, t.expected_hzd_ctrl.flush_if_id,
                 t.hzd_ctrl.flush_id_ex, t.expected_hzd_ctrl.flush_id_ex);

        $display("  ---- FWD (DUT / EXP) ----");
        $display("  for_id_a=%s/%s  for_id_b=%s/%s",
                 t.for_id_a.name(), t.expected_for_id_a.name(),
                 t.for_id_b.name(), t.expected_for_id_b.name());
        $display("  for_ex_a=%s/%s  for_ex_b=%s/%s",
                 t.for_ex_a.name(), t.expected_for_ex_a.name(),
                 t.for_ex_b.name(), t.expected_for_ex_b.name());
    endtask

    // ============================================================
    // Vòng lặp chính
    // ============================================================
    task run();
        hz_fwd_txn txn;

        repeat (num_txn) begin
            mon2sb.get(txn);
            txn_err = 0;

            // ref điền exp_dep, exp_stall_cond, expected_hzd_ctrl, expected_for_*
            void'(ref_m.predict(txn));

            chk_dep(txn.dep, txn.exp_dep);
            chk_stall_cond(txn.stall_cond, txn.exp_stall_cond);
            chk_hzd(txn.hzd_ctrl, txn.expected_hzd_ctrl);
            chk_fwd(txn);

            if (txn_err == 0) begin
                pass++;
            end
            else begin
                fail++;
                $display("[SB] Transaction #%0d FAIL (%0d lỗi)", pass + fail, txn_err);
                dump_txn(txn);
            end
        end

        -> done;
    endtask

    function void report();
        $display("\n[SB] HZ_FWD PASS=%0d FAIL=%0d RESULT=%s",
                 pass, fail, (fail == 0) ? "PASS" : "FAIL");
    endfunction
endclass









