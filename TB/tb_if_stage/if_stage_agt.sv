// import if_stage_pkg::*;

class if_stage_agt;
    virtual if_stage_if vif;

    mailbox #(if_stage_txn) gen2drv;
    mailbox #(if_stage_txn) mon2sb;
    mailbox #(if_stage_txn) mon2cov;

    if_stage_gene generator;
    if_stage_drv    driver;
    if_stage_mon  monitor;

    function new(virtual if_stage_if vif, int num_txn);
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
