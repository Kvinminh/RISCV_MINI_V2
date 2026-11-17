import isa_pkg::*;
import core_pkg::*;

class ha_pipe_gene;

    // Kịch bản cho phase random
    typedef enum int {
        SC_RAND,        // random theo constraint mặc định
        SC_LOAD_USE,    // ALU phụ thuộc load ở EX
        SC_BR_EX,       // branch phụ thuộc EX
        SC_BR_MEM,      // branch phụ thuộc MEM
        SC_JUMP,        // jump hoặc branch taken
        SC_WIDE_MATCH,  // rs/rd 0..31, trùng nhau
        SC_WIDE_NEAR,   // rs/rd 0..31, khác nhau nhưng trùng 4 bit thấp
        SC_ZERO_RD,     // rd hoặc rs = x0
        SC_NO_EN,       // trùng địa chỉ nhưng reg_en = 0
        SC_RESET        // rst_n = 0
    } sc_e;

    // Số bit quét: 15 bit => 32768 tổ hợp, bỏ bớt tổ hợp không hợp lệ
    localparam int SWEEP_BITS = 15;

    mailbox #(ha_pipe_txn) gen2drv;
    ha_pipe_txn            plan[$];     // toàn bộ txn, dựng trong build()
    int                    num_rand;
    int                    num_sweep;
    event                  done;

    function new(mailbox #(ha_pipe_txn) gen2drv, int num_rand);
        this.gen2drv  = gen2drv;
        this.num_rand = num_rand;
        this.num_sweep = 0;
    endfunction

    // Số txn thực tế, dùng để truyền cho drv/mon/sb
    function int total();
        return plan.size();
    endfunction

    //////////////////////////////////////////
    // PHASE 1: QUÉT ĐỀU KHÔNG GIAN HAZARD
    // Bit của chỉ số i:
    //  0 rs1_used    1 rs2_used    2 ex_en      3 mem_en
    //  4 ex_mre      5 mem_mre     6 br_en      7 jump_en
    //  8 br_taken    9 rs1==rd_ex  10 rs2==rd_ex 11 rs1==rd_mem
    //  12 rs2==rd_mem 13 rd_ex==rd_mem 14 rd_ex==x0
    // Tổ hợp không khả thi bị randomize bỏ qua
    //////////////////////////////////////////
    function void build_sweep();
        ha_pipe_txn t;
        bit s1u, s2u, exen, memen, exmre, memmre;
        bit bre, jmp, brt, mx1, mx2, mm1, mm2, same, zex;
        bit ok;

        for (int i = 0; i < (1 << SWEEP_BITS); i++) begin
            s1u    = i[0];   s2u   = i[1];   exen = i[2];   memen = i[3];
            exmre  = i[4];   memmre = i[5];  bre  = i[6];   jmp   = i[7];
            brt    = i[8];   mx1   = i[9];   mx2  = i[10];  mm1   = i[11];
            mm2    = i[12];  same  = i[13];  zex  = i[14];

            if (bre && jmp) continue;   // AP_F01_3

            t  = new();
            ok = (t.randomize() with {
                rst_n == 1'b1;
                rs1_used == s1u;
                rs2_used == s2u;
                for_info_ex.reg_en  == exen;
                for_info_mem.reg_en == memen;
                for_info_ex.mem_re  == exmre;
                for_info_mem.mem_re == memmre;
                br_en    == bre;
                jump_en  == jmp;
                br_taken == brt;
                ((rs1_addr == for_info_ex.rd_addr)  == mx1);
                ((rs2_addr == for_info_ex.rd_addr)  == mx2);
                ((rs1_addr == for_info_mem.rd_addr) == mm1);
                ((rs2_addr == for_info_mem.rd_addr) == mm2);
                ((for_info_ex.rd_addr == for_info_mem.rd_addr) == same);
                ((for_info_ex.rd_addr == REG_ZERO) == zex);
            }) == 1;

            if (ok) plan.push_back(t);
        end
        num_sweep = plan.size();
    endfunction

    //////////////////////////////////////////
    // PHASE 2: RANDOM CÓ KỊCH BẢN
    //////////////////////////////////////////
    function sc_e pick_sc();
        int r;
        r = $urandom_range(0, 99);
        if      (r < 25) return SC_RAND;
        else if (r < 40) return SC_LOAD_USE;
        else if (r < 52) return SC_BR_EX;
        else if (r < 62) return SC_BR_MEM;
        else if (r < 70) return SC_JUMP;
        else if (r < 77) return SC_WIDE_MATCH;
        else if (r < 83) return SC_WIDE_NEAR;
        else if (r < 89) return SC_ZERO_RD;
        else if (r < 95) return SC_NO_EN;
        else             return SC_RESET;
    endfunction

    function bit gen_one(sc_e sc, ha_pipe_txn t);
        bit ok;
        case (sc)
            SC_RAND: ok = (t.randomize() == 1);

            SC_LOAD_USE: ok = (t.randomize() with {
                br_en == 0;
                for_info_ex.reg_en == 1;
                for_info_ex.mem_re == 1;
                for_info_ex.rd_addr != REG_ZERO;
                ((rs1_used == 1) && (rs1_addr == for_info_ex.rd_addr)) ||
                ((rs2_used == 1) && (rs2_addr == for_info_ex.rd_addr));
            }) == 1;

            SC_BR_EX: ok = (t.randomize() with {
                br_en == 1;
                jump_en == 0;
                for_info_ex.reg_en == 1;
                for_info_ex.rd_addr != REG_ZERO;
                ((rs1_used == 1) && (rs1_addr == for_info_ex.rd_addr)) ||
                ((rs2_used == 1) && (rs2_addr == for_info_ex.rd_addr));
            }) == 1;

            SC_BR_MEM: ok = (t.randomize() with {
                br_en == 1;
                jump_en == 0;
                for_info_mem.reg_en == 1;
                for_info_mem.mem_re == 1;
                for_info_mem.rd_addr != REG_ZERO;
                ((rs1_used == 1) && (rs1_addr == for_info_mem.rd_addr)) ||
                ((rs2_used == 1) && (rs2_addr == for_info_mem.rd_addr));
            }) == 1;

            SC_JUMP: ok = (t.randomize() with {
                (jump_en == 1 && br_en == 0) ||
                (br_en == 1 && br_taken == 1 && jump_en == 0);
            }) == 1;

            SC_WIDE_MATCH: ok = (t.randomize() with {
                rs1_used == 1;
                for_info_ex.reg_en == 1;
                rs1_addr inside {[0:31]};
                for_info_ex.rd_addr inside {[0:31]};
                rs1_addr == for_info_ex.rd_addr;
            }) == 1;

            // rs1 khác rd nhưng 4 bit thấp giống nhau: bắt lỗi so sánh thiếu bit
            SC_WIDE_NEAR: ok = (t.randomize() with {
                rs1_used == 1;
                for_info_ex.reg_en == 1;
                for_info_ex.mem_re == 1;
                br_en == 0;
                rs1_addr inside {[0:31]};
                for_info_ex.rd_addr inside {[0:31]};
                rs1_addr != for_info_ex.rd_addr;
                ((int'(rs1_addr) - int'(for_info_ex.rd_addr)) % 16) == 0;
            }) == 1;

            SC_ZERO_RD: ok = (t.randomize() with {
                for_info_ex.reg_en == 1;
                for_info_mem.reg_en == 1;
                for_info_ex.mem_re == 1;
                for_info_mem.mem_re == 1;
                (for_info_ex.rd_addr == REG_ZERO) || (for_info_mem.rd_addr == REG_ZERO);
                ((rs1_used == 1) && (rs1_addr == REG_ZERO)) ||
                ((rs2_used == 1) && (rs2_addr == REG_ZERO));
            }) == 1;

            SC_NO_EN: ok = (t.randomize() with {
                br_en == 0;
                rs1_used == 1;
                for_info_ex.reg_en == 0;
                for_info_ex.mem_re == 1;
                rs1_addr == for_info_ex.rd_addr;
            }) == 1;

            SC_RESET: ok = (t.randomize() with {
                rst_n == 1'b0;
            }) == 1;

            default: ok = (t.randomize() == 1);
        endcase
        return ok;
    endfunction

    function void build_random();
        ha_pipe_txn t;
        sc_e        sc;
        bit         ok;
        int         tries;

        for (int k = 0; k < num_rand; k++) begin
            sc    = pick_sc();
            ok    = 0;
            tries = 0;
            while (!ok && tries < 50) begin
                t     = new();
                ok    = gen_one(sc, t);
                tries++;
            end
            if (!ok) $fatal(1, "[GEN] scenario %s khong randomize duoc", sc.name());
            plan.push_back(t);
        end
    endfunction

    //////////////////////////////////////////
    // BUILD: dựng toàn bộ plan trước khi chạy
    //////////////////////////////////////////
    function void build();
        plan.delete();
        build_sweep();
        build_random();
        plan.shuffle();   // xáo trộn thứ tự, tránh chuỗi sweep quá có cấu trúc
        $display("[GEN] sweep=%0d random=%0d total=%0d",
                 num_sweep, num_rand, plan.size());
    endfunction

    //////////////////////////////////////////
    // RUN: đưa toàn bộ plan vào mailbox
    //////////////////////////////////////////
    task run();
        foreach (plan[i]) gen2drv.put(plan[i]);
        -> done;
    endtask

endclass