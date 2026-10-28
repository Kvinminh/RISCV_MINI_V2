// import core_pkg::*;
// import ctrl_pkg::*;
// import isa_pkg::*;
// // import alu_pkg::*;

// class alu_cov;
// mailbox #(alu_txn) mon2cov;


// int sample_cnt = 0;
// real goal = 100.0;

// covergroup cg_alu_ctrl with function sample(alu_txn txn);
//     option.per_instance = 1;

//     // VR-F02-1 -> VR-F02-39: ALU operation coverage
//     cp_alu_ctrl : coverpoint txn.alu_ctrl {
//         bins add  = {ALU_ADD};
//         bins sub  = {ALU_SUB};
//         bins and_ = {ALU_AND};
//         bins or_  = {ALU_OR};
//         bins xor_ = {ALU_XOR};
//         bins sll  = {ALU_SLL};
//         bins srl  = {ALU_SRL};

//         // SLT, SLTU, SRA chua implement: van can sample de kiem tra default
//         // bins slt  = {ALU_SLT};
//         // bins sltu = {ALU_SLTU};
//         // bins sra  = {ALU_SRA};
//     }

//     // ---------- ADD: operand boundaries ----------
//     cp_add_a : coverpoint txn.A iff (txn.alu_ctrl == ALU_ADD) {
//         bins zero     = {32'h00000000};
//         bins one      = {32'h00000001};
//         bins all_ones = {32'hFFFFFFFF};
//         bins max_pos  = {32'h7FFFFFFF};
//         bins min_neg  = {32'h80000000};
//         bins other    = default;
//     }

//     cp_add_b : coverpoint txn.B iff (txn.alu_ctrl == ALU_ADD) {
//         bins zero     = {32'h00000000};
//         bins one      = {32'h00000001};
//         bins all_ones = {32'hFFFFFFFF};
//         bins max_pos  = {32'h7FFFFFFF};
//         bins min_neg  = {32'h80000000};
//         bins other    = default;
//     }

//     x_add_corner : cross cp_add_a, cp_add_b;

//     // ---------- SUB: operand boundaries ----------
//     cp_sub_a : coverpoint txn.A iff (txn.alu_ctrl == ALU_SUB) {
//         bins zero     = {32'h00000000};
//         bins one      = {32'h00000001};
//         bins all_ones = {32'hFFFFFFFF};
//         bins max_pos  = {32'h7FFFFFFF};
//         bins min_neg  = {32'h80000000};
//         bins other    = default;
//     }

//     cp_sub_b : coverpoint txn.B iff (txn.alu_ctrl == ALU_SUB) {
//         bins zero     = {32'h00000000};
//         bins one      = {32'h00000001};
//         bins all_ones = {32'hFFFFFFFF};
//         bins max_pos  = {32'h7FFFFFFF};
//         bins min_neg  = {32'h80000000};
//         bins other    = default;
//     }

//     x_sub_corner : cross cp_sub_a, cp_sub_b;

//     // ---------- Logic: operand patterns ----------
//     cp_logic_a : coverpoint txn.A
//         iff (txn.alu_ctrl inside {ALU_AND, ALU_OR, ALU_XOR}) {
//         bins zero       = {32'h00000000};
//         bins all_ones   = {32'hFFFFFFFF};
//         bins pattern_a  = {32'hAAAAAAAA};
//         bins pattern_5  = {32'h55555555};
//         bins one        = {32'h00000001};
//         bins other      = default;
//     }

//     cp_logic_b : coverpoint txn.B
//         iff (txn.alu_ctrl inside {ALU_AND, ALU_OR, ALU_XOR}) {
//         bins zero       = {32'h00000000};
//         bins all_ones   = {32'hFFFFFFFF};
//         bins pattern_a  = {32'hAAAAAAAA};
//         bins pattern_5  = {32'h55555555};
//         bins one        = {32'h00000001};
//         bins other      = default;
//     }

