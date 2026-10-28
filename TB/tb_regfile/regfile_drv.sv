// import regfile_pkg::*;
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

class regfile_drv;
    virtual regfile_if.DRV vif;
    mailbox #(regfile_txn) gen2drv;
    int num_txn;

    function new(
            virtual regfile_if.DRV vif,
            mailbox #(regfile_txn) gen2drv,
            int num_txn
    );
        this.vif = vif;
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    task reset();
        vif.rst_n= 1;
        vif.rs1_addr = riscv_reg_e'(0);
        vif.rs2_addr = riscv_reg_e'(0);
        vif.wb = '0;
    endtask

    task run();
        regfile_txn txn;
        repeat(num_txn) begin
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.rst_n= txn.rst_n;
            vif.rs1_addr = txn.rs1_addr;
            vif.rs2_addr = txn.rs2_addr;
            vif.wb = txn.wb;
        end
    endtask
endclass