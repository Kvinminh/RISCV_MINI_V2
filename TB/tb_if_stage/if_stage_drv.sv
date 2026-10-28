class if_stage_drv;
    virtual if_stage_if.DRV vif;
    mailbox #(if_stage_txn) gen2drv;
    int num_txn;

    function new(
        virtual if_stage_if.DRV vif,
        mailbox #(if_stage_txn) gen2drv,
        int num_txn
    );
        this.vif = vif;
        this.gen2drv;
        this.num_txn= num_txn;
    endfunction

    task reset();
        
        vif.rst_n = '0;
        vif.stall_pc = '0;
        vif.data_control_jump_id = '0;
        vif.ins = '0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run(); 
        if_stage_txn txn;
        repeat(num_txn) begin
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.rst_n = txn.rst_n;
            vif.stall_pc = txn.stall_pc;
            vif.data_control_jump_id = txn.data_control_jump_id;
            vif.ins = txn.ins;
        end
    endtask
endclass