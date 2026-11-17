import isa_pkg::*;
import core_pkg::*;

class ha_pipe_tests;
    virtual ha_pipe_if vif;
    ha_pipe_env        env;

    int pass = 0;
    int fail = 0;
    int num_txn;

    function new(virtual ha_pipe_if vif, int num_txn);
        this.vif     = vif;
        this.num_txn = num_txn;
        env          = new(vif, num_txn);
    endfunction

    //////////////////////////////////////////
    // TXN HELPERS
    //////////////////////////////////////////

    // Pipeline payload: f_* = 1 thì toàn bộ bit của thanh ghi = 1, = 0 thì = 0
    function ha_pipe_txn set_pipe(
        ha_pipe_txn      t,
        logic [XLEN-1:0] pc,
        bit f_if, bit f_id, bit f_ex, bit f_mem
    );
        t.pc_next = pc;
        t.if_reg  = {$bits(if_id_reg_t){f_if}};
        t.id_reg  = {$bits(id_ex_reg_t){f_id}};
        t.ex_reg  = {$bits(ex_mem_reg_t){f_ex}};
        t.mem_reg = {$bits(mem_wb_reg_t){f_mem}};
        return t;
    endfunction

    // Txn mặc định: không hazard, không jump, không reset, pipeline = 0
    function ha_pipe_txn mk_txn(
        logic rs1_u = 0, int rs1 = 0,
        logic rs2_u = 0, int rs2 = 0,
        logic jump  = 0,
        logic br    = 0,
        logic brt   = 0,
        int   rd_ex = 0, logic ex_en  = 0, logic ex_mre  = 0,
        int   rd_mem = 0, logic mem_en = 0, logic mem_mre = 0
    );
        ha_pipe_txn t = new();
        t.rst_n                = 1'b1;
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
        return set_pipe(t, '0, 0, 0, 0, 0);
    endfunction

    //////////////////////////////////////////
    // DRIVE / CHECK
    //////////////////////////////////////////

    // Đưa txn vào interface tại negedge, chờ tổ hợp ổn định
    task drive(ha_pipe_txn t);
        @(negedge vif.clk);
        vif.rst_n        = t.rst_n;
        vif.rs1_addr     = t.rs1_addr;
        vif.rs2_addr     = t.rs2_addr;
        vif.rs1_used     = t.rs1_used;
        vif.rs2_used     = t.rs2_used;
        vif.jump_en      = t.jump_en;
        vif.br_en        = t.br_en;
        vif.br_taken     = t.br_taken;
        vif.for_info_ex  = t.for_info_ex;
        vif.for_info_mem = t.for_info_mem;
        vif.pc_next      = t.pc_next;
        vif.if_reg       = t.if_reg;
        vif.id_reg       = t.id_reg;
        vif.ex_reg       = t.ex_reg;
        vif.mem_reg      = t.mem_reg;
        #1;   // hazard là tổ hợp, chờ ổn định
    endtask

    // S = stall (stall_pc = stall_if_id = flush_id_ex), F = flush_if_id
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

    task check_regs(
        string           name,
        logic [XLEN-1:0] pc_e,
        if_id_reg_t      id_e,
        id_ex_reg_t      ex_e,
        ex_mem_reg_t     mem_e,
        mem_wb_reg_t     wb_e
    );
        if (vif.pc_cur !== pc_e) begin
            fail++;
            $error("[REG][FAIL] %s PC_CUR actual=%08h expected=%08h",
                   name, vif.pc_cur, pc_e);
        end
        else pass++;

        if (vif.reg_id !== id_e) begin
            fail++;
            $error("[REG][FAIL] %s REG_ID actual=%h expected=%h",
                   name, vif.reg_id, id_e);
        end
        else pass++;

        if (vif.reg_ex !== ex_e) begin
            fail++;
            $error("[REG][FAIL] %s REG_EX actual=%h expected=%h",
                   name, vif.reg_ex, ex_e);
        end
        else pass++;

        if (vif.reg_mem !== mem_e) begin
            fail++;
            $error("[REG][FAIL] %s REG_MEM actual=%h expected=%h",
                   name, vif.reg_mem, mem_e);
        end
        else pass++;

        if (vif.reg_wb !== wb_e) begin
            fail++;
            $error("[REG][FAIL] %s REG_WB actual=%h expected=%h",
                   name, vif.reg_wb, wb_e);
        end
        else pass++;
    endtask

    // Chỉ kiểm tra hazard (tổ hợp, không cần cạnh clock)
    task hzd_case(string name, ha_pipe_txn t, bit s, bit f);
        drive(t);
        check_hzd(name, s, f);
    endtask

    // Drive -> check hazard -> cạnh lên -> check thanh ghi
    task run_step(
        string           name,
        ha_pipe_txn      t,
        bit              s,
        bit              f,
        logic [XLEN-1:0] pc_e,
        if_id_reg_t      id_e,
        id_ex_reg_t      ex_e,
        ex_mem_reg_t     mem_e,
        mem_wb_reg_t     wb_e
    );
        drive(t);
        check_hzd(name, s, f);
        @(posedge vif.clk);
        #1;
        check_regs(name, pc_e, id_e, ex_e, mem_e, wb_e);
    endtask

    // Reset: không check hazard (xem AP-F01-5), chỉ check thanh ghi sau cạnh lên
    task reset_step(string name, ha_pipe_txn t);
        drive(t);
        @(posedge vif.clk);
        #1;
        check_regs(name, '0, '0, '0, '0, '0);
    endtask

    //////////////////////////////////////////
    // VF-F01: KHÔNG STALL / KHÔNG FLUSH
    //////////////////////////////////////////
    task run_f01();
        hzd_case("VF-F01-1a", mk_txn(.rs1_u(0), .rs1(5), .rs2_u(1), .rs2(3),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-1b", mk_txn(.rs1_u(1), .rs1(3), .rs2_u(0), .rs2(5),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-2a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(0), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-2b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(0), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-3a", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(0), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-3b", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5),
                 .mem_en(0), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-4a", mk_txn(.rs1_u(1), .rs1(0), .rd_ex(0),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-4b", mk_txn(.rs2_u(1), .rs2(0), .rd_ex(0),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-5a", mk_txn(.rs1_u(1), .rs1(0), .rd_mem(0),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-5b", mk_txn(.rs2_u(1), .rs2(0), .rd_mem(0),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-6",  mk_txn(.rs1_u(1), .rs1(5), .rd_ex(7),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-7",  mk_txn(.rs2_u(1), .rs2(5), .rd_ex(7),
                 .ex_en(1), .ex_mre(1)), 0, 0);
        hzd_case("VF-F01-8",  mk_txn(.rs1_u(1), .rs1(5), .rd_mem(7),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-9",  mk_txn(.rs2_u(1), .rs2(5), .rd_mem(7),
                 .mem_en(1), .mem_mre(1), .br(1)), 0, 0);
        hzd_case("VF-F01-10", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0)), 0, 0);
    endtask

    //////////////////////////////////////////
    // VF-F02: LOAD-USE (ALU phụ thuộc LOAD ở EX)
    //////////////////////////////////////////
    task run_f02();
        hzd_case("VF-F02-1a", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
        hzd_case("VF-F02-1b", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F03: BRANCH PHỤ THUỘC EX
    //////////////////////////////////////////
    task run_f03();
        hzd_case("VF-F03-1", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0), .br(1)), 1, 0);   // br2alu_ex
        hzd_case("VF-F03-2", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(0), .br(1)), 1, 0);   // br2alu_ex
        hzd_case("VF-F03-3", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .br(1)), 1, 0);   // br2load_ex
        hzd_case("VF-F03-4", mk_txn(.rs2_u(1), .rs2(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1), .br(1)), 1, 0);   // br2load_ex
    endtask

    //////////////////////////////////////////
    // VF-F04: BRANCH PHỤ THUỘC MEM
    //////////////////////////////////////////
    task run_f04();
        hzd_case("VF-F04-1", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .br(1)), 1, 0);  // br2load_mem
        hzd_case("VF-F04-2", mk_txn(.rs2_u(1), .rs2(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .br(1)), 1, 0);  // br2load_mem
        hzd_case("VF-F04-3", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(1), .br(0)), 0, 0);  // negative
        hzd_case("VF-F04-4", mk_txn(.rs1_u(1), .rs1(5), .rd_mem(5),
                 .mem_en(1), .mem_mre(0), .br(1)), 0, 0);  // negative
    endtask

    //////////////////////////////////////////
    // VF-F05: JUMP / FLUSH
    //////////////////////////////////////////
    task run_f05();
        hzd_case("VF-F05-1", mk_txn(.jump(1)), 0, 1);
        hzd_case("VF-F05-2", mk_txn(.br(1), .brt(1)), 0, 1);
        hzd_case("VF-F05-3", mk_txn(.br(1), .brt(0)), 0, 0);
        // Directed test bỏ qua c_jump_en_br nên tổ hợp này được kiểm tra
        hzd_case("VF-F05-4", mk_txn(.br(0), .brt(1)), 0, 0);
        // Stall được ưu tiên: có load-use thì không flush IF/ID
        hzd_case("VF-F05-5", mk_txn(.jump(1), .rs1_u(1), .rs1(5), .rd_ex(5),
                 .ex_en(1), .ex_mre(1)), 1, 0);
        hzd_case("VF-F05-6", mk_txn(.br(1), .brt(1), .rs1_u(1), .rs1(5),
                 .rd_ex(5), .ex_en(1), .ex_mre(0)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F06: NHIỀU ĐIỀU KIỆN CÙNG LÚC
    //////////////////////////////////////////
    task run_f06();
        hzd_case("VF-F06-1", mk_txn(.rs1_u(1), .rs1(5), .rs2_u(1), .rs2(5),
                 .rd_ex(5), .ex_en(1), .ex_mre(1)), 1, 0);
        hzd_case("VF-F06-2", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1),
                 .ex_mre(0), .rd_mem(5), .mem_en(1), .mem_mre(1), .br(1)), 1, 0);
        hzd_case("VF-F06-3", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1),
                 .ex_mre(1), .rs2_u(1), .rs2(6), .rd_mem(6), .mem_en(1),
                 .mem_mre(1), .br(1)), 1, 0);
    endtask

    //////////////////////////////////////////
    // VF-F07: DẢI ĐỊA CHỈ ĐẦY ĐỦ
    //////////////////////////////////////////
    task run_f07();
        hzd_case("VF-F07-1", mk_txn(.rs1_u(1), .rs1(31), .rd_ex(31),
                 .ex_en(1), .ex_mre(1)), 1, 0);
        // rs1 = 5 và rd = 21 có 4 bit thấp giống nhau, phải không stall
        hzd_case("VF-F07-2", mk_txn(.rs1_u(1), .rs1(5), .rd_ex(21),
                 .ex_en(1), .ex_mre(1)), 0, 0);
    endtask

    //////////////////////////////////////////
    // VF-R: THANH GHI PIPELINE
    //////////////////////////////////////////
    task run_reg_tests();
        // Setup: nạp state = 1 ở mọi thanh ghi, PC = 0x1000
        run_step("VF-R00-SETUP", set_pipe(mk_txn(), 32'h1000, 1, 1, 1, 1),
                 0, 0, 32'h1000, '1, '1, '1, '1);

        // VF-R01-1: stall (alu2load), payload khác state đã nạp
        // PC, IF/ID giữ nguyên; ID/EX về 0; EX/MEM, MEM/WB nhận input mới
        run_step("VF-R01-1",
                 set_pipe(mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1), .ex_mre(1)),
                          32'h3000, 0, 1, 0, 0),
                 1, 0, 32'h1000, '1, '0, '0, '0);

        // VF-R01-2: flush IF/ID (jump), không stall
        // IF/ID về 0; PC nhận pc_next; các thanh ghi khác nhận input
        run_step("VF-R01-2",
                 set_pipe(mk_txn(.jump(1)), 32'h2000, 1, 1, 1, 1),
                 0, 1, 32'h2000, '0, '1, '1, '1);

        // VF-R01-3: không stall, không flush: mọi thanh ghi nhận input
        run_step("VF-R01-3",
                 set_pipe(mk_txn(), 32'h3000, 1, 1, 1, 1),
                 0, 0, 32'h3000, '1, '1, '1, '1);
    endtask

    //////////////////////////////////////////
    // VF-RST: RESET
    //////////////////////////////////////////
    task run_reset_tests();
        ha_pipe_txn t;

        // Setup state khác 0 và đang stall
        run_step("VF-RST-SETUP", set_pipe(mk_txn(), 32'h1000, 1, 1, 1, 1),
                 0, 0, 32'h1000, '1, '1, '1, '1);

        // VF-RST-1: rst_n = 0 khi đang stall -> mọi thanh ghi về 0 (async)
        t = set_pipe(mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1), .ex_mre(1)),
                     32'h5000, 1, 1, 1, 1);
        t.rst_n = 1'b0;
        reset_step("VF-RST-1", t);

        // VF-RST-2: nhả reset khi đang stall
        // PC và IF/ID giữ 0 (giá trị sau reset), ID/EX flush về 0,
        // EX/MEM và MEM/WB nhận input
        t = set_pipe(mk_txn(.rs1_u(1), .rs1(5), .rd_ex(5), .ex_en(1), .ex_mre(1)),
                     32'h5000, 1, 1, 1, 1);
        run_step("VF-RST-2", t, 1, 0, '0, '0, '0, '1, '1);
    endtask

    //////////////////////////////////////////
    // RANDOM OOP TEST
    //////////////////////////////////////////
    task run_random_tests();
        $display("");
        $display("============================================================");
        $display("                  HA_PIPE OOP RANDOM TEST");
        $display("============================================================");

        

        repeat (5) @(posedge vif.clk);
        #1;

        $display("[OOP] Random generation completed.");
    endtask

    //////////////////////////////////////////
    // FINAL REPORT
    //////////////////////////////////////////
    task report();
        $display("");
        $display("============================================================");
        $display("                  HA_PIPE FINAL REPORT");
        $display("============================================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", pass, fail);

        // env.scoreboard.report();  // bật khi đã nối scoreboard vào env
        // env.coverage.report();    // bật khi đã nối coverage vào env

        if ((fail == 0) && (env.scoreboard.fail == 0))
            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");

        $display("============================================================");
    endtask

    //////////////////////////////////////////
    // RUN
    //////////////////////////////////////////
    task run();
        ha_pipe_txn t;

        pass = 0;
        fail = 0;

        // Reset ban đầu
        t = mk_txn();
        t.rst_n = 1'b0;
        drive(t);
        @(posedge vif.clk);
        #1;

        run_f01();
        run_f02();
        run_f03();
        run_f04();
        run_f05();
        run_f06();
        run_f07();
        run_reg_tests();
        run_reset_tests();

        $display("========================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", pass, fail);
        $display("========================================");

        if (fail != 0)
            $fatal(1, "[DIRECT] TEST FAILED: %0d failures", fail);
        else
            $display("[DIRECT] ALL TESTS PASSED");

        //run_random_tests();
        env.run();
        report();
    endtask

endclass