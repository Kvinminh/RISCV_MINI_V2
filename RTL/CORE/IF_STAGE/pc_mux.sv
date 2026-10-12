`timescale 1ns/1ps
module pc_mux
import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;
(
    input jump_t data_control_jump_id_i,
    input logic [XLEN-1:0] pc4_i,
    output logic [XLEN-1:0] pc_next_o
);
    logic jal,jalr,br_en,br_taken;
    logic [XLEN-1:0]     pc_jump;

    always_comb begin : unpack_jump
        br_taken =      data_control_jump_id_i.br_taken;
        br_en =         data_control_jump_id_i.br_en;
        jal =           data_control_jump_id_i.jal;
        jalr  =         data_control_jump_id_i.jalr;
        pc_jump =     data_control_jump_id_i.pc_jump;
    end

    pc_sel_e pc_sel;
    assign pc_sel =  pc_sel_e'(( br_taken && br_en) || jal || jalr);

    always_comb begin : sel_pc_jump
        pc_next_o = pc4_i;
        case( pc_sel)
            PC4: begin
                pc_next_o = pc4_i;
            end 
            PC_JUMP: begin
                pc_next_o = pc_jump;
            end 
            default: pc_next_o = pc4_i;
        endcase
    end 
endmodule

