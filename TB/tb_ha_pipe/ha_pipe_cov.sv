class ha_pipe_cov;

    mailbox #(ha_pipe_txn) mon2cov;
    ha_pipe_ref            ref_m;

    int  sample_cnt = 0;
    int  skip_cnt   = 0;        // txn có rst_n = 0, không đưa vào coverage hazard
    real goal = 90.0;

    // Đếm số lần mỗi special case xuất hiện
    int hit_br2alu_ex   = 0;
    int hit_br2load_ex  = 0;
    int hit_br2load_mem = 0;
    int hit_alu2load    = 0;

    // ------------------------------------------------------------
    // CG1: địa chỉ thanh ghi, cross rs với rd ở EX/MEM
    // ------------------------------------------------------------
    covergroup cg_addr with function sample(ha_pipe_txn txn);
        option.per_instance = 1;

        cp_rs1_addr: coverpoint txn.rs1_addr {
            bins r[] = {[0:4]};
        }
        cp_rs2_addr: coverpoint txn.rs2_addr {
            bins r[] = {[0:4]};
        }
        cp_rd_ex: coverpoint txn.for_info_ex.rd_addr {
            bins r[] = {[0:4]};
        }
        cp_rd_mem: coverpoint txn.for_info_mem.rd_addr {
            bins r[] = {[0:4]};
        }

        cx_rs1_rdex:  cross cp_rs1_addr, cp_rd_ex;
        cx_rs2_rdex:  cross cp_rs2_addr, cp_rd_ex;
        cx_rs1_rdmem: cross cp_rs1_addr, cp_rd_mem;
        cx_rs2_rdmem: cross cp_rs2_addr, cp_rd_mem;
    endgroup

    // ------------------------------------------------------------
    // CG2: các cờ điều khiển và valid của EX/MEM
    // ------------------------------------------------------------
    covergroup cg_ctrl with function sample(ha_pipe_txn txn);
        option.per_instance = 1;

        cp_rs1_used: coverpoint txn.rs1_used { bins no = {0}; bins yes = {1}; }
        cp_rs2_used: coverpoint txn.rs2_used { bins no = {0}; bins yes = {1}; }
        cp_ex_en:    coverpoint txn.for_info_ex.reg_en  { bins no = {0}; bins yes = {1}; }
        cp_mem_en:   coverpoint txn.for_info_mem.reg_en { bins no = {0}; bins yes = {1}; }
        cp_ex_mre:   coverpoint txn.for_info_ex.mem_re  { bins no = {0}; bins yes = {1}; }
        cp_mem_mre:  coverpoint txn.for_info_mem.mem_re { bins no = {0}; bins yes = {1}; }
        cp_br_en:    coverpoint txn.br_en    { bins no = {0}; bins yes = {1}; }
        cp_jump_en:  coverpoint txn.jump_en  { bins no = {0}; bins yes = {1}; }
        cp_br_taken: coverpoint txn.br_taken { bins no = {0}; bins yes = {1}; }

        // 4 cờ dùng trong điều kiện dependency
        cx_used_en: cross cp_rs1_used, cp_rs2_used, cp_ex_en, cp_mem_en;
    endgroup

    // ------------------------------------------------------------
    // CG3: toàn bộ tổ hợp dependency (rs1/rs2 với EX/MEM)
    // ------------------------------------------------------------
    covergroup cg_dep with function sample(ha_pipe_txn txn, ha_pipe_ref::dep_t d);
        option.per_instance = 1;

        cp_dep:     coverpoint d;                    // 16 bin tự động
        cp_br_en:   coverpoint txn.br_en;
        cp_mre_ex:  coverpoint txn.for_info_ex.mem_re;
        cp_mre_mem: coverpoint txn.for_info_mem.mem_re;

        cx_dep_ctrl: cross cp_dep, cp_br_en, cp_mre_ex, cp_mre_mem;
    endgroup

    // ------------------------------------------------------------
    // CG4: 4 special case, mã hóa {br2alu_ex, br2load_ex, br2load_mem, alu2load}
    // ------------------------------------------------------------
    covergroup cg_case with function sample(logic [3:0] v);
        option.per_instance = 1;

        cp_case: coverpoint v {
            bins idle          = {4'b0000};
            bins br2alu_ex     = {4'b1000};
            bins br2load_ex    = {4'b0100};
            bins br2load_mem   = {4'b0010};
            bins alu2load      = {4'b0001};
            bins br2alu_mem    = {4'b1010};   // br2alu_ex + br2load_mem
            bins br2loadex_mem = {4'b0110};   // br2load_ex + br2load_mem
            // 9 tổ hợp còn lại không thể xảy ra theo logic ref
            illegal_bins impossible = default;
        }
    endgroup

    // ------------------------------------------------------------
    // CG5: stall/flush của DUT đối chiếu với ref
    // Vector = {hzd_ctrl[3:0], need_stall, take_jump}
    // ------------------------------------------------------------
    covergroup cg_hzd with function sample(logic [5:0] v);
        option.per_instance = 1;

        cp_hzd: coverpoint v {
            bins idle         = {6'b000000};   // không hazard, không jump
            bins flush_if     = {6'b001001};   // không hazard, có jump
            bins stall_nojump = {6'b110110};   // hazard, không jump
            bins stall_jump   = {6'b110111};   // hazard, có jump (vẫn stall)
            // DUT xuất tổ hợp không khớp với ref sẽ rơi vào đây
            illegal_bins bad = default;
        }
    endgroup

    function new(mailbox #(ha_pipe_txn) mon2cov);
        this.mon2cov = mon2cov;
        ref_m        = new();
        cg_addr      = new();
        cg_ctrl      = new();
        cg_dep       = new();
        cg_case      = new();
        cg_hzd       = new();
    endfunction

    function void sample_txn(ha_pipe_txn txn, ha_pipe_ref::dep_t d, ha_pipe_ref::case_t c);
        logic [3:0] vc;
        logic       need;
        logic       take;         

        vc   = c;
        need = (vc != 4'b0);
        take = txn.jump_en || (txn.br_taken && txn.br_en);

        cg_addr.sample(txn);
        cg_ctrl.sample(txn);
        cg_dep.sample(txn, d);
        cg_case.sample(vc);
        cg_hzd.sample({txn.hzd_ctrl, need, take});
        sample_cnt++;

        if (c.br2alu_ex)   hit_br2alu_ex++;
        if (c.br2load_ex)  hit_br2load_ex++;
        if (c.br2load_mem) hit_br2load_mem++;
        if (c.alu2load)    hit_alu2load++;
    endfunction

    task run();
        ha_pipe_txn         txn;
        ha_pipe_ref::dep_t  d;
        ha_pipe_ref::case_t c;

        forever begin
            mon2cov.get(txn);
            if (!txn.rst_n) begin
                skip_cnt++;
                continue;
            end
            d = ref_m.dau_hieu_stall(txn);
            c = ref_m.case_stall(txn, d);
            sample_txn(txn, d, c);
        end
    endtask

    function string hit_str(int n);
        return (n > 0) ? "HIT" : "NOT HIT";
    endfunction

    function void report();
        real   cov_arr[5];
        string names[5];
        string status;
        real   total;
        int    n_pass;
        int    n_special_hit;

        cov_arr[0] = cg_addr.get_inst_coverage();
        cov_arr[1] = cg_ctrl.get_inst_coverage();
        cov_arr[2] = cg_dep.get_inst_coverage();
        cov_arr[3] = cg_case.get_inst_coverage();
        cov_arr[4] = cg_hzd.get_inst_coverage();

        names = '{"cg_addr", "cg_ctrl", "cg_dep", "cg_case", "cg_hzd"};

        total = 0.0;
        for (int i = 0; i < 5; i++) total += cov_arr[i];
        total = total / 5.0;

        n_pass = 0;

        $display("==================================================");
        $display("         HA_PIPE FUNCTIONAL COVERAGE REPORT");
        $display("==================================================");
        $display("  Transactions sampled : %0d  (skip rst_n=0: %0d)", sample_cnt, skip_cnt);
        $display("--------------------------------------------------");
        $display("  %-8s %-18s %8s", "ID", "COVERGROUP", "COV(%)");
        $display("--------------------------------------------------");

        for (int i = 0; i < 5; i++) begin
            if (cov_arr[i] >= goal) begin
                status = "PASS";
                n_pass++;
            end
            else
                status = "FAIL";
            $display("  %-8s %-18s : %6.2f%%", $sformatf("HZ-%02d", i+1), names[i], cov_arr[i]);
            $display("           status: %s", status);
        end

        $display("--------------------------------------------------");
        $display("  SPECIAL CASE       HITS   STATUS");
        $display("  br2alu_ex    %8d   %s", hit_br2alu_ex,   hit_str(hit_br2alu_ex));
        $display("  br2load_ex   %8d   %s", hit_br2load_ex,  hit_str(hit_br2load_ex));
        $display("  br2load_mem  %8d   %s", hit_br2load_mem, hit_str(hit_br2load_mem));
        $display("  alu2load     %8d   %s", hit_alu2load,    hit_str(hit_alu2load));

       n_special_hit = (hit_br2alu_ex   > 0 ? 1 : 0)
              + (hit_br2load_ex  > 0 ? 1 : 0)
              + (hit_br2load_mem > 0 ? 1 : 0)
              + (hit_alu2load    > 0 ? 1 : 0);

        $display("--------------------------------------------------");
        $display("  Covergroups passed   : %0d / 5", n_pass);
        $display("  Special cases hit    : %0d / 4", n_special_hit);
        $display("  TOTAL (average)      : %6.2f%% (goal %0.1f%%)", total, goal);
        $display("  RESULT               : %s",
                 (total >= goal && n_special_hit == 4) ? "PASS" : "FAIL");
        $display("==================================================");
    endfunction

endclass