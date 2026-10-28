// import immgen_pkg::*;

class immgen_agt;
    virtual immgen_if vif;

    mailbox #(immgen_txn) gen2drv;
    mailbox #(immgen_txn) mon2sb;
    mailbox #(immgen_txn) mon2cov;

    immgen_gene generator;
    immgen_drv    driver;
    immgen_mon   monitor;

    function new(virtual immgen_if vif, int num_txn);
        this.vif = vif;

        gen2drv = new();
        mon2sb  = new();
        mon2cov = new();

        generator = new(gen2drv, num_txn);
        driver    = new(vif.DRV, gen2drv,num_txn);
        monitor   = new(vif.MON, mon2sb, mon2cov, num_txn);  // bỏ ref_model
    endfunction

    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
        join_none
    endtask
endclass
