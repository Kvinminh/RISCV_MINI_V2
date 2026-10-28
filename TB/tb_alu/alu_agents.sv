// import alu_pkg::*;

class alu_agents;
    virtual alu_if vif;

    mailbox #(alu_txn) gen2drv;
    mailbox #(alu_txn) mon2sb;
    mailbox #(alu_txn) mon2cov;

    alu_generator generator;
    alu_driver    driver;
    alu_monitor   monitor;

    function new(virtual alu_if vif, int num_txn);
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
