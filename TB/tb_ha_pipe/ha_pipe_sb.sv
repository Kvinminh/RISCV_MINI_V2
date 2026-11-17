// Ép mọi giá trị về 64 bit trước khi so sánh, tránh WIDTHEXPAND
`define CMP(stage, fld, a, e) cmp(stage, fld, 64'(a), 64'(e))

class ha_pipe_sb;
    ha_pipe_ref ref_m;
    mailbox #(ha_pipe_txn) mon2sb;
    int num_txn;

    int pass;
    int fail;
    int txn_err;       // số lỗi của transaction hiện tại
    event done;

    function new(mailbox #(ha_pipe_txn) mon2sb, int num_txn);
        this.mon2sb  = mon2sb;
        this.num_txn = num_txn;
        this.ref_m   = new();
        this.pass    = 0;
        this.fail    = 0;
        this.txn_err = 0;
    endfunction

    // ============================================================
    // So sánh 1 field, báo lỗi nếu sai
    // ============================================================
    function void cmp(string stage, string fld,
                      longint unsigned act, longint unsigned exp_v);
        if (act !== exp_v) begin
            txn_err++;
            $error("[SB][FAIL][%s] %-10s ACTUAL=%0h  EXPECTED=%0h",
                   stage, fld, act, exp_v);
        end
    endfunction

    // ============================================================
    // Kiểm tra từng thanh ghi pipeline, đủ mọi field
    // ============================================================
    function void chk_if_id(if_id_reg_t a, if_id_reg_t e);
        `CMP("IF/ID", "pc_cur", a.pc_cur, e.pc_cur);
        `CMP("IF/ID", "pc_4",   a.pc_4,   e.pc_4);
        `CMP("IF/ID", "ins",    a.ins,    e.ins);
    endfunction

    function void chk_id_ex(id_ex_reg_t a, id_ex_reg_t e);
        `CMP("ID/EX", "f3",        a.f3,              e.f3);
        `CMP("ID/EX", "f7_5",      a.f7_5,            e.f7_5);
        `CMP("ID/EX", "pc_cur",    a.pc_cur,          e.pc_cur);
        `CMP("ID/EX", "pc_4",      a.pc_4,            e.pc_4);
        `CMP("ID/EX", "imm_out",   a.imm_out,         e.imm_out);
        `CMP("ID/EX", "rd_addr",   a.rd_addr,         e.rd_addr);
        `CMP("ID/EX", "rs1_addr",  a.rs1_addr,        e.rs1_addr);
        `CMP("ID/EX", "rs2_addr",  a.rs2_addr,        e.rs2_addr);
        `CMP("ID/EX", "rs1_data",  a.rs1_data,        e.rs1_data);
        `CMP("ID/EX", "rs2_data",  a.rs2_data,        e.rs2_data);
        `CMP("ID/EX", "alu_op",    a.ex_ctrl.alu_op,  e.ex_ctrl.alu_op);
        `CMP("ID/EX", "sel_a",     a.ex_ctrl.sel_a,   e.ex_ctrl.sel_a);
        `CMP("ID/EX", "sel_b",     a.ex_ctrl.sel_b,   e.ex_ctrl.sel_b);
        `CMP("ID/EX", "dmem_re",   a.mem_ctrl.dmem_re,  e.mem_ctrl.dmem_re);
        `CMP("ID/EX", "dmem_wri",  a.mem_ctrl.dmem_wri, e.mem_ctrl.dmem_wri);
        `CMP("ID/EX", "extension", a.extension,       e.extension);
        `CMP("ID/EX", "wb_reg_en", a.wb_ctrl.reg_en,  e.wb_ctrl.reg_en);
        `CMP("ID/EX", "wb_sel",    a.wb_ctrl.sel_wb,  e.wb_ctrl.sel_wb);
    endfunction

    function void chk_ex_mem(ex_mem_reg_t a, ex_mem_reg_t e);
        `CMP("EX/MEM", "f3",        a.f3,                e.f3);
        `CMP("EX/MEM", "pc_4",      a.pc_4,              e.pc_4);
        `CMP("EX/MEM", "alu",       a.alu,               e.alu);
        `CMP("EX/MEM", "rs2_data",  a.rs2_data,          e.rs2_data);
        `CMP("EX/MEM", "rd_addr",   a.rd_addr,           e.rd_addr);
        `CMP("EX/MEM", "extension", a.extension,         e.extension);
        `CMP("EX/MEM", "dmem_re",   a.mem_ctrl.dmem_re,  e.mem_ctrl.dmem_re);
        `CMP("EX/MEM", "dmem_wri",  a.mem_ctrl.dmem_wri, e.mem_ctrl.dmem_wri);
        `CMP("EX/MEM", "wb_reg_en", a.wb_ctrl.reg_en,    e.wb_ctrl.reg_en);
        `CMP("EX/MEM", "wb_sel",    a.wb_ctrl.sel_wb,    e.wb_ctrl.sel_wb);
    endfunction

    function void chk_mem_wb(mem_wb_reg_t a, mem_wb_reg_t e);
        `CMP("MEM/WB", "pc_4",       a.pc_4,           e.pc_4);
        `CMP("MEM/WB", "alu_result", a.alu_result,     e.alu_result);
        `CMP("MEM/WB", "mem_rdata",  a.mem_rdata,      e.mem_rdata);
        `CMP("MEM/WB", "rd_addr",    a.rd_addr,        e.rd_addr);
        `CMP("MEM/WB", "wb_reg_en",  a.wb_ctrl.reg_en, e.wb_ctrl.reg_en);
        `CMP("MEM/WB", "wb_sel",     a.wb_ctrl.sel_wb, e.wb_ctrl.sel_wb);
    endfunction

    // ============================================================
    // Kiểm tra stall / flush
    // ============================================================
    function void chk_hzd(hzd_ctrl_t a, hzd_ctrl_t e);
        `CMP("HZD", "stall_pc",    a.stall_pc,    e.stall_pc);
        `CMP("HZD", "stall_if_id", a.stall_if_id, e.stall_if_id);
        `CMP("HZD", "flush_if_id", a.flush_if_id, e.flush_if_id);
        `CMP("HZD", "flush_id_ex", a.flush_id_ex, e.flush_id_ex);
    endfunction

    // In toàn bộ input và kết quả phân loại hazard để debug
    task dump_txn(ha_pipe_txn t);
        ha_pipe_ref::dep_t  d;
        ha_pipe_ref::case_t c;

        $display("  ---- INPUT ----");
        $display("  rst_n=%0b  pc_next=%0h", t.rst_n, t.pc_next);
        $display("  rs1_addr=%0d rs1_used=%0b  rs2_addr=%0d rs2_used=%0b",
                 t.rs1_addr, t.rs1_used, t.rs2_addr, t.rs2_used);
        $display("  jump_en=%0b  br_en=%0b  br_taken=%0b",
                 t.jump_en, t.br_en, t.br_taken);
        $display("  for_info_ex : rd=%0d mem_re=%0b reg_en=%0b",
                 t.for_info_ex.rd_addr, t.for_info_ex.mem_re, t.for_info_ex.reg_en);
        $display("  for_info_mem: rd=%0d mem_re=%0b reg_en=%0b",
                 t.for_info_mem.rd_addr, t.for_info_mem.mem_re, t.for_info_mem.reg_en);

        if (t.rst_n) begin
            d = ref_m.dau_hieu_stall(t);
            c = ref_m.case_stall(t, d);
            $display("  ---- HAZARD REF ----");
            $display("  rs1_ex=%0b rs2_ex=%0b rs1_mem=%0b rs2_mem=%0b",
                     d.rs1_ex, d.rs2_ex, d.rs1_mem, d.rs2_mem);
            $display("  br2alu_ex=%0b br2load_ex=%0b br2load_mem=%0b alu2load=%0b",
                     c.br2alu_ex, c.br2load_ex, c.br2load_mem, c.alu2load);
        end

        $display("  ---- HAZARD DUT ----");
        $display("  stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b",
                 t.hzd_ctrl.stall_pc, t.hzd_ctrl.stall_if_id,
                 t.hzd_ctrl.flush_if_id, t.hzd_ctrl.flush_id_ex);
        $display("  ---- HAZARD EXP ----");
        $display("  stall_pc=%0b stall_if_id=%0b flush_if_id=%0b flush_id_ex=%0b",
                 t.expected_hzd_ctrl.stall_pc, t.expected_hzd_ctrl.stall_if_id,
                 t.expected_hzd_ctrl.flush_if_id, t.expected_hzd_ctrl.flush_id_ex);
    endtask

    // ============================================================
    // Vòng lặp chính
    // ============================================================
    task run();
        ha_pipe_txn txn;

        repeat (num_txn) begin
            mon2sb.get(txn);
            txn_err = 0;

            // Ref tính expected_* và cập nhật state pipeline
            txn.expected_hzd_ctrl = ref_m.predict(txn);

            // Output
            `CMP("PC", "pc_cur", txn.pc_cur, txn.expected_pc_cur);

            // Thanh ghi pipeline (kiểm tra cả ảnh hưởng của stall/flush)
            chk_if_id (txn.reg_id,  txn.expected_reg_id);
            chk_id_ex (txn.reg_ex,  txn.expected_reg_ex);
            chk_ex_mem(txn.reg_mem, txn.expected_reg_mem);
            chk_mem_wb(txn.reg_wb,  txn.expected_reg_wb);

            // Stall / flush: không so sánh khi reset
            if (txn.rst_n)
                chk_hzd(txn.hzd_ctrl, txn.expected_hzd_ctrl);

            if (txn_err == 0) begin
                pass++;
            end
            else begin
                fail++;
                $display("[SB] Transaction #%0d FAIL (%0d lỗi), dump:",
                         pass + fail, txn_err);
                dump_txn(txn);
            end
        end

        -> done;
    endtask

    function void report();
        $display(
            "\n[SB] HA_PIPE PASS=%0d FAIL=%0d RESULT=%s",
            pass, fail, (fail == 0) ? "PASS" : "FAIL"
        );
    endfunction
endclass