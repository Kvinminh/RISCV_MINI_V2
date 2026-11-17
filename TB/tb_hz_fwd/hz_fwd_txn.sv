    // Phát hiện phụ thuộc thanh ghi với EX / MEM
    typedef struct packed {
        logic rs1_ex;
        logic rs2_ex;
        logic rs1_mem;
        logic rs2_mem;
    } hz_dep_t;

    // Điều kiện stall, tổng hợp từ dep và loại lệnh
    typedef struct packed {
        logic br2alu_ex;
        logic br2load_ex;
        logic br2load_mem;
        logic alu2load;
    } hz_stall_t;


class hz_fwd_txn;
    rand riscv_reg_e            rs1_addr;
    rand riscv_reg_e            rs2_addr;

    rand logic                  rs1_used;
    rand logic                  rs2_used;

    rand logic                  jump_en;       // JAL || JALR từ decode
    rand logic                  br_en;         // Branch từ decode
    rand logic                  br_taken;      // Kết quả br_compare

    rand for_info_t             for_info_ex;
    rand for_info_t             for_info_mem;
    rand for_info_t             for_info_wb;
    rand riscv_reg_e            ex_rs1_addr;
    rand riscv_reg_e            ex_rs2_addr;

   

    
    // biến trung gian: monitor điền từ DUT, ref điền exp_*
    hz_dep_t                    dep;
    hz_dep_t                    exp_dep;
    hz_stall_t                  stall_cond;
    hz_stall_t                  exp_stall_cond;

    // DUT output (monitor lấy)
    for_sel_e                   for_id_a;
    for_sel_e                   for_id_b;
    forward_e                   for_ex_a;
    forward_e                   for_ex_b;
    hzd_ctrl_t                  hzd_ctrl;

    // Ref tính
    for_sel_e                   expected_for_id_a;
    for_sel_e                   expected_for_id_b;
    forward_e                   expected_for_ex_a;
    forward_e                   expected_for_ex_b;
    hzd_ctrl_t                  expected_hzd_ctrl;

    // Địa chỉ: soft để gen có thể override sang 0..31
    constraint c_rs1_addr { soft rs1_addr inside {[0:4]}; }
    constraint c_rs2_addr { soft rs2_addr inside {[0:4]}; }

    constraint c_rs1_used { rs1_used dist {0 := 70, 1 := 30}; }
    constraint c_rs2_used { rs2_used dist {0 := 70, 1 := 30}; }

    // jump và branch không đồng thời, br_taken độc lập với br_en
    constraint c_jump_br  { !(jump_en && br_en); }
    constraint c_br_en    { br_en    dist {0 := 90, 1 := 10}; }
    constraint c_jump_en  { jump_en  dist {0 := 70, 1 := 30}; }
    constraint c_br_taken { br_taken dist {0 := 70, 1 := 30}; }

    constraint c_ex_rs1_addr { soft ex_rs1_addr inside {[0:4]}; }
    constraint c_ex_rs2_addr { soft ex_rs2_addr inside {[0:4]}; }

    constraint c_for_info_ex {
        soft for_info_ex.rd_addr inside {[0:4]};
        for_info_ex.mem_re dist {0 := 70, 1 := 30};
        for_info_ex.reg_en dist {0 := 70, 1 := 30};
    }

    constraint c_for_info_mem {
        soft for_info_mem.rd_addr inside {[0:4]};
        for_info_mem.mem_re dist {0 := 70, 1 := 30};
        for_info_mem.reg_en dist {0 := 70, 1 := 30};
    }

    constraint c_for_info_wb {
        soft for_info_wb.rd_addr inside {[0:4]};
        for_info_wb.mem_re dist {0 := 70, 1 := 30};
        for_info_wb.reg_en dist {0 := 70, 1 := 30};
    }

    function void copy(hz_fwd_txn rhs);
        if (rhs == null) return;

        rs1_addr     = rhs.rs1_addr;
        rs2_addr     = rhs.rs2_addr;
        rs1_used     = rhs.rs1_used;
        rs2_used     = rhs.rs2_used;

        jump_en      = rhs.jump_en;
        br_en        = rhs.br_en;
        br_taken     = rhs.br_taken;

        for_info_ex  = rhs.for_info_ex;
        for_info_mem = rhs.for_info_mem;
        for_info_wb  = rhs.for_info_wb;

        dep            = rhs.dep;
        exp_dep        = rhs.exp_dep;
        stall_cond     = rhs.stall_cond;
        exp_stall_cond = rhs.exp_stall_cond;

        for_id_a     = rhs.for_id_a;
        for_id_b     = rhs.for_id_b;
        for_ex_a     = rhs.for_ex_a;
        for_ex_b     = rhs.for_ex_b;
        hzd_ctrl     = rhs.hzd_ctrl;

        expected_for_id_a = rhs.expected_for_id_a;
        expected_for_id_b = rhs.expected_for_id_b;
        expected_for_ex_a = rhs.expected_for_ex_a;
        expected_for_ex_b = rhs.expected_for_ex_b;
        expected_hzd_ctrl = rhs.expected_hzd_ctrl;
        ex_rs1_addr  = rhs.ex_rs1_addr;
        ex_rs2_addr  = rhs.ex_rs2_addr;
    endfunction

    function hz_fwd_txn clone();
        hz_fwd_txn t = new();
        t.copy(this);
        return t;
    endfunction
endclass