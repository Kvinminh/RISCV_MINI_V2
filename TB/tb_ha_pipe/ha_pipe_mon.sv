class ha_pipe_mon;
    virtual ha_pipe_if.MON vif;
    mailbox #(ha_pipe_txn) mon2sb;
    mailbox #(ha_pipe_txn) mon2cov;
    int num_txn;

    function new(
        virtual ha_pipe_if.MON vif,
        mailbox #(ha_pipe_txn) mon2sb,
        mailbox #(ha_pipe_txn) mon2cov,
        int num_txn
    );
        this.vif      = vif;
        this.mon2sb   = mon2sb;
        this.mon2cov  = mon2cov;
        this.num_txn  = num_txn;
    endfunction

    task run();
        ha_pipe_txn txn;
        repeat(num_txn) begin
            @(posedge vif.clk) #1;
            txn = new();

            // input
            txn.rst_n        = vif.rst_n;
            txn.rs1_addr     = vif.rs1_addr;
            txn.rs2_addr     = vif.rs2_addr;
            txn.rs1_used     = vif.rs1_used;
            txn.rs2_used     = vif.rs2_used;
            txn.jump_en      = vif.jump_en;
            txn.br_en        = vif.br_en;
            txn.br_taken     = vif.br_taken;
            txn.for_info_ex  = vif.for_info_ex;
            txn.for_info_mem = vif.for_info_mem;
            txn.pc_next      = vif.pc_next;
            txn.if_reg       = vif.if_reg;
            txn.id_reg       = vif.id_reg;
            txn.ex_reg       = vif.ex_reg;
            txn.mem_reg      = vif.mem_reg;
            

            // output quan sát từ DUT
            txn.pc_cur       = vif.pc_cur;
            txn.reg_id       = vif.reg_id;
            txn.reg_ex       = vif.reg_ex;
            txn.reg_mem      = vif.reg_mem;
            txn.reg_wb       = vif.reg_wb;
            txn.hzd_ctrl = vif.hzd_ctrl;

            mon2sb.put(txn);
            mon2cov.put(txn.clone());
        end
    endtask
endclass