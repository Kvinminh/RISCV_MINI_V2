// import hz_fwd_pkg::*;

class hz_fwd_agt;
    virtual hz_fwd_if vif;

    mailbox #(hz_fwd_txn) gen2drv;
    mailbox #(hz_fwd_txn) mon2sb;
    mailbox #(hz_fwd_txn) mon2cov;

    hz_fwd_gene generator;
    hz_fwd_drv    driver;
    hz_fwd_mon  monitor;

    function new(virtual hz_fwd_if vif, int num_txn);
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