//     cp_logic_op : coverpoint txn.alu_ctrl
//         iff (txn.alu_ctrl inside {ALU_AND, ALU_OR, ALU_XOR}) {
//         bins and_ = {ALU_AND};
//         bins or_  = {ALU_OR};
//         bins xor_ = {ALU_XOR};
//     }

//     x_logic_pattern : cross cp_logic_op, cp_logic_a, cp_logic_b;

//     // ---------- Shift: shamt boundaries ----------
//     cp_shamt_low : coverpoint txn.B[4:0]
//         iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
//         bins zero  = {0};
//         bins one   = {1};
//         bins two   = {2};
//         bins max   = {31};
//         bins other = {[3:30]};
//     }

//     cp_shamt_high : coverpoint (txn.B[31:5] != 0)
//         iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
//         bins zero_high    = {0};
//         bins nonzero_high = {1};
//     }

//     cp_shift_op : coverpoint txn.alu_ctrl
//         iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
//         bins sll = {ALU_SLL};
//         bins srl = {ALU_SRL};
//     }

//     x_shamt_mask : cross cp_shift_op, cp_shamt_low, cp_shamt_high;

//     // ---------- Shift: A sign and bit patterns ----------
//     cp_shift_a_sign : coverpoint txn.A[31]
//         iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
//         bins msb_zero = {0};
//         bins msb_one  = {1};
//     }

//     x_shift_sign : cross cp_shift_op, cp_shift_a_sign;

//     // ---------- Walking-1: input A ----------
//     cp_walking_one_a : coverpoint txn.A
//         iff (txn.alu_ctrl inside {ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL}) {
//         bins walking_one[] = {
//             32'h00000001, 32'h00000002, 32'h00000004, 32'h00000008,
//             32'h00000010, 32'h00000020, 32'h00000040, 32'h00000080,
//             32'h00000100, 32'h00000200, 32'h00000400, 32'h00000800,
//             32'h00001000, 32'h00002000, 32'h00004000, 32'h00008000,
//             32'h00010000, 32'h00020000, 32'h00040000, 32'h00080000,
//             32'h00100000, 32'h00200000, 32'h00400000, 32'h00800000,
//             32'h01000000, 32'h02000000, 32'h04000000, 32'h08000000,
//             32'h10000000, 32'h20000000, 32'h40000000, 32'h80000000
//         };
//         bins other = default;
//     }

//     x_walking_one : cross cp_shift_op, cp_walking_one_a;

//     // ---------- SUB: comparison and borrow ----------
//     cp_sub_cmp : coverpoint {txn.A == txn.B, txn.A < txn.B}
//         iff (txn.alu_ctrl == ALU_SUB) {
//         bins a_lt_b = {2'b01};
//         bins a_eq_b = {2'b10};
//         bins a_gt_b = {2'b00};
//     }

//     // ---------- Result zero/nonzero ----------
//     cp_res_zero : coverpoint (txn.alu == 32'h00000000) {
//         bins zero    = {1};
//         bins nonzero = {0};
//     }

//     x_res_zero : cross cp_alu_ctrl, cp_res_zero;

// endgroup

// //Constructor
// function new(mailbox #(alu_txn) mon2cov);
//     this.mon2cov = mon2cov;
//     cg_alu_ctrl = new();
// endfunction

// // Sampling truc tiep tu direct test
// // 
// function void sample_direct(alu_txn txn);
//     cg_alu_ctrl.sample(txn);
//     sample_cnt++;
// endfunction

// // Sampling transaction tu monitor
// task run();
//     alu_txn txn;

//     forever begin
//         mon2cov.get(txn);
//         cg_alu_ctrl.sample(txn);
//         sample_cnt++;
//     end
// endtask

// function void print_item(string id, string name, real cov);
//     $display("  %-10s %-24s : %6.2f%%", id, name, cov);
// endfunction

// function void report();
//     real total;

//     total = cg_alu_ctrl.get_inst_coverage();

//     $display("==================================================");
//     $display("         ALU FUNCTIONAL COVERAGE REPORT");
//     $display("==================================================");
//     $display("  Transactions sampled : %0d", sample_cnt);
//     $display("--------------------------------------------------");

