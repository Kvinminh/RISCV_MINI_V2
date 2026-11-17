// import ha_pipe_pkg::*;

class ha_pipe_env;
  ha_pipe_agt      agents;
  ha_pipe_sb scoreboard;   // chứa ref_model bên trong
  ha_pipe_cov   coverage;

    function new(virtual ha_pipe_if vif, int num_txn);
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