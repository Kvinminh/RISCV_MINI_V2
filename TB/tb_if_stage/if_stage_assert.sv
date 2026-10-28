module if_stage_assert
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
    (
        input logic clk,
        input logic rst_n,
        input logic stall_pc,
        input jump_t    data_control_jump_id,
        input  logic [XLEN-1:0] ins,

        output if_id_reg_t if_reg
    );

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);


    AP_F01_1a: assert property (!$isunknown(if_reg.pc_cur))
        else $error ( "[AP-F01-1A] PC_CUR  co X/Y: %b  @%time",if_reg.pc_cur,$time );

    AP_F01_1b: assert property (!$isunknown(if_reg.pc_4))
        else $error ( "[AP-F01-1b] PC_4 co X/Y: %b  @%time",if_reg.pc_4,$time );
    
    AP_F01_1c: assert property (
    !$isunknown(data_control_jump_id)
    ) else $error("[AP-F01-1c] jump co X/Z | jal=%b jalr=%b br_en=%b br_taken=%b pc_jump=%h @%0t",
              data_control_jump_id.jal,
              data_control_jump_id.jalr,
              data_control_jump_id.br_en,
              data_control_jump_id.br_taken,
              data_control_jump_id.pc_jump,
              $time);

    
    AP_F01_2: assert property (
            pc4 == pc_cur + 4 && !$isunknown(pc4))
    else $error("AP-F02-1] pc4 = %b sai khong bang pc_cur = %b + 4  @%time", 
            if_reg.pc_4,if_reg.pc_cur, $time);

     AP_F02_1a: assert property (
        !$isunknown(pc_next)
    ) else $error("[AP-F02-1a] pc_next co X/Z @%0t", $time);

     AP_F02_1b: assert property (
        !$isunknown(stall_pc)
    ) else $error("[AP-F02-1b] stall_pc co X/Z @%0t", $time);
    
     AP_F02_2: assert property (
        !stall_pc |=> pc_cur == $past(pc_next)
    ) else $error("[AP-F02-2] pc_cur != pc_next truoc do: pc_cur=%h pc_next_prev=%h @%0t",
                  pc_cur, $past(pc_next), $time);

    AP_F02_3: assert property (
        stall_pc |=> pc_cur == $past(pc_cur)
    ) else $error("[AP-F02-3] stall=1 nhung pc_cur doi: %h -> %h @%0t",
                  $past(pc_cur), pc_cur, $time);

    // Cover: đảm bảo kịch bản stall thực sự xảy ra trong simulation
    C_F02_STALL: cover property (stall_pc ##1 !stall_pc);
    C_F02_RUN:   cover property (!stall_pc ##1 !stall_pc);

endmodule

bind if_stage if_stage_assert u_if_assert (
    .clk                  (clk),
    .rst_n                (rst_n),
    .stall_pc             (stall_pc_i),
    .data_control_jump_id (data_control_jump_id_i),
    .ins                  (ins_i),
    .pc_cur               (pc_cur),
    .pc4                  (pc4),
    .pc_next              (pc_next),
    .if_reg               (if_reg_o)
);