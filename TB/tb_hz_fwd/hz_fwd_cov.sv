import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;

class hz_fwd_cov;

    // Kết quả so khớp của một rs với rd ở EX / MEM / WB
    typedef struct packed {
        logic ex;
        logic mem;
        logic wb;
    } hz_match_t;

    mailbox #(hz_fwd_txn) mon2cov;
    int                   num_txn;
    int                   sample_cnt = 0;
    real                  goal = 90.0;

    // ============================================================
    // CG_CTRL: tín hiệu điều khiển đầu vào
    // ============================================================
    covergroup cg_ctrl with function sample(hz_fwd_txn txn);
        option.per_instance = 1;

        cp_rs1_used: coverpoint txn.rs1_used   { bins no = {0}; bins yes = {1}; }
        cp_rs2_used: coverpoint txn.rs2_used   { bins no = {0}; bins yes = {1}; }
        cp_ex_reg:   coverpoint txn.for_info_ex.reg_en  { bins no = {0}; bins yes = {1}; }
        cp_mem_reg:  coverpoint txn.for_info_mem.reg_en { bins no = {0}; bins yes = {1}; }
        cp_wb_reg:   coverpoint txn.for_info_wb.reg_en  { bins no = {0}; bins yes = {1}; }

        // {jump_en, br_en}: decode không sinh jump và branch cùng lúc
        cp_ctl: coverpoint {txn.jump_en, txn.br_en} {
            bins none   = {2'b00};
            bins jump   = {2'b10};
            bins branch = {2'b01};
            illegal_bins both = {2'b11};
        }

        // {br_en, br_taken}: br_taken chỉ có nghĩa khi br_en = 1
        cp_br: coverpoint {txn.br_en, txn.br_taken} {
            bins no_br        = {2'b00, 2'b01};
            bins br_not_taken = {2'b10};
            bins br_taken     = {2'b11};
        }

        cx_used_reg: cross cp_rs1_used, cp_rs2_used, cp_ex_reg, cp_mem_reg;
    endgroup

    // ============================================================
    // CG_ADDR: địa chỉ theo nhóm (zero / low 1..4 / high 5..31)
    // ============================================================
    covergroup cg_addr with function sample(hz_fwd_txn txn);
        option.per_instance = 1;

        cp_rs1: coverpoint txn.rs1_addr {
            bins zero = {REG_ZERO};
            bins low  = {[1:4]};
            bins high = {[5:31]};
        }
        cp_rs2: coverpoint txn.rs2_addr {
            bins zero = {REG_ZERO};
            bins low  = {[1:4]};
            bins high = {[5:31]};
        }
        cp_rd_ex: coverpoint txn.for_info_ex.rd_addr {
            bins zero = {REG_ZERO};
            bins low  = {[1:4]};
            bins high = {[5:31]};
        }
        cp_rd_mem: coverpoint txn.for_info_mem.rd_addr {
            bins zero = {REG_ZERO};
            bins low  = {[1:4]};
            bins high = {[5:31]};
        }
        cp_rd_wb: coverpoint txn.for_info_wb.rd_addr {
            bins zero = {REG_ZERO};
            bins low  = {[1:4]};
            bins high = {[5:31]};
        }

        cx_rs1_ex:  cross cp_rs1, cp_rd_ex;
        cx_rs2_ex:  cross cp_rs2, cp_rd_ex;
        cx_rs1_mem: cross cp_rs1, cp_rd_mem;
        cx_rs2_mem: cross cp_rs2, cp_rd_mem;
        cx_rs1_wb:  cross cp_rs1, cp_rd_wb;
        cx_rs2_wb:  cross cp_rs2, cp_rd_wb;
    endgroup

    // ============================================================
    // CG_DEP: phát hiện phụ thuộc (tầng 1)
    // ============================================================
    covergroup cg_dep with function sample(hz_dep_t d, logic mre_ex, logic mre_mem);
        option.per_instance = 1;

        cp_dep:     coverpoint d;                       // 16 bin tự động
        cp_mre_ex:  coverpoint mre_ex  { bins no = {0}; bins yes = {1}; }
        cp_mre_mem: coverpoint mre_mem { bins no = {0}; bins yes = {1}; }

        cx_dep_mre: cross cp_dep, cp_mre_ex, cp_mre_mem;
    endgroup

    // ============================================================
    // CG_STALL: điều kiện stall (tầng 2)
    // {cmp, stall_cond}: cmp = jump_en || br_en
    // 8 tổ hợp hợp lệ, còn lại là illegal
    // ============================================================
    covergroup cg_stall with function sample(hz_stall_t s, logic cmp);
        option.per_instance = 1;

        cp_stall_cmp: coverpoint {cmp, s} {
            bins idle_nocmp     = {5'b0_0000};
            bins alu2load_nocmp = {5'b0_0001};   // alu2load cần cmp = 0
            bins idle_cmp       = {5'b1_0000};
            bins br2load_mem    = {5'b1_0010};
            bins br2alu_ex      = {5'b1_1000};
            bins br2alu_lmem    = {5'b1_1010};
            bins br2lex_alu2ld  = {5'b1_0101};
            bins br2lex_full    = {5'b1_0111};
            illegal_bins impossible = default;
        }
    endgroup

    // ============================================================
    // CG_HZD: stall / flush ra ngoài (tầng 3)
    // v = {need, take, flush_if_id}
    // ============================================================
    covergroup cg_hzd with function sample(logic [2:0] v, logic stall_ok);
        option.per_instance = 1;

        cp_out: coverpoint v {
            bins idle       = {3'b000};
            bins jump_flush = {3'b011};   // không stall, có jump -> flush
            bins stall      = {3'b100};   // stall, không jump
            bins stall_take = {3'b110};   // stall và có jump, flush bị chặn
            illegal_bins other = default;
        }

        // stall_pc = stall_if_id = flush_id_ex = need
        cp_stall_ok: coverpoint stall_ok {
            bins ok = {1};
            illegal_bins mismatch = {0};
        }
    endgroup

    // ============================================================
    // CG_FWD_ID: forward_id
    // Mã 6 bit = {ex, mem, wb, code}, code: 0=ID 1=EX 2=MEM 3=WB, 7=khác
    // 8 tổ hợp hợp lệ theo ưu tiên EX > MEM > WB > thanh ghi
    // ============================================================
    covergroup cg_fwd_id with function sample(logic [5:0] ca, logic [5:0] cb);
        option.per_instance = 1;

        cp_a: coverpoint ca {
            bins id_nomatch = {6'b000_000};
            bins ex_only    = {6'b100_001};
            bins ex_wb      = {6'b101_001};
            bins ex_mem     = {6'b110_001};
            bins ex_all     = {6'b111_001};
            bins mem_only   = {6'b010_010};
            bins mem_wb     = {6'b011_010};
            bins wb_only    = {6'b001_011};
            illegal_bins other = default;
        }

        cp_b: coverpoint cb {
            bins id_nomatch = {6'b000_000};
            bins ex_only    = {6'b100_001};
            bins ex_wb      = {6'b101_001};
            bins ex_mem     = {6'b110_001};
            bins ex_all     = {6'b111_001};
            bins mem_only   = {6'b010_010};
            bins mem_wb     = {6'b011_010};
            bins wb_only    = {6'b001_011};
            illegal_bins other = default;
        }
    endgroup

    // ============================================================
    // CG_FWD_EX: forward_ex
    // Mã 4 bit = {mem, wb, code}, code: 0=EX 1=MEM 2=WB, 3=khác
    // 4 tổ hợp hợp lệ, MEM ưu tiên hơn WB
    // ============================================================
    covergroup cg_fwd_ex with function sample(logic [3:0] ca, logic [3:0] cb);
        option.per_instance = 1;

        cp_a: coverpoint ca {
            bins ex_nomatch = {4'b0000};
            bins mem_only   = {4'b1001};
            bins mem_wb     = {4'b1101};   // MEM thắng WB
            bins wb_only    = {4'b0110};
            illegal_bins other = default;
        }

        cp_b: coverpoint cb {
            bins ex_nomatch = {4'b0000};
            bins mem_only   = {4'b1001};
            bins mem_wb     = {4'b1101};
            bins wb_only    = {4'b0110};
            illegal_bins other = default;
        }
    endgroup

    function new(mailbox #(hz_fwd_txn) mon2cov, int num_txn);
        this.mon2cov = mon2cov;
        this.num_txn = num_txn;

        cg_ctrl   = new();
        cg_addr   = new();
        cg_dep    = new();
        cg_stall  = new();
        cg_hzd    = new();
        cg_fwd_id = new();
        cg_fwd_ex = new();
    endfunction

    // So khớp của rs với rd ở EX / MEM / WB, theo đúng điều kiện RTL
    function automatic hz_match_t match_of(riscv_reg_e rs,
                                           for_info_t ex, for_info_t mem, for_info_t wb);
        hz_match_t m;
        m = '0;
        if (rs != REG_ZERO) begin
            m.ex  = ex.reg_en  && (ex.rd_addr  != REG_ZERO) && (ex.rd_addr  == rs);
            m.mem = mem.reg_en && (mem.rd_addr != REG_ZERO) && (mem.rd_addr == rs);
            m.wb  = wb.reg_en  && (wb.rd_addr  != REG_ZERO) && (wb.rd_addr  == rs);
        end
        return m;
    endfunction

    // Mã hóa cho forward_id: ghép match với lựa chọn DUT
    function automatic logic [5:0] enc_id(hz_match_t m, for_sel_e sel, for_sel_e id_val);
        logic [2:0] c;
        if      (sel == id_val)      c = 3'd0;
        else if (sel == RD_DATA_EX)  c = 3'd1;
        else if (sel == RD_DATA_MEM) c = 3'd2;
        else if (sel == RD_DATA_WB)  c = 3'd3;
        else                         c = 3'd7;
        return {m.ex, m.mem, m.wb, c};
    endfunction

    // Mã hóa cho forward_ex: chỉ có MEM và WB, EX là mặc định
    function automatic logic [3:0] enc_ex(hz_match_t m, forward_e sel);
        logic [1:0] c;
        if      (sel == RD_EX)  c = 2'd0;
        else if (sel == RD_MEM) c = 2'd1;
        else if (sel == RD_WB)  c = 2'd2;
        else                    c = 2'd3;
        return {m.mem, m.wb, c};
    endfunction

    function void sample_txn(hz_fwd_txn t);
        logic       cmp, take, need, stall_ok;
        hz_match_t  ma, mb;

        cmp  = t.jump_en || t.br_en;
        take = t.jump_en || (t.br_taken && t.br_en);
        need = (t.stall_cond != '0);

        stall_ok = (t.hzd_ctrl.stall_pc    == need)
                && (t.hzd_ctrl.stall_if_id == need)
                && (t.hzd_ctrl.flush_id_ex == need);

        ma = match_of(t.rs1_addr, t.for_info_ex, t.for_info_mem, t.for_info_wb);
        mb = match_of(t.rs2_addr, t.for_info_ex, t.for_info_mem, t.for_info_wb);

        cg_ctrl.sample(t);
        cg_addr.sample(t);
        cg_dep.sample(t.dep, t.for_info_ex.mem_re, t.for_info_mem.mem_re);
        cg_stall.sample(t.stall_cond, cmp);
        cg_hzd.sample({need, take, t.hzd_ctrl.flush_if_id}, stall_ok);
        cg_fwd_id.sample(enc_id(ma, t.for_id_a, RS1_DATA_ID),
                         enc_id(mb, t.for_id_b, RS2_DATA_ID));
        cg_fwd_ex.sample(enc_ex(ma, t.for_ex_a), enc_ex(mb, t.for_ex_b));

        sample_cnt++;
    endfunction

    task run();
        hz_fwd_txn txn;
        repeat (num_txn) begin
            mon2cov.get(txn);
            sample_txn(txn);
        end
    endtask

    function void report();
        real   cov[7];
        string nm[7];
        int    n_pass;
        real   total;
        string st;

        cov[0] = cg_ctrl.get_inst_coverage();   nm[0] = "cg_ctrl";
        cov[1] = cg_addr.get_inst_coverage();   nm[1] = "cg_addr";
        cov[2] = cg_dep.get_inst_coverage();    nm[2] = "cg_dep";
        cov[3] = cg_stall.get_inst_coverage();  nm[3] = "cg_stall";
        cov[4] = cg_hzd.get_inst_coverage();    nm[4] = "cg_hzd";
        cov[5] = cg_fwd_id.get_inst_coverage(); nm[5] = "cg_fwd_id";
        cov[6] = cg_fwd_ex.get_inst_coverage(); nm[6] = "cg_fwd_ex";

        n_pass = 0;
        total  = 0.0;

        $display("==================================================");
        $display("         HZ_FWD FUNCTIONAL COVERAGE REPORT");
        $display("==================================================");
        $display("  Transactions sampled : %0d", sample_cnt);
        $display("--------------------------------------------------");

        for (int i = 0; i < 7; i++) begin
            total += cov[i];
            if (cov[i] >= goal) begin
                st = "PASS";
                n_pass++;
            end
            else
                st = "FAIL";
            $display("  %-12s : %6.2f%%  [%s]", nm[i], cov[i], st);
        end

        total = total / 7.0;

        $display("--------------------------------------------------");
        $display("  Covergroups passed : %0d / 7", n_pass);
        $display("  TOTAL (average)    : %6.2f%% (goal %0.1f%%)", total, goal);
        $display("  RESULT             : %s", (n_pass == 7) ? "PASS" : "FAIL");
        $display("==================================================");
    endfunction

endclass