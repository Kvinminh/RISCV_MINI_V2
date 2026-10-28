class regfile_ref;

    localparam int REG_COUNT = 32;
    logic [XLEN-1:0] mem [0:REG_COUNT-1];

    function new();
        reset();
    endfunction

    function void reset();
        foreach (mem[i]) mem[i] = '0;
    endfunction

    // Đọc trước, ghi sau: khớp regfile RTL (ghi ở posedge, đọc tổ hợp, không bypass)
    // function void predict(regfile_txn txn);
    //     if (txn == null) return;

    //     // Reset bất đồng bộ: xóa hết, đầu ra về 0
    //     if (!txn.rst_n) begin
    //         reset();
    //         return;
    //     end

    //     // 1. ĐỌC (giá trị cũ, trước khi ghi)
        
    //     txn.expected_rs1_data = (txn.rs1_addr == 5'd0) ? '0 : mem[txn.rs1_addr];
    //     txn.expected_rs2_data = (txn.rs2_addr == 5'd0) ? '0 : mem[txn.rs2_addr];

    //     // 2. GHI (có hiệu lực cho các lần đọc sau). x0 không bao giờ bị ghi
    //     if (txn.wb.reg_en && (txn.wb.rd_addr != 5'd0))
    //         mem[txn.wb.rd_addr] = txn.wb.rd_data;


    // endfunction


    function void predict(regfile_txn txn);
    if (txn == null) return;

    if (!txn.rst_n) begin
        reset();
        txn.expected_rs1_data = '0;
        txn.expected_rs2_data = '0;
        return;
    end

    // Ghi trước
    if (txn.wb.reg_en && (txn.wb.rd_addr != REG_ZERO))
        mem[txn.wb.rd_addr] = txn.wb.rd_data;

    // Đọc sau
    txn.expected_rs1_data =
        (txn.rs1_addr == REG_ZERO) ? '0 : mem[txn.rs1_addr];

    txn.expected_rs2_data =
        (txn.rs2_addr == REG_ZERO) ? '0 : mem[txn.rs2_addr];
endfunction

endclass