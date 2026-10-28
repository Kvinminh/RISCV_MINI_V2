class immgen_cov;

    mailbox #(immgen_txn) mon2cov;
    int  sample_cnt = 0;
    real goal = 90.0;

    // Đổi opcode thành index format: 0=I, 1=S, 2=B, 3=U, 4=J, 5=không hợp lệ
    static function automatic int opc2fmt(logic [6:0] opc);
        case (opc)
            7'b0010011, 7'b0000011, 7'b1100111: return 0; // OP-IMM, LOAD, JALR
            7'b0100011:                         return 1; // STORE
            7'b1100011:                         return 2; // BRANCH
            7'b0110111, 7'b0010111:             return 3; // LUI, AUIPC
            7'b1101111:                         return 4; // JAL
            default:                            return 5;
        endcase
    endfunction

    // ------------------------------------------------------------
    // Covergroup 1: format (imm_sel có khớp với opcode không)
    // ------------------------------------------------------------
    covergroup cg_immgen_fmt with function sample(immgen_txn txn, int fmt_opc, bit fmt_match);
        option.per_instance = 1;

        cp_imm_sel: coverpoint txn.imm_sel {
            bins i_type = {IMMGEN_I};
            bins s_type = {IMMGEN_S};
            bins b_type = {IMMGEN_B};
            bins u_type = {IMMGEN_U};
            bins j_type = {IMMGEN_J};
        }

        cp_opc_fmt: coverpoint fmt_opc {
            bins i_ops = {0};
            bins s_ops = {1};
            bins b_ops = {2};
            bins u_ops = {3};
            bins j_ops = {4};
            illegal_bins bad_opc = {5};   // opcode không thuộc 5 format
        }

        // Mỗi lần sample, imm_sel phải khớp với opcode.
        // Mismatch là illegal, nên tb sinh sai sẽ báo lỗi ngay.
        cp_match: coverpoint fmt_match {
            bins match    = {1};
            illegal_bins mismatch = {0};
        }
    endgroup

    // ------------------------------------------------------------
    // Covergroup 2: giá trị (dấu và imm_out)
    // ------------------------------------------------------------
    covergroup cg_immgen_val with function sample(immgen_txn txn);
        option.per_instance = 1;

        cp_imm_sel: coverpoint txn.imm_sel {
            bins i_type = {IMMGEN_I};
            bins s_type = {IMMGEN_S};
            bins b_type = {IMMGEN_B};
            bins u_type = {IMMGEN_U};
            bins j_type = {IMMGEN_J};
        }

        cp_sign: coverpoint txn.ins[31] {
            bins neg = {1'b1};
            bins pos = {1'b0};
        }

        cp_imm_out: coverpoint txn.imm_out {
            bins zero      = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins pos_small = {[32'd1 : 32'd255]};
            bins pos_large = {[32'd256 : 32'h7FFF_FFFF]};
            bins neg       = {[32'h8000_0000 : 32'hFFFF_FFFE]};
        }

        // Mỗi format phải có cả dấu âm lẫn dương để kiểm tra sign-extend
        cx_sel_sign: cross cp_imm_sel, cp_sign;
    endgroup

    function new(mailbox #(immgen_txn) mon2cov);
        this.mon2cov = mon2cov;
        cg_immgen_fmt = new();
        cg_immgen_val = new();
    endfunction

    function void sample_txn(immgen_txn txn);
        int  fmt_opc;
        bit  fmt_match;

        fmt_opc   = opc2fmt(txn.ins[6:0]);
        fmt_match = (fmt_opc == int'(txn.imm_sel));

        cg_immgen_fmt.sample(txn, fmt_opc, fmt_match);
        cg_immgen_val.sample(txn);
        sample_cnt++;
    endfunction

    task run();
        immgen_txn txn;
        forever begin
            mon2cov.get(txn);
            sample_txn(txn);
        end
    endtask

    function void print_item(string id, string name, real cov);
        $display("  %-8s %-18s : %6.2f%%", id, name, cov);
    endfunction

    function void report();
        real   cov_fmt, cov_val, total;
        real   cov_arr[2];
        string names[2];
        string status;
        int    n_pass;

        cov_fmt = cg_immgen_fmt.get_inst_coverage();
        cov_val = cg_immgen_val.get_inst_coverage();

        cov_arr = '{cov_fmt, cov_val};
        names   = '{"cg_immgen_fmt", "cg_immgen_val"};
        total   = (cov_fmt + cov_val) / 2.0;
        n_pass  = 0;

        $display("==================================================");
        $display("           IMMGEN FUNCTIONAL COVERAGE REPORT");
        $display("==================================================");
        $display("  Transactions sampled : %0d", sample_cnt);
        $display("--------------------------------------------------");
        $display("  %-8s %-18s %8s", "ID", "COVERGROUP", "COV(%)");
        $display("--------------------------------------------------");

        for (int i = 0; i < 2; i++) begin
            if (cov_arr[i] >= goal) begin
                status = "PASS";
                n_pass++;
            end
            else
                status = "FAIL";
            print_item($sformatf("IG-%02d", i+1), names[i], cov_arr[i]);
            $display("           status: %s", status);
        end

        $display("--------------------------------------------------");
        $display("  Covergroups passed   : %0d / 2", n_pass);
        $display("  TOTAL (average)      : %6.2f%% (goal %0.1f%%)", total, goal);
        $display("  RESULT               : %s", (total >= goal) ? "PASS" : "FAIL");
        $display("==================================================");
    endfunction

endclass