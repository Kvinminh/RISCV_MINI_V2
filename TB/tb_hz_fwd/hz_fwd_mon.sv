class hz_fwd_mon;
    virtual hz_fwd_if.MON  vif;
    mailbox #(hz_fwd_txn)  mon2sb;
    mailbox #(hz_fwd_txn)  mon2cov;
    int                    num_txn;

    function new(
        virtual hz_fwd_if.MON vif,
        mailbox #(hz_fwd_txn) mon2sb,
        mailbox #(hz_fwd_txn) mon2cov,
        int num_txn
    );
        this.vif     = vif;
        this.mon2sb  = mon2sb;
        this.mon2cov = mon2cov;
        this.num_txn = num_txn;
    endfunction

    task run();
        hz_fwd_txn txn;
        int        cnt = 0;

        while (cnt < num_txn) begin
            @(vif.mon_cb);

            // Bỏ qua mẫu khi đang reset, lúc này biến trung gian có thể là x
            if (!vif.mon_cb.rst_n) continue;

            txn = new();

            // input
            txn.rs1_addr     = vif.mon_cb.rs1_addr;
            txn.rs2_addr     = vif.mon_cb.rs2_addr;
            txn.rs1_used     = vif.mon_cb.rs1_used;
            txn.rs2_used     = vif.mon_cb.rs2_used;
            txn.jump_en      = vif.mon_cb.jump_en;
            txn.br_en        = vif.mon_cb.br_en;
            txn.br_taken     = vif.mon_cb.br_taken;
            txn.for_info_ex  = vif.mon_cb.for_info_ex;
            txn.for_info_mem = vif.mon_cb.for_info_mem;
            txn.for_info_wb  = vif.mon_cb.for_info_wb;

            // biến trung gian nội bộ của DUT
            txn.dep = '{
                rs1_ex:  vif.mon_cb.rs1_ex,
                rs2_ex:  vif.mon_cb.rs2_ex,
                rs1_mem: vif.mon_cb.rs1_mem,
                rs2_mem: vif.mon_cb.rs2_mem
            };

            txn.stall_cond = '{
                br2alu_ex:   vif.mon_cb.br2alu_ex,
                br2load_ex:  vif.mon_cb.br2load_ex,
                br2load_mem: vif.mon_cb.br2load_mem,
                alu2load:    vif.mon_cb.alu2load
            };

            // output của DUT
            txn.for_id_a     = vif.mon_cb.for_id_a;
            txn.for_id_b     = vif.mon_cb.for_id_b;
            txn.for_ex_a     = vif.mon_cb.for_ex_a;
            txn.for_ex_b     = vif.mon_cb.for_ex_b;
            txn.hzd_ctrl     = vif.mon_cb.hzd_ctrl;

            mon2sb.put(txn);
            mon2cov.put(txn.clone());

            cnt++;
        end
    endtask
endclass