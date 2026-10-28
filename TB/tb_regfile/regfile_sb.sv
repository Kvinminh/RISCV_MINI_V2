class regfile_sb;
    regfile_ref regfile_ref;
    mailbox #(regfile_txn) mon2sb;
    int num_txn;

    int pass;
    int fail;

    event done;

    function new(
        mailbox #(regfile_txn) mon2sb,
        int num_txn
    );
        this.mon2sb = mon2sb;
        this.num_txn = num_txn;
        this.pass = 0;
        this.fail = 0;
    endfunction

    task run();
        regfile_txn txn;
        regfile_ref = new();
        repeat (num_txn) begin
            mon2sb.get(txn);
            regfile_ref.predict(txn);

            // Check both read ports
            if ((txn.rs1_data == txn.expected_rs1_data) &&
                (txn.rs2_data == txn.expected_rs2_data)) begin
                pass++;
            end
            else begin
                fail++;

                $error("\n[SB][FAIL] REGFILE_READ\nRS1_ADDR = %0d RS1_DATA_ACTUAL = %08h RS1_DATA_EXPECTED = %08h\nRS2_ADDR = %0d RS2_DATA_ACTUAL = %08h RS2_DATA_EXPECTED = %08h\nREG_EN = %0d RD_ADDR = %0d RD_DATA = %08h\n rst_n = %0d ",
                    txn.rs1_addr, txn.rs1_data, txn.expected_rs1_data,
                    txn.rs2_addr, txn.rs2_data, txn.expected_rs2_data,
                    txn.wb.reg_en, txn.wb.rd_addr, txn.wb.rd_data,
                    txn.rst_n
                );
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