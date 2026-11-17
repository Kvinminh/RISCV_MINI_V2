class if_stage_mon;
    virtual if_stage_if.MON vif;
    mailbox #(if_stage_txn) mon2sb;
    mailbox #(if_stage_txn) mon2cov;
    int num_txn;

    function new(
            virtual if_stage_if.MON vif,
            mailbox #(if_stage_txn) mon2sb,
            mailbox #(if_stage_txn) mon2cov,
            int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.num_txn = num_txn;
    endfunction

    task run();
        if_stage_txn txn;
        repeat(num_txn) begin
            @(posedge vif.clk) #1;
            //$display("[MON] vif=%p vif.rst_n=%p", vif, vif.rst_n);
            txn = new();
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