class if_stage_cov;

    mailbox #(if_stage_txn) mon2cov;
    int sample= 0 ;
    real goal = 90.0;


    covergroup cg_pc_4 with function sample(if_stage_txn txn);

        







    endgroup















endclass
