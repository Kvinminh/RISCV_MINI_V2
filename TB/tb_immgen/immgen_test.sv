class immgen_test;

    virtual immgen_if vif;
    immgen_env env;
    int direct_pass = 0;
    int direct_fail = 0;
    int num_txn;

    function new(virtual immgen_if vif, int num_txn);
        this.vif     = vif;
        this.num_txn = num_txn;
        env = new(vif, num_txn);
    endfunction

    ////////////////////////////////////////// ENCODER ///////////////////////////
    // Ghép imm thành lệnh đúng format RISC-V. Encoder viết độc lập với cách
    // tách bit của DUT/ref nên direct test không tự kiểm chính mình.
    // rs1/rs2/rd/funct3 cố định, chỉ imm thay đổi.

    function automatic logic [31:0] enc_i(input logic [31:0] imm);
        return {imm[11:0], 5'd1, 3'b000, 5'd5, 7'b0010011};
    endfunction

    function automatic logic [31:0] enc_s(input logic [31:0] imm);
        return {imm[11:5], 5'd2, 5'd1, 3'b010, imm[4:0], 7'b0100011};
    endfunction

    function automatic logic [31:0] enc_b(input logic [31:0] imm);
        return {imm[12], imm[10:5], 5'd2, 5'd1, 3'b000, imm[4:1], imm[11], 7'b1100011};
    endfunction

    function automatic logic [31:0] enc_u(input logic [31:0] imm);
        return {imm[31:12], 5'd5, 7'b0110111};
    endfunction

    function automatic logic [31:0] enc_j(input logic [31:0] imm);
        return {imm[20], imm[10:1], imm[11], imm[19:12], 5'd5, 7'b1101111};
    endfunction

    function automatic logic [31:0] encode(immgen_sel_e sel, logic [31:0] imm);
        case (sel)
            IMMGEN_I: return enc_i(imm);
            IMMGEN_S: return enc_s(imm);
            IMMGEN_B: return enc_b(imm);
            IMMGEN_U: return enc_u(imm);
            IMMGEN_J: return enc_j(imm);
            default:  return '0;
        endcase
    endfunction

    ////////////////////////////////////////// DIRECT HELPERS ///////////////////////////

    task automatic direct_check(string name, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            direct_fail++;
            $error("[DIRECT][FAIL] %s actual=%08h expected=%08h",
                   name, actual, expected);
        end
        else begin
            direct_pass++;
            $display("[DIRECT][PASS] %s value=%08h", name, actual);
        end
    endtask

    task automatic direct_sample_cov(logic [31:0] ins_val,
                                     immgen_sel_e sel,
                                     logic [31:0] imm_val);
        immgen_txn t = new();
        t.ins     = ins_val;
        t.imm_sel = sel;
        t.imm_out = imm_val;
        env.coverage.sample_txn(t);
    endtask

    task automatic direct_apply(string name,
                                immgen_sel_e sel,
                                logic [31:0] ins_val,
                                logic [31:0] expected);
        vif.ins     = ins_val;
        vif.imm_sel = sel;
        #1;
        direct_check(name, vif.imm_out, expected);
        direct_sample_cov(ins_val, sel, vif.imm_out);
    endtask

    // Encode imm theo format sel, rồi kiểm tra output = expected
    task automatic direct_imm(string name,
                              immgen_sel_e sel,
                              logic [31:0] imm,
                              logic [31:0] expected);
        direct_apply(name, sel, encode(sel, imm), expected);
    endtask

    ////////////////////////////////////////// DIRECT TESTS ///////////////////////////

    // I: imm[11:0], sign-extend từ bit 11
    task direct_i_type();
        direct_imm("VR-I-01", IMMGEN_I, 32'h0000_0000, 32'h0000_0000); // zero
        direct_imm("VR-I-02", IMMGEN_I, 32'h0000_0001, 32'h0000_0001); // +1
        direct_imm("VR-I-03", IMMGEN_I, 32'hFFFF_FFFF, 32'hFFFF_FFFF); // -1
        direct_imm("VR-I-04", IMMGEN_I, 32'h0000_07FF, 32'h0000_07FF); // max dương
        direct_imm("VR-I-05", IMMGEN_I, 32'hFFFF_F800, 32'hFFFF_F800); // min âm

        for (int k = 0; k <= 10; k++)
            direct_imm($sformatf("VR-I-W%0d", k), IMMGEN_I,
                       32'h1 << k, 32'h1 << k);
    endtask

    // S: imm[11:5] từ ins[31:25], imm[4:0] từ ins[11:7]
    task direct_s_type();
        direct_imm("VR-S-01", IMMGEN_S, 32'h0000_0000, 32'h0000_0000);
        direct_imm("VR-S-02", IMMGEN_S, 32'h0000_0001, 32'h0000_0001);
        direct_imm("VR-S-03", IMMGEN_S, 32'hFFFF_FFFF, 32'hFFFF_FFFF);
        direct_imm("VR-S-04", IMMGEN_S, 32'h0000_07FF, 32'h0000_07FF);
        direct_imm("VR-S-05", IMMGEN_S, 32'hFFFF_F800, 32'hFFFF_F800);

        for (int k = 0; k <= 10; k++)
            direct_imm($sformatf("VR-S-W%0d", k), IMMGEN_S,
                       32'h1 << k, 32'h1 << k);
    endtask

    // B: imm[12|10:5|4:1|11], bit 0 = 0
    task direct_b_type();
        direct_imm("VR-B-01", IMMGEN_B, 32'h0000_0000, 32'h0000_0000); // zero
        direct_imm("VR-B-02", IMMGEN_B, 32'h0000_0002, 32'h0000_0002); // +2
        direct_imm("VR-B-03", IMMGEN_B, 32'hFFFF_FFFE, 32'hFFFF_FFFE); // -2
        direct_imm("VR-B-04", IMMGEN_B, 32'h0000_0FFE, 32'h0000_0FFE); // max dương
        direct_imm("VR-B-05", IMMGEN_B, 32'hFFFF_F000, 32'hFFFF_F000); // min âm

        for (int k = 1; k <= 11; k++)
            direct_imm($sformatf("VR-B-W%0d", k), IMMGEN_B,
                       32'h1 << k, 32'h1 << k);
    endtask

    // U: imm[31:12], 12 bit thấp = 0
    task direct_u_type();
        direct_imm("VR-U-01", IMMGEN_U, 32'h0000_0000, 32'h0000_0000);
        direct_imm("VR-U-02", IMMGEN_U, 32'h7FFF_F000, 32'h7FFF_F000); // max dương
        direct_imm("VR-U-03", IMMGEN_U, 32'h8000_0000, 32'h8000_0000); // min âm
        direct_imm("VR-U-04", IMMGEN_U, 32'hFFFF_F000, 32'hFFFF_F000); // -4096
        direct_imm("VR-U-05", IMMGEN_U, 32'h1234_5000, 32'h1234_5000);

        for (int k = 12; k <= 31; k++)
            direct_imm($sformatf("VR-U-W%0d", k), IMMGEN_U,
                       32'h1 << k, 32'h1 << k);
    endtask

    // J: imm[20|10:1|11|19:12], bit 0 = 0
    task direct_j_type();
        direct_imm("VR-J-01", IMMGEN_J, 32'h0000_0000, 32'h0000_0000);
        direct_imm("VR-J-02", IMMGEN_J, 32'h0000_0002, 32'h0000_0002); // +2
        direct_imm("VR-J-03", IMMGEN_J, 32'hFFFF_FFFE, 32'hFFFF_FFFE); // -2
        direct_imm("VR-J-04", IMMGEN_J, 32'h000F_FFFE, 32'h000F_FFFE); // max dương
        direct_imm("VR-J-05", IMMGEN_J, 32'hFFF0_0000, 32'hFFF0_0000); // min âm

        for (int k = 1; k <= 19; k++)
            direct_imm($sformatf("VR-J-W%0d", k), IMMGEN_J,
                       32'h1 << k, 32'h1 << k);
    endtask

    // Sel ngoài enum: imm_out phải = 0 (khớp nhánh default của RTL và ref).
    // Không sample coverage vì sel không hợp lệ sẽ kích illegal bin của cg_immgen_fmt.
    task direct_default();
        vif.ins     = 32'hFFFF_FFFF;
        vif.imm_sel = immgen_sel_e'('1);
        #1;
        direct_check("VR-DEF-01", vif.imm_out, 32'h0000_0000);
    endtask

    task run_direct_tests();
        direct_pass = 0;
        direct_fail = 0;

        direct_i_type();
        direct_s_type();
        direct_b_type();
        direct_u_type();
        direct_j_type();
        direct_default();

        $display("========================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);
        $display("========================================");

        if (direct_fail != 0)
            $fatal(1, "[DIRECT] TEST FAILED: %0d failures", direct_fail);
        else
            $display("[DIRECT] ALL TESTS PASSED");
    endtask

    ////////////////////////////////////////// RANDOM TEST ///////////////////////////

    task run_random_tests();
        $display("");
        $display("============================================================");
        $display("                   OOP RANDOM TEST");
        $display("============================================================");

        env.run();
        #1;
        $display("[OOP] Random generation completed.");
    endtask

    ////////////////////////////////////////// REPORT ///////////////////////////

    task report();
        $display("");
        $display("============================================================");
        $display("                 IMMGEN FINAL REPORT");
        $display("============================================================");
        $display("[DIRECT] PASS=%0d FAIL=%0d", direct_pass, direct_fail);
        env.coverage.report();
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