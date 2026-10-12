module regfile 
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    input  riscv_reg_e  rs1_addr_i,
    input  riscv_reg_e  rs2_addr_i,
    input  regfile_wb   wb_i,

    output logic [XLEN-1:0] rs1_data_o,
    output logic [XLEN-1:0] rs2_data_o
);

    localparam int REG_COUNT = 32;
    logic [XLEN-1:0] mem_reg [0:REG_COUNT-1];
    integer i;
    // ============================================================
    // Write port
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < REG_COUNT; i++) begin
                mem_reg[i] <= '0;
            end
        end
        else begin
            // x0 is hard-wired to zero
            if (wb_i.reg_en && (wb_i.rd_addr != REG_ZERO)) begin
                mem_reg[wb_i.rd_addr] <= wb_i.rd_data;
            end
        end
    end
    // ============================================================
    // Read ports
    // ============================================================
    always_comb begin
        if (rs1_addr_i == REG_ZERO)
            rs1_data_o = '0;
        else
            rs1_data_o = mem_reg[rs1_addr_i];


        if (rs2_addr_i == REG_ZERO)
            rs2_data_o = '0;
        else
            rs2_data_o = mem_reg[rs2_addr_i];
    end
endmodule
