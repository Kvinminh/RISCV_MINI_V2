import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

interface alu_if( input logic clk );
    alu_ctrl_e alu_ctrl;
    logic [XLEN-1:0] A;
    logic [XLEN-1:0] B;
    logic [XLEN-1:0] alu;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output alu_ctrl, A,B;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input  alu_ctrl,A,B, alu;
    endclocking

    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);
endinterface