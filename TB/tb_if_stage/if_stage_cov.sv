class if_stage_cov;

    mailbox #(if_stage_txn) mon2cov;
    int  sample_cnt = 0;
    real goal = 90.0;

    // ------------------------------------------------------------
    // Covergroup 1: pc_4
    // ------------------------------------------------------------
    covergroup cg_pc_4 with function sample(if_stage_txn txn);
        option.per_instance = 1;

        c_pc_4: coverpoint txn.if_reg.pc_4 {
            bins zero      = {0};
            bins one       = {1};
            bins small_pos = {[2:255]};
            bins mid_pos   = {[256:32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins mid_neg   = {[32'h8000_0001:32'hFFFF_FEFF]};
            bins small_neg = {[32'hFFFF_FF00:32'hFFFF_FFFE]};
            bins all_ones  = {32'hFFFF_FFFF};
        }
    endgroup

    // ------------------------------------------------------------
    // Covergroup 2: data jump (br/jal/jalr + pc_jump)
    // ------------------------------------------------------------
    covergroup cg_data_jump with function sample(if_stage_txn txn);
        option.per_instance = 1;

        cp_br_taken: coverpoint txn.data_control_jump_id.br_taken {
            bins zero = {0};
            bins one  = {1};
        }
        cp_br_en: coverpoint txn.data_control_jump_id.br_en {
            bins zero = {0};
            bins one  = {1};
        }
        cp_jal: coverpoint txn.data_control_jump_id.jal {
            bins zero = {0};
            bins one  = {1};
        }
        cp_jalr: coverpoint txn.data_control_jump_id.jalr {
            bins zero = {0};
            bins one  = {1};
        }
        cp_pc_jump: coverpoint txn.data_control_jump_id.pc_jump {
            bins zero      = {0};
            bins one       = {1};
            bins small_pos = {[2:255]};
            bins mid_pos   = {[256:32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins mid_neg   = {[32'h8000_0001:32'hFFFF_FEFF]};
            bins small_neg = {[32'hFFFF_FF00:32'hFFFF_FFFE]};
            bins all_ones  = {32'hFFFF_FFFF};
        }

        // Cross các cờ điều khiển nhảy (bỏ cp_pc_jump vì 9 bin x 16 tổ hợp dễ gây bin không thể đạt)
        cx_jump_ctrl: cross cp_br_taken, cp_br_en, cp_jal, cp_jalr;
    endgroup

    // ------------------------------------------------------------
    // Covergroup 3: pc_next theo rst_n
    // ------------------------------------------------------------
    covergroup cg_pc with function sample(if_stage_txn txn);
        option.per_instance = 1;

        cp_rst_n: coverpoint txn.rst_n {
            bins zero = {0};
            bins one  = {1};
        }
        cp_pc_next: coverpoint txn.pc_next {
            bins zero      = {0};
            bins one       = {1};
            bins small_pos = {[2:255]};
            bins mid_pos   = {[256:32'h7FFF_FFFE]};
            bins max_pos   = {32'h7FFF_FFFF};
            bins min_neg   = {32'h8000_0000};
            bins mid_neg   = {[32'h8000_0001:32'hFFFF_FEFF]};
            bins small_neg = {[32'hFFFF_FF00:32'hFFFF_FFFE]};
            bins all_ones  = {32'hFFFF_FFFF};
        }

        cx_pc: cross cp_rst_n, cp_pc_next;
    endgroup

    function new(mailbox #(if_stage_txn) mon2cov);
        this.mon2cov = mon2cov;
        cg_pc_4      = new();
        cg_data_jump = new();
        cg_pc        = new();
    endfunction

    function void sample_txn(if_stage_txn txn);
        cg_pc_4.sample(txn);
        cg_data_jump.sample(txn);
        cg_pc.sample(txn);
        sample_cnt++;
    endfunction

    task run();
        if_stage_txn txn;
        forever begin
            mon2cov.get(txn);
            sample_txn(txn);
        end
    endtask

    function void print_item(string id, string name, real cov);
        $display("  %-8s %-18s : %6.2f%%", id, name, cov);
    endfunction

    function void report();
        real   cov_arr[3];
        string names[3];
        string status;
        real   total;
        int    n_pass;

        cov_arr[0] = cg_pc_4.get_inst_coverage();
        cov_arr[1] = cg_data_jump.get_inst_coverage();
        cov_arr[2] = cg_pc.get_inst_coverage();

        names = '{"cg_pc_4", "cg_data_jump", "cg_pc"};
        total = (cov_arr[0] + cov_arr[1] + cov_arr[2]) / 3.0;
        n_pass = 0;

        $display("==================================================");
        $display("         IF STAGE FUNCTIONAL COVERAGE REPORT");
        $display("==================================================");
        $display("  Transactions sampled : %0d", sample_cnt);
        $display("--------------------------------------------------");
        $display("  %-8s %-18s %8s", "ID", "COVERGROUP", "COV(%)");
        $display("--------------------------------------------------");

        for (int i = 0; i < 3; i++) begin
            if (cov_arr[i] >= goal) begin
                status = "PASS";
                n_pass++;
            end
            else
                status = "FAIL";
            print_item($sformatf("IF-%02d", i+1), names[i], cov_arr[i]);
            $display("           status: %s", status);
        end

        $display("--------------------------------------------------");
        $display("  Covergroups passed   : %0d / 3", n_pass);
        $display("  TOTAL (average)      : %6.2f%% (goal %0.1f%%)", total, goal);
        $display("  RESULT               : %s", (total >= goal) ? "PASS" : "FAIL");
        $display("==================================================");
    endfunction

endclass