// // import regfile_pkg::*;
// import isa_pkg::*;


// class regfile_test;

//     virtual regfile_if vif;
//     regfile_env env;

//     int direct_pass = 0;
//     int direct_fail = 0;
//     int num_txn;

//     function new(virtual regfile_if vif, int num_txn);
//         this.vif = vif;
//         this.num_txn = num_txn;
//         env = new(vif, num_txn);
//     endfunction

//     //////////////////////////////////////////
//     // DIRECT_TEST
//     //////////////////////////////////////////

//     task direct_idle();
//         vif.wb.reg_en  = '0;
//         vif.wb.rd_addr = riscv_reg_e'(0);
//         vif.wb.rd_data = '0;
//         vif.rs1_addr = riscv_reg_e'(0);
//         vif.rs2_addr = riscv_reg_e'(0);
//     endtask

//     task direct_check(
//         string name,
//         logic [31:0] actual,
//         logic [31:0] expected
//     );
//         if (actual !== expected) begin
//             direct_fail++;
//             $error(
//                 "[DIRECT][FAIL] %s actual=%08h expected=%08h",
//                 name, actual, expected
//             );
//         end
//         else begin
//             direct_pass++;
//             $display(
//                 "[DIRECT][PASS] %s value=%08h",
//                 name, actual
//             );
//         end
//     endtask

//     task direct_sample_cov();
//         regfile_txn t = new();

//         t.wb.reg_en   = vif.wb.reg_en;
//         t.wb.rd_addr  = vif.wb.rd_addr;
//         t.wb.rd_data  = vif.wb.rd_data;
//         t.rs1_addr    = vif.rs1_addr;
//         t.rs2_addr    = vif.rs2_addr;
//         t.rs1_data    = vif.rs1_data;
//         t.rs2_data    = vif.rs2_data;

//         env.coverage.sample_direct(t);
//     endtask

//     task automatic direct_write(
//         string name,
//         riscv_reg_e addr,
//         logic [31:0] data
//     );
//         @(negedge vif.clk);
//         vif.wb.reg_en  = 1'b1;
//         vif.wb.rd_addr = addr;
//         vif.wb.rd_data = data;

//         @(posedge vif.clk);
//         #1;

//         direct_sample_cov();
//     endtask

//     task automatic direct_read_check(
//         string name,
//         logic [4:0] addr1,
//         logic [4:0] addr2,
//         logic [31:0] expected1,
//         logic [31:0] expected2
//     );
//         vif.rs1_addr = addr1;
//         vif.rs2_addr = addr2;

//         #1;

//         direct_check(
//             {name, "_RS1"},
//             vif.rs1_data,
//             expected1
//         );

//         direct_check(
//             {name, "_RS2"},
//             vif.rs2_data,
//             expected2
//         );

//         direct_sample_cov();
//     endtask

//     //////////////////////////////////////////
//     // VR-F01: WRITE TESTS 
//     //////////////////////////////////////////

//     task direct_write_read_all();
//         logic [31:0] expected [0:31];

//         // VR-F01-1
//         // Write registers 1..31 with random data.
//         for (int i = 1; i < 32; i++) begin
//             expected[i] = $urandom;
//             direct_write(
//                 $sformatf("VR-F01-1_WRITE_R%0d", i),
//                 i,
//                 expected[i]
//             );
//         end

//         expected[0] = '0;

//         for (int i = 0; i < 32; i++) begin
//             direct_read_check(
//                 $sformatf("VR-F01-1_READ_R%0d", i),
//                 i, i,
//                 expected[i], expected[i]
//             );
//         end
//     endtask

//     task direct_write_disabled();
//         logic [31:0] old_value;
//         logic [31:0] new_value;

//         // VR-F01-2
//         old_value = 32'h12345678;
//         new_value = 32'hEDCBA987;

//         direct_write("VR-F01-2_INIT", 5'd5, old_value);

//         @(negedge vif.clk);
//         vif.reg_en  = 1'b0;
//         vif.rd_addr = 5'd5;
//         vif.rd_data = new_value;

//         @(posedge vif.clk);
//         #1;

//         direct_read_check(
//             "VR-F01-2_NO_WRITE",
//             5'd5, 5'd5,
//             old_value, old_value
//         );
//     endtask

//     task direct_write_all();
//         logic [31:0] expected [0:31];

//         // VR-F01-3
//         expected[0] = '0;

//         for (int i = 1; i < 32; i++) begin
//             expected[i] = $urandom;
//             direct_write(
//                 $sformatf("VR-F01-3_WRITE_R%0d", i),
//                 i, expected[i]
//             );
//         end

