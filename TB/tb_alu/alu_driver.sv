// import alu_pkg::*;
class alu_driver;

    virtual alu_if.DRV vif;
    mailbox #(alu_txn) gen2drv;
    int num_txn;
    function new(
                virtual alu_if.DRV vif,
                mailbox #(alu_txn) gen2drv,
                int num_txn
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task reset();
        vif.alu_ctrl = ALU_ADD;
        vif.A = '0;
        vif.B = '0;
        repeat (3) @(negedge vif.clk);
    endtask

    task run();
        alu_txn txn;
        repeat(num_txn) begin
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.alu_ctrl = txn.alu_ctrl;
            vif.A        =txn.A;
            vif.B        =txn.B;
        end 
        $display("xong driver");
    endtask


endclass