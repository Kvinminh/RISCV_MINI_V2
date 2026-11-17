import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

class hz_fwd_tests;
    virtual hz_fwd_if vif;
    int num_txn;

    int pass = 0;
    int fail = 0;

    function new(virtual hz_fwd_if vif,int num_txn);
        this.vif = vif;
        this.num_txn = num_txn;
    endfunction

    //////////////////////////////////////////
    // TXN HELPERS
    //////////////////////////////////////////

    // Txn mặc định: không dùng rs, không jump/branch, không ghi thanh ghi nào
    function hz_fwd_txn mk_txn(
        logic rs1_u = 0, int rs1 = 0,
        logic rs2_u = 0, int rs2 = 0,
        logic jump  = 0,
        logic br    = 0,
        logic brt   = 0,
        int   rd_ex  = 0, logic ex_en  = 0, logic ex_mre  = 0,
        int   rd_mem = 0, logic mem_en = 0, logic mem_mre = 0,
        int   rd_wb  = 0, logic wb_en  = 0
    );
        hz_fwd_txn t = new();
        t.rs1_used             = rs1_u;
        t.rs1_addr             = riscv_reg_e'(rs1);
        t.rs2_used             = rs2_u;
        t.rs2_addr             = riscv_reg_e'(rs2);
        t.jump_en              = jump;
        t.br_en                = br;
        t.br_taken             = brt;
        t.for_info_ex.rd_addr  = riscv_reg_e'(rd_ex);
        t.for_info_ex.reg_en   = ex_en;
        t.for_info_ex.mem_re   = ex_mre;
        t.for_info_mem.rd_addr = riscv_reg_e'(rd_mem);
        t.for_info_mem.reg_en  = mem_en;
        t.for_info_mem.mem_re  = mem_mre;
        t.for_info_wb.rd_addr  = riscv_reg_e'(rd_wb);
        t.for_info_wb.reg_en   = wb_en;
        t.for_info_wb.mem_re   = 0;     // DUT không dùng, đặt rõ để tránh X
        return t;
    endfunction

    //////////////////////////////////////////
    // EXPECTED FORWARDING (theo RTL)
    //////////////////////////////////////////

    // forward_id: EX > MEM > WB > giá trị thanh ghi. Không xét rs_used, đúng RTL.
    function automatic for_sel_e exp_id(riscv_reg_e rs, hz_fwd_txn t, for_sel_e dflt);
        if (rs != REG_ZERO) begin
            if (t.for_info_ex.reg_en && (t.for_info_ex.rd_addr != REG_ZERO)
                && (t.for_info_ex.rd_addr == rs))
                return RD_DATA_EX;
            if (t.for_info_mem.reg_en && (t.for_info_mem.rd_addr != REG_ZERO)
                && (t.for_info_mem.rd_addr == rs))
                return RD_DATA_MEM;
            if (t.for_info_wb.reg_en && (t.for_info_wb.rd_addr != REG_ZERO)
                && (t.for_info_wb.rd_addr == rs))
                return RD_DATA_WB;
        end
        return dflt;
    endfunction

    // forward_ex: MEM > WB > EX (mặc định)
    function automatic forward_e exp_ex(riscv_reg_e rs, hz_fwd_txn t);
        if (rs != REG_ZERO) begin
            if (t.for_info_mem.reg_en && (t.for_info_mem.rd_addr != REG_ZERO)
                && (t.for_info_mem.rd_addr == rs))
                return RD_MEM;
            if (t.for_info_wb.reg_en && (t.for_info_wb.rd_addr != REG_ZERO)
                && (t.for_info_wb.rd_addr == rs))
                return RD_WB;
        end
        return RD_EX;
    endfunction

    //////////////////////////////////////////
    // DRIVE / CHECK
    //////////////////////////////////////////

    // Hazard và forward đều là tổ hợp: đặt input tại negedge, chờ #1 cho ổn định
    task drive(hz_fwd_txn t);
        @(negedge vif.clk);
        vif.rs1_addr     = t.rs1_addr;
        vif.rs2_addr     = t.rs2_addr;
        vif.rs1_used     = t.rs1_used;
        vif.rs2_used     = t.rs2_used;
        vif.jump_en      = t.jump_en;
        vif.br_en        = t.br_en;
        vif.br_taken     = t.br_taken;
        vif.for_info_ex  = t.for_info_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.for_info_wb  = t.for_info_wb;
        #1;
    endtask

    // s = stall (stall_pc = stall_if_id = flush_id_ex), f = flush_if_id
    task check_hzd(string name, bit s, bit f);
        hzd_ctrl_t exp_hz;
        exp_hz             = '0;
        exp_hz.stall_pc    = s;
        exp_hz.stall_if_id = s;
        exp_hz.flush_id_ex = s;
        exp_hz.flush_if_id = f;

        if (vif.hzd_ctrl !== exp_hz) begin
            fail++;
            $error("[HZD][FAIL] %s actual=%b expected=%b (S=%0b F=%0b)",
                   name, vif.hzd_ctrl, exp_hz, s, f);
        end
        else pass++;
    endtask

    task check_fwd(string name, hz_fwd_txn t);
        for_sel_e e_ia, e_ib;
        forward_e e_xa, e_xb;

        e_ia = exp_id(t.rs1_addr, t, RS1_DATA_ID);
        e_ib = exp_id(t.rs2_addr, t, RS2_DATA_ID);
        e_xa = exp_ex(t.rs1_addr, t);
        e_xb = exp_ex(t.rs2_addr, t);

        if (vif.for_id_a !== e_ia) begin
            fail++;
            $error("[FWD][FAIL] %s FOR_ID_A actual=%s expected=%s",
                   name, vif.for_id_a.name(), e_ia.name());
        end
        else pass++;

        if (vif.for_id_b !== e_ib) begin
            fail++;
            $error("[FWD][FAIL] %s FOR_ID_B actual=%s expected=%s",
                   name, vif.for_id_b.name(), e_ib.name());
        end
        else pass++;

        if (vif.for_ex_a !== e_xa) begin
            fail++;
            $error("[FWD][FAIL] %s FOR_EX_A actual=%s expected=%s",
                   name, vif.for_ex_a.name(), e_xa.name());
        end
        else pass++;

        if (vif.for_ex_b !== e_xb) begin
            fail++;
            $error("[FWD][FAIL] %s FOR_EX_B actual=%s expected=%s",
                   name, vif.for_ex_b.name(), e_xb.name());
        end
        else pass++;
    endtask

    // Drive một txn, kiểm tra hazard với s/f cho trước, kiểm tra forward theo RTL
    task run_case(string name, hz_fwd_txn t, bit s, bit f);
        drive(t);
        check_hzd(name, s, f);
        check_fwd(name, t);
    endtask

    //////////////////////////////////////////
    // VF-F01: KHÔNG STALL / KHÔNG FLUSH
    // Lưu ý: 11, 13 có trường hợp stall, mình gán expected theo RTL
    //////////////////////////////////////////
    task run_f01();
        // 1: rs chưa dùng (used = 0) thì không phát hiện phụ thuộc
        run_case("VF-F01-1a", mk_txn(.rs1_u(0), .rs1(5), .rs2_u(1), .rs2(3),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 0, 0);
        run_case("VF-F01-1b", mk_txn(.rs1_u(1), .rs1(3), .rs2_u(0), .rs2(5),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 0, 0);

        // 2: ex.reg_en = 0 thì không phụ thuộc EX
        run_case("VF-F01-2a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(0), .ex_mre(1)), 0, 0);
        run_case("VF-F01-2b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(0), .ex_mre(1)), 0, 0);

        // 3: mem.reg_en = 0 thì không phụ thuộc MEM
        run_case("VF-F01-3a", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(0), .mem_mre(1), .br(1)), 0, 0);
        run_case("VF-F01-3b", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5),
                 .mem_en(0), .mem_mre(1), .br(1)), 0, 0);

        // 4: ex.rd = x0 không tạo phụ thuộc
        run_case("VF-F01-4a", mk_txn(.rs1_u(1), .rs1(0), .rd_ex(0),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        run_case("VF-F01-4b", mk_txn(.rs2_u(1), .rs2(0), .rd_ex(0),
                 .ex_en(1), .ex_mre(1)), 0, 0);

        // 5: mem.rd = x0 không tạo phụ thuộc
        run_case("VF-F01-5a", mk_txn(.rs1_u(1), .rs1(0), .rd_mem(0),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        run_case("VF-F01-5b", mk_txn(.rs2_u(1), .rs2(0), .rd_mem(0),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);

        // 6-7: ex.rd khác rs1 / rs2
        run_case("VF-F01-6",  mk_txn(.rs1_u(1), .rs1(5), .rd_ex(7),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        run_case("VF-F01-7",  mk_txn(.rs2_u(1), .rs2(5), .rd_ex(7),
                 .ex_en(1), .ex_mre(1)), 0, 0);

        // 8-9: mem.rd khác rs1 / rs2
        run_case("VF-F01-8",  mk_txn(.rs1_u(1), .rs1(5), .rd_mem(7),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        run_case("VF-F01-9",  mk_txn(.rs2_u(1), .rs2(5), .rd_mem(7),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);

        // 10: phụ thuộc EX nhưng không phải load, không branch/jump -> forward, không stall
        run_case("VF-F01-10", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0)), 0, 0);

        // 11: phụ thuộc EX là load, jump = 0 hoặc 1 -> stall (alu2load), không flush
        run_case("VF-F01-11a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .jump(0)), 1, 0);
        run_case("VF-F01-11b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .jump(1)), 1, 0);

        // 12: phụ thuộc MEM là load, jump = 0, không branch -> không stall
        run_case("VF-F01-12a", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .rd_ex(9), .ex_en(1), .ex_mre(0)), 0, 0);
        run_case("VF-F01-12b", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .rd_ex(9), .ex_en(1), .ex_mre(1)), 0, 0);

        // 13: phụ thuộc MEM là load (mem_mre = 1), jump = 0 hoặc 1
        //     jump = 0 -> không stall; jump = 1 -> stall (br2load_mem), không flush
        run_case("VF-F01-13a", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .jump(0)), 0, 0);
        run_case("VF-F01-13b", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .jump(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F02: LOAD-USE (ALU phụ thuộc LOAD ở EX), take_jump = 0
    //////////////////////////////////////////
    task run_f02();
        run_case("VF-F02-1a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
        run_case("VF-F02-1b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F03: PHỤ THUỘC EX, take_jump = 1
    //////////////////////////////////////////
    task run_f03();
        // ALU ở EX, lệnh ở ID là jump
        run_case("VF-F03-1a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0), .jump(1)), 1, 0);   // br2alu_ex
        // ALU ở EX, branch taken, phụ thuộc rs2
        run_case("VF-F03-1b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0), .br(1), .brt(1)), 1, 0);   // br2alu_ex
        // LOAD ở EX, branch taken
        run_case("VF-F03-1c", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .br(1), .brt(1)), 1, 0);   // br2load_ex
    endtask

    //////////////////////////////////////////
    // VF-F04: PHỤ THUỘC EX là LOAD, take_jump = 1
    //////////////////////////////////////////
    task run_f04();
        run_case("VF-F04-1a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .jump(1)), 1, 0);
        run_case("VF-F04-1b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .br(1), .brt(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F05: PHỤ THUỘC MEM, take_jump = 1
    // Hiểu điều kiện "ex.mem_re = 1" như trong đề, MEM là load quyết định stall
    //////////////////////////////////////////
    task run_f05();
        // MEM là load -> br2load_mem -> stall. EX cũng là load nhưng không phụ thuộc
        run_case("VF-F05-1a", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .rd_ex(9), .ex_en(1), .ex_mre(1),
                 .jump(1)), 1, 0);
        // MEM không phải load -> không stall, chỉ flush vì take_jump
        run_case("VF-F05-1b", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(0), .rd_ex(9), .ex_en(1), .ex_mre(1),
                 .jump(1)), 0, 1);
        // Biến thể rs2 với branch taken
        run_case("VF-F05-1c", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .br(1), .brt(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F06: NHIỀU PHỤ THUỘC CÙNG LÚC
    //////////////////////////////////////////
    task run_f06();
        // rs1 = rs2 = rd_ex
        run_case("VF-F06-1a", mk_txn(.rs1_u(1), .rs1(5), .rs2_u(1), .rs2(5),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 1, 0);
        // rs1 = rs2 = rd_mem, branch
        run_case("VF-F06-1b", mk_txn(.rs1_u(1), .rs1(5), .rs2_u(1), .rs2(5),
                 .rd_mem(5), .mem_en(1), .mem_mre(1), .br(1)), 1, 0);
        // rs1 = rd_ex = rd_mem
        run_case("VF-F06-3a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1),
                 .ex_mre(1), .rd_mem(5), .mem_en(1), .mem_mre(1), .br(1)), 1, 0);
        // rs2 = rd_ex = rd_mem
        run_case("VF-F06-3b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5), .ex_en(1),
                 .ex_mre(1), .rd_mem(5), .mem_en(1), .mem_mre(1), .br(1)), 1, 0);
        // br2load_ex và br2load_mem cùng lúc
        run_case("VF-F06-5",  mk_txn(.rs1_u(1), .rs1(5), .rs2_u(1), .rs2(6),
                 .rd_ex(5), .ex_en(1), .ex_mre(1),
                 .rd_mem(6), .mem_en(1), .mem_mre(1), .br(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F07 (bổ sung): FORWARD WB và thứ tự ưu tiên
    //////////////////////////////////////////
    task run_f07();
        // Chỉ WB khớp
        run_case("VF-F07-1", mk_txn(.rs1_u(1), .rs1(5), .rd_wb(5), .wb_en(1)), 0, 0);

        // EX thắng MEM và WB
        run_case("VF-F07-2", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1), .ex_mre(0),
                 .rd_mem(5), .mem_en(1), .mem_mre(0), .rd_wb(5), .wb_en(1)), 0, 0);

        // MEM thắng WB, trên rs2
        run_case("VF-F07-3", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5), .mem_en(1),
                 .mem_mre(0), .rd_wb(5), .wb_en(1)), 0, 0);

        // rd = x0 không bao giờ được forward
        run_case("VF-F07-4", mk_txn(.rs1_u(1), .rs1(0), .rd_ex(0), .ex_en(1),
                 .rd_mem(0), .mem_en(1), .rd_wb(0), .wb_en(1)), 0, 0);
    endtask

    //////////////////////////////////////////
    // VF-F08 (bổ sung): FLUSH IF/ID cơ bản
    //////////////////////////////////////////
    task run_f08();
        run_case("VF-F08-1", mk_txn(.jump(1)), 0, 1);
        run_case("VF-F08-2", mk_txn(.br(1), .brt(1)), 0, 1);
        run_case("VF-F08-3", mk_txn(.br(1), .brt(0)), 0, 0);
        run_case("VF-F08-4", mk_txn(.br(0), .brt(1)), 0, 0);
        // jump kèm load-use: stall ưu tiên, không flush
        run_case("VF-F08-5", mk_txn(.jump(1), .rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // FINAL REPORT
    //////////////////////////////////////////
    task report();
        $display("");
        $display("============================================================");
        $display("                  HZ_FWD DIRECT TEST REPORT");
        $display("============================================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", pass, fail);

        if (fail == 0)
            $display("[FINAL] DIRECT TEST = PASS");
        else
            $display("[FINAL] DIRECT TEST = FAIL");

        $display("============================================================");
    endtask

    //////////////////////////////////////////
    // RUN
    //////////////////////////////////////////
    task run();
        pass = 0;
        fail = 0;

        run_f01();
        run_f02();
        run_f03();
        run_f04();
        run_f05();
        run_f06();
        run_f07();
        run_f08();

        report();

        if (fail != 0)
            $fatal(1, "[DIRECT] TEST FAILED: %0d failures", fail);
        else
            $display("[DIRECT] ALL TESTS PASSED");
    endtask

endclass