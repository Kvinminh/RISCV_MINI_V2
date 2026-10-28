class if_stage_sb;
    if_stage_ref ref_m;
    mailbox #(if_stage_txn) mon2sb;
    int num_txn;

    int pass;
    int fail;
    event done;

    function new(
        mailbox #(if_stage_txn) mon2sb,
        int num_txn
    );
        this.mon2sb  = mon2sb;
        this.num_txn = num_txn;
        this.ref_m   = new();
        this.pass    = 0;
        this.fail    = 0;
    endfunction

    task run();
        if_stage_txn txn;
        bit pc_cur_ok, pc_4_ok, ins_ok;

        repeat (num_txn) begin
            mon2sb.get(txn);

            // Ref model tính expected và cập nhật state nội bộ
            txn.expected_if_reg = ref_m.predict(txn);

            pc_cur_ok = (txn.if_reg.pc_cur == txn.expected_if_reg.pc_cur);
            pc_4_ok   = (txn.if_reg.pc_4   == txn.expected_if_reg.pc_4);
            ins_ok    = (txn.if_reg.ins    == txn.expected_if_reg.ins);

            if (pc_cur_ok && pc_4_ok && ins_ok) begin
                pass++;
            end
            else begin
                fail++;

                // Kiểm tra độc lập để báo đủ mọi field sai trong cùng transaction
                if (!pc_cur_ok)
                    $error("\n[SB][FAIL] PC_CUR  ACTUAL=%0h  EXPECTED=%0h\n  JAL=%0b JALR=%0b BR_EN=%0b BR_TAKEN=%0b JUMP_ADDR=%0h",
                           txn.if_reg.pc_cur, txn.expected_if_reg.pc_cur,
                           txn.data_control_jump_id.jal,
                           txn.data_control_jump_id.jalr,
                           txn.data_control_jump_id.br_en,
                           txn.data_control_jump_id.br_taken,
                           txn.data_control_jump_id.pc_jump);

                if (!pc_4_ok)
                    $error("\n[SB][FAIL] PC_4  ACTUAL=%0h  EXPECTED=%0h  (PC_CUR=%0h)",
                           txn.if_reg.pc_4, txn.expected_if_reg.pc_4,
                           txn.if_reg.pc_cur);

                if (!ins_ok)
                    $error("\n[SB][FAIL] INS  ACTUAL=%0h  EXPECTED=%0h",
                           txn.if_reg.ins, txn.expected_if_reg.ins);
            end
        end

        -> done;
    endtask

    function void report();
        $display(
            "\n[SB] IF_STAGE PASS=%0d FAIL=%0d RESULT=%s",
            pass,
            fail,
            (fail == 0) ? "PASS" : "FAIL"
        );
    endfunction
endclass