//         for (int i = 0; i < 32; i++) begin
//             direct_read_check(
//                 $sformatf("VR-F01-3_READ_R%0d", i),
//                 i, i,
//                 expected[i], expected[i]
//             );
//         end
//     endtask

//     task direct_boundary_values();
//         logic [31:0] values [0:8];
//         logic [31:0] expected [0:31];

//         // VR-F01-4
//         values[0] = 32'h00000000;
//         values[1] = 32'h00000001;
//         values[2] = 32'h7FFFFFFF;
//         values[3] = 32'h80000000;
//         values[4] = 32'hFFFFFFFF;
//         values[5] = 32'hAAAAAAAA;
//         values[6] = 32'h55555555;
//         values[7] = 32'h00000001;
//         values[8] = 32'hFFFFFFFE;

//         for (int i = 1; i < 32; i++) begin
//             expected[i] = '0;
//         end

//         // Fixed boundary patterns.
//         for (int i = 0; i < 7; i++) begin
//             expected[i+1] = values[i];

//             direct_write(
//                 $sformatf("VR-F01-4_BOUNDARY_%0d", i),
//                 i+1, values[i]
//             );
//         end

//         // Walking-1.
//         for (int i = 0; i < 32; i++) begin
//             expected[(i % 31)+1] = 32'h00000001 << i;

//             direct_write(
//                 $sformatf("VR-F01-4_WALKING1_%0d", i),
//                 (i % 31)+1,
//                 32'h00000001 << i
//             );
//         end

//         // Walking-0.
//         for (int i = 0; i < 32; i++) begin
//             expected[(i % 31)+1] = ~(32'h00000001 << i);

//             direct_write(
//                 $sformatf("VR-F01-4_WALKING0_%0d", i),
//                 (i % 31)+1,
//                 ~(32'h00000001 << i)
//             );
//         end

//         for (int i = 1; i < 32; i++) begin
//             direct_read_check(
//                 $sformatf("VR-F01-4_READ_R%0d", i),
//                 i, i,
//                 expected[i], expected[i]
//             );
//         end
//     endtask

//     task direct_same_address();
//         // VR-F01-5
//         direct_write("VR-F01-5_WRITE1", 5'd7, 32'h11111111);
//         direct_write("VR-F01-5_WRITE2", 5'd7, 32'h22222222);
//         direct_write("VR-F01-5_WRITE3", 5'd7, 32'h33333333);
//         direct_write("VR-F01-5_WRITE4", 5'd7, 32'hA5A55A5A);

//         direct_read_check(
//             "VR-F01-5_LAST_WRITE_WINS",
//             5'd7, 5'd7,
//             32'hA5A55A5A, 32'hA5A55A5A
//         );
//     endtask

//     task direct_preserve_other_registers();
//         logic [31:0] expected [0:31];

//         // VR-F01-6
//         expected[0] = '0;

//         for (int i = 1; i < 32; i++) begin
//             expected[i] = 32'h10000000 + i;
//             direct_write(
//                 $sformatf("VR-F01-6_INIT_R%0d", i),
//                 i, expected[i]
//             );
//         end

//         for (int n = 1; n < 32; n++) begin
//             expected[n] = $urandom;

//             direct_write(
//                 $sformatf("VR-F01-6_WRITE_R%0d", n),
//                 n, expected[n]
//             );

//             for (int j = 0; j < 32; j++) begin
//                 direct_read_check(
//                     $sformatf("VR-F01-6_R%0d_AFTER_WRITE_R%0d", j, n),
//                     j, j,
//                     expected[j], expected[j]
//                 );
//             end
//         end
//     endtask

//     //////////////////////////////////////////
//     // VR-F02: READ TESTS
//     //////////////////////////////////////////

//     task direct_dual_port_read();
//         logic [31:0] expected [0:31];

//         // VR-F02-1
//         expected[0] = '0;

//         for (int i = 1; i < 32; i++) begin
//             expected[i] = 32'hA5000000 | i;
//             direct_write(
//                 $sformatf("VR-F02-1_WRITE_R%0d", i),
//                 i, expected[i]
//             );
//         end

//         for (int i = 0; i < 32; i++) begin
//             for (int j = 0; j < 32; j++) begin
//                 direct_read_check(
//                     $sformatf("VR-F02-1_R%0d_R%0d", i, j),
//                     i, j,
//                     expected[i], expected[j]
//                 );
//             end
//         end
//     endtask

