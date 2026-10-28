// import alu_pkg::*;
class alu_generator;

    mailbox #(alu_txn) gen2drv;
    int num_txn;
    event done;

    function new(
                mailbox #(alu_txn) gen2drv,
                int num_txn
    ); 
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task run();
        alu_txn txn;
        repeat(num_txn) begin 
            txn = new();
            if (txn.randomize() == 1 ) gen2drv.put(txn);
            else $fatal(1, "randomization failed");
        end
        -> done;
        $display("xong generator");
    endtask
endclass


