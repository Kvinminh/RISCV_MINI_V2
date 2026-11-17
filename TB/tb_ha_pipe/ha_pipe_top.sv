module ha_pipe_top;
    import isa_pkg::*;
    import core_pkg::*;
    import ha_pipe_pkg::*;      // package chứa ha_pipe_txn, ha_pipe_ref, ha_pipe_env, ha_pipe_tests

    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    ha_pipe_if vif(clk);

    // Tên port giả định trùng tên signal của interface, giống bind trong ha_pipe_assert.
    // Nếu ha_pipe dùng hậu tố _i/_o thì sửa lại cho khớp.
    ha_pipe dut (
        .clk            (clk),
        .rst_n          (vif.rst_n),

        .rs1_addr       (vif.rs1_addr),
        .rs2_addr       (vif.rs2_addr),
        .rs1_used       (vif.rs1_used),
        .rs2_used       (vif.rs2_used),
        .jump_en        (vif.jump_en),
        .br_en          (vif.br_en),
        .br_taken       (vif.br_taken),
        .for_info_ex_i  (vif.for_info_ex),
        .for_info_mem_i (vif.for_info_mem),

        .pc_next      (vif.pc_next),
        .if_reg       (vif.if_reg),
        .id_reg       (vif.id_reg),
        .ex_reg       (vif.ex_reg),
        .mem_reg      (vif.mem_reg),

       
        .pc_cur       (vif.pc_cur),
        .reg_id       (vif.reg_id),
        .reg_ex       (vif.reg_ex),
        .reg_mem      (vif.reg_mem),
        .reg_wb       (vif.reg_wb)
    );

    assign vif.hzd_ctrl = dut.u_hazard.hzd_ctrl_o;
    

    // Khởi tạo input ngay tại t=0.
    // Nếu rst_n còn X trước lần drive đầu tiên, default disable iff (!rst_n)
    // không tắt assertion và AP_F01_* sẽ báo lỗi giả ở cạnh lên đầu tiên.
    initial begin
        vif.rst_n        = 1'b0;
        vif.rs1_addr     = riscv_reg_e'(0);
        vif.rs2_addr     = riscv_reg_e'(0);
        vif.rs1_used     = 1'b0;
        vif.rs2_used     = 1'b0;
        vif.jump_en      = 1'b0;
        vif.br_en        = 1'b0;
        vif.br_taken     = 1'b0;
        vif.for_info_ex  = '0;
        vif.for_info_mem = '0;
        vif.pc_next      = '0;
        vif.if_reg       = '0;
        vif.id_reg       = '0;
        vif.ex_reg       = '0;
        vif.mem_reg      = '0;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, ha_pipe_top);
    end

    initial begin
        ha_pipe_tests test;
        test = new(vif, 200);
        test.run();

        $display("");
        $display("============================================================");
        $display("                 SIMULATION FINISHED");
        $display("============================================================");

        $finish;
    end

    // Timeout: 10,000,000 ns = 1,000,000 chu kỳ với clock 10 ns
    initial begin
        #10000000;
        $error("[TB] TIMEOUT");
        $finish;
    end

endmodule