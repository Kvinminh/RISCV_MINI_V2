// import if_stage_pkg::*;

class if_stage_env;
  if_stage_agt      agents;
  if_stage_sb scoreboard;   // chứa ref_model bên trong
  if_stage_cov   coverage;

    function new(virtual if_stage_if vif, int num_txn);
        agents     = new(vif, num_txn);
        scoreboard = new(agents.mon2sb,num_txn);
        coverage   = new(agents.mon2cov);
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