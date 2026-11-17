import if_stage_pkg::*;

module if_stage_top;
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;

    logic clk;
     initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    if_stage_if vif(clk);
    if_stage dut(
        .clk(clk),
        .rst_n(vif.rst_n),
        .stall_pc_i(vif.stall_pc),
        .data_control_jump_id_i(vif.data_control_jump_id),
        .ins_i(vif.ins),
        .if_reg_o(vif.if_reg)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,tb_if_stage);
    end


     initial begin
        if_stage_tests test;
        test = new(vif,200);
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