class if_stage_txn;
    //rand logic clk;
    rand logic rst_n;
    rand logic stall_pc;
    rand jump_t data_control_jump_id;
    rand logic [XLEN-1:0] ins;

    logic [XLEN-1:0] pc_next;
    if_id_reg_t if_reg;
    if_id_reg_t expected_if_reg;


    constraint c_rst_n {
        rst_n dist{
            1 := 90,
            0 := 10
        };
    };

    constraint c_stall_pc{
        stall_pc dist{
            1 := 90,
            0 := 10
        };
    };

    rand int unsigned kind;  // 0: none, 1: jal, 2: jalr, 3: br

    constraint c_kind { kind dist { 0 := 70, 1 := 10, 2 := 10, 3 := 10 }; };

    constraint c_jump_ctrl {
        data_control_jump_id.jal      == (kind == 1);
        data_control_jump_id.jalr     == (kind == 2);
        data_control_jump_id.br_en    == (kind == 3);
        data_control_jump_id.br_taken == (kind == 3);
    };

    constraint c_jump_addr {
        data_control_jump_id.pc_jump inside {[0:31]};
    };
    
    constraint c_ins {
        ins inside {[0:31]};
    };

    function void copy (if_stage_txn rhs);
        if (rhs == null) return;
        rst_n = rhs.rst_n;
        stall_pc = rhs.stall_pc;
        data_control_jump_id = rhs.data_control_jump_id;
        ins = rhs.ins;
    endfunction

    function if_stage_txn clone();
        if_stage_txn t = new();
        t.copy(this);
        return t;
    endfunction
endclass