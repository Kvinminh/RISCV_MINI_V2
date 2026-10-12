module addr_jump_pc
import isa_pkg::*;
  import ctrl_pkg::*;
  import core_pkg::*;
(
    input  logic [XLEN-1:0] addr_jump_pc_a_i,
    input  logic [XLEN-1:0] addr_jump_pc_b_i,
    output  logic [XLEN-1:0] pc_jump_o
);

   assign pc_jump_o = addr_jump_pc_a_i + addr_jump_pc_b_i;

endmodule
