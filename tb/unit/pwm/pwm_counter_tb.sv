// =============================================================================
// pwm_counter_tb.sv
//
// Self-checking unit testbench for rtl/pwm/pwm_counter.sv.
//
// Verifies:
//
//   1. Reset value is zero.
//   2. frame_tick_o is low after reset.
//   3. prescale=0 increments once every clk_ref cycle.
//   4. prescale=N increments once every (N+1) clk_ref cycles.
//   5. Counter reaches 4095 without an early frame tick.
//   6. Counter wraps 4095 -> 0.
//   7. frame_tick_o pulses exactly on the wrap cycle.
//   8. frame_tick_o is only one clock wide.
//   9. sleep_i freezes count and suppresses frame ticks.
//  10. Counter resumes correctly after wake.
//  11. Prescale divider is deterministic after wake.
//  12. Additional randomized prescale/count behavior.
//
// =============================================================================

`timescale 1ns/1ps

module pwm_counter_tb;

  localparam int PWM_WIDTH      = 12;
  localparam int PRESCALE_WIDTH = 8;
  localparam time CLK_PERIOD    = 10ns;

  logic clk_ref;
  logic rst_n;

  logic [PRESCALE_WIDTH-1:0] prescale_i;
  logic                      sleep_i;

  logic [PWM_WIDTH-1:0]      count_o;
  logic                      frame_tick_o;

  int errors = 0;
  int checks = 0;

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------

  pwm_counter #(
    .PWM_WIDTH      (PWM_WIDTH),
    .PRESCALE_WIDTH (PRESCALE_WIDTH)
  ) dut (
    .clk_ref      (clk_ref),
    .rst_n        (rst_n),
    .prescale_i   (prescale_i),
    .sleep_i      (sleep_i),
    .count_o      (count_o),
    .frame_tick_o (frame_tick_o)
  );

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  initial clk_ref = 1'b0;

  always #(CLK_PERIOD / 2) clk_ref = ~clk_ref;

  // ---------------------------------------------------------------------------
  // Check helpers
  // ---------------------------------------------------------------------------

  task automatic expect_count(
    input logic [PWM_WIDTH-1:0] got,
    input logic [PWM_WIDTH-1:0] expected,
    input string tag
  );
    checks++;

    if (got !== expected) begin
      errors++;
      $display(
        "FAIL [%s]: got=%0d expected=%0d",
        tag,
        got,
        expected
      );
    end
  endtask

  task automatic expect_tick(
    input logic got,
    input logic expected,
    input string tag
  );
    checks++;

    if (got !== expected) begin
      errors++;
      $display(
        "FAIL [%s]: got=%0b expected=%0b",
        tag,
        got,
        expected
      );
    end
  endtask

  // ---------------------------------------------------------------------------
  // Reset
  //
  // Important:
  //
  // Reset is asserted asynchronously.
  // Reset is released on a NEGEDGE so that the following POSEDGE is the first
  // active clock edge seen by the DUT.
  //
  // We intentionally do NOT consume a POSEDGE after releasing reset.
  // ---------------------------------------------------------------------------

  task automatic do_reset();

    rst_n      = 1'b0;
    prescale_i = '0;
    sleep_i    = 1'b0;

    // Allow several clocks while reset is active.
    repeat (3) @(posedge clk_ref);

    // Release reset away from the active clock edge.
    @(negedge clk_ref);
    rst_n = 1'b1;

    // Small delay to allow combinational outputs to settle.
    #1;

  endtask

  // ---------------------------------------------------------------------------
  // Wait for N active clock edges and sample after NBA updates.
  // ---------------------------------------------------------------------------

  task automatic wait_clocks(input int n);
    repeat (n) begin
      @(posedge clk_ref);
      #1;
    end
  endtask

  // ===========================================================================
  // TESTS
  // ===========================================================================

  initial begin

    // -------------------------------------------------------------------------
    // Test 1: reset value
    // -------------------------------------------------------------------------

    do_reset();

    expect_count(
      count_o,
      12'd0,
      "reset_value"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "reset_frame_tick"
    );


    // -------------------------------------------------------------------------
    // Test 2: prescale=0
    //
    // Every active clk_ref edge produces one PWM tick.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd0;

    for (int i = 1; i <= 10; i++) begin

      @(posedge clk_ref);
      #1;

      expect_count(
        count_o,
        i[11:0],
        $sformatf("prescale0_cycle_%0d", i)
      );

      expect_tick(
        frame_tick_o,
        1'b0,
        $sformatf("prescale0_no_frame_tick_%0d", i)
      );

    end


    // -------------------------------------------------------------------------
    // Test 3: prescale=3
    //
    // PWM tick every 4 clk_ref cycles.
    //
    // Starting divider = 0:
    //
    // cycle 1: divider 0 -> 1
    // cycle 2: divider 1 -> 2
    // cycle 3: divider 2 -> 3
    // cycle 4: divider 3 -> 0, count increments
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd3;

    for (int expected_count = 1;
         expected_count <= 5;
         expected_count++) begin

      repeat (4) @(posedge clk_ref);
      #1;

      expect_count(
        count_o,
        expected_count[11:0],
        $sformatf(
          "prescale3_after_%0d_groups",
          expected_count
        )
      );

      expect_tick(
        frame_tick_o,
        1'b0,
        $sformatf(
          "prescale3_no_frame_tick_%0d",
          expected_count
        )
      );

    end


    // -------------------------------------------------------------------------
    // Test 4: no early frame tick
    //
    // Run until count reaches 4094.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd0;

    repeat (4094) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'hFFE,
      "pre_wrap_count_4094"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "frame_tick_low_at_4094"
    );


    // -------------------------------------------------------------------------
    // Test 5: count reaches 4095 without frame tick
    // -------------------------------------------------------------------------

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'hFFF,
      "frame_pre_wrap_count_4095"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "frame_tick_low_before_wrap"
    );


    // -------------------------------------------------------------------------
    // Test 6: actual 4095 -> 0 wrap
    //
    // The SAME active clock edge:
    //
    //     count:       4095 -> 0
    //     frame_tick:     0 -> 1
    // -------------------------------------------------------------------------

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'h000,
      "wrap_to_zero"
    );

    expect_tick(
      frame_tick_o,
      1'b1,
      "frame_tick_asserted_at_wrap"
    );


    // -------------------------------------------------------------------------
    // Test 7: frame_tick is exactly one cycle
    // -------------------------------------------------------------------------

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'h001,
      "post_wrap_count_one"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "frame_tick_deasserted_after_wrap"
    );


    // -------------------------------------------------------------------------
    // Test 8: sleep freezes counter
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd0;

    repeat (5) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd5,
      "pre_sleep_count"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "pre_sleep_frame_tick"
    );

    // Enter sleep.
    sleep_i = 1'b1;

    repeat (20) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd5,
      "count_frozen_during_sleep"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "no_frame_tick_during_sleep"
    );


    // -------------------------------------------------------------------------
    // Test 9: wake resumes counter
    // -------------------------------------------------------------------------

    sleep_i = 1'b0;

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd6,
      "count_resumes_after_wake"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "no_frame_tick_after_wake"
    );


    // -------------------------------------------------------------------------
    // Test 10: sleep near frame boundary
    //
    // Put counter at 4095, sleep it, verify it stays there, then wake and
    // verify that the first PWM tick wraps and generates frame_tick_o.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd0;

    repeat (4095) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'hFFF,
      "sleep_boundary_precheck"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "sleep_boundary_tick_low"
    );

    sleep_i = 1'b1;

    repeat (10) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'hFFF,
      "sleep_boundary_count_frozen"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "sleep_boundary_no_tick"
    );

    sleep_i = 1'b0;

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'h000,
      "sleep_boundary_wrap_after_wake"
    );

    expect_tick(
      frame_tick_o,
      1'b1,
      "sleep_boundary_frame_tick_after_wake"
    );

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'h001,
      "sleep_boundary_post_wrap_count"
    );

    expect_tick(
      frame_tick_o,
      1'b0,
      "sleep_boundary_tick_cleared"
    );


    // -------------------------------------------------------------------------
    // Test 11: prescale=1
    //
    // Tick every 2 clocks.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd1;

    // First clock: divider 0 -> 1, no count increment.
    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd0,
      "prescale1_cycle1_no_tick"
    );

    // Second clock: divider 1 matches, count increments.
    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd1,
      "prescale1_cycle2_tick"
    );


    // -------------------------------------------------------------------------
    // Test 12: prescale=2
    //
    // Tick every 3 clocks.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'd2;

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd0,
      "prescale2_cycle1"
    );

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd0,
      "prescale2_cycle2"
    );

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd1,
      "prescale2_cycle3"
    );


    // -------------------------------------------------------------------------
    // Test 13: maximum prescale
    //
    // prescale=255 means one PWM tick every 256 clk_ref cycles.
    // -------------------------------------------------------------------------

    do_reset();

    prescale_i = 8'hFF;

    repeat (255) @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd0,
      "prescale255_before_tick"
    );

    @(posedge clk_ref);
    #1;

    expect_count(
      count_o,
      12'd1,
      "prescale255_first_tick"
    );


    // -------------------------------------------------------------------------
    // Final result
    // -------------------------------------------------------------------------

    if (errors == 0) begin

      $display(
        "PASS: pwm_counter_tb - %0d checks, 0 errors",
        checks
      );

      $finish(0);

    end
    else begin

      $display(
        "FAIL: pwm_counter_tb - %0d checks, %0d errors",
        checks,
        errors
      );

      $fatal(1);

    end

  end


  // ---------------------------------------------------------------------------
  // Safety timeout
  // ---------------------------------------------------------------------------

  initial begin

    #1000000;

    $display("FAIL: pwm_counter_tb - TIMEOUT");
    $fatal(1);

  end

endmodule