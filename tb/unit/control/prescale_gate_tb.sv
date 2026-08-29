// =============================================================================
// prescale_gate_tb.sv
//
// Self-checking unit testbench for rtl/control/prescale_gate.sv.
//
// register_bank.sv (Checkpoint 2 step 1) is instantiated alongside the
// DUT, with prescale_gate's output wired directly into register_bank's
// presc_write_allow_i exactly as it will be at the real top level
// (Section 4) -- same pattern as register_decode_tb.sv and
// shadow_active_ctrl_tb.sv, so every check confirms the *effect* of the
// write guard on real PRE_SCALE storage, not just the gate signal in
// isolation. A second, bare instance of the DUT with no register_bank
// attached is also included to directly verify the module is purely
// combinational (no clk/rst dependency at all).
//
// Covers:
//   1. Purely-combinational property: presc_write_allow_o tracks sleep_i
//      immediately (same simulation-time-step, no clock edge needed),
//      on the bare (unconnected-to-register_bank) DUT instance.
//   2. Reset state: MODE1 resets to 0x11 (SLEEP=1), so a PRE_SCALE write
//      is accepted immediately after reset with no MODE1 write needed.
//   3. Write guard while awake (SLEEP=0): a MODE1 write clearing SLEEP
//      causes prescale_gate's output to drop; a subsequent PRE_SCALE
//      write is silently dropped -- the stored value in register_bank
//      does not change, and a readback confirms this.
//   4. Write guard while asleep (SLEEP=1 again): re-setting MODE1.SLEEP
//      re-asserts presc_write_allow_o, and the *same* PRE_SCALE write
//      that was just dropped now lands and reads back correctly.
//   5. Toggling SLEEP repeatedly (awake -> asleep -> awake) confirms the
//      guard has no memory/latching behavior of its own -- each write's
//      outcome depends only on SLEEP at the time of that write, matching
//      the module's purely-combinational, stateless design.
//   6. active_prescale_o (what pwm_counter actually consumes) only ever
//      reflects accepted writes, never a dropped one, confirming the
//      guard's effect reaches the signal that matters downstream.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o prescale_gate_tb \
//     rtl/registers/register_bank.sv rtl/control/prescale_gate.sv \
//     tb/unit/control/prescale_gate_tb.sv
//   vvp prescale_gate_tb
// =============================================================================

