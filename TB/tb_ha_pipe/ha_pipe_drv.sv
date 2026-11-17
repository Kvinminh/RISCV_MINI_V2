class ha_pipe_drv;
    virtual ha_pipe_if.DRV vif;
    mailbox #(ha_pipe_txn) gen2drv;
    int num_txn;

    function new(
        virtual ha_pipe_if.DRV vif,
        mailbox #(ha_pipe_txn) gen2drv,
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
        vif.pc_next      = '0;
        vif.if_reg       = '0;
        vif.id_reg       = '0;
        vif.ex_reg       = '0;
        vif.mem_reg      = '0;
        repeat(3) @(negedge vif.clk);
    endtask

    task run();
        ha_pipe_txn txn;
        repeat(num_txn) begin
            gen2drv.get(txn);
            @(negedge vif.clk);
            vif.rst_n        = txn.rst_n;
            vif.rs1_addr     = txn.rs1_addr;
            vif.rs2_addr     = txn.rs2_addr;
            vif.rs1_used     = txn.rs1_used;
            vif.rs2_used     = txn.rs2_used;
            vif.jump_en      = txn.jump_en;
            vif.br_en        = txn.br_en;
            vif.br_taken     = txn.br_taken;
            vif.for_info_ex  = txn.for_info_ex;
            vif.for_info_mem = txn.for_info_mem;
            vif.pc_next      = txn.pc_next;
            vif.if_reg       = txn.if_reg;
            vif.id_reg       = txn.id_reg;
            vif.ex_reg       = txn.ex_reg;
            vif.mem_reg      = txn.mem_reg;
        end
    endtask
endclass