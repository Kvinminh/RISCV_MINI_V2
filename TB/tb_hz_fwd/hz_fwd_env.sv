// import hz_fwd_pkg::*;

class hz_fwd_env;
  hz_fwd_agt      agents;
  hz_fwd_sb scoreboard;   // chứa ref_model bên trong
  hz_fwd_cov   coverage;

    function new(virtual hz_fwd_if vif, int num_txn);
        agents     = new(vif, num_txn);
        scoreboard = new(agents.mon2sb,num_txn);
        coverage   = new(agents.mon2cov,num_txn);
    endfunction

    task run();
        fork
            agents.run();
            scoreboard.run();
            coverage.run();
        join_none

        @(scoreboard.done);   // scoreboard xử lý đủ num_txn
        #1;                   // chờ coverage sample nốt
        scoreboard.report();
        coverage.report();
    endtask
endclass