// import alu_pkg::*;

class alu_test;
    virtual alu_if vif;
    alu_env env;
    int direct_pass = 0;
    int direct_fail = 0;
    int num_txn;

    function new(virtual alu_if vif, int num_txn );
        this.vif = vif;
        this.num_txn = num_txn;
        env = new(vif,num_txn);
    endfunction
    
    ////////////////////////////////////////// DIRECT_TEST ///////////////////////////

task direct_idle();
    vif.alu_ctrl = alu_ctrl_e'('0);
    vif.A = '0;
    vif.B = '0;
endtask

task direct_check(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
        direct_fail++;
        $error("[DIRECT][FAIL] %s actual=%08h expected=%08h",
               name, actual, expected);
    end
    else begin
        direct_pass++;
        $display("[DIRECT][PASS] %s value=%08h", name, actual);
    end
endtask

task direct_sample_cov();
    alu_txn t = new();

    t.alu_ctrl = vif.alu_ctrl;
    t.A        = vif.A;
    t.B        = vif.B;
    t.alu      = vif.alu;

    env.coverage.sample_direct(t);
endtask

task automatic direct_apply(
    string name,
    alu_ctrl_e op,
    logic [31:0] a,
    logic [31:0] b,
    logic [31:0] expected
);
    vif.alu_ctrl = op;
    vif.A = a;
    vif.B = b;

    #1;

    direct_check(name, vif.alu, expected);
    direct_sample_cov();
endtask

task direct_add_sub();
    logic [31:0] a, b, expected;

    // VR-F02-1 to VR-F02-6
    direct_apply("VR-F02-1", ALU_ADD,
                 32'h00000000, 32'h00000000, 32'h00000000);
    direct_apply("VR-F02-2", ALU_ADD,
                 32'h12345678, 32'h00000000, 32'h12345678);
    direct_apply("VR-F02-3", ALU_ADD,
                 32'h7FFFFFFF, 32'h00000001, 32'h80000000);
    direct_apply("VR-F02-4", ALU_ADD,
                 32'h55555555, 32'h55555555, 32'hAAAAAAAA);
    direct_apply("VR-F02-5", ALU_ADD,
                 32'hFFFFFFFF, 32'h00000001, 32'h00000000);
    direct_apply("VR-F02-6", ALU_ADD,
                 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE);

    

    // VR-F02-7: ADD random

    // VR-F02-8 to VR-F02-13
    direct_apply("VR-F02-8", ALU_SUB,
                 32'h12345678, 32'h12345678, 32'h00000000);
    direct_apply("VR-F02-9", ALU_SUB,
                 32'h12345678, 32'h00000000, 32'h12345678);
    direct_apply("VR-F02-10", ALU_SUB,
                 32'h80000000, 32'h00000001, 32'h7FFFFFFF);
    direct_apply("VR-F02-11", ALU_SUB,
                 32'h00000000, 32'h00000001, 32'hFFFFFFFF);
    direct_apply("VR-F02-12", ALU_SUB,
                 32'h00000000, 32'hFFFFFFFF, 32'h00000001);
    direct_apply("VR-F02-13", ALU_SUB,
                 32'h00000001, 32'h00000002, 32'hFFFFFFFF);

    // VR-F02-14: SUB random
   
endtask

task direct_logic();
    // VR-F02-15 to VR-F02-25
    direct_apply("VR-F02-15", ALU_AND,
                 32'h12345678, 32'h00000000, 32'h00000000);
    direct_apply("VR-F02-16", ALU_AND,
                 32'h12345678, 32'hFFFFFFFF, 32'h12345678);
    direct_apply("VR-F02-17", ALU_AND,
                 32'hAAAAAAAA, 32'h55555555, 32'h00000000);
    direct_apply("VR-F02-18", ALU_AND,
                 32'h12345678, 32'h12345678, 32'h12345678);

    direct_apply("VR-F02-19", ALU_OR,
                 32'h12345678, 32'h00000000, 32'h12345678);
    direct_apply("VR-F02-20", ALU_OR,
                 32'h12345678, 32'hFFFFFFFF, 32'hFFFFFFFF);
    direct_apply("VR-F02-21", ALU_OR,
                 32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF);

    direct_apply("VR-F02-22", ALU_XOR,
                 32'h12345678, 32'h12345678, 32'h00000000);
    direct_apply("VR-F02-23", ALU_XOR,
                 32'h12345678, 32'h00000000, 32'h12345678);
    direct_apply("VR-F02-24", ALU_XOR,
                 32'h12345678, 32'hFFFFFFFF, 32'hEDCBA987);
    direct_apply("VR-F02-25", ALU_XOR,
                 32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF);
endtask

task direct_shift();
    // VR-F02-26 to VR-F02-37
    direct_apply("VR-F02-26", ALU_SLL,
                 32'h12345678, 32'd0, 32'h12345678);
    direct_apply("VR-F02-27", ALU_SLL,
                 32'h00000001, 32'd1, 32'h00000002);
    direct_apply("VR-F02-28", ALU_SLL,
                 32'hFFFFFFFF, 32'd2, 32'hFFFFFFFC);
    direct_apply("VR-F02-29", ALU_SLL,
                 32'h00000001, 32'd31, 32'h80000000);
    direct_apply("VR-F02-30", ALU_SLL,
                 32'h12345678, 32'd32, 32'h12345678);
    direct_apply("VR-F02-31", ALU_SLL,
                 32'h00000001, 32'hFFFFFFE2, 32'h00000004);

    direct_apply("VR-F02-32", ALU_SRL,
                 32'h12345678, 32'd0, 32'h12345678);
    direct_apply("VR-F02-33", ALU_SRL,
                 32'h80000000, 32'd1, 32'h40000000);
    direct_apply("VR-F02-34", ALU_SRL,
                 32'hFFFFFFFF, 32'd2, 32'h3FFFFFFF);
    direct_apply("VR-F02-35", ALU_SRL,
                 32'hFFFFFFFF, 32'd31, 32'h00000001);
    direct_apply("VR-F02-36", ALU_SRL,
                 32'h80000000, 32'd32, 32'h80000000);
    direct_apply("VR-F02-37", ALU_SRL,
                 32'h80000000, 32'hFFFFFFE2, 32'h20000000);
endtask

task direct_walking_one();
    logic [31:0] a, b, expected;

    // VR-F02-38
    for (int i = 0; i < 32; i++) begin
        a = 32'h00000001 << i;
        b = $urandom;

        direct_apply($sformatf("VR-F02-38_AND_%0d", i),
                     ALU_AND, a, b, a & b);

        direct_apply($sformatf("VR-F02-38_OR_%0d", i),
                     ALU_OR, a, b, a | b);

        direct_apply($sformatf("VR-F02-38_XOR_%0d", i),
                     ALU_XOR, a, b, a ^ b);

        expected = a << b[4:0];
        direct_apply($sformatf("VR-F02-38_SLL_%0d", i),
                     ALU_SLL, a, b, expected);

        expected = a >> b[4:0];
        direct_apply($sformatf("VR-F02-38_SRL_%0d", i),
                     ALU_SRL, a, b, expected);
    end
endtask

task direct_default();
    logic [31:0] a, b;

    a = 32'hA5A55A5A;
    b = 32'h5A5AA5A5;

    // VR-F02-39
    direct_apply("VR-F02-39_INVALID", alu_ctrl_e'('1),
                 a, b, 32'h00000000);
    direct_apply("VR-F02-39_SLT", ALU_SLT,
                 a, b, 32'h00000000);
    direct_apply("VR-F02-39_SLTU", ALU_SLTU,
                 a, b, 32'h00000000);
    direct_apply("VR-F02-39_SRA", ALU_SRA,
                 a, b, 32'h00000000);
endtask

task run_direct_tests();
    direct_pass = 0;
    direct_fail = 0;

    direct_idle();
    #1;

    direct_add_sub();
    direct_logic();
    direct_shift();
    direct_walking_one();
    direct_default();

    $display("========================================");
    $display("[DIRECT] PASS=%0d FAIL=%0d",
             direct_pass, direct_fail);
    $display("========================================");

    if (direct_fail != 0)
        $fatal(1, "[DIRECT] TEST FAILED: %0d failures", direct_fail);
    else
        $display("[DIRECT] ALL TESTS PASSED");
endtask



task run_random_tests();
        $display("");
        $display("============================================================");
        $display("                   OOP RANDOM TEST");
        $display("============================================================");
    direct_idle();

    env.run();
    repeat (5) @(posedge vif.clk);
    #1;
    $display("[OOP] Random generation completed.");
endtask



task report();
    $display("");
    $display("============================================================");
    $display("                 EX-STAGE FINAL REPORT");
    $display("============================================================");
    $display("[DIRECT] PASS=%0d FAIL=%0d",direct_pass,direct_fail);
    env.coverage.report();
    if ((direct_fail == 0) && (env.scoreboard.fail == 0))
        $display("[FINAL] FUNCTIONAL CHECKING = PASS");
    else
    $display("[FINAL] FUNCTIONAL CHECKING = FAIL");
    $display("============================================================");

endtask


task run();
    run_direct_tests();
    run_random_tests();
    report();
endtask

endclass
