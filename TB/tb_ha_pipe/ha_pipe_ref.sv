import isa_pkg::*;
import core_pkg::*;

class ha_pipe_ref;

    // ============================================================
    // State: giá trị đang lưu trong các thanh ghi pipeline
    // ============================================================
    logic [XLEN-1:0] pc_q;
    if_id_reg_t      if_q;
    id_ex_reg_t      id_q;
    ex_mem_reg_t     ex_q;
    mem_wb_reg_t     mem_q;

    // Kết quả trung gian của hazard unit
    typedef struct packed { logic rs1_ex, rs2_ex, rs1_mem, rs2_mem; } dep_t;
    typedef struct packed { logic br2alu_ex, br2load_ex, br2load_mem, alu2load; } case_t;

    // ============================================================
    // Hazard unit ref
    // ============================================================

    // Hàm 1: kiểm tra phụ thuộc thanh ghi với EX và MEM
    function dep_t dau_hieu_stall(ha_pipe_txn txn);
        dep_t d;
        d.rs1_ex  = txn.rs1_used && txn.for_info_ex.reg_en
                 && (txn.for_info_ex.rd_addr != REG_ZERO)
                 && (txn.for_info_ex.rd_addr == txn.rs1_addr);

        d.rs2_ex  = txn.rs2_used && txn.for_info_ex.reg_en
                 && (txn.for_info_ex.rd_addr != REG_ZERO)
                 && (txn.for_info_ex.rd_addr == txn.rs2_addr);

        d.rs1_mem = txn.rs1_used && txn.for_info_mem.reg_en
                 && (txn.for_info_mem.rd_addr != REG_ZERO)
                 && (txn.for_info_mem.rd_addr == txn.rs1_addr);

        d.rs2_mem = txn.rs2_used && txn.for_info_mem.reg_en
                 && (txn.for_info_mem.rd_addr != REG_ZERO)
                 && (txn.for_info_mem.rd_addr == txn.rs2_addr);
        return d;
    endfunction

    // Hàm 2: phân loại các case gây stall (branch + load-use)
    function case_t case_stall(ha_pipe_txn txn, dep_t d);
        case_t c;
        logic dep_ex;
        logic dep_mem;

        dep_ex  = d.rs1_ex  || d.rs2_ex;
        dep_mem = d.rs1_mem || d.rs2_mem;

        c.br2alu_ex   = dep_ex  && txn.br_en && !txn.for_info_ex.mem_re;
        c.br2load_ex  = dep_ex  && txn.br_en &&  txn.for_info_ex.mem_re;
        c.br2load_mem = dep_mem && txn.br_en &&  txn.for_info_mem.mem_re;
        c.alu2load    = dep_ex  && txn.for_info_ex.mem_re && !txn.br_en;
        return c;
    endfunction

    // Hàm 3: đặt tín hiệu stall và flush
    function hzd_ctrl_t quyet_dinh_stall(ha_pipe_txn txn, case_t c);
        hzd_ctrl_t hz;
        logic need_stall;
        logic take_jump;

        need_stall = c.br2alu_ex || c.br2load_ex || c.br2load_mem || c.alu2load;
        take_jump  = txn.jump_en || (txn.br_taken && txn.br_en);

        hz.stall_pc    = need_stall;
        hz.stall_if_id = need_stall;
        hz.flush_id_ex = need_stall;
        hz.flush_if_id = take_jump && !need_stall;
        return hz;
    endfunction

    // Ghép 3 hàm trên thành output hazard (tổ hợp)
    function hzd_ctrl_t hazard_predict(ha_pipe_txn txn);
        dep_t    d;
        case_t   c;
        hzd_ctrl_t hz;
        d  = dau_hieu_stall(txn);
        c  = case_stall(txn, d);
        hz = quyet_dinh_stall(txn, c);
        return hz;
    endfunction

    // ============================================================
    // Pipeline register ref (cập nhật state theo cạnh clock)
    // ============================================================

    function void reset();
        pc_q  = '0;
        if_q  = '0;
        id_q  = '0;
        ex_q  = '0;
        mem_q = '0;
    endfunction

    // PC: giữ nguyên khi stall, ngược lại lấy pc_next
    function void step_pc(logic [XLEN-1:0] pc_next, hzd_ctrl_t hz);
        if (!hz.stall_pc)
            pc_q = pc_next;
    endfunction

    // IF/ID: flush -> 0, stall -> giữ, còn lại lấy input
    function void step_if_id(if_id_reg_t nxt, hzd_ctrl_t hz);
        if (hz.flush_if_id)
            if_q = '0;
        else if (!hz.stall_if_id)
            if_q = nxt;
    endfunction

    // ID/EX: flush -> 0, còn lại lấy input
    function void step_id_ex(id_ex_reg_t nxt, hzd_ctrl_t hz);
        if (hz.flush_id_ex)
            id_q = '0;
        else
            id_q = nxt;
    endfunction

    // EX/MEM: không có flush/stall
    function void step_ex_mem(ex_mem_reg_t nxt);
        ex_q = nxt;
    endfunction

    // MEM/WB: không có flush/stall
    function void step_mem_wb(mem_wb_reg_t nxt);
        mem_q = nxt;
    endfunction

    // ============================================================
    // Hàm tổng: nhận txn, cập nhật state, ghi expected vào txn
    // ============================================================
    function hzd_ctrl_t predict(ha_pipe_txn txn);
        hzd_ctrl_t hz;

        hz = hazard_predict(txn);

        if (!txn.rst_n) begin
            reset();
        end
        else begin
            step_pc(txn.pc_next, hz);
            step_if_id(txn.if_reg, hz);
            step_id_ex(txn.id_reg, hz);
            step_ex_mem(txn.ex_reg);
            step_mem_wb(txn.mem_reg);
        end

        // Output = giá trị thanh ghi sau cạnh clock của txn này
        txn.expected_pc_cur  = pc_q;
        txn.expected_reg_id  = if_q;
        txn.expected_reg_ex  = id_q;
        txn.expected_reg_mem = ex_q;
        txn.expected_reg_wb  = mem_q;

        return hz;
    endfunction

endclass