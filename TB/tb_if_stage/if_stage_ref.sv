class if_stage_ref;

    
    logic [XLEN-1:0] pc_q;          // thanh ghi PC


    function void reset();
        pc_q = '0;
    endfunction

    function automatic logic [XLEN-1:0] next_pc(
        input jump_t             jmp,
        input logic [XLEN-1:0]   pc_cur
    );
        logic taken;
        taken = (jmp.br_taken && jmp.br_en) || jmp.jal || jmp.jalr;
        return taken ? jmp.pc_jump : (pc_cur + XLEN'(4));
    endfunction


    function if_id_reg_t predict(if_stage_txn txn);
        if_id_reg_t expected;

        if (!txn.rst_n)
            pc_q = '0;

        // 2. Output tổ hợp của stage tại chu kỳ hiện tại
        expected.pc_cur = pc_q;
        expected.pc_4   = pc_q + XLEN'(4);
        expected.ins    = txn.ins;

        // 3. Cập nhật state tại cạnh clock:
        //    không reset và không stall thì PC nhảy sang giá trị kế tiếp
        if (txn.rst_n && !txn.stall_pc)
            pc_q = next_pc(txn.data_control_jump_id, pc_q);

        return expected;
    endfunction

endclass