//     task direct_read_boundaries();
//         // VR-F02-2
//         direct_boundary_values();
//     endtask

//     task direct_async_read();
//         logic [31:0] expected [0:3];

//         // VR-F02-3
//         direct_write("VR-F02-3_INIT1", 5'd1, 32'h11111111);
//         direct_write("VR-F02-3_INIT2", 5'd2, 32'h22222222);
//         direct_write("VR-F02-3_INIT3", 5'd3, 32'h33333333);
//         direct_write("VR-F02-3_INIT4", 5'd4, 32'h44444444);

//         expected[0] = 32'h11111111;
//         expected[1] = 32'h22222222;
//         expected[2] = 32'h33333333;
//         expected[3] = 32'h44444444;

//         for (int i = 0; i < 4; i++) begin
//             vif.rs1_addr = i + 1;
//             #1;

//             direct_check(
//                 $sformatf("VR-F02-3_ASYNC_READ_%0d", i),
//                 vif.rs1_data, expected[i]
//             );
//         end
//     endtask

//     task direct_read_write_same_cycle();
//         // VR-F02-4
//         direct_write("VR-F02-4_INIT", 5'd10, 32'h12345678);

//         @(negedge vif.clk);
//         vif.reg_en   = 1'b1;
//         vif.rd_addr  = 5'd10;
//         vif.rd_data  = 32'h87654321;
//         vif.rs1_addr = 5'd10;
//         vif.rs2_addr = 5'd10;

//         #1;

//         // Asynchronous read ports normally see the old value
//         // before the active write edge.
//         direct_check(
//             "VR-F02-4_BEFORE_WRITE",
//             vif.rs1_data, 32'h12345678
//         );

//         @(posedge vif.clk);
//         #1;

//         direct_check(
//             "VR-F02-4_AFTER_WRITE_RS1",
//             vif.rs1_data, 32'h87654321
//         );

//         direct_check(
//             "VR-F02-4_AFTER_WRITE_RS2",
//             vif.rs2_data, 32'h87654321
//         );
//     endtask

//     task direct_read_next_cycle();
//         // VR-F02-5
//         direct_write("VR-F02-5_WRITE", 5'd11, 32'hCAFEBABE);

//         @(negedge vif.clk);
//         vif.reg_en = 1'b0;

//         @(posedge vif.clk);
//         #1;

//         direct_read_check(
//             "VR-F02-5_READ_NEXT_CYCLE",
//             5'd11, 5'd11,
//             32'hCAFEBABE, 32'hCAFEBABE
//         );
//     endtask

//     task direct_same_read_address();
//         // VR-F02-6
//         direct_write("VR-F02-6_WRITE", 5'd12, 32'hDEADBEEF);

//         direct_read_check(
//             "VR-F02-6_SAME_ADDRESS",
//             5'd12, 5'd12,
//             32'hDEADBEEF, 32'hDEADBEEF
//         );
//     endtask

//     //////////////////////////////////////////
//     // VR-F03: RESET TESTS
//     //////////////////////////////////////////

//     task direct_reset_all();
//         // VR-F03-1
//         for (int i = 1; i < 32; i++) begin
//             direct_write(
//                 $sformatf("VR-F03-1_INIT_R%0d", i),
//                 i, $urandom
//             );
//         end

//         @(negedge vif.clk);
//         vif.reg_en = 1'b0;
//         vif.rst_n = 1'b0;

//         repeat (2) @(posedge vif.clk);
//         #1;

//         for (int i = 0; i < 32; i++) begin
//             direct_read_check(
//                 $sformatf("VR-F03-1_RESET_R%0d", i),
//                 i, i,
//                 32'h00000000, 32'h00000000
//             );
//         end

//         @(negedge vif.clk);
//         vif.rst_n = 1'b1;
//     endtask

//     task direct_reset_during_write();
//         // VR-F03-2
//         @(negedge vif.clk);
//         vif.reg_en  = 1'b1;
//         vif.rd_addr = 5'd15;
//         vif.rd_data = 32'hFFFFFFFF;

//         vif.rst_n = 1'b0;

//         repeat (2) @(posedge vif.clk);
//         #1;

//         direct_read_check(
//             "VR-F03-2_RESET_DURING_WRITE",
//             5'd15, 5'd15,
//             32'h00000000, 32'h00000000
//         );

//         @(negedge vif.clk);
//         vif.rst_n = 1'b1;
//         vif.reg_en = 1'b0;
//     endtask