//     //  print_item("ALU-01", "cp_alu_ctrl",
//     //             cg_alu_ctrl.cp_alu_ctrl.get_inst_coverage());

//     print_item("ALU-02", "x_add_corner",
//                cg_alu_ctrl.x_add_corner.get_inst_coverage());

//     // print_item("ALU-03", "x_sub_corner",
//     //            cg_alu_ctrl.x_sub_corner.get_inst_coverage());

//     // print_item("ALU-04", "x_logic_pattern",
//     //            cg_alu_ctrl.x_logic_pattern.get_inst_coverage());

//     // print_item("ALU-05", "x_shamt_mask",
//     //            cg_alu_ctrl.x_shamt_mask.get_inst_coverage());

//     // print_item("ALU-06", "x_shift_sign",
//     //            cg_alu_ctrl.x_shift_sign.get_inst_coverage());

//     // print_item("ALU-07", "x_walking_one",
//     //            cg_alu_ctrl.x_walking_one.get_inst_coverage());

//     // print_item("ALU-08", "cp_sub_cmp",
//     //            cg_alu_ctrl.cp_sub_cmp.get_inst_coverage());

//     // print_item("ALU-09", "x_res_zero",
//     //            cg_alu_ctrl.x_res_zero.get_inst_coverage());

    
//     $display("--------------------------------------------------");
//     $display("  TOTAL (cg_alu_ctrl) : %6.2f%% (goal %0.1f%%)",
//              total, goal);
//     $display("  RESULT              : %s",
//              (total >= goal) ? "PASS" : "FAIL");
//     $display("==================================================");
// endfunction

// endclass



























import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;

