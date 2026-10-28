// import alu_pkg::*;
class alu_monitor;
    virtual alu_if.MON vif;
    mailbox #(alu_txn) mon2sb;
    mailbox #(alu_txn) mon2cov;

    int num_txn;
    event done;

    function new(
                virtual alu_if.MON vif,
                mailbox #(alu_txn) mon2sb,
                mailbox #(alu_txn) mon2cov,
                int num_txn
    ); 
        this.vif = vif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;  
        this.num_txn = num_txn; 
    endfunction

    task run();
        alu_txn txn;
        repeat(num_txn) begin
            @(posedge vif.clk); #1;
            txn = new();

            txn.alu_ctrl = vif.alu_ctrl;
            txn.A        = vif.A;
            txn.B        = vif.B;
            txn.alu      = vif.alu;

            mon2sb.put(txn);
            mon2cov.put(txn);
        end
        $display(" xong monitor");
    endtask
endclass