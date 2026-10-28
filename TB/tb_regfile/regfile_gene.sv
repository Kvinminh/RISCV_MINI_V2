
class regfile_gene;
    mailbox #(regfile_txn) gen2drv;
    int num_txn;
    event done;

    function new(
            mailbox #(regfile_txn) gen2drv,
            int num_txn
    );
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task run();
        regfile_txn txn;
        repeat(num_txn) begin
            txn = new();
            if ( txn.randomize() == 1) gen2drv.put(txn);
            else $fatal (1, "random fail");
        end
        ->done;
    endtask

endclass