// class hz_fwd_gene;
//     virtual hz_fwd_if.DRV  vif;
//     mailbox #(hz_fwd_txn)  gen2drv;
//     int                    num_txn;
//     event                  done;

//     function new(mailbox #(hz_fwd_txn) gen2drv, int num_txn = 0);
//         this.gen2drv = gen2drv;
//         this.num_txn = num_txn;
//     endfunction

//     // ---------- 1. ĐỊA CHỈ: mỗi hàm là một case ----------
//     // 1: rs1, rs2, rd_ex, rd_mem, rd_wb đôi một khác nhau
//     function void khac_nhau(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs1_addr != for_info_wb.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//             rs2_addr != for_info_wb.rd_addr;
//         };
//         if (!ok) $fatal(1, "khac_nhau: randomize failed");
//     endfunction

//     // 2: rs1 == rd_ex
//     function void rs1_rd_ex(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr == for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs1_addr != for_info_wb.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//             rs2_addr != for_info_wb.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs1_rd_ex: randomize failed");
//     endfunction

//     // 3: rs1 == rd_mem
//     function void rs1_rd_mem(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr == for_info_mem.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs1_rd_mem: randomize failed");
//     endfunction

//     // 4: rs1 == rd_ex == rd_mem
//     function void rs1_rd_ex_rd_mem(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr == for_info_ex.rd_addr;
//             rs1_addr == for_info_mem.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs1_rd_ex_rd_mem: randomize failed");
//     endfunction

//     // 5: rs2 == rd_ex  (đã sửa: rs1 != rd_ex, không phải == )
//     function void rs2_rd_ex(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs2_addr == for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs2_rd_ex: randomize failed");
//     endfunction

//     // 6: rs2 == rd_mem  (đã sửa k == 6)
//     function void rs2_rd_mem(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr == for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs2_rd_mem: randomize failed");
//     endfunction

//     // 7: rs2 == rd_ex == rd_mem
//     function void rs2_rd_ex_rd_mem(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr != rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs1_addr != for_info_wb.rd_addr;
//             rs2_addr == for_info_ex.rd_addr;
//             rs2_addr == for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs2_rd_ex_rd_mem: randomize failed");
//     endfunction

//     // 8: rs1 == rs2 == rd_ex, rd_mem khác
//     function void rs1_rs2_rd_ex(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr == rs2_addr;
//             rs1_addr == for_info_ex.rd_addr;
//             rs1_addr != for_info_mem.rd_addr;
//             rs1_addr != for_info_wb.rd_addr;
//             rs2_addr == for_info_ex.rd_addr;
//             rs2_addr != for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs1_rs2_rd_ex: randomize failed");
//     endfunction

//     // 9: rs1 == rs2 == rd_mem, rd_ex khác
//     function void rs1_rs2_rd_mem(hz_fwd_txn t);
//         bit ok;
//         ok = t.randomize() with {
//             rs1_addr == rs2_addr;
//             rs1_addr != for_info_ex.rd_addr;
//             rs1_addr == for_info_mem.rd_addr;
//             rs2_addr != for_info_ex.rd_addr;
//             rs2_addr == for_info_mem.rd_addr;
//         };
//         if (!ok) $fatal(1, "rs1_rs2_rd_mem: randomize failed");
//     endfunction

//     // Chọn case theo k
//     function void set_addr(hz_fwd_txn t, int k);
//         case (k)
//             1: khac_nhau(t);
//             2: rs1_rd_ex(t);
//             3: rs1_rd_mem(t);
//             4: rs1_rd_ex_rd_mem(t);
//             5: rs2_rd_ex(t);
//             6: rs2_rd_mem(t);
//             7: rs2_rd_ex_rd_mem(t);
//             8: rs1_rs2_rd_ex(t);
//             9: rs1_rs2_rd_mem(t);
//             default: $fatal(1, "set_addr: k=%0d khong hop le", k);
//         endcase
//     endfunction

//     // ---------- 2. 6 CỜ: f = 0..63 ----------
//     function void set_flags(hz_fwd_txn t, int f);
//         t.rs1_used            = f[0];
//         t.rs2_used            = f[1];
//         t.for_info_ex.reg_en  = f[2];
//         t.for_info_ex.mem_re  = f[3];
//         t.for_info_mem.reg_en = f[4];
//         t.for_info_mem.mem_re = f[5];
//     endfunction

//     // ---------- 3. JUMP / BRANCH: c = 0 none, 1 jump, 2 branch ----------
//     function void set_ctrl(hz_fwd_txn t, int c);
//         t.jump_en  = (c == 1);
//         t.br_en    = (c == 2);
//         t.br_taken = $urandom_range(0, 1);
//     endfunction

