class immgen_gene;

    mailbox #(immgen_txn) gen2drv;
    int num_txn;
    int n = num_txn/5;
    event done;
    
    function new(mailbox #(immgen_txn) gen2drv, int num_txn);
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction


       // 1. I-type: OP-IMM, LOAD, JALR
    task gen_i_type(int n);
        immgen_txn t;
        int        ok;
        repeat (n) begin
            t  = new();
            ok = t.randomize() with {
                imm_sel == IMMGEN_I;
                ins[6:0] inside {7'b0010011, 7'b0000011, 7'b1100111};
            };
            if (ok == 0) $error("[GEN] randomize I-type failed");
            gen2drv.put(t);
        end
    endtask

    // 2. S-type: STORE
    task gen_s_type(int n);
        immgen_txn t;
        int        ok;
        repeat (n) begin
            t  = new();
            ok = t.randomize() with {
                imm_sel == IMMGEN_S;
                ins[6:0] == 7'b0100011;
            };
            if (ok == 0) $error("[GEN] randomize S-type failed");
            gen2drv.put(t);
        end
    endtask

    // 3. B-type: BRANCH
    task gen_b_type(int n);
        immgen_txn t;
        int        ok;
        repeat (n) begin
            t  = new();
            ok = t.randomize() with {
                imm_sel == IMMGEN_B;
                ins[6:0] == 7'b1100011;
            };
            if (ok == 0) $error("[GEN] randomize B-type failed");
            gen2drv.put(t);
        end
    endtask

    // 4. U-type: LUI, AUIPC
    task gen_u_type(int n);
        immgen_txn t;
        int        ok;
        repeat (n) begin
            t  = new();
            ok = t.randomize() with {
                imm_sel == IMMGEN_U;
                ins[6:0] inside {7'b0110111, 7'b0010111};
            };
            if (ok == 0) $error("[GEN] randomize U-type failed");
            gen2drv.put(t);
        end
    endtask

    // 5. J-type: JAL
    task gen_j_type(int n);
        immgen_txn t;
        int        ok;
        repeat (n) begin
            t  = new();
            ok = t.randomize() with {
                imm_sel == IMMGEN_J;
                ins[6:0] == 7'b1101111;
            };
            if (ok == 0) $error("[GEN] randomize J-type failed");
            gen2drv.put(t);
        end
    endtask

    task run();
        gen_i_type(n);
        gen_s_type(n);
        gen_b_type(n);
        gen_u_type(n);
        gen_j_type(n);
        -> done;
    endtask

endclass