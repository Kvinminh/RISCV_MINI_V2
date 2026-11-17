class hz_fwd_ref;

    // ============================================================
    // Helper: thanh ghi addr có được ghi bởi stage info không
    // (loại x0, khớp với RTL)
    // ============================================================
    function bit hit(riscv_reg_e addr, for_info_t info);
        return (addr != REG_ZERO) && info.reg_en
            && (info.rd_addr != REG_ZERO) && (info.rd_addr == addr);
    endfunction

    // ============================================================
    // Hazard unit ref
    // ============================================================

    // Hàm 1: phụ thuộc thanh ghi ở ID với EX và MEM
    function hz_dep_t dau_hieu_stall(hz_fwd_txn txn);
        hz_dep_t d;
        d.rs1_ex  = txn.rs1_used && hit(txn.rs1_addr, txn.for_info_ex);
        d.rs2_ex  = txn.rs2_used && hit(txn.rs2_addr, txn.for_info_ex);
        d.rs1_mem = txn.rs1_used && hit(txn.rs1_addr, txn.for_info_mem);
        d.rs2_mem = txn.rs2_used && hit(txn.rs2_addr, txn.for_info_mem);
        return d;
    endfunction

    // Hàm 2: phân loại các case stall
    function hz_stall_t case_stall(hz_fwd_txn txn, hz_dep_t d);
        hz_stall_t c;
        logic dep_ex, dep_mem, rs_cmp;

        dep_ex  = d.rs1_ex  || d.rs2_ex;
        dep_mem = d.rs1_mem || d.rs2_mem;
        // ID cần rs để quyết định nhánh/địa chỉ, không phụ thuộc taken
        rs_cmp  = txn.br_en || txn.jump_en;

        c.br2alu_ex   = dep_ex  && rs_cmp && !txn.for_info_ex.mem_re;
        c.br2load_ex  = dep_ex  && rs_cmp &&  txn.for_info_ex.mem_re;
        c.br2load_mem = dep_mem && rs_cmp &&  txn.for_info_mem.mem_re;
        c.alu2load    = dep_ex  &&            txn.for_info_ex.mem_re;   // mọi consumer
        return c;
    endfunction

    // Hàm 3: đặt stall và flush
    function hzd_ctrl_t quyet_dinh_stall(hz_fwd_txn txn, hz_stall_t c);
        hzd_ctrl_t hz;
        logic need_stall, take_jump;

        need_stall = c.br2alu_ex || c.br2load_ex || c.br2load_mem || c.alu2load;
        take_jump  = txn.jump_en || (txn.br_en && txn.br_taken);

        hz.stall_pc    = need_stall;
        hz.stall_if_id = need_stall;
        hz.flush_id_ex = need_stall;
        hz.flush_if_id = take_jump && !need_stall;
        return hz;
    endfunction

    // ============================================================
    // Forward ref
    // ============================================================

    // forward_id: ưu tiên EX > MEM > WB, mặc định đọc regfile tại ID
    function for_sel_e exp_fwd_id(riscv_reg_e addr,
                                  for_info_t ex, for_info_t mem, for_info_t wb,
                                  for_sel_e dflt);
        if      (hit(addr, ex))  return RD_DATA_EX;
        else if (hit(addr, mem)) return RD_DATA_MEM;
        else if (hit(addr, wb))  return RD_DATA_WB;
        else                     return dflt;
    endfunction

    // forward_ex: ưu tiên MEM > WB, mặc định RD_EX (không có đường EX->EX)
    function forward_e exp_fwd_ex(riscv_reg_e addr, for_info_t mem, for_info_t wb);
        if      (hit(addr, mem)) return RD_MEM;
        else if (hit(addr, wb))  return RD_WB;
        else                     return RD_EX;
    endfunction

    // ============================================================
    // Hàm tổng: tính expected và ghi vào txn
    // ============================================================
    function hzd_ctrl_t predict(hz_fwd_txn txn);
        hz_dep_t   d;
        hz_stall_t c;
        hzd_ctrl_t hz;

        d  = dau_hieu_stall(txn);
        c  = case_stall(txn, d);
        hz = quyet_dinh_stall(txn, c);

        txn.exp_dep           = d;
        txn.exp_stall_cond    = c;
        txn.expected_hzd_ctrl = hz;

        // forward_id: so sánh với rs1_addr / rs2_addr (ID stage)
        txn.expected_for_id_a = exp_fwd_id(txn.rs1_addr, txn.for_info_ex,
                                           txn.for_info_mem, txn.for_info_wb, RS1_DATA_ID);
        txn.expected_for_id_b = exp_fwd_id(txn.rs2_addr, txn.for_info_ex,
                                           txn.for_info_mem, txn.for_info_wb, RS2_DATA_ID);

        // forward_ex: so sánh với ex_rs1_addr / ex_rs2_addr (EX stage)
        txn.expected_for_ex_a = exp_fwd_ex(txn.ex_rs1_addr, txn.for_info_mem, txn.for_info_wb);
        txn.expected_for_ex_b = exp_fwd_ex(txn.ex_rs2_addr, txn.for_info_mem, txn.for_info_wb);

        return hz;
    endfunction

endclass