class alu_cov;

    mailbox #(alu_txn) mon2cov;

    int sample_cnt = 0;
    real goal = 90.0;

    // ==================================================
    // CG-01: ALU operation coverage
    // ==================================================
    covergroup cg_alu_op with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_alu_ctrl : coverpoint txn.alu_ctrl {
            bins add  = {ALU_ADD};
            bins sub  = {ALU_SUB};
            bins and_ = {ALU_AND};
            bins or_  = {ALU_OR};
            bins xor_ = {ALU_XOR};
            bins sll  = {ALU_SLL};
            bins srl  = {ALU_SRL};
        }
    endgroup


    // ==================================================
    // CG-02: ADD corner cases
    // ==================================================
    covergroup cg_add with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_add_a : coverpoint txn.A
            iff (txn.alu_ctrl == ALU_ADD) {
            bins zero     = {32'h00000000};
            bins one      = {32'h00000001};
            bins all_ones = {32'hFFFFFFFF};
            bins max_pos  = {32'h7FFFFFFF};
            bins min_neg  = {32'h80000000};
            bins other    = default;
        }

        cp_add_b : coverpoint txn.B
            iff (txn.alu_ctrl == ALU_ADD) {
            bins zero     = {32'h00000000};
            bins one      = {32'h00000001};
            bins all_ones = {32'hFFFFFFFF};
            bins max_pos  = {32'h7FFFFFFF};
            bins min_neg  = {32'h80000000};
            bins other    = default;
        }

        x_add_corner : cross cp_add_a, cp_add_b;
    endgroup


    // ==================================================
    // CG-03: SUB corner cases + comparison
    // ==================================================
    covergroup cg_sub with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_sub_a : coverpoint txn.A
            iff (txn.alu_ctrl == ALU_SUB) {
            bins zero     = {32'h00000000};
            bins one      = {32'h00000001};
            bins all_ones = {32'hFFFFFFFF};
            bins max_pos  = {32'h7FFFFFFF};
            bins min_neg  = {32'h80000000};
            bins other    = default;
        }

        cp_sub_b : coverpoint txn.B
            iff (txn.alu_ctrl == ALU_SUB) {
            bins zero     = {32'h00000000};
            bins one      = {32'h00000001};
            bins all_ones = {32'hFFFFFFFF};
            bins max_pos  = {32'h7FFFFFFF};
            bins min_neg  = {32'h80000000};
            bins other    = default;
        }

        x_sub_corner : cross cp_sub_a, cp_sub_b;

        // cp_sub_cmp : coverpoint {
        //     (txn.A == txn.B), (txn.A < txn.B)
        // } iff (txn.alu_ctrl == ALU_SUB) {
        //     bins a_lt_b = {2'b01};
        //     bins a_eq_b = {2'b10};
        //     bins a_gt_b = {2'b00};
        // }
    endgroup


    // ==================================================
    // CG-04: Logic operation patterns
    // ==================================================
    covergroup cg_logic with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_logic_a : coverpoint txn.A
            iff (txn.alu_ctrl inside {
                ALU_AND, ALU_OR, ALU_XOR
            }) {
            bins zero      = {32'h00000000};
            bins all_ones  = {32'hFFFFFFFF};
            bins pattern_a = {32'hAAAAAAAA};
            bins pattern_5 = {32'h55555555};
            bins one       = {32'h00000001};
            bins other     = default;
        }

        cp_logic_b : coverpoint txn.B
            iff (txn.alu_ctrl inside {
                ALU_AND, ALU_OR, ALU_XOR
            }) {
            bins zero      = {32'h00000000};
            bins all_ones  = {32'hFFFFFFFF};
            bins pattern_a = {32'hAAAAAAAA};
            bins pattern_5 = {32'h55555555};
            bins one       = {32'h00000001};
            bins other     = default;
        }

        cp_logic_op : coverpoint txn.alu_ctrl
            iff (txn.alu_ctrl inside {
                ALU_AND, ALU_OR, ALU_XOR
            }) {
            bins and_ = {ALU_AND};
            bins or_  = {ALU_OR};
            bins xor_ = {ALU_XOR};
        }

        x_logic_pattern : cross
            cp_logic_op, cp_logic_a, cp_logic_b;
    endgroup


    // ==================================================
    // CG-05: Shift amount, mask and sign
    // ==================================================
    covergroup cg_shift with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_shamt_low : coverpoint txn.B[4:0]
            iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
            bins zero  = {0};
            bins one   = {1};
            bins two   = {2};
            bins max   = {31};
            bins other = {[3:30]};
        }

        cp_shamt_high : coverpoint (txn.B[31:5] != 0)
            iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
            bins zero_high    = {0};
            bins nonzero_high = {1};
        }

        cp_shift_op : coverpoint txn.alu_ctrl
            iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
            bins sll = {ALU_SLL};
            bins srl = {ALU_SRL};
        }

        x_shamt_mask : cross
            cp_shift_op, cp_shamt_low, cp_shamt_high;

        cp_shift_a_sign : coverpoint txn.A[31]
            iff (txn.alu_ctrl inside {ALU_SLL, ALU_SRL}) {
            bins msb_zero = {0};
            bins msb_one  = {1};
        }

        x_shift_sign : cross cp_shift_op, cp_shift_a_sign;
    endgroup


    // ==================================================
    // CG-06: Walking-one input A
    // ==================================================
    covergroup cg_walking with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_walking_op : coverpoint txn.alu_ctrl
            iff (txn.alu_ctrl inside {
                ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL
            }) {
            bins and_ = {ALU_AND};
            bins or_  = {ALU_OR};
            bins xor_ = {ALU_XOR};
            bins sll  = {ALU_SLL};
            bins srl  = {ALU_SRL};
        }

        cp_walking_one_a : coverpoint txn.A
            iff (txn.alu_ctrl inside {
                ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL
            }) {
            bins walking_one[] = {
                32'h00000001, 32'h00000002,
                32'h00000004, 32'h00000008,
                32'h00000010, 32'h00000020,
                32'h00000040, 32'h00000080,
                32'h00000100, 32'h00000200,
                32'h00000400, 32'h00000800,
                32'h00001000, 32'h00002000,
                32'h00004000, 32'h00008000,
                32'h00010000, 32'h00020000,
                32'h00040000, 32'h00080000,
                32'h00100000, 32'h00200000,
                32'h00400000, 32'h00800000,
                32'h01000000, 32'h02000000,
                32'h04000000, 32'h08000000,
                32'h10000000, 32'h20000000,
                32'h40000000, 32'h80000000
            };
            bins other = default;
        }

        x_walking_one : cross cp_walking_op, cp_walking_one_a;
    endgroup


    // ==================================================
    // CG-07: Result zero/nonzero
    // ==================================================
    covergroup cg_result with function sample(alu_txn txn);
        option.per_instance = 1;

        cp_result_op : coverpoint txn.alu_ctrl {
            bins add  = {ALU_ADD};
            bins sub  = {ALU_SUB};
            bins and_ = {ALU_AND};
            bins or_  = {ALU_OR};
            bins xor_ = {ALU_XOR};
            bins sll  = {ALU_SLL};
            bins srl  = {ALU_SRL};
        }

        cp_res_zero : coverpoint (txn.alu == 32'h00000000) {
            bins zero    = {1};
            bins nonzero = {0};
        }

        x_res_zero : cross cp_result_op, cp_res_zero;
    endgroup


    // ==================================================
    // Constructor
    // ==================================================
    function new(mailbox #(alu_txn) mon2cov);
        this.mon2cov = mon2cov;

        cg_alu_op = new();
        cg_add    = new();
        cg_sub    = new();
        cg_logic  = new();
        cg_shift  = new();
        cg_walking = new();
        cg_result = new();
    endfunction


    // ==================================================
    // Sample all covergroups
    // ==================================================
    function void sample_all(alu_txn txn);
        cg_alu_op.sample(txn);
        cg_add.sample(txn);
        cg_sub.sample(txn);
        cg_logic.sample(txn);
        cg_shift.sample(txn);
        cg_walking.sample(txn);
        cg_result.sample(txn);

        sample_cnt++;
    endfunction


    // Sampling directly from test
    function void sample_direct(alu_txn txn);
        sample_all(txn);
    endfunction


    // Sampling transactions from monitor
    task run();
        alu_txn txn;

        forever begin
            mon2cov.get(txn);
            sample_all(txn);
        end
    endtask


    // ==================================================
    // Print one coverage item
    // ==================================================
    function void print_item(
        string id,
        string name,
        real cov
    );
        $display("  %-10s %-24s : %6.2f%%",
                 id, name, cov);
    endfunction


    // ==================================================
    // Coverage report
    // ==================================================
    function void report();
        real cov_op;
        real cov_add;
        real cov_sub;
        real cov_logic;
        real cov_shift;
        real cov_walking;
        real cov_result;
        real total;

        cov_op      = cg_alu_op.get_inst_coverage();
        cov_add     = cg_add.get_inst_coverage();
        cov_sub     = cg_sub.get_inst_coverage();
        cov_logic   = cg_logic.get_inst_coverage();
        cov_shift   = cg_shift.get_inst_coverage();
        cov_walking = cg_walking.get_inst_coverage();
        cov_result  = cg_result.get_inst_coverage();

        // Average coverage across 7 covergroups
        total = (
            cov_op      +
            cov_add     +
            cov_sub     +
            cov_logic   +
            cov_shift   +
            cov_walking +
            cov_result
        ) / 7.0;

        $display("==================================================");
        $display("          ALU FUNCTIONAL COVERAGE REPORT");
        $display("==================================================");
        $display("  Transactions sampled : %0d", sample_cnt);
        $display("--------------------------------------------------");

        print_item("ALU-01", "cg_alu_op",  cov_op);
        print_item("ALU-02", "cg_add",     cov_add);
        print_item("ALU-03", "cg_sub",     cov_sub);
        print_item("ALU-04", "cg_logic",   cov_logic);
        print_item("ALU-05", "cg_shift",   cov_shift);
        print_item("ALU-06", "cg_walking", cov_walking);
        print_item("ALU-07", "cg_result",  cov_result);

        $display("--------------------------------------------------");
        $display("  TOTAL (average) : %6.2f%% (goal %0.1f%%)",
                 total, goal);

        $display("  RESULT          : %s",
                 (total >= goal) ? "PASS" : "FAIL");

        $display("==================================================");
    endfunction

endclass
