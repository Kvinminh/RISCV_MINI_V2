import regfile_pkg::*;

module regfile_top;
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
    logic clk;


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    regfile_if vif(clk);

    regfile dut(
        .clk(clk),
        .rst_n(vif.rst_n),
        .rs1_addr_i(vif.rs1_addr),
        .rs2_addr_i(vif.rs2_addr),
        .wb_i(vif.wb),
        .rs1_data_o(vif.rs1_data),
        .rs2_data_o(vif.rs2_data)
    );


    initial begin
        $dumpfile("tb_regfiel.vcd");
        $dumpvars(0,tb_regfile);
    end

    initial begin
        regfile_test test;
        test = new(vif,20000);
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