//     task direct_reset_duration();
//         // VR-F03-3: Long reset.
//         @(negedge vif.clk);
//         vif.reg_en = 1'b0;
//         vif.rst_n = 1'b0;

//         repeat (4) @(posedge vif.clk);
//         @(negedge vif.clk);
//         vif.rst_n = 1'b1;

//         // Short reset pulse: shorter than one clock period.
//         #1;
//         vif.rst_n = 1'b0;
//         #1;
//         vif.rst_n = 1'b1;

//         #1;

//         // For asynchronous reset, a short pulse should clear state.
//         direct_read_check(
//             "VR-F03-3_SHORT_RESET",
//             5'd1, 5'd1,
//             32'h00000000, 32'h00000000
//         );
//     endtask

//     task direct_write_after_reset();
//         // VR-F03-4
//         direct_write("VR-F03-4_WRITE", 5'd20, 32'hABCDEF01);

//         direct_read_check(
//             "VR-F03-4_READ",
//             5'd20, 5'd20,
//             32'hABCDEF01, 32'hABCDEF01
//         );
//     endtask

//     //////////////////////////////////////////
//     // VR-F04: x0 TESTS
//     //////////////////////////////////////////

//     task direct_write_x0();
//         logic [31:0] values [0:4];

//         // VR-F04-1
//         values[0] = 32'h00000001;
//         values[1] = 32'hFFFFFFFF;
//         values[2] = 32'hAAAAAAAA;
//         values[3] = 32'h55555555;
//         values[4] = 32'h80000000;

//         for (int i = 0; i < 5; i++) begin
//             direct_write(
//                 $sformatf("VR-F04-1_WRITE_X0_%0d", i),
//                 5'd0, values[i]
//             );

//             direct_read_check(
//                 $sformatf("VR-F04-1_READ_X0_%0d", i),
//                 5'd0, 5'd0,
//                 32'h00000000, 32'h00000000
//             );
//         end
//     endtask

//     task direct_read_x0();
//         // VR-F04-2
//         direct_read_check(
//             "VR-F04-2_READ_X0",
//             5'd0, 5'd0,
//             32'h00000000, 32'h00000000
//         );
//     endtask

//     //////////////////////////////////////////
//     // RUN DIRECT TESTS
//     //////////////////////////////////////////

//     task run_direct_tests();
//         direct_pass = 0;
//         direct_fail = 0;

//         direct_idle();

//         // Release reset before testing.
//         vif.rst_n = 1'b1;
//         #1;

//         direct_write_read_all();
//         direct_write_disabled();
//         direct_write_all();
//         direct_boundary_values();
//         direct_same_address();
//         direct_preserve_other_registers();

//         direct_dual_port_read();
//         direct_read_boundaries();
//         direct_async_read();
//         direct_read_write_same_cycle();
//         direct_read_next_cycle();
//         direct_same_read_address();

//         direct_reset_all();
//         direct_reset_during_write();
//         direct_reset_duration();
//         direct_write_after_reset();

//         direct_write_x0();
//         direct_read_x0();

//         $display("========================================");
//         $display(
//             "[DIRECT] PASS=%0d FAIL=%0d",
//             direct_pass, direct_fail
//         );
//         $display("========================================");

//         if (direct_fail != 0)
//             $fatal(1, "[DIRECT] TEST FAILED: %0d failures", direct_fail);
//         else
//             $display("[DIRECT] ALL TESTS PASSED");
//     endtask

//     //////////////////////////////////////////
//     // RANDOM OOP TEST
//     //////////////////////////////////////////

//     task run_random_tests();
//         $display("");
//         $display("============================================================");
//         $display("                  REGFILE OOP RANDOM TEST");
//         $display("============================================================");

//         direct_idle();
//         env.run();

//         repeat (5) @(posedge vif.clk);
//         #1;

//         $display("[OOP] Random generation completed.");
//     endtask

//     //////////////////////////////////////////
//     // FINAL REPORT
//     //////////////////////////////////////////

//     task report();
//         $display("");
//         $display("============================================================");
//         $display("                  REGFILE FINAL REPORT");
//         $display("============================================================");

//         $display(
//             "[DIRECT] PASS=%0d FAIL=%0d",
//             direct_pass, direct_fail
//         );

//         env.coverage.report();

//         if ((direct_fail == 0) && (env.scoreboard.fail == 0))
//             $display("[FINAL] FUNCTIONAL CHECKING = PASS");
//         else
//             $display("[FINAL] FUNCTIONAL CHECKING = FAIL");

