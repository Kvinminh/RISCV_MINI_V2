class immgen_sb;
    immgen_ref immgen_ref;
    mailbox #(immgen_txn) mon2sb;
    int num_txn;

    int pass;
    int fail;
    event done;

    function new(
                // immgen_ref immgen_ref,
                mailbox #(immgen_txn) mon2sb,
                int num_txn
    );
        this.mon2sb = mon2sb;
        this.num_txn = num_txn;
    endfunction

    task run();
        immgen_txn txn ; 
        immgen_ref = new();
        repeat(num_txn) begin
            mon2sb.get(txn);
            immgen_ref.predict(txn);

            if ( txn.imm_out == txn.expected_imm_out)begin
                pass++;
            end
            else begin
                fail++;
                $error ("\n[SB][FAIL] IMMGEN\n IMM_OUT_ACTUAL = %0d  IMM_OUT_EXPECT  = %0d\nins = %0d  imm_sel = %0d ",
                        txn.imm_out, txn.expected_imm_out,
                        txn.ins, 
                        txn.imm_sel);
            end
        end
        ->done;
    endtask

    function void report();
        $display(
            "\n[SB] PASS=%0d FAIL=%0d RESULT=%s",
            pass,
            fail,
            (fail == 0) ? "PASS" : "FAIL"
        );
    endfunction
endclass