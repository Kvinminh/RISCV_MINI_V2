module hz_fwd_top;
    import isa_pkg::*;
    import core_pkg::*;
    import hz_fwd_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk;

    hz_fwd_if vif(clk);

    hz_fwd dut (
        .clk          (clk),
        .rst_n        (vif.rst_n),
        .rs1_addr     (vif.rs1_addr),
        .rs2_addr     (vif.rs2_addr),
        .rs1_used     (vif.rs1_used),
        .rs2_used     (vif.rs2_used),
        .jump_en      (vif.jump_en),
        .br_en        (vif.br_en),
        .br_taken     (vif.br_taken),
        .for_info_ex  (vif.for_info_ex),
        .for_info_mem (vif.for_info_mem),
        .for_info_wb  (vif.for_info_wb),
        .for_id_a     (vif.for_id_a),
        .for_id_b     (vif.for_id_b),
        .for_ex_a     (vif.for_ex_a),
        .for_ex_b     (vif.for_ex_b),
        .hzd_ctrl     (vif.hzd_ctrl)
    );

    // Nối biến trung gian từ bên trong DUT vào interface.
    // Sửa đường dẫn u_hazard nếu grep cho thấy chúng nằm chỗ khác.
    assign vif.rs1_ex      = dut.u_hazard.rs1_ex;
    assign vif.rs2_ex      = dut.u_hazard.rs2_ex;
    assign vif.rs1_mem     = dut.u_hazard.rs1_mem;
    assign vif.rs2_mem     = dut.u_hazard.rs2_mem;
    assign vif.br2alu_ex   = dut.u_hazard.br2alu_ex;
    assign vif.br2load_ex  = dut.u_hazard.br2load_ex;
    assign vif.br2load_mem = dut.u_hazard.br2load_mem;
    assign vif.alu2load    = dut.u_hazard.alu2load;

    // Reset: chỉ dùng nếu test không tự drive rst_n
    initial begin
        vif.rst_n = 0;
        repeat (2) @(posedge clk);
        vif.rst_n = 1;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, hz_fwd_top);
    end

    initial begin
        hz_fwd_tests test;
        test = new(vif, 1000);
        test.run();

        $display("");
        $display("============================================================");
        $display("                 SIMULATION FINISHED");
        $display("============================================================");
        $finish;
    end

    // Timeout: 10,000,000 ns, clock 10 ns
    initial begin
        #10000000;
        $error("[TB] TIMEOUT");
        $finish;
    end
endmodule