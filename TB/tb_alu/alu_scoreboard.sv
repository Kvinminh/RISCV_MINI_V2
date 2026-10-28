// import alu_pkg::*;

class alu_scoreboard;
    alu_ref_model alu_ref_model;
    mailbox #(alu_txn) mon2sb;
    int num_txn;

    int pass;
    int fail;
    
    event done;

    function new(
                mailbox #(alu_txn) mon2sb,
                int num_txn
    );
        this.mon2sb = mon2sb;
        this.num_txn = num_txn;
    endfunction

    task run();
    alu_txn txn;
    alu_ref_model = new();
    repeat(num_txn) begin
        mon2sb.get(txn);
        alu_ref_model.predict(txn);
        if (txn.alu == txn.expected_alu) pass++;
        else begin
            fail++;
            $error("[SB][FAIL] ALU_RESUT\n ACTUAL = %08h  EXPECTED = %08h\n ALU_CTRL = %08h A = %08h B = %08h ",
                    txn.alu,
                    txn.expected_alu,
                    txn.alu_ctrl,
                    txn.A,
                    txn.B,
                    );
        end
    end
    ->done;
    // $display("xong scoreboard");
    endtask

    function void report();
        $display("\n[SB] PASS=%0d FAIL=%0d RESULT=%s", pass, fail, (fail == 0) ? "PASS" : "FAIL");
    endfunction
endclass   