class ha_pipe_txn;
    rand logic rst_n;

    rand riscv_reg_e            rs1_addr;
    rand riscv_reg_e            rs2_addr;

    rand logic                  rs1_used;
    rand logic                  rs2_used;

    rand logic                  jump_en;       // JAL || JALR từ decode
    rand logic                  br_en;         // Branch từ decode
    rand logic                  br_taken;      // Kết quả br_compare

    rand for_info_t             for_info_ex;
    rand for_info_t             for_info_mem;

    rand logic [XLEN-1:0]       pc_next;
    rand if_id_reg_t            if_reg;
    rand id_ex_reg_t            id_reg;
    rand ex_mem_reg_t           ex_reg;
    rand mem_wb_reg_t           mem_reg;


    logic [XLEN-1:0] pc_cur;
    if_id_reg_t      reg_id;
    id_ex_reg_t      reg_ex;
    ex_mem_reg_t     reg_mem;
    mem_wb_reg_t     reg_wb;

    logic [XLEN-1:0] expected_pc_cur;
    if_id_reg_t      expected_reg_id;
    id_ex_reg_t      expected_reg_ex;
    ex_mem_reg_t     expected_reg_mem;
    mem_wb_reg_t     expected_reg_wb;


    hzd_ctrl_t hzd_ctrl;            // DUT output (monitor lấy)
    hzd_ctrl_t expected_hzd_ctrl;   // ref tính

    // Địa chỉ: soft để gene có thể override sang 0..31
    constraint c_rs1_addr { soft rs1_addr inside {[0:4]}; }
    constraint c_rs2_addr { soft rs2_addr inside {[0:4]}; }

    constraint c_rs1_used { rs1_used dist {0 := 70, 1 := 30}; }
    constraint c_rs2_used { rs2_used dist {0 := 70, 1 := 30}; }

    // AP_F01_3: jump và branch không đồng thời
    // br_taken độc lập với br_en, để sinh được VF-F05-4 (br_en = 0, br_taken = 1)
    constraint c_jump_br   { !(jump_en && br_en); }
    constraint c_br_en     { br_en     dist {0 := 90, 1 := 10}; }
    constraint c_jump_en   { jump_en   dist {0 := 70, 1 := 30}; }
    constraint c_br_taken  { br_taken  dist {0 := 70, 1 := 30}; }

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

    // pipeline: giữ quan hệ, rd thành soft
    constraint c_id_reg {
        id_reg.pc_cur % 4 == 0;
        id_reg.pc_4 == id_reg.pc_cur + 4;
        soft id_reg.rd_addr inside {[0:4]};
        id_reg.rs1_addr == rs1_addr;
        id_reg.rs2_addr == rs2_addr;
    }

    constraint c_ex_reg {
        soft ex_reg.rd_addr inside {[0:4]};
        ex_reg.rd_addr == for_info_ex.rd_addr;
    }

    constraint c_mem_reg {
        soft mem_reg.rd_addr inside {[0:4]};
        mem_reg.rd_addr == for_info_mem.rd_addr;
    }

    // pc_next: căn 4 byte, full range, soft
    constraint c_pc_next { soft pc_next[1:0] == 2'b00; }

    function void copy(ha_pipe_txn rhs);
    if (rhs == null) return;

        rst_n        = rhs.rst_n;
        rs1_addr     = rhs.rs1_addr;
        rs2_addr     = rhs.rs2_addr;
        rs1_used     = rhs.rs1_used;
        rs2_used     = rhs.rs2_used;

        jump_en      = rhs.jump_en;
        br_en        = rhs.br_en;
        br_taken     = rhs.br_taken;

        for_info_ex  = rhs.for_info_ex;
        for_info_mem = rhs.for_info_mem;

        pc_next      = rhs.pc_next;
        if_reg       = rhs.if_reg;
        id_reg       = rhs.id_reg;
        ex_reg       = rhs.ex_reg;
        mem_reg      = rhs.mem_reg;

        pc_cur           = rhs.pc_cur;
        reg_id           = rhs.reg_id;
        reg_ex           = rhs.reg_ex;
        reg_mem          = rhs.reg_mem;
        reg_wb           = rhs.reg_wb;

        hzd_ctrl = rhs.hzd_ctrl;

        expected_pc_cur  = rhs.expected_pc_cur;
        expected_reg_id  = rhs.expected_reg_id;
        expected_reg_ex  = rhs.expected_reg_ex;
        expected_reg_mem = rhs.expected_reg_mem;
        expected_reg_wb  = rhs.expected_reg_wb;
        
        expected_hzd_ctrl = rhs.expected_hzd_ctrl;
    endfunction

function ha_pipe_txn clone();
    ha_pipe_txn t = new();
    t.copy(this);
    return t;
endfunction
endclass