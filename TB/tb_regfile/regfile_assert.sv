// module regfile_assert
//     import isa_pkg::*;
//     import ctrl_pkg::*;
//     import core_pkg::*;
//     // import alu_pkg::*;
// (
//     input logic clk,
//     input logic rst_n,
//     input logic [4:0] rs1_addr,
//     input logic [4:0] rs2_addr,
//     input regfile_wb wb,

//     output logic [XLEN-1:0] rs1_data,
//     output logic [XLEN-1:0] rs2_data
// );

//     default clocking cv @(posedge clk);
//     endclocking
//     default disable iff(!rst_n);


//     logic [XLEN-1:0] mem[0:XLEN-1];
//     integer i;


//     initial begin
//         assert ( $bit(rs1_addr)   == 5 &&
//                  $bit(rs2_addr)   == 5 &&
//                  $bit(wb.reg_en)  == 1 &&
//                  $bit(wb.rd_addr) == 5 &&
//                  $bit(wb.rd_data) == 32 &&
//                  $bit(rs1_data)   == 32 &&
//                  $bit(rs1_data)   == 32 )
//         else $fatal (1,"co data vao ko dung bik đã quy định ");  
//     end

//     AP_F01_1: assert property (
//         !$isunknown({wb.reg_en, wb.rd_addr, wb.rd_data})
//     )
//     else $error(
//         "AP-F01-1 CO X/Z: reg_en=%b, rd_addr=%b, rd_data=%b luc %0t",
//         wb.reg_en, wb.rd_addr, wb.rd_data, $time
//     );



//     AP_FO1_2: assert property (
//         wb.reg_en == 0 |=> mem[rd_addr] == 0
//     )
//     else


//     AP_FO1_3: assert property (
//         wb.reg_en == 1 |=> mem[wb.rd_addr] == wb.rd_data
//     )
//     else

//     AP_FO1_4: assert property (
//         wb.reg_en == 1 |=> mem[wb.rd_addr] == wb.rd_data
//     )
//     else



//     AP_F02_1: assert property (
//         !$isunknown ({rs1_addr, rs2_addr, rs1_data, rd2_data})
//     )
//     else

//     AP_F02_2A: assert property (
//       mem[rs1_addr] == rs1_data
//     )
//     else


//     AP_F02_2B: assert property (
//       mem[rs2_addr] == rs2_data
//     )
//     else


//     AP_F02_3: assert property (
//         $changed( {rs1_addr, rs2_addr}) |-> $changed( {rs1_data, rs2_data}) 
//     )
    









// endmodule





module regfile_assert
    import isa_pkg::*;
    import ctrl_pkg::*;
    import core_pkg::*;
