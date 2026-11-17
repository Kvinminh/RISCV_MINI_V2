module mem_wb_reg
import ctrl_pkg::*;
import core_pkg::*;
(
    input logic clk,
    input logic rst_n,
    input mem_wb_reg_t mem_reg_i,
    output mem_wb_reg_t reg_wb_o
);


always_ff @(posedge clk or negedge rst_n) begin
    if ( !rst_n) begin
        reg_wb_o <= '0;
    end
    else begin
        reg_wb_o <= mem_reg_i;
    end
end
endmodule
