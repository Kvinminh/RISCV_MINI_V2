import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;


interface regfile_if (input logic clk);
    logic rst_n;
    riscv_reg_e rs1_addr;
    riscv_reg_e rs2_addr;
    regfile_wb   wb;

    logic [XLEN-1:0 ] rs1_data;
    logic [XLEN-1:0 ] rs2_data;


    clocking drv_cb @(posedge clk );
        default input #1step output #1;
        output rst_n,rs1_addr,rs2_addr,wb;
    endclocking 

    clocking mon_cb @(posedge clk );
        default input #1step output #1;
        input rst_n,rs1_addr,rs2_addr,wb,rs1_data,rs2_data;
    endclocking 

    modport DRV( clocking drv_cb, input clk);
    modport MON( clocking mon_cb, input clk);

endinterface 