`timescale 1ns/1ps

module prescale_gate_tb;

  import semfonix_regmap_pkg::*;

  localparam int  NUM_CHANNELS = 16;
  localparam time CLK_PERIOD   = 10ns;

  logic clk_ref, rst_n;

  // --- bare DUT instance: no register_bank attached, used only to prove
  //     the module is purely combinational (check 1) ---
  logic bare_sleep_i;
  logic bare_presc_write_allow_o;

  prescale_gate bare_dut (
    .sleep_i              (bare_sleep_i),
    .presc_write_allow_o  (bare_presc_write_allow_o)
  );

  // --- integration instance: wired into a real register_bank exactly as
  //     at the top level (Section 4) ---
  logic        rb_wr_en, rb_rd_en;
  logic [7:0]  rb_addr, rb_wdata;
  logic [7:0]  rb_rdata;
  logic        commit_pulse;
  logic        presc_write_allow;
  logic        dirty_o, group_update_req_o;

  pwm_chan_cfg_t active_cfg_o [NUM_CHANNELS];
  logic [7:0]  active_prescale_o;
  logic        active_sleep_o, active_ai_o, active_allcall_o, active_och_o;
  logic [2:0]  active_subx_en_o;
  logic [1:0]  active_outne_o;
  logic        active_outdrv_o, active_invrt_o;
  logic [6:0]  active_allcalladr_o;
  logic [6:0]  active_subadr_o [3];

  int errors = 0;
  int checks = 0;

  register_bank #(.NUM_CHANNELS(NUM_CHANNELS)) rb (
    .clk_ref              (clk_ref),
    .rst_n                (rst_n),
    .rb_wr_en             (rb_wr_en),
    .rb_rd_en             (rb_rd_en),
    .rb_addr              (rb_addr),
    .rb_wdata             (rb_wdata),
    .rb_rdata             (rb_rdata),
    .commit_pulse         (commit_pulse),
    .presc_write_allow_i  (presc_write_allow),
    .dirty_o              (dirty_o),
    .group_update_req_o   (group_update_req_o),
    .active_cfg_o         (active_cfg_o),
    .active_prescale_o    (active_prescale_o),
    .active_sleep_o       (active_sleep_o),
    .active_ai_o          (active_ai_o),
    .active_allcall_o     (active_allcall_o),
    .active_subx_en_o     (active_subx_en_o),
    .active_outne_o       (active_outne_o),
    .active_outdrv_o      (active_outdrv_o),
    .active_invrt_o       (active_invrt_o),
    .active_och_o         (active_och_o),
    .active_allcalladr_o  (active_allcalladr_o),
    .active_subadr_o      (active_subadr_o)
  );

  prescale_gate dut (
    .sleep_i              (active_sleep_o),
    .presc_write_allow_o  (presc_write_allow)
  );

  initial clk_ref = 1'b0;
  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  task automatic expect_eq(input logic [63:0] got, input logic [63:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=%0d expected=%0d", tag, got, exp);
    end
  endtask

  task automatic expect_eq8(input logic [7:0] got, input logic [7:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=0x%02h expected=0x%02h", tag, got, exp);
    end
  endtask

  // one clk_ref-synchronous write via the direct regbus (bypassing
  // register_decode, same pattern as register_bank_tb.sv)
  task automatic wr(input logic [7:0] a, input logic [7:0] d);
    begin
      @(negedge clk_ref);
      rb_addr = a; rb_wdata = d; rb_wr_en = 1'b1;
      @(posedge clk_ref);
      @(negedge clk_ref);
      rb_wr_en = 1'b0;
    end
  endtask

  // combinational read (valid same cycle regardless of clock)
  task automatic rd(input logic [7:0] a, output logic [7:0] d);
    begin
      rb_addr = a; rb_rd_en = 1'b1;
      #1;
      d = rb_rdata;
      rb_rd_en = 1'b0;
    end
  endtask

  // writes MODE1 directly (bit4 = SLEEP), preserving the rest of the
  // reset-default bit pattern except the bits under test
  task automatic set_mode1_sleep(input logic sleep_bit);
    begin
        wr(8'h00, {3'b000, sleep_bit, 3'b000, 1'b0}); // AI=0, SLEEP=sleep_bit, SUBx=0, ALLCALL=0
    end
  endtask

  task automatic do_reset();
    begin
      rst_n = 1'b0;
      rb_wr_en = 1'b0; rb_rd_en = 1'b0;
      rb_addr = '0; rb_wdata = '0;
      commit_pulse = 1'b0;
      bare_sleep_i = 1'b0;
      repeat (3) @(posedge clk_ref);
      rst_n = 1'b1;
      @(posedge clk_ref);
      @(negedge clk_ref);
    end
  endtask

  logic [7:0] rdval;

  initial begin
    // -------------------------------------------------------------------
    // 1. Bare-instance combinational property: no clk/rst needed at all,
    //    output tracks input within the same time step.
    // -------------------------------------------------------------------
    bare_sleep_i = 1'b0;
    #1;
    expect_eq(bare_presc_write_allow_o, 1'b0, "bare_sleep0_allow0");
    bare_sleep_i = 1'b1;
    #1;
    expect_eq(bare_presc_write_allow_o, 1'b1, "bare_sleep1_allow1");
    bare_sleep_i = 1'b0;
    #1;
    expect_eq(bare_presc_write_allow_o, 1'b0, "bare_toggle_back_to_0");

    // -------------------------------------------------------------------
    // Integration instance, real register_bank attached.
    // -------------------------------------------------------------------
    do_reset();

    // -------------------------------------------------------------------
    // 2. Reset state: MODE1=0x11 => SLEEP=1 => write allowed immediately,
    //    no MODE1 write needed first.
    // -------------------------------------------------------------------
    expect_eq(active_sleep_o, 1'b1, "reset_sleep_is_1");
    expect_eq(presc_write_allow, 1'b1, "reset_write_allow_is_1");
    rd(8'hFE, rdval); expect_eq8(rdval, 8'h1E, "reset_prescale_default");

    wr(8'hFE, 8'h30);
    rd(8'hFE, rdval); expect_eq8(rdval, 8'h30, "reset_sleep_write_accepted");
    expect_eq8(active_prescale_o, 8'h30, "reset_sleep_write_active_updated");

    // -------------------------------------------------------------------
    // 3. Write guard while awake (SLEEP=0): write must be dropped, both
    //    at the shadow-readback level and at active_prescale_o.
    // -------------------------------------------------------------------
    set_mode1_sleep(1'b0);
    expect_eq(active_sleep_o, 1'b0, "awake_sleep_is_0");
    expect_eq(presc_write_allow, 1'b0, "awake_write_allow_is_0");

    wr(8'hFE, 8'h7F); // attempted write while awake
    rd(8'hFE, rdval); expect_eq8(rdval, 8'h30, "awake_write_dropped_readback_unchanged");
    expect_eq8(active_prescale_o, 8'h30, "awake_write_dropped_active_unchanged");

    // -------------------------------------------------------------------
    // 4. Write guard re-asserted (SLEEP=1 again): the same value just
    //    rejected now lands.
    // -------------------------------------------------------------------
    set_mode1_sleep(1'b1);
    expect_eq(presc_write_allow, 1'b1, "reasleep_write_allow_is_1");

    wr(8'hFE, 8'h7F);
    rd(8'hFE, rdval); expect_eq8(rdval, 8'h7F, "reasleep_write_accepted");
    expect_eq8(active_prescale_o, 8'h7F, "reasleep_write_active_updated");

    // -------------------------------------------------------------------
    // 5. Stateless-guard check: awake -> asleep -> awake, each write's
    //    outcome depends only on SLEEP at that instant, no latching.
    // -------------------------------------------------------------------
    set_mode1_sleep(1'b0);
    wr(8'hFE, 8'hAA); // dropped
    rd(8'hFE, rdval); expect_eq8(rdval, 8'h7F, "cycle2_awake_drop");

    set_mode1_sleep(1'b1);
    wr(8'hFE, 8'hAA); // accepted
    rd(8'hFE, rdval); expect_eq8(rdval, 8'hAA, "cycle2_asleep_accept");

    set_mode1_sleep(1'b0);
    wr(8'hFE, 8'h11); // dropped again
    rd(8'hFE, rdval); expect_eq8(rdval, 8'hAA, "cycle3_awake_drop_no_latch_of_prior_accept");
    expect_eq8(active_prescale_o, 8'hAA, "cycle3_active_still_reflects_last_accepted");

    if (errors == 0) begin
      $display("PASS: prescale_gate_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: prescale_gate_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout
  initial begin
    #1000000;
    $display("FAIL: prescale_gate_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
