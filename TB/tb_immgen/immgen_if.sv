import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;



interface immgen_if( input logic clk);
    logic [XLEN-1:0] ins;
    immgen_sel_e imm_sel;
    logic [XLEN-1:0] imm_out;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output ins,imm_sel;
    endclocking 

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input ins,imm_sel,imm_out;
    endclocking 

    modport DRV(clocking drv_cb, input  clk);
    modport MON(clocking mon_cb, input  clk);
endinterface