// =============================================================================
// i2c_bus_sync_tb.sv
//
// Self-checking unit testbench for rtl/i2c/i2c_bus_sync.sv.
//
// Verifies:
//   1. Reset value: both synchronized outputs idle-high.
//   2. Exact 2-cycle latency of the 2-FF synchronizers.
//   3. SCL/SDA synchronizer independence.
//   4. Sub-cycle glitch that is never sampled is not propagated.
//   5. Back-to-back toggling with exact 2-cycle tracking.
//
// IMPORTANT:
// Inputs are changed away from clk_ref edges to avoid a testbench race.
// The DUT samples scl_i/sda_i only on posedge clk_ref.
//
// Expected architecture:
//   async input -> FF1 -> FF2 -> synchronized output
//
// Therefore, a value sampled by FF1 on cycle N appears at FF2/output
// on cycle N+1 relative to the sampling edge, i.e. two sequential
// sampling stages from the externally-driven transition.
// =============================================================================

`timescale 1ns/1ps

module i2c_bus_sync_tb;

  localparam time CLK_PERIOD = 10ns;

  logic clk_ref;
  logic rst_n;
  logic scl_i, sda_i;
  logic scl_sync_o, sda_sync_o;

  int errors = 0;
  int checks = 0;

  i2c_bus_sync dut (
    .clk_ref    (clk_ref),
    .rst_n      (rst_n),
    .scl_i      (scl_i),
    .sda_i      (sda_i),
    .scl_sync_o (scl_sync_o),
    .sda_sync_o (sda_sync_o)
  );

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  initial clk_ref = 1'b0;

  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  // ---------------------------------------------------------------------------
  // Common checker
  // ---------------------------------------------------------------------------

  task automatic expect_eq(
    input logic  got,
    input logic exp,
    input string tag
  );
    checks++;

    if (got !== exp) begin
      errors++;
      $display(
        "FAIL [%s]: got=%0b expected=%0b",
        tag,
        got,
        exp
      );
    end
  endtask

  // ---------------------------------------------------------------------------
  // Reset helper
  //
  // IMPORTANT:
  // Leave reset and then wait away from the clock edge before returning.
  // This prevents the caller from changing inputs in the same timestep
  // as a DUT posedge.
  // ---------------------------------------------------------------------------

  task automatic do_reset();
    rst_n = 1'b0;
    scl_i = 1'b1;
    sda_i = 1'b1;

    repeat (3) @(posedge clk_ref);

    rst_n = 1'b1;

    // Move away from the posedge before returning to caller.
    #1;
  endtask

  // ---------------------------------------------------------------------------
  // Main tests
  // ---------------------------------------------------------------------------

  initial begin

    // ========================================================================
    // Test 1: reset values
    // ========================================================================

    do_reset();

    expect_eq(
      scl_sync_o,
      1'b1,
      "reset_scl_sync"
    );

    expect_eq(
      sda_sync_o,
      1'b1,
      "reset_sda_sync"
    );


    // ========================================================================
    // Test 2: SCL falling edge
    //
    // Drive SCL low at a safe point 1 ns after a clock edge.
    //
    // Next posedge:
    //   scl_meta_q <= 0
    //   scl_sync_o <= old scl_meta_q = 1
    //
    // Following posedge:
    //   scl_sync_o <= 0
    // ========================================================================

    do_reset();

    // Drive away from clock edge.
    scl_i = 1'b0;

    @(posedge clk_ref);
    #1;

    expect_eq(
      scl_sync_o,
      1'b1,
      "scl_fall_lat_cycle1_still_old"
    );

    @(posedge clk_ref);
    #1;

    expect_eq(
      scl_sync_o,
      1'b0,
      "scl_fall_lat_cycle2_new_value"
    );


    // ========================================================================
    // Test 2b: SDA falling edge independently
    // ========================================================================

    do_reset();

    sda_i = 1'b0;

    @(posedge clk_ref);
    #1;

    expect_eq(
      sda_sync_o,
      1'b1,
      "sda_fall_lat_cycle1_still_old"
    );

    expect_eq(
      scl_sync_o,
      1'b1,
      "sda_change_does_not_affect_scl_cycle1"
    );

    @(posedge clk_ref);
    #1;

    expect_eq(
      sda_sync_o,
      1'b0,
      "sda_fall_lat_cycle2_new_value"
    );

    expect_eq(
      scl_sync_o,
      1'b1,
      "sda_change_does_not_affect_scl_cycle2"
    );


    // ========================================================================
    // Test 3: independence
    //
    // SDA is held low while SCL toggles.
    // SDA synchronized output must remain low.
    // ========================================================================

    do_reset();

    sda_i = 1'b0;

    // Allow SDA to propagate through both synchronizer stages.
    @(posedge clk_ref);
    #1;

    @(posedge clk_ref);
    #1;

    expect_eq(
      sda_sync_o,
      1'b0,
      "sda_settled_low_before_scl_toggle"
    );

    // Now change SCL independently.
    scl_i = 1'b0;

    @(posedge clk_ref);
    #1;

    expect_eq(
      sda_sync_o,
      1'b0,
      "sda_unaffected_by_scl_toggle_cycle1"
    );

    scl_i = 1'b1;

    @(posedge clk_ref);
    #1;

    expect_eq(
      sda_sync_o,
      1'b0,
      "sda_unaffected_by_scl_toggle_cycle2"
    );

    // SCL's first falling transition has now propagated.
    expect_eq(
      scl_sync_o,
      1'b0,
      "scl_reflects_first_fall"
    );


    // ========================================================================
    // Test 4: sub-cycle glitch
    //
    // The glitch occurs entirely between two rising edges:
    //
    //       posedge       posedge
    //           |            |
    //           | <- glitch ->|
    //
    // Since the input is high at both sampling points, the synchronizer
    // never sees the low pulse.
    // ========================================================================

    do_reset();

    @(posedge clk_ref);
    #1;

    scl_i = 1'b0;

    #2;

    scl_i = 1'b1;

    // Wait several cycles.
    repeat (4) @(posedge clk_ref);
    #1;

    expect_eq(
      scl_sync_o,
      1'b1,
      "sub_cycle_glitch_never_sampled"
    );


    // ========================================================================
    // Test 5: back-to-back toggling
    //
    // Each input transition is driven 1 ns after a clock edge, guaranteeing
    // that the DUT cannot accidentally sample it on the preceding edge.
    //
    // Every transition must emerge through the 2-stage pipeline correctly.
    // ========================================================================

    do_reset();

    scl_i = 1'b1;

    for (int i = 0; i < 8; i++) begin

      // Change input away from clock edge.
      scl_i = ~scl_i;

      // First sampling edge.
      @(posedge clk_ref);
      #1;

      // Output must still contain previous value.
      //
      // FF1 has captured the new input, but FF2/output has not yet
      // received it.
      expect_eq(
        scl_sync_o,
        ~scl_i,
        $sformatf("toggle_iter_%0d_cycle1_old", i)
      );

      // Second sampling edge.
      @(posedge clk_ref);
      #1;

      // New value must now be visible.
      expect_eq(
        scl_sync_o,
        scl_i,
        $sformatf("toggle_iter_%0d_cycle2_new", i)
      );
    end


    // ========================================================================
    // Final result
    // ========================================================================

    if (errors == 0) begin

      $display(
        "PASS: i2c_bus_sync_tb - %0d checks, 0 errors",
        checks
      );

      $finish(0);

    end else begin

      $display(
        "FAIL: i2c_bus_sync_tb - %0d checks, %0d errors",
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

    $display("FAIL: i2c_bus_sync_tb - TIMEOUT");

    $fatal(1);

  end

endmodule