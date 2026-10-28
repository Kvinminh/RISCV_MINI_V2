// import regfile_pkg::*;

class regfile_agt;
    virtual regfile_if vif;

    mailbox #(regfile_txn) gen2drv;
    mailbox #(regfile_txn) mon2sb;
    mailbox #(regfile_txn) mon2cov;

    regfile_gene generator;
    regfile_drv    driver;
    regfile_mon  monitor;

    function new(virtual regfile_if vif, int num_txn);
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
