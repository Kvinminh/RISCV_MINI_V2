`timescale 1ps/1ps
import core_pkg::*;
import ctrl_pkg::*;
import isa_pkg::*;
// import alu_pkg::*;

typedef enum {LOW, 
              MID,
              HIGH,
              ZERO,
              ONE,
              ALL_ONE,
              MAX_POS,
              MIN_REG,
              PATTERN_A,
              PATTERN_5
              } range_e;

class alu_txn;
    rand range_e      a_range, b_range;
    rand alu_ctrl_e alu_ctrl;
    rand bit [31:0] A;
    rand bit [31:0] B;
    // dut output
    logic [XLEN-1:0] alu;
    //ref_model
    logic [XLEN-1:0] expected_alu;

    constraint c_alu{
        alu_ctrl inside {ALU_ADD,
                         ALU_SUB, 
                         ALU_SLL,                        
                         ALU_XOR, 
                         ALU_SRL, 
                         ALU_OR, 
                         ALU_AND};
    };

    constraint c_A_pick {
        a_range dist { ZERO := 10,
                       ONE := 10, 
                       ALL_ONE := 10, 
                       MAX_POS := 10,
                       MIN_REG := 10,
                       PATTERN_A := 10,
                       PATTERN_5 := 10,
                       LOW := 10 ,
                       MID := 10 , 
                       HIGH := 10};
    }

    constraint c_B_pick {
        b_range dist {  ZERO := 10,
                       ONE := 10, 
                       ALL_ONE := 10, 
                       MAX_POS := 10,
                       MIN_REG := 10,
                       PATTERN_A := 10,
                       PATTERN_5 := 10,
                       LOW := 10 ,
                       MID := 10 , 
                       HIGH := 10};
    }

    constraint c_A_val {
        (a_range == ZERO ) ->  A inside {32'h00000000};
        (a_range == ONE ) ->  A inside {32'h00000001};
        (a_range == ALL_ONE ) ->  A inside {32'hFFFFFFFF};
        (a_range == MAX_POS ) ->  A inside {32'h7FFFFFFF};
        (a_range == MIN_REG ) ->  A inside {32'h80000000};
        (a_range == PATTERN_A ) ->  A inside {32'hAAAAAAAA};
        (a_range == PATTERN_A ) ->  A inside {32'h55555555};

        (a_range == LOW ) ->  A inside {[0:9]};
        (a_range == MID ) ->  A inside {[10:21]};
        (a_range == HIGH ) ->  A inside {[25:31]};
    }

    constraint c_B_val {
        (b_range == ZERO ) ->  B inside {32'h00000000};
        (b_range == ONE ) ->  B inside {32'h00000001};
        (b_range == ALL_ONE ) ->  B inside {32'hFFFFFFFF};
        (b_range == MAX_POS ) ->  B inside {32'h7FFFFFFF};
        (b_range == MIN_REG ) ->  B inside {32'h80000000};
        (b_range == PATTERN_A ) ->  B inside {32'hAAAAAAAA};
        (b_range == PATTERN_A ) ->  B inside {32'h55555555};
        (b_range == LOW ) ->  B inside {[0:9]};
        (b_range == MID ) ->  B inside {[10:21]};
        (b_range == HIGH ) ->  B inside {[25:31]};
    }
    
    
    function void copy (alu_txn rhs);
        if(rhs == null) return;
        alu_ctrl = rhs.alu_ctrl;
        A        = rhs.A;
        B        = rhs.B;
    endfunction

    function alu_txn clone();
        alu_txn t = new();
        t.copy(this);
        return t;
    endfunction

    function string cover2string ();
        return $sformatf(
            "ALU_CTRL = %0d\n A = %0d\n B = %0d\n ALU = %0d\n EXPECTED_ALU = %0d",
            alu_ctrl,
            A,
            B,
            alu, 
            expected_alu
        );
    endfunction
endclass




