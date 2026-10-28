class regfile_mon; 
    virtual regfile_if.MON vif;
    mailbox #(regfile_txn) mon2cov;
    mailbox #(regfile_txn) mon2sb;

    int num_txn;
    event done;

    function new(
        virtual regfile_if.MON vif,
        mailbox #(regfile_txn) mon2cov,
        mailbox #(regfile_txn) mon2sb,
        int num_txn
    );
        this.vif = vif;
        this.mon2cov = mon2cov;
        this.mon2sb = mon2sb;
        this.num_txn = num_txn;
    endfunction 


    task run();
        regfile_txn txn;
        repeat(num_txn) begin 
            @(posedge vif.clk) #1;
            txn = new();

            txn.rst_n = vif.rst_n;
            txn.rs1_addr = vif.rs1_addr;
            txn.rs2_addr = vif.rs2_addr;
            txn.wb = vif.wb;
            txn.rs1_data = vif.rs1_data;
            txn.rs2_data = vif.rs2_data;

            mon2sb.put(txn);
            mon2cov.put(txn);
        end
    endtask
endclass