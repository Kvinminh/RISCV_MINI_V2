// import alu_pkg::*;
class alu_ref_model;
    
    alu_ctrl_e ref_alu_ctrl;
    bit [XLEN-1:0] ref_A;
    bit [XLEN-1:0] ref_B;
    bit [XLEN-1:0] ref_alu;

    function void predict(alu_txn txn);
        bit [4:0]  shamt;
        int signed sA, sB;

        ref_alu_ctrl = txn.alu_ctrl;
        ref_A        = txn.A;
        ref_B        = txn.B;

        shamt = ref_B[4:0];          
        sA    = ref_A;               // bản có dấu, dùng cho SLT và SRA
        sB    = ref_B;

        case (ref_alu_ctrl)
            ALU_ADD:  ref_alu = ref_A + ref_B;
            ALU_SUB:  ref_alu = ref_A - ref_B;
            ALU_SLL:  ref_alu = ref_A << shamt;
            ALU_SLT:  ref_alu = (sA < sB) ? 32'd1 : 32'd0;
            ALU_SLTU: ref_alu = (ref_A < ref_B) ? 32'd1 : 32'd0;
            ALU_XOR:  ref_alu = ref_A ^ ref_B;
            ALU_SRL:  ref_alu = ref_A >> shamt;
            ALU_SRA:  ref_alu = sA >>> shamt;
            ALU_OR:   ref_alu = ref_A | ref_B;
            ALU_AND:  ref_alu = ref_A & ref_B;
            default:  ref_alu = 32'd0;
        endcase

        txn.expected_alu = ref_alu; 
    endfunction
endclass