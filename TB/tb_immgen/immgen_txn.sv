import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;


class immgen_txn;

    rand logic [XLEN-1:0] ins;
    rand immgen_sel_e imm_sel;
    // output 
    logic [XLEN-1:0] imm_out;
    // output kuf vongj 
    logic [XLEN-1:0] expected_imm_out;

    constraint c_ins {
        ins inside {[0:31]};
    };

    constraint c_immsel{
        imm_sel inside {IMMGEN_I,
                        IMMGEN_S,
                        IMMGEN_B,
                        IMMGEN_U,
                        IMMGEN_J};
    };



    function void copy (immgen_txn rhs );
        if( rhs == null) return;
        ins = rhs.ins;
        imm_sel = rhs.imm_sel;
    endfunction

    function immgen_txn clone();
        immgen_txn t = new();
        t.copy(this);
        return t;
    endfunction


    function string cover2string();
    return $sformatf(
        "INS = 0x%08h\n IMM_SEL = %s\n IMM_OUT = 0x%08h\n EXPECTED_IMM_OUT = 0x%08h",
        ins,
        imm_sel.name(),
        imm_out,
        expected_imm_out
    );
endfunction
endclass

