interface ha_pipe_if(input logic clk );
    // logic  clk;
    logic rst_n;

    riscv_reg_e            rs1_addr;
    riscv_reg_e            rs2_addr;

    logic                  rs1_used;
    logic                  rs2_used;

    logic                  jump_en;       // JAL || JALR từ decode
    logic                  br_en;         // Branch từ decode
    logic                  br_taken;      // Kết quả br_compare

    for_info_t             for_info_ex;
    for_info_t             for_info_mem;


    // pc 
    //logic stall_pc;
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_cur;

    // ifd 
    //  logic       ifd_stall
    //  logic       ifd_flush;

    if_id_reg_t if_reg;
    if_id_reg_t reg_id;


    //  logic       id_ex_flush;
    id_ex_reg_t id_reg;
    id_ex_reg_t reg_ex;


    // ex_mem 
    ex_mem_reg_t       ex_reg;
    ex_mem_reg_t      reg_mem;
    // mem_wb
    mem_wb_reg_t mem_reg;
    mem_wb_reg_t reg_wb;

    hzd_ctrl_t hzd_ctrl;

    clocking drv_cb @(posedge clk);
        default input #1step output #1;
        output rst_n,rs1_addr,rs2_addr,rs1_used,rs2_used,jump_en,br_en,br_taken,for_info_ex,for_info_mem;
        output pc_next;
        output if_reg;
        output id_reg;
        output ex_reg;
        output mem_reg;
    endclocking 

    clocking mon_cb @(posedge clk);
        default input #1step output #1;
        input rst_n,rs1_addr,rs2_addr,rs1_used,rs2_used,jump_en,br_en,br_taken,for_info_ex,for_info_mem;
        input pc_next,pc_cur;
        input if_reg,reg_id;
        input id_reg,reg_ex;
        input ex_reg,reg_mem;
        input mem_reg,reg_wb;
    endclocking 

    modport DRV(clocking drv_cb, input  clk);
    modport MON(clocking mon_cb, input  clk);
endinterface