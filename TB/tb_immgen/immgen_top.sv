import immgen_pkg::*;

module immgen_top;
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;

    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // Không có clock: immgen thuần tổ hợp, test tự đặt input và chờ #1
    immgen_if vif(clk);

    immgen dut(
        .ins_i    (vif.ins),
        .imm_sel_i(vif.imm_sel),
        .imm_out_o(vif.imm_out)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, immgen_top);
    end

    initial begin
        immgen_test test;
        test = new(vif,1000);
        test.run();

        $display("");
        $display("============================================================");
        $display("                 SIMULATION FINISHED");
        $display("============================================================");

        $finish;
    end

    initial begin
        #10000000;
        $fatal(1, "[TB] TIMEOUT");
    end

endmodule