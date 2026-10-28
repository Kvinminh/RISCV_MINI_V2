class if_stage_mon;
    virtual if_stage_if.MON vif;
    mailbox #(if_satge_txn) mon2sb;
    mailbox #(if_satge_txn) mon2cov;
    int num_int;

    function new(
             virtual if_stage_if.MON vif,
            mailbox #(if_satge_txn) mon2sb,
            mailbox #(if_satge_txn) mon2cov,
            int num_int
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.num_int = num_int;
    endfunction

    task run();
        if_stage_txn txn;
        repaet(num_txn) begin
            @(posedge vif.clk) #1;
            txn.rst_n = vif.rst_n;
            txn.stall_pc = vif.stall_pc;
            txn.data_control_jump_id = vif.data_control_jump_id;
            txn.ins = vif.ins;
            txn.if_reg = vif.if_reg;

            mon2sb.put(txn);
            mon2cov.put(txn);
        end
    endtask
endclass