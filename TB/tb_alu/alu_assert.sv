// module alu_assert
//     import isa_pkg::*;
//     import ctrl_pkg::*;
//     //import core_pkg::*;
// (
//     input logic        clk,
//     input alu_ctrl_e   alu_ctrl_i,
//     input logic [31:0] A,
//     input logic [31:0] B,
//     input logic [31:0] alu_result_o
// );

//     wire in_known = !$isunknown({alu_ctrl_i, A, B});

//     wire op_valid =
//         alu_ctrl_i inside {
//             ALU_ADD, ALU_SUB,
//             ALU_SLL, ALU_SLT, ALU_SLTU,
//             ALU_XOR, ALU_SRL, ALU_SRA,
//             ALU_OR, ALU_AND
//         };

//     default clocking cb @(posedge clk); endclocking
//     default disable iff (!in_known);

//     // Input hợp lệ -> output không X/Z
//     a_no_x_out: assert property (
//         in_known |-> !$isunknown(alu_result_o)
//     )
//     else $error(
//         "[ALU-SVA] out X/Z: ctrl=%0d A=%h B=%h out=%h",
//         alu_ctrl_i, A, B, alu_result_o
//     );

//     // Opcode không hợp lệ -> output = 0
//     property p_default;
//         !op_valid |-> (alu_result_o == '0);
//     endproperty

    
//     a_default: assert property (p_default)
//     else $error(
//         "[ALU-SVA] ctrl=%0d invalid, out=%h",
//         alu_ctrl_i, alu_result_o
//     );

//     // SLT/SLTU -> chỉ 0 hoặc 1
//     property p_cmp_range;
//         (alu_ctrl_i inside {ALU_SLT, ALU_SLTU})
//         |-> (alu_result_o[31:1] == '0);
//     endproperty

//     a_cmp_range: assert property (p_cmp_range)
//     else $error(
//         "[ALU-SVA] cmp bit cao != 0: %h",
//         alu_result_o
//     );

//     // Shift chỉ phụ thuộc B[4:0]
//     property p_shamt_only;
//         (alu_ctrl_i inside {ALU_SLL, ALU_SRL, ALU_SRA}
//          && $stable(alu_ctrl_i)
//          && $stable(A)
//          && $stable(B[4:0])
//          && $changed(B[31:5]))
//         |-> $stable(alu_result_o);
//     endproperty

//     a_shamt_only: assert property (p_shamt_only)
//     else $error(
//         "[ALU-SVA] shift depends on B[31:5]"
//     );

// endmodule


// bind alu alu_assert u_alu_assert (
//     .clk          (clk),
//     .alu_ctrl_i   (alu_ctrl_i),
//     .A            (A),
//     .B            (B),
//     .alu_result_o (alu_result_o)
// );

















































module alu_assert
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
    // import alu_pkg::*;
(
    input logic        clk,
    input logic        rst_n,          // them moi: reset active-low
    input alu_ctrl_e   alu_ctrl_i,
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [31:0] alu_result_o
);

    // ------------------------------------------------------------------
    // Clocking / reset mac dinh cho toan bo assertion
    // ------------------------------------------------------------------
    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // ------------------------------------------------------------------
    // Helper: kiem tra gia tri co thuoc enum alu_ctrl_e hay khong.
    // Duyet bang first()/next() nen khong phai liet ke tay tung gia tri
    // -> them/bot phan tu enum thi assertion tu cap nhat.
    // ------------------------------------------------------------------
    function automatic bit is_valid_alu_ctrl(alu_ctrl_e v);
        alu_ctrl_e e;
        e = e.first();
        do begin
            if (e == v) return 1'b1;
            e = e.next();
        end while (e != e.first());
        return 1'b0;
    endfunction

    // ------------------------------------------------------------------
    // Static check: do rong port dung 32 bit (fail luc elaboration)
    // ------------------------------------------------------------------
    initial begin
        assert ($bits(A) == 32 && $bits(B) == 32)
        else $fatal(1, "[AP-F02-3] Port A/B width != 32 (A=%0d, B=%0d)",
                    $bits(A), $bits(B));
    end

    // ------------------------------------------------------------------
    // AP-F02-1: input khong duoc co X/Z
    // ------------------------------------------------------------------
    AP_F02_1_NO_XZ_ALU_CTRL : assert property (!$isunknown(alu_ctrl_i))
        else $error("[AP-F02-1] alu_ctrl_i co X/Z: %b @%0t", alu_ctrl_i, $time);

    AP_F02_1_NO_XZ_A : assert property (!$isunknown(A))
        else $error("[AP-F02-1] A co X/Z: %b @%0t", A, $time);

    AP_F02_1_NO_XZ_B : assert property (!$isunknown(B))
        else $error("[AP-F02-1] B co X/Z: %b @%0t", B, $time);

    // ------------------------------------------------------------------
    // AP-F02-2: alu_ctrl_i phai nam trong enum alu_ctrl_e
    // (neu X/Z thi da bi AP-F02-1 bat; o day bo qua de tranh bao trung)
    // ------------------------------------------------------------------
    AP_F02_2_ALU_CTRL_IN_ENUM : assert property (
        !$isunknown(alu_ctrl_i) |-> is_valid_alu_ctrl(alu_ctrl_i)
    ) else $error("[AP-F02-2] alu_ctrl_i ngoai enum: 0x%0h @%0t", alu_ctrl_i, $time);

    // ------------------------------------------------------------------
    // AP-F02-3: A, B hop le 32 bit (khong X/Z tren tung bit)
    // Gop thanh 1 property de report 1 lan khi ca hai xau
    // ------------------------------------------------------------------
    AP_F02_3_AB_VALID_32B : assert property (
        !$isunknown({A, B})
    ) else $error("[AP-F02-3] A/B khong hop le: A=%b B=%b @%0t", A, B, $time);

    // ------------------------------------------------------------------
    // Cover: chung minh assertion khong bi vacuous
    // ------------------------------------------------------------------
    COV_ALU_CTRL_VALID : cover property (
        !$isunknown(alu_ctrl_i) && is_valid_alu_ctrl(alu_ctrl_i));

    COV_AB_VALID : cover property (!$isunknown({A, B}));

endmodule

bind alu alu_assert u_alu_assert (

    .alu_ctrl_i  (alu_ctrl_i),
    .A           (A),
    .B           (B),
    .alu_result_o(alu_result_o)
);