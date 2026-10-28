


class immgen_ref;

    static function automatic logic [XLEN-1:0] calc_imm (
        input logic [XLEN-1:0] ins,
        input immgen_sel_e     sel
    );
        logic [XLEN-1:0] imm;

        case (sel)
            
            IMMGEN_I: imm = {{20{ins[31]}}, ins[31:20]};

            
            IMMGEN_S: imm = {{20{ins[31]}}, ins[31:25], ins[11:7]};

            
            IMMGEN_B: imm = {{19{ins[31]}}, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};

           
            IMMGEN_U: imm = {ins[31:12], 12'b0};

            
            IMMGEN_J: imm = {{11{ins[31]}}, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};

            default:  imm = '0;
        endcase

        return imm;
    endfunction

    
    function void predict (immgen_txn txn);
        txn.expected_imm_out = calc_imm(txn.ins, txn.imm_sel);
    endfunction

    function bit check (immgen_txn txn);
        if (txn.imm_out !== txn.expected_imm_out) begin
            $error("[REF] MISMATCH\n%s", txn.cover2string());
            return 0;
        end
        return 1;
    endfunction

endclass