//         $display("============================================================");
//     endtask

//     task run();
//         run_direct_tests();
//         run_random_tests();
//         report();
//     endtask

// endclass




















// import regfile_pkg::*;
import isa_pkg::*;


class regfile_test;

    virtual regfile_if vif;
    regfile_env env;

    int direct_pass = 0;
    int direct_fail = 0;
    int num_txn;

    function new(virtual regfile_if vif, int num_txn);
        this.vif = vif;
        this.num_txn = num_txn;
        env = new(vif, num_txn);
    endfunction

    //////////////////////////////////////////
    // DIRECT_TEST
    //////////////////////////////////////////

    task direct_idle();
        vif.wb.reg_en  = '0;
        vif.wb.rd_addr = riscv_reg_e'(0);
        vif.wb.rd_data = '0;
        vif.rs1_addr = riscv_reg_e'(0);
        vif.rs2_addr = riscv_reg_e'(0);
    endtask

    task direct_check(
        string name,
        logic [31:0] actual,
        logic [31:0] expected
    );
        if (actual !== expected) begin
            direct_fail++;
            $error(
                "[DIRECT][FAIL] %s actual=%08h expected=%08h",
                name, actual, expected
            );
        end
        else begin
            direct_pass++;
            // $display(
            //     "[DIRECT][PASS] %s value=%08h",
            //     name, actual
            // );
        end
    endtask

    task direct_sample_cov();
        regfile_txn t = new();

        t.wb.reg_en   = vif.wb.reg_en;
        t.wb.rd_addr  = vif.wb.rd_addr;
        t.wb.rd_data  = vif.wb.rd_data;
        t.rs1_addr    = vif.rs1_addr;
        t.rs2_addr    = vif.rs2_addr;
        t.rs1_data    = vif.rs1_data;
        t.rs2_data    = vif.rs2_data;

        env.coverage.sample_direct(t);
    endtask

    task automatic direct_write(
        string name,
        riscv_reg_e addr,
        logic [31:0] data
    );
        @(negedge vif.clk);
        vif.wb.reg_en  = 1'b1;
        vif.wb.rd_addr = addr;
        vif.wb.rd_data = data;

        @(posedge vif.clk);
        #1;

        direct_sample_cov();
    endtask

    task automatic direct_read_check(
        string name,
        riscv_reg_e addr1,
        riscv_reg_e addr2,
        logic [31:0] expected1,
        logic [31:0] expected2
    );
        vif.rs1_addr = addr1;
        vif.rs2_addr = addr2;

        #1;

        direct_check(
            {name, "_RS1"},
            vif.rs1_data,
            expected1
        );

        direct_check(
            {name, "_RS2"},
            vif.rs2_data,
            expected2
        );

        direct_sample_cov();
    endtask

    //////////////////////////////////////////
    // VR-F01: WRITE TESTS 
    //////////////////////////////////////////

    task direct_write_read_all();
        logic [31:0] expected [0:31];

        // VR-F01-1
        // Write registers 1..31 with random data.
        for (int i = 1; i < 32; i++) begin
            expected[i] = $urandom;
            direct_write(
                $sformatf("VR-F01-1_WRITE_R%0d", i),
                riscv_reg_e'(i),
                expected[i]
            );
        end

        expected[0] = '0;

        for (int i = 0; i < 32; i++) begin
            direct_read_check(
                $sformatf("VR-F01-1_READ_R%0d", i),
                riscv_reg_e'(i), riscv_reg_e'(i),
                expected[i], expected[i]
            );
        end
    endtask

    task direct_write_disabled();
        logic [31:0] old_value;
        logic [31:0] new_value;

        // VR-F01-2
        old_value = 32'h12345678;
        new_value = 32'hEDCBA987;

        direct_write("VR-F01-2_INIT", riscv_reg_e'(5'd5), old_value);

        @(negedge vif.clk);
        vif.wb.reg_en  = 1'b0;
        vif.wb.rd_addr = riscv_reg_e'(5'd5);
        vif.wb.rd_data = new_value;

        @(posedge vif.clk);
        #1;

        direct_read_check(
            "VR-F01-2_NO_WRITE",
            riscv_reg_e'(5'd5), riscv_reg_e'(5'd5),
            old_value, old_value
        );
    endtask

    task direct_write_all();
        logic [31:0] expected [0:31];

        // VR-F01-3
        expected[0] = '0;

        for (int i = 1; i < 32; i++) begin
            expected[i] = $urandom;
            direct_write(
                $sformatf("VR-F01-3_WRITE_R%0d", i),
                riscv_reg_e'(i), expected[i]
            );
        end

        for (int i = 0; i < 32; i++) begin
            direct_read_check(
                $sformatf("VR-F01-3_READ_R%0d", i),
                riscv_reg_e'(i), riscv_reg_e'(i),
                expected[i], expected[i]
            );
        end
    endtask

    task direct_boundary_values();
        logic [31:0] values [0:8];
        logic [31:0] expected [0:31];

        // VR-F01-4
        values[0] = 32'h00000000;
        values[1] = 32'h00000001;
        values[2] = 32'h7FFFFFFF;
        values[3] = 32'h80000000;
        values[4] = 32'hFFFFFFFF;
        values[5] = 32'hAAAAAAAA;
        values[6] = 32'h55555555;
        values[7] = 32'h00000001;
        values[8] = 32'hFFFFFFFE;

        for (int i = 1; i < 32; i++) begin
            expected[i] = '0;
        end

        // Fixed boundary patterns.
        for (int i = 0; i < 7; i++) begin
            expected[i+1] = values[i];

            direct_write(
                $sformatf("VR-F01-4_BOUNDARY_%0d", i),
                riscv_reg_e'(i+1), values[i]
            );
        end

        // Walking-1.
        for (int i = 0; i < 32; i++) begin
            expected[(i % 31)+1] = 32'h00000001 << i;

            direct_write(
                $sformatf("VR-F01-4_WALKING1_%0d", i),
                riscv_reg_e'((i % 31)+1),
                32'h00000001 << i
            );
        end

        // Walking-0.
        for (int i = 0; i < 32; i++) begin
            expected[(i % 31)+1] = ~(32'h00000001 << i);

            direct_write(
                $sformatf("VR-F01-4_WALKING0_%0d", i),
                riscv_reg_e'((i % 31)+1),
                ~(32'h00000001 << i)
            );
        end

        for (int i = 1; i < 32; i++) begin
            direct_read_check(
                $sformatf("VR-F01-4_READ_R%0d", i),
                riscv_reg_e'(i), riscv_reg_e'(i),
                expected[i], expected[i]
            );
        end
    endtask

    task direct_same_address();
        // VR-F01-5
        direct_write("VR-F01-5_WRITE1", riscv_reg_e'(5'd7), 32'h11111111);
        direct_write("VR-F01-5_WRITE2", riscv_reg_e'(5'd7), 32'h22222222);
        direct_write("VR-F01-5_WRITE3", riscv_reg_e'(5'd7), 32'h33333333);
        direct_write("VR-F01-5_WRITE4", riscv_reg_e'(5'd7), 32'hA5A55A5A);

        direct_read_check(
            "VR-F01-5_LAST_WRITE_WINS",
            riscv_reg_e'(5'd7), riscv_reg_e'(5'd7),
            32'hA5A55A5A, 32'hA5A55A5A
        );
    endtask

    task direct_preserve_other_registers();
        logic [31:0] expected [0:31];

        // VR-F01-6
        expected[0] = '0;

        for (int i = 1; i < 32; i++) begin
            expected[i] = 32'h10000000 + i;
            direct_write(
                $sformatf("VR-F01-6_INIT_R%0d", i),
                riscv_reg_e'(i), expected[i]
            );
        end

        for (int n = 1; n < 32; n++) begin
            expected[n] = $urandom;

            direct_write(
                $sformatf("VR-F01-6_WRITE_R%0d", n),
                riscv_reg_e'(n), expected[n]
            );

            for (int j = 0; j < 32; j++) begin
                direct_read_check(
                    $sformatf("VR-F01-6_R%0d_AFTER_WRITE_R%0d", j, n),
                    riscv_reg_e'(j), riscv_reg_e'(j),
                    expected[j], expected[j]
                );
            end
        end
    endtask

    //////////////////////////////////////////
    // VR-F02: READ TESTS
    //////////////////////////////////////////

    task direct_dual_port_read();
        logic [31:0] expected [0:31];

        // VR-F02-1
        expected[0] = '0;

        for (int i = 1; i < 32; i++) begin
            expected[i] = 32'hA5000000 | i;
            direct_write(
                $sformatf("VR-F02-1_WRITE_R%0d", i),
                riscv_reg_e'(i), expected[i]
            );
        end

        for (int i = 0; i < 32; i++) begin
            for (int j = 0; j < 32; j++) begin
                direct_read_check(
                    $sformatf("VR-F02-1_R%0d_R%0d", i, j),
                    riscv_reg_e'(i), riscv_reg_e'(j),
                    expected[i], expected[j]
                );
            end
        end
    endtask

    task direct_read_boundaries();
        // VR-F02-2
        direct_boundary_values();
    endtask

    task direct_async_read();
        logic [31:0] expected [0:3];

        // VR-F02-3
        direct_write("VR-F02-3_INIT1", riscv_reg_e'(5'd1), 32'h11111111);
        direct_write("VR-F02-3_INIT2", riscv_reg_e'(5'd2), 32'h22222222);
        direct_write("VR-F02-3_INIT3", riscv_reg_e'(5'd3), 32'h33333333);
        direct_write("VR-F02-3_INIT4", riscv_reg_e'(5'd4), 32'h44444444);

        expected[0] = 32'h11111111;
        expected[1] = 32'h22222222;
        expected[2] = 32'h33333333;
        expected[3] = 32'h44444444;

        for (int i = 0; i < 4; i++) begin
            vif.rs1_addr = riscv_reg_e'(i + 1);
            #1;

            direct_check(
                $sformatf("VR-F02-3_ASYNC_READ_%0d", i),
                vif.rs1_data, expected[i]
            );
        end
    endtask

    task direct_read_write_same_cycle();
        // VR-F02-4
        direct_write("VR-F02-4_INIT", riscv_reg_e'(5'd10), 32'h12345678);

        @(negedge vif.clk);
        vif.wb.reg_en   = 1'b1;
        vif.wb.rd_addr  = riscv_reg_e'(5'd10);
        vif.wb.rd_data  = 32'h87654321;
        vif.rs1_addr = riscv_reg_e'(5'd10);
        vif.rs2_addr = riscv_reg_e'(5'd10);

        #1;

        // Asynchronous read ports normally see the old value
        // before the active write edge.
        direct_check(
            "VR-F02-4_BEFORE_WRITE",
            vif.rs1_data, 32'h12345678
        );

        @(posedge vif.clk);
        #1;

        direct_check(
            "VR-F02-4_AFTER_WRITE_RS1",
            vif.rs1_data, 32'h87654321
        );

        direct_check(
            "VR-F02-4_AFTER_WRITE_RS2",
            vif.rs2_data, 32'h87654321
        );
    endtask

    task direct_read_next_cycle();
        // VR-F02-5
        direct_write("VR-F02-5_WRITE", riscv_reg_e'(5'd11), 32'hCAFEBABE);

        @(negedge vif.clk);
        vif.wb.reg_en = 1'b0;

        @(posedge vif.clk);
        #1;

        direct_read_check(
            "VR-F02-5_READ_NEXT_CYCLE",
            riscv_reg_e'(5'd11), riscv_reg_e'(5'd11),
            32'hCAFEBABE, 32'hCAFEBABE
        );
    endtask

    task direct_same_read_address();
        // VR-F02-6
        direct_write("VR-F02-6_WRITE", riscv_reg_e'(5'd12), 32'hDEADBEEF);

        direct_read_check(
            "VR-F02-6_SAME_ADDRESS",
            riscv_reg_e'(5'd12), riscv_reg_e'(5'd12),
            32'hDEADBEEF, 32'hDEADBEEF
        );
    endtask

    //////////////////////////////////////////
    // VR-F03: RESET TESTS
    //////////////////////////////////////////

    task direct_reset_all();
        // VR-F03-1
        for (int i = 1; i < 32; i++) begin
            direct_write(
                $sformatf("VR-F03-1_INIT_R%0d", i),
                riscv_reg_e'(i), $urandom
            );
        end

        @(negedge vif.clk);
        vif.wb.reg_en = 1'b0;
        vif.rst_n = 1'b0;

        repeat (2) @(posedge vif.clk);
        #1;

        for (int i = 0; i < 32; i++) begin
            direct_read_check(
                $sformatf("VR-F03-1_RESET_R%0d", i),
                riscv_reg_e'(i), riscv_reg_e'(i),
                32'h00000000, 32'h00000000
            );
        end

        @(negedge vif.clk);
        vif.rst_n = 1'b1;
    endtask

    task direct_reset_during_write();
        // VR-F03-2
        @(negedge vif.clk);
        vif.wb.reg_en  = 1'b1;
        vif.wb.rd_addr = riscv_reg_e'(5'd15);
        vif.wb.rd_data = 32'hFFFFFFFF;

        vif.rst_n = 1'b0;

        repeat (2) @(posedge vif.clk);
        #1;

        direct_read_check(
            "VR-F03-2_RESET_DURING_WRITE",
            riscv_reg_e'(5'd15), riscv_reg_e'(5'd15),
            32'h00000000, 32'h00000000
        );

        @(negedge vif.clk);
        vif.rst_n = 1'b1;
        vif.wb.reg_en = 1'b0;
    endtask

    task direct_reset_duration();
        // VR-F03-3: Long reset.
        @(negedge vif.clk);
        vif.wb.reg_en = 1'b0;
        vif.rst_n = 1'b0;

        repeat (4) @(posedge vif.clk);
        @(negedge vif.clk);
        vif.rst_n = 1'b1;

        // Short reset pulse: shorter than one clock period.
        #1;
        vif.rst_n = 1'b0;
        #1;
        vif.rst_n = 1'b1;

        #1;

        // For asynchronous reset, a short pulse should clear state.
        direct_read_check(
            "VR-F03-3_SHORT_RESET",
            riscv_reg_e'(5'd1), riscv_reg_e'(5'd1),
            32'h00000000, 32'h00000000
        );
    endtask

    task direct_write_after_reset();
        // VR-F03-4
        direct_write("VR-F03-4_WRITE", riscv_reg_e'(5'd20), 32'hABCDEF01);

        direct_read_check(
            "VR-F03-4_READ",
            riscv_reg_e'(5'd20), riscv_reg_e'(5'd20),
            32'hABCDEF01, 32'hABCDEF01
        );
    endtask

    //////////////////////////////////////////
    // VR-F04: x0 TESTS
    //////////////////////////////////////////

    task direct_write_x0();
        logic [31:0] values [0:4];

        // VR-F04-1
        values[0] = 32'h00000001;
        values[1] = 32'hFFFFFFFF;
        values[2] = 32'hAAAAAAAA;
        values[3] = 32'h55555555;
        values[4] = 32'h80000000;

        for (int i = 0; i < 5; i++) begin
            direct_write(
                $sformatf("VR-F04-1_WRITE_X0_%0d", i),
                riscv_reg_e'(5'd0), values[i]
            );

            direct_read_check(
                $sformatf("VR-F04-1_READ_X0_%0d", i),
                riscv_reg_e'(5'd0), riscv_reg_e'(5'd0),
                32'h00000000, 32'h00000000
            );
        end
    endtask

    task direct_read_x0();
        // VR-F04-2
        direct_read_check(
            "VR-F04-2_READ_X0",
            riscv_reg_e'(5'd0), riscv_reg_e'(5'd0),
            32'h00000000, 32'h00000000
        );
    endtask

    //////////////////////////////////////////
    // RUN DIRECT TESTS
    //////////////////////////////////////////

    task run_direct_tests();
        direct_pass = 0;
        direct_fail = 0;

        direct_idle();

        // Release reset before testing.
        vif.rst_n = 1'b1;
        #1;

        direct_write_read_all();
        direct_write_disabled();
        direct_write_all();
        direct_boundary_values();
        direct_same_address();
        direct_preserve_other_registers();

        direct_dual_port_read();
        direct_read_boundaries();
        direct_async_read();
        direct_read_write_same_cycle();
        direct_read_next_cycle();
        direct_same_read_address();

        direct_reset_all();
        direct_reset_during_write();
        direct_reset_duration();
        direct_write_after_reset();

        direct_write_x0();
        direct_read_x0();

        $display("========================================");
        $display(
            "[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass, direct_fail
        );
        $display("========================================");

        if (direct_fail != 0)
            $fatal(1, "[DIRECT] TEST FAILED: %0d failures", direct_fail);
        else
            $display("[DIRECT] ALL TESTS PASSED");
    endtask

    //////////////////////////////////////////
    // RANDOM OOP TEST
    //////////////////////////////////////////

    task run_random_tests();
        $display("");
        $display("============================================================");
        $display("                  REGFILE OOP RANDOM TEST");
        $display("============================================================");

        direct_idle();
        env.run();

        repeat (5) @(posedge vif.clk);
        #1;

        $display("[OOP] Random generation completed.");
    endtask

    //////////////////////////////////////////
    // FINAL REPORT
    //////////////////////////////////////////

    task report();
        $display("");
        $display("============================================================");
        $display("                  REGFILE FINAL REPORT");
        $display("============================================================");

        $display(
            "[DIRECT] PASS=%0d FAIL=%0d",
            direct_pass, direct_fail
        );

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