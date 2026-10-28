class if_stage_gene;

    mailbox #(if_stage_txn) gen2drv;
    int num_txn;
    int num_case;
    event done;

    function new( mailbox #(if_stage_txn) gen2drv,int num_int);
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task run();
        if_stage_txn txn;
        repeat(num_txn) begin
            txn = new();
            if ( txn.randomize() == 1) gen2drv.put(txn);
            else $fatal (1, "random fail");
        end
        ->done;
    endtask

endclass