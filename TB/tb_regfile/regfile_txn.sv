import isa_pkg::*;
import ctrl_pkg::*;
import core_pkg::*;


class regfile_txn;
    rand bit rst_n;
    rand riscv_reg_e rs1_addr;
    rand riscv_reg_e rs2_addr;
    rand regfile_wb wb;

    // DUT 
    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;

     // REF_model
    logic [XLEN-1:0] expected_rs1_data;
    logic [XLEN-1:0] expected_rs2_data;

    constraint c_rs1_addr {
            rs1_addr inside {
                [0:4]
            };
    };

    constraint c_rs2_addr {
            rs2_addr inside {
                [0:4]
            };
    };

    constraint c_wb {
        wb.reg_en dist {
            1 := 70,
            0 := 30
        };

        wb.rd_addr inside {
            [0:4]
        };

        wb.rd_data inside {
            [1: XLEN-1]
        };
    };


    function void copy ( regfile_txn rhs); 
        if ( rhs == null ) return; 
        rst_n = rhs.rst_n;
        rs1_addr = rhs.rs1_addr;
        rs2_addr = rhs.rs2_addr;
        wb = rhs.wb;
    endfunction 


    function regfile_txn clone();
        regfile_txn t = new();
        t.copy(this);
        return t;
    endfunction

    
    function string cover2string();
    return $sformatf(
        "RST_N = %0d\n RS1_ADDR = %0d\n RS2_ADDR = %0d\n WB_REG_EN = %0d\n WB_RD_ADDR = %0d\n WB_RD_DATA = %0d\n RS1_DATA = %0d\n RS2_DATA = %0d\n EXPECTED_RS1_DATA = %0d\n EXPECTED_RS2_DATA = %0d",
        rst_n,
        rs1_addr,
        rs2_addr,
        wb.reg_en,
        wb.rd_addr,
        wb.rd_data,
        rs1_data,
        rs2_data,
        expected_rs1_data,
        expected_rs2_data
    );
    endfunction

    



endclass