//     // ---------- Quét: 9 địa chỉ × 3 điều khiển × 64 cờ = 1728 ----------
//     task run_sweep();
//         hz_fwd_txn t;
//         for (int k = 1; k <= 9; k++)
//             for (int c = 0; c < 3; c++)
//                 for (int f = 0; f < 64; f++) begin
//                     t = new();
//                     set_addr(t, k);    // gọi đầu tiên: randomize có ràng buộc địa chỉ
//                     set_flags(t, f);   // ghi đè 6 cờ
//                     set_ctrl(t, c);    // ghi đè jump/br
//                     // ref_model(t);   // tính expected_* nếu generator làm việc này
//                     gen2drv.put(t);
//                 end
//         -> done;
//     endtask














class hz_fwd_gene;
    virtual hz_fwd_if.DRV  vif;
    mailbox #(hz_fwd_txn)  gen2drv;
    int                    num_txn;
    event                  done;

    function new(mailbox #(hz_fwd_txn) gen2drv, int num_txn = 0);
        this.gen2drv = gen2drv;
        this.num_txn = num_txn;
    endfunction

    // ---------- 1. ĐỊA CHỈ ----------
    // m1[s] / m2[s]: rs1 / rs2 có bằng rd của stage s không (s: 0=EX, 1=MEM, 2=WB)
    // eq:  rs1 == rs2
    // x0:  stage bị khớp thì rd của stage đó = x0 (kiểm tra nhánh REG_ZERO)
    function bit feasible(bit [2:0] m1, bit [2:0] m2, bit eq);
        return eq ? (m1 == m2) : ((m1 & m2) == 0);
    endfunction

    function bit set_addr(hz_fwd_txn t, bit [2:0] m1, bit [2:0] m2, bit eq, bit x0);
        bit ok;
        ok = (t.randomize() with {
            if (m1[0]) rs1_addr == for_info_ex.rd_addr;  else rs1_addr != for_info_ex.rd_addr;
            if (m1[1]) rs1_addr == for_info_mem.rd_addr; else rs1_addr != for_info_mem.rd_addr;
            if (m1[2]) rs1_addr == for_info_wb.rd_addr;  else rs1_addr != for_info_wb.rd_addr;

            if (m2[0]) rs2_addr == for_info_ex.rd_addr;  else rs2_addr != for_info_ex.rd_addr;
            if (m2[1]) rs2_addr == for_info_mem.rd_addr; else rs2_addr != for_info_mem.rd_addr;
            if (m2[2]) rs2_addr == for_info_wb.rd_addr;  else rs2_addr != for_info_wb.rd_addr;

            if (eq) rs1_addr == rs2_addr; else rs1_addr != rs2_addr;

            // Không có stage nào bị khớp: 3 rd khác nhau (case "khác nhau")
            if (m1 == 0 && m2 == 0) {
                for_info_ex.rd_addr  != for_info_mem.rd_addr;
                for_info_ex.rd_addr  != for_info_wb.rd_addr;
                for_info_mem.rd_addr != for_info_wb.rd_addr;
            }

            // Stage bị khớp mà rd = x0: forward_id phải KHÔNG forward
            if (x0) {
                if (m1[0] || m2[0]) for_info_ex.rd_addr  == REG_ZERO;
                if (m1[1] || m2[1]) for_info_mem.rd_addr == REG_ZERO;
                if (m1[2] || m2[2]) for_info_wb.rd_addr  == REG_ZERO;
            }
        }) == 1;
        return ok;
    endfunction

    // ---------- 2. CỜ CỦA STAGE: f = 0..255 ----------
    function void set_flags(hz_fwd_txn t, int f);
        t.rs1_used            = f[0];
        t.rs2_used            = f[1];
        t.for_info_ex.reg_en  = f[2];
        t.for_info_ex.mem_re  = f[3];
        t.for_info_mem.reg_en = f[4];
        t.for_info_mem.mem_re = f[5];
        t.for_info_wb.reg_en  = f[6];
        t.for_info_wb.mem_re  = f[7];
    endfunction

    // ---------- 3. JUMP / BRANCH: c = 0..3 ----------
    // 0: không rẽ nhánh   1: jump (JAL/JALR)
    // 2: branch không nhảy   3: branch nhảy
    function void set_ctrl(hz_fwd_txn t, int c);
        t.jump_en  = (c == 1);
        t.br_en    = (c >= 2);
        t.br_taken = (c == 3);
    endfunction

    // ---------- 4. EXPECTED CHO forward_id ----------
    // Cùng thứ tự ưu tiên với RTL: EX > MEM > WB, rs != 0, rd != 0
    function for_sel_e exp_for_id(riscv_reg_e rs,
                                  for_info_t ex, for_info_t mem, for_info_t wb,
                                  for_sel_e dflt);
        if (rs != REG_ZERO) begin
            if (ex.reg_en  && ex.rd_addr  != REG_ZERO && rs == ex.rd_addr)  return RD_DATA_EX;
            if (mem.reg_en && mem.rd_addr != REG_ZERO && rs == mem.rd_addr) return RD_DATA_MEM;
            if (wb.reg_en  && wb.rd_addr  != REG_ZERO && rs == wb.rd_addr)  return RD_DATA_WB;
        end
        return dflt;
    endfunction

    function void calc_expected(hz_fwd_txn t);
        t.expected_for_id_a = exp_for_id(t.rs1_addr, t.for_info_ex, t.for_info_mem,
                                         t.for_info_wb, RS1_DATA_ID);
        t.expected_for_id_b = exp_for_id(t.rs2_addr, t.for_info_ex, t.for_info_mem,
                                         t.for_info_wb, RS2_DATA_ID);
    endfunction

    // ---------- Quét ----------
    // Địa chỉ: 68 tổ hợp (m1, m2, eq, x0) hợp lệ
    // Ctrl: 4, Cờ: 256  ->  68 × 4 × 256 = 69632 transaction
    // task run();
    //     hz_fwd_txn t;
    //     for (int m1 = 0; m1 < 8; m1++)
    //       for (int m2 = 0; m2 < 8; m2++)
    //         for (int eq = 0; eq < 2; eq++)
    //           for (int x0 = 0; x0 < 2; x0++) begin
    //             if (!feasible(m1[2:0], m2[2:0], eq)) continue;
    //             if (x0 && ((m1 | m2) == 0)) continue;
    //             for (int c = 0; c < 4; c++)
    //               for (int f = 0; f < 256; f++) begin
    //                 t = new();
    //                 if (!set_addr(t, m1[2:0], m2[2:0], eq, x0))
    //                     $fatal(1, "set_addr fail m1=%b m2=%b eq=%0d x0=%0d",
    //                            m1[2:0], m2[2:0], eq, x0);
    //                 set_flags(t, f);     // sau set_addr, vì randomize ghi đè các field
    //                 set_ctrl(t, c);
    //                 calc_expected(t);    // sau cùng, khi mọi input đã cố định
    //                 gen2drv.put(t);
    //               end
    //           end
    //     -> done;
    // endtask


    task run();
    hz_fwd_txn t;
    for (int m1 = 0; m1 < 8; m1++)
      for (int m2 = 0; m2 < 8; m2++)
        for (int eq_i = 0; eq_i < 2; eq_i++)
          for (int x0_i = 0; x0_i < 2; x0_i++) begin
            bit eq = eq_i[0];
            bit x0 = x0_i[0];

            if (!feasible(m1[2:0], m2[2:0], eq)) continue;
            if (x0 && ((m1 | m2) == 0)) continue;

            for (int c = 0; c < 4; c++)
              for (int f = 0; f < 256; f++) begin
                t = new();
                if (!set_addr(t, m1[2:0], m2[2:0], eq, x0))
                    $fatal(1, "set_addr fail m1=%b m2=%b eq=%0d x0=%0d",
                           m1[2:0], m2[2:0], eq, x0);
                set_flags(t, f);
                set_ctrl(t, c);
                calc_expected(t);
                gen2drv.put(t);
              end
          end
    -> done;
endtask
endclass









  







































// package hazard_gen_pkg;

//   // ---- Quy ước của testbench ----
//   localparam bit [4:0] REG_ZERO = 5'd0;
//   localparam bit [4:0] BASE_REG = 5'd1;  // base cho LOAD/STORE, không lệnh nào được ghi đè
//   localparam int       MAX_WORD = 16;    // vùng nhớ hợp lệ: 16 word
//   localparam int       MAX_JMP  = 3;     // branch/jal chỉ nhảy tới phía trước (không tạo vòng lặp)

//   typedef enum logic [2:0] {
//     CLS_ALU, CLS_LOAD, CLS_STORE, CLS_BRANCH, CLS_JAL
//   } cls_e;

//   typedef enum int {
//     PAT_RAND,           // lệnh độc lập, không khuôn
//     PAT_FALSE_DEP,      // trùng rs2 nhưng lệnh không đọc rs2 -> KHÔNG được stall
//     PAT_X0,             // producer ghi x0, consumer đọc x0 -> KHÔNG được stall
//     PAT_ALU_ALU,        // ALU -> ALU / ALU -> STORE data (forwarding)
//     PAT_ALU_BR,         // ALU -> branch (br2alu_ex)
//     PAT_LOAD_USE,       // LOAD -> ALU/STORE data (alu2load)
//     PAT_LOAD_BR,        // LOAD -> branch (br2load_ex / br2load_mem)
//     PAT_LOAD_BR_TAKEN,  // LOAD -> branch taken: stall phải thắng flush
//     PAT_TAKEN,          // JAL / branch taken: kiểm tra flush_if_id
//     PAT_WB              // producer đã ở WB khi consumer vào ID -> KHÔNG stall
//   } pat_e;

//   // ============================================================
//   // 1. Một lệnh
//   // ============================================================
//   class riscv_instr;
//     rand cls_e       cls;
//     rand bit [4:0]   rd, rs1, rs2;
//     rand bit         use_rs2;     // chỉ có nghĩa với ALU R-type
//     rand int         imm;         // LOAD/STORE: word index; BRANCH/JAL: số lệnh nhảy tới
//     rand bit         want_taken;  // gợi ý cho data-init (BEQ rs1==rs2, BNE rs1!=rs2)

//     // Ràng buộc cứng: đảm bảo chương trình hợp lệ
//     constraint c_base {
//       (cls inside {CLS_LOAD, CLS_STORE}) -> rs1 == BASE_REG;
//       (cls inside {CLS_ALU, CLS_LOAD, CLS_JAL}) -> rd != BASE_REG;
//     }
//     constraint c_imm {
//       (cls inside {CLS_LOAD, CLS_STORE}) -> imm inside {[0:MAX_WORD-1]};
//       (cls inside {CLS_BRANCH, CLS_JAL}) -> imm inside {[1:MAX_JMP]};
//       (cls == CLS_ALU)                   -> imm inside {[-2048:2047]};
//     }
//     constraint c_taken { (cls != CLS_BRANCH) -> !want_taken; }

//     // Phân bố tổng quát cho lệnh rời rạc
//     constraint c_mix {
//       cls dist {CLS_ALU := 40, CLS_LOAD := 20, CLS_STORE := 10,
//                 CLS_BRANCH := 20, CLS_JAL := 10};
//     }

//     // Mô phỏng logic rs1_used_i / rs2_used_i / writes_rd của decode
//     function bit rs1_used();
//       return (cls inside {CLS_ALU, CLS_LOAD, CLS_STORE, CLS_BRANCH});
//     endfunction
//     function bit rs2_used();
//       return (cls == CLS_STORE) || (cls == CLS_BRANCH) || (cls == CLS_ALU && use_rs2);
//     endfunction
//   endclass

//   // ============================================================
//   // 2. Một khuôn: producer -> [gap lệnh xen giữa] -> consumer
//   // gap = số lệnh xen giữa. Producer ở EX khi gap=0, MEM khi gap=1, WB khi gap>=2.
//   // ============================================================
//   class hazard_chain;
//     rand pat_e        pat;
//     rand int unsigned gap;
//     rand riscv_instr  prod;
//     rand riscv_instr  cons;

//     function void pre_randomize();
//       prod = new();
//       cons = new();
//     endfunction

//     constraint c_pat { pat != PAT_RAND; }

//     constraint c_gap {
//       pat == PAT_WB           -> gap inside {[2:3]};
//       pat == PAT_LOAD_BR_TAKEN -> gap == 0;
//       pat == PAT_ALU_ALU      -> gap dist {0 := 60, 1 := 40};
//       pat == PAT_ALU_BR       -> gap dist {0 := 60, 1 := 40};
//       pat == PAT_LOAD_USE     -> gap dist {0 := 60, 1 := 40};
//       pat == PAT_LOAD_BR      -> gap dist {0 := 50, 1 := 50};
//       pat == PAT_FALSE_DEP    -> gap inside {[0:2]};
//       pat == PAT_X0           -> gap inside {[0:1]};
//       pat == PAT_TAKEN        -> gap inside {[0:2]};
//     }

//     // Producer
//     constraint c_prod {
//       pat inside {PAT_LOAD_USE, PAT_LOAD_BR, PAT_LOAD_BR_TAKEN} -> prod.cls == CLS_LOAD;
//       pat inside {PAT_ALU_ALU, PAT_ALU_BR, PAT_WB, PAT_FALSE_DEP, PAT_X0} -> prod.cls == CLS_ALU;
//       pat inside {PAT_ALU_ALU, PAT_ALU_BR, PAT_WB, PAT_LOAD_USE,
//                   PAT_LOAD_BR, PAT_LOAD_BR_TAKEN} -> prod.rd != REG_ZERO;
//       pat == PAT_X0 -> prod.rd == REG_ZERO;
//     }

//     // Consumer: hazard thật phải đi qua đúng đường rs1_used/rs2_used
//     constraint c_cons {
//       pat == PAT_ALU_ALU -> ((cons.cls == CLS_ALU && cons.rs1 == prod.rd) ||
//                              (cons.cls == CLS_STORE && cons.rs2 == prod.rd));
//       pat == PAT_LOAD_USE -> ((cons.cls == CLS_ALU && cons.rs1 == prod.rd) ||
//                               (cons.cls == CLS_STORE && cons.rs2 == prod.rd));
//       pat == PAT_ALU_BR -> (cons.cls == CLS_BRANCH &&
//                             (cons.rs1 == prod.rd || cons.rs2 == prod.rd));
//       pat == PAT_LOAD_BR -> (cons.cls == CLS_BRANCH &&
//                              (cons.rs1 == prod.rd || cons.rs2 == prod.rd));
//       pat == PAT_LOAD_BR_TAKEN -> (cons.cls == CLS_BRANCH && cons.want_taken &&
//                                    (cons.rs1 == prod.rd || cons.rs2 == prod.rd));
//       pat == PAT_WB -> (cons.cls == CLS_ALU && cons.rs1 == prod.rd);
//       // rs2 trùng nhưng không dùng; rs1 phải khác để không tạo dependency thật
//       pat == PAT_FALSE_DEP -> (cons.cls == CLS_ALU && !cons.use_rs2 &&
//                                cons.rs2 == prod.rd && cons.rs1 != prod.rd);
//       pat == PAT_X0 -> (cons.cls == CLS_ALU && cons.rs1 == REG_ZERO);
//       pat == PAT_TAKEN -> ((cons.cls == CLS_JAL) ||
//                            (cons.cls == CLS_BRANCH && cons.want_taken));
//     }
//   endclass

//   // ============================================================
//   // 3. Bảng phân bố pattern (chỗ chỉnh theo coverage)
//   // ============================================================
//   class pat_sel;
//     rand pat_e p;
//     constraint c_w {
//       p dist {PAT_RAND := 10, PAT_FALSE_DEP := 8, PAT_X0 := 6,
//               PAT_ALU_ALU := 12, PAT_ALU_BR := 10, PAT_LOAD_USE := 12,
//               PAT_LOAD_BR := 12, PAT_LOAD_BR_TAKEN := 8,
//               PAT_TAKEN := 10, PAT_WB := 8};
//     }
//   endclass

//   // ============================================================
//   // 4. Sinh chương trình
//   // ============================================================
//   class hazard_prog_gen;
//     riscv_instr prog[$];
//     pat_sel     psel = new();

//     function void gen(int unsigned n);
//       hazard_chain ch;
//       riscv_instr  f;
//       prog.delete();
//       while (prog.size() < n) begin
//         if (!psel.randomize()) $fatal(1, "pat_sel randomize fail");
//         if (psel.p == PAT_RAND) begin
//           f = new();
//           if (!f.randomize()) $fatal(1, "instr randomize fail");
//           prog.push_back(f);
//         end else begin
//           ch = new();
//           if (!ch.randomize() with { pat == psel.p; })
//             $fatal(1, "chain randomize fail");
//           emit(ch);
//         end
//       end
//       // Đệm NOP để nhánh forward không nhảy ra khỏi chương trình
//       repeat (MAX_JMP) prog.push_back(nop());
//     endfunction

//     local function void emit(hazard_chain ch);
//       riscv_instr f;
//       prog.push_back(ch.prod);
//       repeat (ch.gap) begin
//         f = new();
//         // Filler không ghi producer.rd và không phải lệnh rẽ nhánh,
//         // để không phá chuỗi phụ thuộc đã chọn
//         if (!f.randomize() with {
//               cls inside {CLS_ALU, CLS_LOAD, CLS_STORE};
//               (cls inside {CLS_ALU, CLS_LOAD}) -> rd != ch.prod.rd;
//             }) $fatal(1, "filler randomize fail");
//         prog.push_back(f);
//       end
//       prog.push_back(ch.cons);
//     endfunction

//     function riscv_instr nop();
//       riscv_instr i = new();
//       i.cls = CLS_ALU;
//       i.rd = REG_ZERO; i.rs1 = REG_ZERO; i.rs2 = REG_ZERO;
//       i.use_rs2 = 0; i.imm = 0; i.want_taken = 0;
//       return i;
//     endfunction
//   endclass

// endpackage