(
    input logic              clk,
    input logic              rst_n,
    input riscv_reg_e        rs1_addr_i,
    input riscv_reg_e        rs2_addr_i,
    input regfile_wb         wb_i,
    input logic [XLEN-1:0]   rs1_data_o,
    input logic [XLEN-1:0]   rs2_data_o,
    input logic [XLEN-1:0]   dut_mem [0:31]     // mem_reg cua DUT
);

    localparam int REG_COUNT = 32;

    default clocking cb @(posedge clk); endclocking
    // Khong dung default disable iff: cac property reset tu khai bao rieng.

    // Tat ca thanh ghi = 0 (dung cho AP-F03)
    logic mem_zero;
    always_comb begin
        mem_zero = 1'b1;
        for (int k = 0; k < REG_COUNT; k++)
            if (dut_mem[k] != '0) mem_zero = 1'b0;
    end

    // ============================================================
    // AP-F01: cong ghi
    // ============================================================
    AP_F01_1: assert property (
        disable iff (!rst_n)
        !$isunknown({wb_i.reg_en, wb_i.rd_addr, wb_i.rd_data})
    ) else $error("AP-F01-1 X/Z tren cong ghi t=%0t", $time);

    for (genvar g = 0; g < REG_COUNT; g++) begin : g_wr
        // AP-F01-2: reg_en=0 -> thanh ghi g khong doi
        AP_F01_2: assert property (
            disable iff (!rst_n)
            !wb_i.reg_en |=> $stable(dut_mem[g])
        ) else $error("AP-F01-2 reg_en=0 nhung mem[%0d] doi t=%0t", g, $time);

        // AP-F01-4: ghi vao thanh ghi khac -> thanh ghi g khong doi
        AP_F01_4: assert property (
            disable iff (!rst_n)
            (wb_i.reg_en && wb_i.rd_addr != g) |=> $stable(dut_mem[g])
        ) else $error("AP-F01-4 ghi nham vao mem[%0d] t=%0t", g, $time);

        // AP-F01-3: ghi dung dia chi -> mem[g] = rd_data (bo x0, xem AP-F04)
        if (g != 0) begin : g_f01_3
            AP_F01_3: assert property (
                disable iff (!rst_n)
                (wb_i.reg_en && wb_i.rd_addr == g) |=> dut_mem[g] == $past(wb_i.rd_data)
            ) else $error("AP-F01-3 ghi sai, mem[%0d] != rd_data t=%0t", g, $time);
        end
    end

    // ============================================================
    // AP-F02: cong doc
    // ============================================================
    AP_F02_1: assert property (
        disable iff (!rst_n)
        !$isunknown({rs1_addr_i, rs2_addr_i, rs1_data_o, rs2_data_o})
    ) else $error("AP-F02-1 X/Z tren cong doc t=%0t", $time);

    // AP-F02-2: rs_data luon bang mem[rs_addr]
    // Lay mau truoc canh len nen dut_mem la gia tri cu, dung voi yeu cau.
    AP_F02_2A: assert property (
        disable iff (!rst_n)
        rs1_data_o == dut_mem[rs1_addr_i]
    ) else $error("AP-F02-2A rs1_data=%h != mem[%0d]=%h t=%0t",
                  rs1_data_o, rs1_addr_i, dut_mem[rs1_addr_i], $time);

    AP_F02_2B: assert property (
        disable iff (!rst_n)
        rs2_data_o == dut_mem[rs2_addr_i]
    ) else $error("AP-F02-2B rs2_data=%h != mem[%0d]=%h t=%0t",
                  rs2_data_o, rs2_addr_i, dut_mem[rs2_addr_i], $time);

    // AP-F02-3: doi dia chi -> output doi ngay trong cung chu ky (to hop).
    // Check bang #1 sau khi dia chi doi. Can `timescale 1ns/1ps` o file.
    always @(rs1_addr_i or rs2_addr_i) begin
        #1;
        if (rst_n) begin
            if (rs1_data_o !== dut_mem[rs1_addr_i])
                $error("AP-F02-3 rs1_data chua cap nhat ngay sau khi rs1_addr doi t=%0t", $time);
            if (rs2_data_o !== dut_mem[rs2_addr_i])
                $error("AP-F02-3 rs2_data chua cap nhat ngay sau khi rs2_addr doi t=%0t", $time);
        end
    end

    // AP-F02-4: cung clk, doc va ghi cung dia chi -> lay data CU
    AP_F02_4A: assert property (
        disable iff (!rst_n)
        (wb_i.reg_en && wb_i.rd_addr == rs1_addr_i && rs1_addr_i != REG_ZERO)
            |-> rs1_data_o == dut_mem[rs1_addr_i]
    ) else $error("AP-F02-4A rs1 lay data moi trong cung clk t=%0t", $time);

    AP_F02_4B: assert property (
        disable iff (!rst_n)
        (wb_i.reg_en && wb_i.rd_addr == rs2_addr_i && rs2_addr_i != REG_ZERO)
            |-> rs2_data_o == dut_mem[rs2_addr_i]
    ) else $error("AP-F02-4B rs2 lay data moi trong cung clk t=%0t", $time);

    // AP-F02-5: ghi o clk k, doc cung dia chi o clk k+1 -> lay data moi
    AP_F02_5A: assert property (
        disable iff (!rst_n)
        ($past(wb_i.reg_en) && $past(wb_i.rd_addr) == rs1_addr_i && rs1_addr_i != REG_ZERO)
            |-> rs1_data_o == $past(wb_i.rd_data)
    ) else $error("AP-F02-5A rs1 khong doc duoc data vua ghi t=%0t", $time);

    AP_F02_5B: assert property (
        disable iff (!rst_n)
        ($past(wb_i.reg_en) && $past(wb_i.rd_addr) == rs2_addr_i && rs2_addr_i != REG_ZERO)
            |-> rs2_data_o == $past(wb_i.rd_data)
    ) else $error("AP-F02-5B rs2 khong doc duoc data vua ghi t=%0t", $time);

    // ============================================================
    // AP-F03: reset (bat dong bo)
    // ============================================================

    // AP-F03-1 & F03-2: trong reset, o moi canh clk mem = 0,
    // ke ca khi wb_i.reg_en = 1 (reset uu tien hon ghi).
    AP_F03_1: assert property (
        @(posedge clk) !rst_n |-> mem_zero
    ) else $error("AP-F03-1/2 trong reset mem != 0 t=%0t", $time);

    // AP-F03-3: rst_n xuong 0 -> mem = 0 ngay, khong cho canh clk.
    always @(negedge rst_n) begin
        #1;
        if (mem_zero !== 1'b1 || rs1_data_o !== '0 || rs2_data_o !== '0)
            $error("AP-F03-3 chua xoa ngay khi rst_n=0 t=%0t", $time);
    end

    // AP-F03-4: luc rst_n len 1, mem van = 0 (chua co ghi nao)
    AP_F03_4: assert property (
        $rose(rst_n) |-> mem_zero
    ) else $error("AP-F03-4 sau reset mem != 0 t=%0t", $time);

    // ============================================================
    // AP-F04: x0
    // ============================================================

    // AP-F04-1: mem[0] = 0 tai moi thoi diem
    always @(dut_mem[0]) begin
        if (rst_n && dut_mem[0] !== '0)
            $error("AP-F04-1 mem[0] != 0 t=%0t", $time);
    end

    // AP-F04-2: ghi vao x0 voi bat ky rd_data nao -> mem[0] van = 0
    AP_F04_2: assert property (
        disable iff (!rst_n)
        (wb_i.reg_en && wb_i.rd_addr == REG_ZERO) |=> dut_mem[0] == '0
    ) else $error("AP-F04-2 ghi x0 lam mem[0] != 0 t=%0t", $time);

    // AP-F04-3: doc x0 luon ra 0
    AP_F04_3A: assert property (
        disable iff (!rst_n)
        rs1_addr_i == REG_ZERO |-> rs1_data_o == '0
    ) else $error("AP-F04-3A doc x0 tra ve rs1_data != 0 t=%0t", $time);

    AP_F04_3B: assert property (
        disable iff (!rst_n)
        rs2_addr_i == REG_ZERO |-> rs2_data_o == '0
    ) else $error("AP-F04-3B doc x0 tra ve rs2_data != 0 t=%0t", $time);

endmodule

// ============================================================
// Bind: dat ngoai module regfile, o muc compilation unit
// ============================================================
bind regfile regfile_assert u_regfile_chk (
    .clk       (clk),
    .rst_n     (rst_n),
    .rs1_addr_i(rs1_addr_i),
    .rs2_addr_i(rs2_addr_i),
    .wb_i      (wb_i),
    .rs1_data_o(rs1_data_o),
    .rs2_data_o(rs2_data_o),
    .dut_mem   (mem_reg)
);