module ex_mem_reg
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input logic             clk,
    input logic             rst_n,
    input ex_mem_reg_t       ex_reg_i,
    output ex_mem_reg_t      reg_mem_o
);

always_ff @( posedge clk  or negedge rst_n)begin
    if(!rst_n) reg_mem_o <= '0;
    else reg_mem_o <= ex_reg_i;
end

endmodule
