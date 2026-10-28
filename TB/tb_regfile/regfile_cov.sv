class regfile_cov;
    mailbox #(regfile_txn) mon2cov;
    int sample_cnt = 0;
    real goal = 90.0;

    covergroup cg_regfile_write with function sample(regfile_txn txn);
        option.per_instance = 1;

         cp_rst_n: coverpoint txn.rst_n{
            bins rst_n_1 = {1};
            bins rst_n_0 = {0};
        }
        cp_ren_en: coverpoint txn.wb.reg_en {
            bins en_1 = {1};
            bins en_0 = {0};
        }

        cp_rd_addr: coverpoint txn.wb.rd_addr {
            bins x0 = {5'd0};
            bins x1_x31 = {[5'd1: 5'd31]};
        }

        cp_rd_data: coverpoint txn.wb.rd_data{
            bins zero      = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins pos_small = {[32'd1 : 32'd255]};
            bins pos_large = {[32'd256 : 32'h7FFF_FFFE]};
            bins neg       = {[32'h8000_0000 : 32'hFFFF_FFFE]};
        }

        cx_regfile_write: cross cp_ren_en, cp_rd_addr,cp_rd_data, cp_rst_n;
    endgroup

    covergroup cg_regfile_read with function sample ( regfile_txn txn);
        option.per_instance = 1;

        cp_rs1_addr: coverpoint txn.rs1_addr {
            bins x0 = {5'd0};
            bins x1_x31 = {[5'd1: 5'd31]};
        }

        cp_rs2_addr: coverpoint txn.rs2_addr {
            bins x0 = {5'd0};
            bins x1_x31 = {[5'd1: 5'd31]};
        }

        cp_rst_n: coverpoint txn.rst_n{
            bins rst_n_1 = {1};
            bins rst_n_0 = {0};
        }

        cx_regfile_read: cross cp_rs1_addr,cp_rs2_addr,cp_rst_n;

    endgroup 
    

    function new(mailbox #(regfile_txn ) mon2cov);
        this.mon2cov =mon2cov;
        cg_regfile_write = new();
        cg_regfile_read = new();
    endfunction


    function void sample_all(regfile_txn txn);
        cg_regfile_write.sample(txn);
        cg_regfile_read.sample(txn);
    endfunction

    function void sample_direct(regfile_txn txn);
        sample_all(txn);
    endfunction


    task run();
        regfile_txn txn;

        forever begin
            mon2cov.get(txn);
            sample_all(txn);
        end
    endtask

     function void print_item(
        string id,
        string name,
        real cov
    );
        $display("  %-10s %-24s : %6.2f%%",
                 id, name, cov);
    endfunction

    function void report();
  real cov_write, cov_read, total;
  real cov_arr[2];
  string names[2];
  int n_pass;

  cov_write = cg_regfile_write.get_inst_coverage();
  cov_read  = cg_regfile_read.get_inst_coverage();

  cov_arr = '{cov_write, cov_read};
  names   = '{"cg_regfile_write", "cg_regfile_read"};

  total  = (cov_write + cov_read) / 2.0;
  n_pass = 0;

  $display("==================================================");
  $display("          REGFILE FUNCTIONAL COVERAGE REPORT");
  $display("==================================================");
  $display("  Transactions sampled : %0d", sample_cnt);
  $display("--------------------------------------------------");
  $display("  %-8s %-18s %8s   %-6s", "ID", "COVERGROUP", "COV(%)", "STATUS");
  $display("--------------------------------------------------");

  for (int i = 0; i < 2; i++) begin
    string status;
    status = (cov_arr[i] >= goal) ? "PASS" : "FAIL";
    if (cov_arr[i] >= goal) n_pass++;
    print_item($sformatf("RF-%02d", i+1), names[i], cov_arr[i]);
  end

  $display("--------------------------------------------------");
  $display("  Covergroups passed   : %0d / 2", n_pass);
  $display("  TOTAL (average)      : %6.2f%% (goal %0.1f%%)", total, goal);
  $display("  RESULT               : %s", (total >= goal) ? "PASS" : "FAIL");
  $display("==================================================");
endfunction



endclass