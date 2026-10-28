import alu_pkg::*;


module tb_alu;
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
    logic clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    alu_if vif(clk);

    alu dut(
        .alu_ctrl_i(vif.alu_ctrl),
        .A(vif.A),
        .B(vif.B),
        .alu_result_o(vif.alu)
    );

     initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0,tb_alu);
    end

    initial begin
        alu_test test;
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

        $error("[TB] TIMEOUT");
        $finish;
    end

endmodule


