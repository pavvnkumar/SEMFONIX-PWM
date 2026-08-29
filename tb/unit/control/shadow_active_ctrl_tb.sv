`timescale 1ns/1ps

// =============================================================================
// shadow_active_ctrl_tb.sv
//
// Unit testbench for:
//   rtl/control/shadow_active_ctrl.sv
//
// Verifies:
//   1. Reset
//   2. STOP commit: OCH=0, stop_event=1, dirty=1
//   3. STOP commit blocked when OCH=1
//   4. STOP commit blocked when dirty=0
//   5. ACK4 commit: OCH=1, ack4_event=1
//   6. ACK4 commit blocked when OCH=0
//   7. GROUP_UPDATE commit
//   8. External sync_update synchronization
//   9. Synchronised rising-edge detection
//  10. Registered commit_pulse behavior
//  11. No spurious commits
//  12. Multiple sources
// =============================================================================

`default_nettype none

module shadow_active_ctrl_tb;

  // ---------------------------------------------------------------------------
  // DUT signals
  // ---------------------------------------------------------------------------

  logic clk_ref;
  logic rst_n;

  logic dirty_i;
  logic group_update_req_i;
  logic ack4_event_i;
  logic stop_event_i;
  logic och_i;
  logic sync_update_i;

  logic commit_pulse_o;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------

  shadow_active_ctrl dut (
    .clk_ref              (clk_ref),
    .rst_n                (rst_n),
    .dirty_i              (dirty_i),
    .group_update_req_i   (group_update_req_i),
    .ack4_event_i         (ack4_event_i),
    .stop_event_i         (stop_event_i),
    .och_i                (och_i),
    .sync_update_i        (sync_update_i),
    .commit_pulse_o       (commit_pulse_o)
  );

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  initial begin
    clk_ref = 1'b0;
    forever #5 clk_ref = ~clk_ref;
  end

  // ---------------------------------------------------------------------------
  // Test accounting
  // ---------------------------------------------------------------------------

  integer checks;
  integer errors;

  initial begin
    checks = 0;
    errors = 0;
  end

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  task automatic check_bit(
    input logic actual,
    input logic expected,
    input string name
  );
    begin
      checks = checks + 1;

      if (actual !== expected) begin
        errors = errors + 1;
        $display(
          "FAIL [%s]: got=%0b expected=%0b",
          name,
          actual,
          expected
        );
      end else begin
        $display(
          "PASS [%s]: %0b",
          name,
          actual
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // Wait for a rising edge of clk_ref
  // ---------------------------------------------------------------------------

  task automatic tick;
    begin
      @(posedge clk_ref);
      #1;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Clear all event inputs
  // ---------------------------------------------------------------------------

  task automatic clear_inputs;
    begin
      dirty_i            = 1'b0;
      group_update_req_i = 1'b0;
      ack4_event_i       = 1'b0;
      stop_event_i       = 1'b0;
      och_i              = 1'b0;
      sync_update_i      = 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Reset DUT
  // ---------------------------------------------------------------------------

  task automatic reset_dut;
    begin
      clear_inputs();

      rst_n = 1'b0;

      repeat (3)
        tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "commit_pulse_reset"
      );

      rst_n = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "commit_pulse_after_reset_release"
      );
    end
  endtask

  // ===========================================================================
  // TEST 1: STOP commit
  // ===========================================================================
  //
  // stop_commit =
  //   (!och_i) && stop_event_i && dirty_i
  //
  // commit_pulse_o is registered:
  //
  //   cycle N   : request is present
  //   cycle N+1 : commit_pulse_o = 1
  // ===========================================================================

  task automatic test_stop_commit;
    begin
      $display("");
      $display("=== TEST: STOP commit ===");

      clear_inputs();

      och_i       = 1'b0;
      dirty_i     = 1'b1;
      stop_event_i = 1'b1;

      // Request is sampled here.
      tick();

      // Registered output should now be asserted.
      check_bit(
        commit_pulse_o,
        1'b1,
        "stop_commit_pulse"
      );

      // Remove event.
      stop_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_commit_single_cycle"
      );
    end
  endtask

  // ===========================================================================
  // TEST 2: STOP blocked by OCH=1
  // ===========================================================================

  task automatic test_stop_blocked_by_och;
    begin
      $display("");
      $display("=== TEST: STOP blocked when OCH=1 ===");

      clear_inputs();

      och_i        = 1'b1;
      dirty_i      = 1'b1;
      stop_event_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_blocked_och"
      );

      stop_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_blocked_och_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 3: STOP blocked when dirty=0
  // ===========================================================================

  task automatic test_stop_blocked_when_clean;
    begin
      $display("");
      $display("=== TEST: STOP blocked when dirty=0 ===");

      clear_inputs();

      och_i        = 1'b0;
      dirty_i      = 1'b0;
      stop_event_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_blocked_clean"
      );

      stop_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_blocked_clean_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 4: ACK4 commit
  // ===========================================================================
  //
  // ack_commit =
  //   och_i && ack4_event_i
  //
  // Note: dirty is intentionally irrelevant for ACK4.
  // ===========================================================================

  task automatic test_ack4_commit;
    begin
      $display("");
      $display("=== TEST: ACK4 commit ===");

      clear_inputs();

      och_i        = 1'b1;
      ack4_event_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "ack4_commit_pulse"
      );

      ack4_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "ack4_commit_single_cycle"
      );
    end
  endtask

  // ===========================================================================
  // TEST 5: ACK4 blocked when OCH=0
  // ===========================================================================

  task automatic test_ack4_blocked_without_och;
    begin
      $display("");
      $display("=== TEST: ACK4 blocked when OCH=0 ===");

      clear_inputs();

      och_i        = 1'b0;
      ack4_event_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "ack4_blocked_no_och"
      );

      ack4_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "ack4_blocked_no_och_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 6: GROUP_UPDATE commit
  // ===========================================================================

  task automatic test_group_update;
    begin
      $display("");
      $display("=== TEST: GROUP_UPDATE commit ===");

      clear_inputs();

      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "group_update_commit"
      );

      group_update_req_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "group_update_single_cycle"
      );
    end
  endtask

  // ===========================================================================
  // TEST 7: GROUP_UPDATE independent of OCH and dirty
  // ===========================================================================

  task automatic test_group_update_independent;
    begin
      $display("");
      $display("=== TEST: GROUP_UPDATE qualification independence ===");

      clear_inputs();

      och_i   = 1'b0;
      dirty_i = 1'b0;

      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "group_update_clean_stop_mode"
      );

      group_update_req_i = 1'b0;

      tick();

      clear_inputs();

      och_i   = 1'b1;
      dirty_i = 1'b0;

      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "group_update_och_mode"
      );

      group_update_req_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "group_update_independent_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 8: No commit with no events
  // ===========================================================================

  task automatic test_no_event;
    begin
      $display("");
      $display("=== TEST: No event => no commit ===");

      clear_inputs();

      repeat (4) begin
        tick();

        check_bit(
          commit_pulse_o,
          1'b0,
          "no_event_no_commit"
        );
      end
    end
  endtask

  // ===========================================================================
  // TEST 9: Synchronous external sync_update rising edge
  // ===========================================================================
  //
  // Internal pipeline:
  //
  //   sync_meta_q <= sync_update_i
  //   sync_sync_q <= sync_meta_q
  //   sync_prev_q <= sync_sync_q
  //
  // Therefore the rising edge is detected after synchronization.
  //
  // sync_update_pulse =
  //   sync_sync_q & ~sync_prev_q
  //
  // commit_pulse_o is then registered from that request.
  //
  // We deliberately hold sync_update_i high long enough to make the
  // synchronization behavior deterministic.
  // ===========================================================================

  task automatic test_sync_rising_edge;
    begin
      $display("");
      $display("=== TEST: synchronized sync_update rising edge ===");

      clear_inputs();

      // Start low.
      sync_update_i = 1'b0;

      repeat (3)
        tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_initial_low"
      );

      // External signal rises.
      sync_update_i = 1'b1;

      // First sampling stage.
      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_after_first_stage"
      );

      // Second synchronization stage.
      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_after_second_stage"
      );

      // sync_sync_q is now high.
      // sync_prev_q becomes old sync_sync_q.
      // The pulse is therefore generated from this transition.
      tick();

      // commit_pulse_o reflects the sampled sync_commit.
      check_bit(
        commit_pulse_o,
        1'b1,
        "sync_commit_pulse"
      );

      // Keep input high. There must not be another pulse.
      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_no_repeat_while_high"
      );

      // Return low.
      sync_update_i = 1'b0;

      repeat (3)
        tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_low_after_rising_edge"
      );
    end
  endtask

  // ===========================================================================
  // TEST 10: sync_update must produce only a rising-edge commit
  // ===========================================================================

  task automatic test_sync_no_falling_commit;
    begin
      $display("");
      $display("=== TEST: sync_update falling edge does not commit ===");

      clear_inputs();

      sync_update_i = 1'b1;

      repeat (4)
        tick();

      // Any rising-edge commit should already have happened.
      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_high_stable"
      );

      // Falling edge.
      sync_update_i = 1'b0;

      repeat (4)
        tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "sync_falling_no_commit"
      );
    end
  endtask

  // ===========================================================================
  // TEST 11: One-clock registered pulse
  // ===========================================================================

  task automatic test_registered_pulse;
    begin
      $display("");
      $display("=== TEST: registered one-cycle pulse ===");

      clear_inputs();

      // GROUP request asserted.
      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "registered_pulse_asserted"
      );

      // Hold request high for another cycle.
      //
      // Since group_update_req_i remains high, the DUT naturally generates
      // another registered pulse. This verifies that the DUT reflects the
      // level of the request each clock cycle rather than generating an
      // implicit edge detector for GROUP_UPDATE.
      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "registered_pulse_request_held"
      );

      // Remove request.
      group_update_req_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "registered_pulse_after_request_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 12: Simultaneous commit sources
  // ===========================================================================

  task automatic test_simultaneous_sources;
    begin
      $display("");
      $display("=== TEST: simultaneous commit sources ===");

      clear_inputs();

      // STOP source.
      och_i         = 1'b0;
      dirty_i       = 1'b1;
      stop_event_i  = 1'b1;

      // GROUP source simultaneously.
      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "simultaneous_stop_group"
      );

      clear_inputs();

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "simultaneous_sources_clear"
      );

      // ACK4 + GROUP.
      och_i              = 1'b1;
      ack4_event_i       = 1'b1;
      group_update_req_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "simultaneous_ack_group"
      );

      clear_inputs();

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "simultaneous_ack_group_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 13: STOP dirty qualification changes dynamically
  // ===========================================================================

  task automatic test_stop_dirty_transition;
    begin
      $display("");
      $display("=== TEST: STOP dirty transition ===");

      clear_inputs();

      och_i        = 1'b0;
      stop_event_i = 1'b1;

      // Clean -> no commit.
      dirty_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_clean_no_commit"
      );

      // Dirty becomes set while stop remains asserted.
      dirty_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "stop_dirty_commit"
      );

      stop_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "stop_dirty_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 14: ACK4 does not require dirty
  // ===========================================================================

  task automatic test_ack4_without_dirty;
    begin
      $display("");
      $display("=== TEST: ACK4 works with dirty=0 ===");

      clear_inputs();

      och_i        = 1'b1;
      dirty_i      = 1'b0;
      ack4_event_i = 1'b1;

      tick();

      check_bit(
        commit_pulse_o,
        1'b1,
        "ack4_without_dirty"
      );

      ack4_event_i = 1'b0;

      tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "ack4_without_dirty_clear"
      );
    end
  endtask

  // ===========================================================================
  // TEST 15: Reset clears synchronizer and output
  // ===========================================================================

  task automatic test_reset_during_sync;
    begin
      $display("");
      $display("=== TEST: reset clears synchronized sync_update state ===");

      clear_inputs();

      sync_update_i = 1'b1;

      tick();

      // Reset before synchronization can complete.
      rst_n = 1'b0;

      #1;

      check_bit(
        commit_pulse_o,
        1'b0,
        "reset_clears_commit"
      );

      rst_n = 1'b1;

      sync_update_i = 1'b0;

      repeat (4)
        tick();

      check_bit(
        commit_pulse_o,
        1'b0,
        "reset_clears_sync_state"
      );
    end
  endtask

  // ===========================================================================
  // Main test sequence
  // ===========================================================================

  initial begin

    // Initial values.
    rst_n = 1'b0;

    clear_inputs();

    // Allow reset to operate.
    repeat (2)
      tick();

    rst_n = 1'b1;

    tick();

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    test_no_event();

    test_stop_commit();

    test_stop_blocked_by_och();

    test_stop_blocked_when_clean();

    test_ack4_commit();

    test_ack4_blocked_without_och();

    test_ack4_without_dirty();

    test_group_update();

    test_group_update_independent();

    test_registered_pulse();

    test_stop_dirty_transition();

    test_simultaneous_sources();

    test_sync_rising_edge();

    test_sync_no_falling_commit();

    test_reset_during_sync();

    // -------------------------------------------------------------------------
    // Final result
    // -------------------------------------------------------------------------

    $display("");
    $display("============================================================");
    $display("shadow_active_ctrl_tb COMPLETE");
    $display("Checks : %0d", checks);
    $display("Errors : %0d", errors);
    $display("============================================================");

    if (errors != 0) begin
      $display("FAIL: shadow_active_ctrl_tb - %0d errors", errors);
      $fatal(1);
    end else begin
      $display("PASS: shadow_active_ctrl_tb - all %0d checks passed", checks);
      $finish;
    end

  end

endmodule

`default_nettype wire

