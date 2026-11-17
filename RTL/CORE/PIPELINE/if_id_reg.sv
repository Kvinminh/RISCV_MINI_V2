module if_id_reg
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       if_id_stall_i,
    input  logic       if_id_flush_i,

    input  if_id_reg_t if_reg_i,
    output if_id_reg_t reg_id_o
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_id_o <= '0;
        else if (if_id_flush_i)
            reg_id_o <= '0;
        else if (if_id_stall_i )
            reg_id_o <= reg_id_o;
        else
            reg_id_o <= if_reg_i;
    end

endmodule
