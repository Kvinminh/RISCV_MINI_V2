interface hz_fwd_if( input logic clk);
    //  logic                  clk;
     logic                  rst_n;

     riscv_reg_e            rs1_addr;
     riscv_reg_e            rs2_addr;

     logic                  rs1_used;
     logic                  rs2_used;

     logic                  jump_en;       // JAL || JALR từ decode
     logic                  br_en;         // Branch từ decode
     logic                  br_taken;      // Kết quả br_compare

     for_info_t             for_info_ex;
     for_info_t             for_info_mem;
     for_info_t             for_info_wb;


     for_sel_e             for_id_a;
     for_sel_e             for_id_b;

     forward_e             for_ex_a;
     forward_e             for_ex_b;

     hzd_ctrl_t            hzd_ctrl;


    logic                       rs1_ex;
    logic                       rs2_ex;
    logic                       rs1_mem;
    logic                       rs2_mem;
    logic                       br2alu_ex;
    logic                       br2load_ex;
    logic                       br2load_mem;
    logic                       alu2load;

    // assign rs1_ex      = tb_top.dut.rs1_ex;
    // assign rs2_ex      = tb_top.dut.rs2_ex;
    // assign rs1_mem     = tb_top.dut.rs1_mem;
    // assign rs2_mem     = tb_top.dut.rs2_mem;
    // assign br2alu_ex   = tb_top.dut.br2alu_ex;
    // assign br2load_ex  = tb_top.dut.br2load_ex;
    // assign br2load_mem = tb_top.dut.br2load_mem;
    // assign alu2load    = tb_top.dut.alu2load;
    

    clocking drv_cb @(posedge clk) ;
        default input #1step output #1;
        output rst_n,rs1_addr,rs2_addr,rs1_used,rs2_used;
        output jump_en,br_en,br_taken;
        output for_info_ex,for_info_mem,for_info_wb;
    endclocking 

    clocking mon_cb @(posedge clk) ;
        default input #1step output #1;
        input rst_n,rs1_addr,rs2_addr,rs1_used,rs2_used;
        input jump_en,br_en,br_taken;
        input for_info_ex,for_info_mem,for_info_wb;        
        input for_id_a,for_id_b,for_ex_a,for_ex_b,hzd_ctrl;
        input rs1_ex,rs2_ex,rs1_mem,rs2_mem,br2alu_ex,br2load_ex,br2load_mem,alu2load;
    endclocking 

    modport DRV (input clk, clocking drv_cb);
    modport MON (input clk, clocking mon_cb);
endinterface