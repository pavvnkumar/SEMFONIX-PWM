// =============================================================================
// clk_reset_sync_tb.sv
//
// Self-checking unit testbench for rtl/clock/clk_reset_sync.sv.
//
// Verifies:
//   1. Reset value: rst_n_sync_o is 0 immediately after power-up with
//      rst_n held low (before any clk_ref edge has occurred at all).
//   2. Asynchronous assert: dropping rst_n mid-cycle (strictly between
//      two clk_ref posedges) drives rst_n_sync_o to 0 immediately,
//      combinationally-fast, with NO dependency on a clk_ref edge --
//      the defining property distinguishing this from a purely
//      synchronous reset.
//   3. Synchronous release, exact 2-cycle timing: once rst_n returns
//      high, rst_n_sync_o stays 0 through the first clk_ref posedge
//      after release and only rises on the second, never earlier and
//      never later -- proving the 2-flop shift-through, not a 1-cycle
//      or 3-cycle release.
//   4. rst_n held low across many clk_ref cycles: rst_n_sync_o remains
//      pinned at 0 the entire time (no spurious release while the
//      async source is still asserted).
//   5. Repeatability: assert/release cycled 5 times back-to-back,
//      re-checking the exact 2-cycle release timing each time (no
//      first-cycle-only artifact, no accumulating state between
//      cycles).
//   6. extclk_sel_i is NOT a port of this module (per the module's own
//      header rationale) -- confirmed implicitly by this testbench
//      instantiating the DUT with only clk_ref/rst_n/rst_n_sync_o and
//      compiling cleanly; no separate runtime check is meaningful for
//      "a port that doesn't exist," so this is a structural/compile-
//      time property, not a simulated assertion.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o clk_reset_sync_tb rtl/clock/clk_reset_sync.sv tb/unit/clock/clk_reset_sync_tb.sv
//   vvp clk_reset_sync_tb
// =============================================================================

`timescale 1ns/1ps

module clk_reset_sync_tb;

  localparam time CLK_PERIOD = 10ns;

  logic clk_ref;
  logic rst_n;
  logic rst_n_sync_o;

  int errors = 0;
  int checks = 0;

  clk_reset_sync dut (
    .clk_ref      (clk_ref),
    .rst_n        (rst_n),
    .rst_n_sync_o (rst_n_sync_o)
  );

  // clock generation
  initial clk_ref = 1'b0;
  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  task automatic expect_eq(input logic got, input logic exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=%0b expected=%0b", tag, got, exp);
    end
  endtask

  initial begin
    rst_n = 1'b1; // start deasserted; Test 1 below drives the real
                  // power-up/assert condition explicitly rather than
                  // relying on x-propagation timing.

    // --- Test 1: reset value, async assert visible with no clk edge ---
    rst_n = 1'b0;
    #1; // strictly between clk_ref edges (clk_ref starts at 0 at t=0,
        // first edge is at t=5ns)
    expect_eq(rst_n_sync_o, 1'b0, "power_on_assert_immediate_no_clk_edge");

    // --- Test 2: async assert mid-cycle while previously released ---
    // release first, run a few clean cycles, then assert strictly
    // between two posedges and confirm the drop is immediate.
    rst_n = 1'b1;
    repeat (5) @(posedge clk_ref);
    expect_eq(rst_n_sync_o, 1'b1, "released_before_midcycle_assert_test");
    @(posedge clk_ref);
    #2; // now strictly mid-cycle, well before the next posedge at #5 more
    rst_n = 1'b0;
    #1; // no clk_ref edge has occurred since rst_n dropped
    expect_eq(rst_n_sync_o, 1'b0, "midcycle_assert_immediate");

    // --- Test 3: rst_n held low across many cycles stays pinned at 0 ---
    repeat (6) @(posedge clk_ref);
    expect_eq(rst_n_sync_o, 1'b0, "held_low_stays_pinned_after_many_cycles");

    // --- Test 4: exact 2-cycle synchronous release timing ---
    @(negedge clk_ref); // release well clear of any posedge race
    rst_n = 1'b1;
    @(posedge clk_ref); #1;
    expect_eq(rst_n_sync_o, 1'b0, "release_cycle1_still_low");
    @(posedge clk_ref); #1;
    expect_eq(rst_n_sync_o, 1'b1, "release_cycle2_now_high");

    // --- Test 5: repeatability -- 5 more assert/release cycles, each
    //     re-checking the exact 2-cycle release timing ---
    for (int i = 0; i < 5; i++) begin
      @(negedge clk_ref);
      rst_n = 1'b0;
      #1;
      expect_eq(rst_n_sync_o, 1'b0, $sformatf("repeat_iter_%0d_assert_immediate", i));
      repeat (3) @(posedge clk_ref); // hold asserted a few cycles
      expect_eq(rst_n_sync_o, 1'b0, $sformatf("repeat_iter_%0d_still_asserted", i));

      @(negedge clk_ref);
      rst_n = 1'b1;
      @(posedge clk_ref); #1;
      expect_eq(rst_n_sync_o, 1'b0, $sformatf("repeat_iter_%0d_release_cycle1_still_low", i));
      @(posedge clk_ref); #1;
      expect_eq(rst_n_sync_o, 1'b1, $sformatf("repeat_iter_%0d_release_cycle2_now_high", i));
    end

    if (errors == 0) begin
      $display("PASS: clk_reset_sync_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: clk_reset_sync_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout
  initial begin
    #1000000;
    $display("FAIL: clk_reset_sync_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
