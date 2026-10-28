

class immgen_drv;
    virtual immgen_if.DRV vif;
    mailbox #(immgen_txn) gen2drv;
    int num_txn;

    function new(
                virtual immgen_if.DRV vif,
                mailbox #(immgen_txn) gen2drv,
                int num_txn
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction


    task reset();
        vif.ins = '0;
        vif.imm_sel  = immgen_sel_e'(0);
        repeat(3) @(negedge vif.clk);
    endtask


    task run();
        immgen_txn txn;
        repeat(num_txn) begin 
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.ins = txn.ins;
            vif.imm_sel = txn.imm_sel;
        end
    endtask
endclass