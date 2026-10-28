import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;


interface if_stage_if ( input logic clk);
    logic clk;
    logic rst_n;
    logic stall_pc;
    jump_t data_control_jump_id;
    logic [XLEN-1:0] ins;

    if_id_reg_t if_reg;


    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output rst_n,stall_pc,data_control_jump_id_i,ins;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input rst_n,stall_pc,data_control_jump_id_i,ins,if_reg;
    endclocking

    modport DRV (input  clk, clocking drv_cb);
    modport MON (input  clk, clocking mon_cb);

endinterface

