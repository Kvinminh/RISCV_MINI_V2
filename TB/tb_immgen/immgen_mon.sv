
class immgen_mon;
    virtual immgen_if.MON vif;
    mailbox  #(immgen_txn) mon2sb;
    mailbox  #(immgen_txn) mon2cov;
    int num_txn;

    function new(
            virtual immgen_if.MON vif,
            mailbox  #(immgen_txn) mon2sb,
            mailbox  #(immgen_txn) mon2cov,
            int num_txn
    );
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.num_txn = num_txn;
    endfunction

    task run();
        immgen_txn txn;
        repeat(num_txn)begin
            @(posedge vif.clk) #1;
            txn = new();
            txn.ins = vif.ins;
            txn.imm_sel = vif.imm_sel;
            txn.imm_out = vif.imm_out;

            mon2sb.put(txn);
            mon2cov.put(txn);
        end
    endtask
endclass