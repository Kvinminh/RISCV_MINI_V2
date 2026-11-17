class if_stage_tests;
    virtual if_stage_if vif;
    if_stage_env env;

    int direct_pass = 0;
    int direct_fail = 0;
    int num_txn;

    // Golden model: PC kỳ vọng sau mỗi cạnh lên
    logic [XLEN-1:0] model_pc = '0;

    function new(virtual if_stage_if vif, int num_txn);
        this.vif     = vif;
        this.num_txn = num_txn;
        env          = new(vif, num_txn);
    endfunction

    //////////////////////////////////////////
    // TXN HELPERS
    //////////////////////////////////////////

    // Tạo txn có hướng cụ thể cho direct test
    function automatic if_stage_txn mk_txn(
        logic            rst,
        logic            stall,
        logic            jal,
        logic            jalr,
        logic            br_en,
        logic            br_taken,
        logic [XLEN-1:0] pc_jump,
        logic [XLEN-1:0] ins_v = '0
    );
        if_stage_txn t = new();
        t.rst_n                         = rst;
        t.stall_pc                      = stall;
        t.data_control_jump_id.jal       = jal;
        t.data_control_jump_id.jalr      = jalr;
        t.data_control_jump_id.br_en     = br_en;
        t.data_control_jump_id.br_taken  = br_taken;
        t.data_control_jump_id.pc_jump   = pc_jump;
        t.ins                           = ins_v;
        t.kind = jal ? 1 : (jalr ? 2 : (br_en ? 3 : 0));
        return t;
    endfunction

    // pc_sel nội bộ: jal | jalr | (branch taken)
    function automatic logic pc_sel_of(if_stage_txn t);
        return t.data_control_jump_id.jal
             | t.data_control_jump_id.jalr
             | (t.data_control_jump_id.br_en & t.data_control_jump_id.br_taken);
    endfunction

    // Golden model: PC kế tiếp theo txn và PC hiện tại
    function automatic logic [XLEN-1:0] model_next(if_stage_txn t);
        if (!t.rst_n)      return '0;
        if (t.stall_pc)    return model_pc;
        if (pc_sel_of(t))  return t.data_control_jump_id.pc_jump;
        return model_pc + 32'd4;
    endfunction

    //////////////////////////////////////////
    // DRIVE / CHECK
    //////////////////////////////////////////

    // Đưa txn vào interface tại negedge, chờ tổ hợp ổn định
    task automatic drive_txn(if_stage_txn t);
        @(negedge vif.clk);
        vif.rst_n                = t.rst_n;
        vif.stall_pc             = t.stall_pc;
        vif.data_control_jump_id = t.data_control_jump_id;
        vif.ins                  = t.ins;
        #1;
    endtask

    task direct_check(
        string       name,
        logic [31:0] actual,
        logic [31:0] expected
    );
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%08h expected=%08h",
                   name, actual, expected);
        end
        else begin
            direct_pass++;
        end
    endtask

    // Drive một txn, qua một cạnh lên, cập nhật model rồi kiểm tra
    task automatic direct_step(if_stage_txn t, string name);
        logic [XLEN-1:0] nxt;

        drive_txn(t);
        nxt = model_next(t);      // tính trước cạnh lên
        @(posedge vif.clk);
        #1;
        model_pc = nxt;

        direct_check($sformatf("%s_PC", name),
                     vif.if_reg.pc_cur, model_pc);
        direct_check($sformatf("%s_PC4", name),
                     vif.if_reg.pc_4, vif.if_reg.pc_cur + 32'd4);

        // Giả định: ins được latch vào if_reg khi không reset và không stall
        if (t.rst_n && !t.stall_pc)
            direct_check($sformatf("%s_INS", name),
                         vif.if_reg.ins, t.ins);
    endtask

    //////////////////////////////////////////
    // DIRECT HELPERS
    //////////////////////////////////////////

    task direct_idle();
        drive_txn(mk_txn(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, '0));
    endtask

    // Giữ reset vài chu kỳ, PC phải bằng 0 sau mỗi cạnh
    task direct_reset_check(string name, int cycles = 2);
        for (int i = 0; i < cycles; i++)
            direct_step(mk_txn(1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, '0),
                        $sformatf("%s_%0d", name, i));
    endtask

    //////////////////////////////////////////
    // VR-F01: PC NEXT SELECTION
    //////////////////////////////////////////

    // VR-F01-1, VR-F01-2: pc_sel = 0 => pc_next = pc_4 => pc tăng 4
    // pc_next không có trong interface nên được kiểm tra qua pc_cur sau cạnh lên
    task direct_pc4_sequential();
        for (int i = 0; i < 16; i++)
            direct_step(mk_txn(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, '0),
                        $sformatf("VR-F01-1_SEQ_%0d", i));
    endtask

    // VR-F01-3: jal / jalr / branch taken => pc_next = pc_jump
    task direct_pc_next_jump();
        logic [XLEN-1:0] jump_addr;
        int k;

        for (int i = 0; i < 16; i++) begin
            jump_addr = $urandom & 32'hFFFF_FFFC;
            k         = i % 3;
            direct_step(mk_txn(1'b1, 1'b0,
                               k == 0, k == 1,
                               k == 2, k == 2,
                               jump_addr),
                        $sformatf("VR-F01-3_JUMP_K%0d_%0d", k, i));
        end
    endtask

    // VR-F01-4: branch not-taken => pc tiếp tục pc_4
    task direct_branch_not_taken();
        logic [XLEN-1:0] jump_addr;

        for (int i = 0; i < 16; i++) begin
            jump_addr = $urandom & 32'hFFFF_FFFC;
            direct_step(mk_txn(1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, jump_addr),
                        $sformatf("VR-F01-4_BR_NT_%0d", i));
        end
    endtask

    //////////////////////////////////////////
    // VR-F02: PC STATE TESTS
    //////////////////////////////////////////

    // VR-F02-1: sau reset thì pc = 0
    task direct_reset_pc_zero();
        direct_step(mk_txn(1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_1000),
                    "VR-F02-1_JUMP_AWAY");
        direct_reset_check("VR-F02-1_RESET_PC", 2);
    endtask

    // VR-F02-1b: sau mỗi clk, pc_cur = pc_next với txn ngẫu nhiên, không stall
    task direct_pc_update_each_clk();
        logic [XLEN-1:0] jump_addr;
        int kind;
        logic br_t;

        for (int i = 0; i < 32; i++) begin
            kind      = $urandom % 4;
            br_t        = 1'($urandom & 1);
            jump_addr = $urandom & 32'hFFFF_FFFC;
            direct_step(mk_txn(1'b1, 1'b0,
                               kind == 1, kind == 2,
                               kind == 3, kind == 3 & br_t,
                               jump_addr),
                        $sformatf("VR-F02-1b_UPD_%0d", i));
        end
    endtask

    // VR-F02-2: stall_pc = 1 => pc giữ nguyên, kể cả khi có lệnh nhảy
    task direct_stall_hold();
        logic [XLEN-1:0] jump_addr;
        int kind;

        // Xuất phát từ PC khác 0
        direct_step(mk_txn(1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 32'h0000_2000),
                    "VR-F02-2_SETUP");

        for (int i = 0; i < 16; i++) begin
            kind      = $urandom % 4;
            jump_addr = $urandom & 32'hFFFF_FFFC;
            direct_step(mk_txn(1'b1, 1'b1,
                               kind == 1, kind == 2,
                               kind == 3, kind == 3,
                               jump_addr),
                        $sformatf("VR-F02-2_HOLD_%0d", i));
        end

        // Nhả stall: pc phải đi tiếp theo pc_next
        direct_step(mk_txn(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, '0),
                    "VR-F02-2_RELEASE");
    endtask

    //////////////////////////////////////////
    // RUN DIRECT TESTS
    //////////////////////////////////////////

    task run_direct_tests();
        direct_pass = 0;
        direct_fail = 0;
        model_pc    = '0;

        direct_idle();
        direct_reset_check("VR-F02-1_INIT_RESET", 2);

        // VR-F01
        direct_pc4_sequential();
        direct_pc_next_jump();
        direct_branch_not_taken();

        // VR-F02
        direct_reset_pc_zero();
        direct_pc_update_each_clk();
        direct_stall_hold();

        $display("========================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);
        $display("========================================");

        if (direct_fail != 0)
            $fatal(1, "[DIRECT] TEST FAILED: %0d failures", direct_fail);
        else
            $display("[DIRECT] ALL TESTS PASSED");
    endtask

    //////////////////////////////////////////
    // RANDOM OOP TEST
    //////////////////////////////////////////

    task run_random_tests();
        $display("");
        $display("============================================================");
        $display("                  IF STAGE OOP RANDOM TEST");
        $display("============================================================");

        direct_idle();

        env.run();

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
        $display("                  IF STAGE FINAL REPORT");
        $display("============================================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);

        // env.coverage.report();  // bật khi đã nối if_stage_cov vào env

        if ((direct_fail == 0) && (env.scoreboard.fail == 0))
            $display("[FINAL] FUNCTIONAL CHECKING = PASS");
        else
            $display("[FINAL] FUNCTIONAL CHECKING = FAIL");

        $display("============================================================");
    endtask

    task run();
        run_direct_tests();
        run_random_tests();
        report();
    endtask

endclass