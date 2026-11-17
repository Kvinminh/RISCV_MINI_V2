// import ha_pipe_pkg::*;

class ha_pipe_agt;
    virtual ha_pipe_if vif;

    mailbox #(ha_pipe_txn) gen2drv;
    mailbox #(ha_pipe_txn) mon2sb;
    mailbox #(ha_pipe_txn) mon2cov;

    ha_pipe_gene generator;
    ha_pipe_drv    driver;
    ha_pipe_mon  monitor;

    function new(virtual ha_pipe_if vif, int num_txn);
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
