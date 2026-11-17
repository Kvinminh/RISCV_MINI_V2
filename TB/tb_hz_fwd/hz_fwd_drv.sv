class hz_fwd_drv;
    virtual hz_fwd_if.DRV  vif;
    mailbox #(hz_fwd_txn) gen2drv;
    int num_txn;

    function new(
        virtual hz_fwd_if.DRV vif,
        mailbox #(hz_fwd_txn) gen2drv,
        int num_txn
    );
        this.vif      = vif;
        this.gen2drv  = gen2drv;
        this.num_txn  = num_txn;
    endfunction

    task reset();
        vif.rst_n        = '0;
        vif.rs1_addr     = riscv_reg_e'(0);
        vif.rs2_addr     = riscv_reg_e'(0);
        vif.rs1_used     = '0;
        vif.rs2_used     = '0;
        vif.jump_en      = '0;
        vif.br_en        = '0;
        vif.br_taken     = '0;
        vif.for_info_ex  = '0;
        vif.for_info_mem = '0;
        vif.for_info_wb  = '0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
        hz_fwd_txn txn;
        repeat(num_txn) begin
            gen2drv.get(txn);
            @(negedge vif.clk);
            // vif.rst_n        = txn.rst_n;
            vif.rs1_addr     = txn.rs1_addr;
            vif.rs2_addr     = txn.rs2_addr;
            vif.rs1_used     = txn.rs1_used;
            vif.rs2_used     = txn.rs2_used;
            vif.jump_en      = txn.jump_en;
            vif.br_en        = txn.br_en;
            vif.br_taken     = txn.br_taken;
            vif.for_info_ex  = txn.for_info_ex;
            vif.for_info_mem = txn.for_info_mem;
            vif.for_info_wb  = txn.for_info_wb;
        end
    endtask
endclass