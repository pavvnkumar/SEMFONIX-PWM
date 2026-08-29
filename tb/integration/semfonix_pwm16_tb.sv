// =============================================================================
// semfonix_pwm16_tb.sv
//
// Integration testbench for semfonix_pwm16_top.sv, per
// docs/MASTER_ARCHITECTURE.md Section 23 ("drives the top level purely
// through clk_ref/rst_n/I2C pins/oe_n_i/sync_update_i (black-box from the
// DUT's perspective) and checks led_o against the reference model, per the
// full test list ... (reset, I2C protocol, PWM all-channel/all-duty-cycle,
// atomic update, addressing, stress)"). This is step 13 of the Section 22
// implementation order, the third of three files closing it out (alongside
// tb/models/i2c_bfm.sv and tb/models/pwm_ref_model.sv, both new this
// session) -- and the first point at which semfonix_pwm16_top.sv (written
// step 12, Checkpoint 5) gets any simulation coverage at all, per
// docs/IMPLEMENTATION_STATUS.md's "Next within Checkpoint 5" note.
//
// The DUT is driven ONLY through its real top-level ports (clk_ref, rst_n,
// scl_i/sda_i, hw_addr_i, oe_n_i, extclk_sel_i, sync_update_i) via
// tb/models/i2c_bfm.sv's register-level task API -- no backdoor writes to
// any internal signal, matching Section 23's "black-box from the DUT's
// perspective" requirement exactly (a genuine departure from every unit
// tb's own "bare-instance + real-dependency" pattern, which by design does
// reach inside individual modules; this file never does).
//
// --- Checking strategy ---
// tb/models/pwm_ref_model.sv continuously (always_comb) computes
// exp_led_o/exp_led_oe_o from its own independently-derived state. A
// background comparator below checks the DUT's real led_o/led_oe_o against
// the model's outputs every clk_ref cycle, but ONLY while `checking_enabled`
// is asserted. `checking_enabled` is deliberately dropped by every stimulus
// helper task (`do_write`, `do_write_burst`, ...) for the duration of the
// I2C transaction it drives and only re-raised after a settle window once
// the transaction (and any resulting commit) has fully landed -- see
// pwm_ref_model.sv's own header for why: the model's non-clocked register
// storage updates at the *simulation-time point* the testbench's task call
// returns, not cycle-accurately reproducing the DUT's own internal
// STOP/ACK-triggered pulse timing, so comparing DURING a transaction would
// produce spurious mismatches around commit boundaries that reflect this
// testbench's own bridging approximation, not a real DUT bug. Once
// checking_enabled is raised after settle, the two free-running timebases
// (DUT's real pwm_counter.sv, the model's own independent tick-divider,
// both clocked by the same clk_ref/rst_n) stay in lockstep for as long as
// no further register write/commit occurs, so every idle/settle window is
// checked CONTINUOUSLY (every single cycle, a full PWM period or more where
// the test allows it) rather than at isolated sample points -- this is
// deliberately stronger than the unit tbs' single-instant sampling
// convention, and is the main new coverage this integration level adds
// beyond what the unit tbs already proved about each block in isolation.
//
// --- Test groups (per Section 23's stated list) ---
//   1. Reset: default register readback (DEVICE_ID/REVISION_ID/MODE1/
//      MODE2/PRE_SCALE), reserved-address read-as-zero.
//   2. I2C protocol: single-register write+readback, AI-enabled 4-byte
//      channel burst write+readback, full 64-byte LED-table burst write
//      (exercises the 0x06..0x45 span with no wrap mid-burst).
//   3. Addressing: default-enabled LED All-Call address, an explicitly
//      enabled Sub-Call address, and General-Call SWRST (ACKed at the
//      protocol level; per semfonix_pwm16_top.sv's own documented known
//      gap -- swrst_o has no consumer yet -- verified NON-disruptive to
//      register state, not verified to perform a reset, since the RTL does
//      not implement that yet).
//   4. PWM all-channel/all-duty-cycle: representative duty cycles
//      (including the wraparound on_count>off_count case), full-on,
//      full-off, SEMFONIX enable gate, SEMFONIX polarity, MODE2.INVRT,
//      and the oe_n_i/OUTNE/OUTDRV forced-state mux -- each checked via a
//      continuous post-settle window (see above), each exercised on more
//      than one channel to catch any per-channel cross-wiring bug pwm_
//      engine.sv's generate loop could introduce.
//   5. Atomic update: OCH=0 STOP-commit glitch-freedom (mid-burst reads
//      unaffected until STOP), OCH=1 ACK-commit (committed strictly before
//      the following STOP, checked mid-transaction), GROUP_UPDATE
//      (commits without a STOP at all), sync_update_i (commits an OCH=1-
//      staged, not-yet-committed change with no I2C activity at all).
//   6. Stress: a short loop of randomized multi-channel GROUP_UPDATE-
//      committed configurations, each checked over a full settle window.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o semfonix_pwm16_tb \
//     rtl/registers/register_bank.sv rtl/registers/register_decode.sv \
//     rtl/registers/address_decode.sv rtl/control/shadow_active_ctrl.sv \
//     rtl/control/prescale_gate.sv rtl/pwm/pwm_compare.sv \
//     rtl/pwm/pwm_channel.sv rtl/pwm/pwm_counter.sv rtl/pwm/pwm_engine.sv \
//     rtl/i2c/i2c_bus_sync.sv rtl/i2c/i2c_rx.sv rtl/i2c/i2c_tx.sv \
//     rtl/i2c/i2c_slave.sv rtl/clock/clk_reset_sync.sv \
//     rtl/top/semfonix_pwm16_top.sv \
//     tb/models/i2c_bfm.sv tb/models/pwm_ref_model.sv \
//     tb/integration/semfonix_pwm16_tb.sv
//   vvp semfonix_pwm16_tb
// =============================================================================

`timescale 1ns/1ps

module semfonix_pwm16_tb;

  localparam int NUM_CHANNELS = 16;
  localparam int PWM_WIDTH    = 12;
  localparam time CLK_PERIOD  = 10ns;

  localparam bit [5:0] HW_ADDR   = 6'h15;             // matches unit tbs' convention
  localparam bit [6:0] DEV_ADDR7 = {1'b1, HW_ADDR};   // 7'h55

  int errors = 0;
  int checks = 0;

  task automatic expect_eq(input logic [63:0] got, input logic [63:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=0x%0h expected=0x%0h", tag, got, exp);
    end
  endtask

  task automatic expect_true(input logic cond, input string tag);
    checks++;
    if (cond !== 1'b1) begin
      errors++;
      $display("FAIL [%s]: expected true", tag);
    end
  endtask

  // ---------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------
  logic clk_ref;
  initial clk_ref = 1'b0;
  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  logic rst_n;

  // ---------------------------------------------------------------------
  // I2C bus wiring: i2c_bfm.sv (master) wired-AND with the DUT's own
  // sda_o/sda_oe, same combine pattern every unit I2C tb already uses.
  // scl is driven directly by the BFM (see i2c_bfm.sv header) and combined
  // with the DUT's (always-tied-off) scl_o/scl_oe for generality.
  // ---------------------------------------------------------------------
  logic bfm_scl, bfm_sda_drive, bfm_sda_val;
  logic dut_sda_o, dut_sda_oe, dut_scl_o, dut_scl_oe;

  wire scl_line = (dut_scl_oe && !dut_scl_o) ? 1'b0 : bfm_scl;
  wire sda_line = (bfm_sda_drive && !bfm_sda_val) ? 1'b0
                 : (dut_sda_oe && !dut_sda_o)      ? 1'b0
                 : 1'b1;

  i2c_bfm #(.HALF_BIT_CYCLES(20)) bfm (
    .clk_ref     (clk_ref),
    .scl_o       (bfm_scl),
    .sda_drive_o (bfm_sda_drive),
    .sda_val_o   (bfm_sda_val),
    .sda_i       (sda_line)
  );

  // ---------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------
  logic [NUM_CHANNELS-1:0] dut_led, dut_led_oe;
  logic oe_n_i, sync_update_i;

  semfonix_pwm16_top #(
    .NUM_CHANNELS (NUM_CHANNELS),
    .PWM_WIDTH    (PWM_WIDTH)
  ) dut (
    .clk_ref       (clk_ref),
    .rst_n         (rst_n),
    .scl_i         (scl_line),
    .sda_i         (sda_line),
    .sda_o         (dut_sda_o),
    .sda_oe        (dut_sda_oe),
    .scl_o         (dut_scl_o),
    .scl_oe        (dut_scl_oe),
    .hw_addr_i     (HW_ADDR),
    .oe_n_i        (oe_n_i),
    .extclk_sel_i  (1'b0),
    .sync_update_i (sync_update_i),
    .led_o         (dut_led),
    .led_oe_o      (dut_led_oe)
  );

  // ---------------------------------------------------------------------
  // Reference model
  // ---------------------------------------------------------------------
  logic [NUM_CHANNELS-1:0] model_led, model_led_oe;

  pwm_ref_model #(
    .NUM_CHANNELS (NUM_CHANNELS),
    .PWM_WIDTH    (PWM_WIDTH)
  ) model (
    .clk_ref      (clk_ref),
    .rst_n        (rst_n),
    .oe_n_i       (oe_n_i),
    .exp_led_o    (model_led),
    .exp_led_oe_o (model_led_oe),
    .count_o      (),
    .dirty_o      ()
  );

  // ---------------------------------------------------------------------
  // Background continuous checker (see file header)
  // ---------------------------------------------------------------------
  bit checking_enabled;
  int bg_check_count;

  always @(posedge clk_ref) begin
    if (checking_enabled) begin
      #1;
      checks++;
      bg_check_count++;
      if ((dut_led !== model_led) || (dut_led_oe !== model_led_oe)) begin
        errors++;
        $display("FAIL [bg_check] @%0t: led got=%b exp=%b  led_oe got=%b exp=%b",
                  $time, dut_led, model_led, dut_led_oe, model_led_oe);
        checking_enabled = 1'b0;  // avoid flooding the log with a stuck mismatch
      end
    end
  end

  task automatic pause_checking();
    checking_enabled = 1'b0;
  endtask

  task automatic resume_after_settle(input int settle_cycles);
    repeat (settle_cycles) @(posedge clk_ref);
    checking_enabled = 1'b1;
  endtask

  // ---------------------------------------------------------------------
  // Stimulus helpers: every real I2C transaction is paired 1:1 with the
  // matching pwm_ref_model.sv call, exactly the "testbench keeps the
  // mirror in sync" contract that module's header documents.
  // ---------------------------------------------------------------------
  task automatic do_write(input logic [7:0] addr, input logic [7:0] data, input int settle = 5);
    bit ok;
    pause_checking();
    bfm.write_reg(DEV_ADDR7, addr, data, ok);
    expect_true(ok, "do_write_acked");
    model.reg_write(addr, data);
    model.stop_commit();
    resume_after_settle(settle);
  endtask

  task automatic do_write_burst(
    input logic [7:0] base_addr,
    input logic [7:0] data [64],
    input int         len,
    input int         settle = 5
  );
    bit ok;
    pause_checking();
    bfm.write_burst(DEV_ADDR7, base_addr, data, len, ok);
    expect_true(ok, "do_write_burst_acked");
    for (int i = 0; i < len; i++) model.reg_write(base_addr + i[7:0], data[i]);
    model.stop_commit();
    resume_after_settle(settle);
  endtask

  task automatic do_read_reg(input logic [7:0] addr, output logic [7:0] data);
    bit ok;
    pause_checking();
    bfm.read_reg(DEV_ADDR7, addr, data, ok);
    expect_true(ok, "do_read_acked");
    resume_after_settle(5);
  endtask

  task automatic do_read_burst(input logic [7:0] addr, input int len, output logic [7:0] data [64]);
    bit ok;
    pause_checking();
    bfm.read_burst(DEV_ADDR7, addr, len, data, ok);
    expect_true(ok, "do_read_burst_acked");
    resume_after_settle(5);
  endtask

  // configure one channel's full 4-byte group in one burst (AI must
  // already be enabled by the caller -- see do_enable_ai())
  task automatic set_channel(
    input int           ch,
    input logic [11:0]  on_count,
    input logic [11:0]  off_count,
    input bit           full_on,
    input bit           full_off,
    input int           settle = 5
  );
    logic [7:0] burst [64];
    burst[0] = on_count[7:0];
    burst[1] = {3'b000, full_on, on_count[11:8]};
    burst[2] = off_count[7:0];
    burst[3] = {3'b000, full_off, off_count[11:8]};
    do_write_burst(8'h06 + 8'(4*ch), burst, 4, settle);
  endtask

  task automatic do_enable_ai();
    do_write(8'h00, 8'h31);  // MODE1: RESTART=0,EXTCLK=0,AI=1,SLEEP=1,SUB=000,ALLCALL=1 (0x31)
  endtask

  task automatic do_wake(input logic [7:0] mode1_val);
    do_write(8'h00, mode1_val);  // caller supplies full MODE1 value with SLEEP=0
  endtask

  task automatic do_reset();
    rst_n = 1'b0;
    checking_enabled = 1'b0;
    oe_n_i = 1'b0;
    sync_update_i = 1'b0;
    bg_check_count = 0;
    repeat (5) @(posedge clk_ref);
    rst_n = 1'b1;
    model.reset_model();
    repeat (5) @(posedge clk_ref);
  endtask

  // =======================================================================
  // Test sequence
  // =======================================================================
  initial begin
    logic [7:0] rdata;
    logic [7:0] rburst [64];
    logic [7:0] wburst [64];
    bit         ok;

    // --- Group 1: Reset ---
    do_reset();
    do_read_reg(8'h55, rdata); expect_eq(rdata, 8'h53, "t1_device_id");
    do_read_reg(8'h56, rdata); expect_eq(rdata, 8'h01, "t1_revision_id");
    do_read_reg(8'h00, rdata); expect_eq(rdata, 8'h11, "t1_mode1_reset");
    do_read_reg(8'h01, rdata); expect_eq(rdata, 8'h04, "t1_mode2_reset");
    do_read_reg(8'hFE, rdata); expect_eq(rdata, 8'h1E, "t1_prescale_reset");
    do_read_reg(8'h46, rdata); expect_eq(rdata, 8'h00, "t1_reserved_reads_zero");

    // --- Group 2: I2C protocol ---
    do_reset();
    // single-register write + readback
    do_write(8'h06, 8'hAB);
    do_read_reg(8'h06, rdata); expect_eq(rdata, 8'hAB, "t2_single_reg_readback");

    // AI-enabled 4-byte channel burst write + burst readback
    do_enable_ai();
    wburst[0] = 8'h34; wburst[1] = 8'h02; wburst[2] = 8'h78; wburst[3] = 8'h19;
    do_write_burst(8'h06, wburst, 4);
    do_read_burst(8'h06, 4, rburst);
    expect_eq(rburst[0], wburst[0], "t2_burst_readback_0");
    expect_eq(rburst[1], wburst[1], "t2_burst_readback_1");
    expect_eq(rburst[2], wburst[2], "t2_burst_readback_2");
    expect_eq(rburst[3], wburst[3], "t2_burst_readback_3");

    // full 64-byte LED-table burst (0x06..0x45, no mid-burst wrap)
    for (int i = 0; i < 64; i++) wburst[i] = 8'(i ^ 8'h5A);
    do_write_burst(8'h06, wburst, 64);
    do_read_burst(8'h06, 64, rburst);
    begin
      bit all_match;
      all_match = 1'b1;
      for (int i = 0; i < 64; i++) if (rburst[i] !== wburst[i]) all_match = 1'b0;
      expect_true(all_match, "t2_full_table_burst_readback");
    end

    // --- Group 3: Addressing ---
    do_reset();
    // default-enabled LED All-Call address (ALLCALL=1, ALLCALLADR=0xE0 -> addr7=0x70)
    begin
      bit addr_ok;
      pause_checking();
      bfm.write_reg(7'h70, 8'h06, 8'h5A, addr_ok);
      expect_true(addr_ok, "t3_allcall_write_acked");
      model.reg_write(8'h06, 8'h5A);
      model.stop_commit();
      resume_after_settle(5);
      do_read_reg(8'h06, rdata);
      expect_eq(rdata, 8'h5A, "t3_allcall_write_landed");
    end

    // explicitly enabled Sub-Call 1 address (SUBADR1 default 0xE2 -> addr7=0x71)
    do_write(8'h00, 8'h19);  // MODE1: SUB1=1, ALLCALL=1, SLEEP=1 (0x19)
    begin
      bit addr_ok;
      pause_checking();
      bfm.write_reg(7'h71, 8'h07, 8'hA5, addr_ok);
      expect_true(addr_ok, "t3_subcall1_write_acked");
      model.reg_write(8'h07, 8'hA5);
      model.stop_commit();
      resume_after_settle(5);
      do_read_reg(8'h07, rdata);
      expect_eq(rdata, 8'hA5, "t3_subcall1_write_landed");
    end

    // General-Call SWRST: ACKed at the protocol level, non-disruptive to
    // register state (known gap -- see file header and
    // semfonix_pwm16_top.sv's own header/docs/IMPLEMENTATION_STATUS.md)
    do_write(8'h00, 8'h11);  // back to reset-default MODE1 for a clean baseline
    begin
      bit swrst_ok;
      pause_checking();
      bfm.general_call_swrst(swrst_ok);
      expect_true(swrst_ok, "t3_general_call_swrst_acked");
      resume_after_settle(5);
      do_read_reg(8'h00, rdata);
      expect_eq(rdata, 8'h11, "t3_swrst_no_register_side_effect_known_gap");
    end

    // --- Group 4: PWM all-channel / all-duty-cycle ---
    do_reset();
    do_enable_ai();
    do_write(8'hFE, 8'h03);          // PRE_SCALE=3 (min per spec), allowed while SLEEP=1
    do_wake(8'h21);                  // MODE1: AI=1, SLEEP=0, ALLCALL=1

    // representative normal-range duty cycle on channel 0, wraparound
    // (on>off) on channel 1, checked over more than one full PWM period
    // (f_pwm period = 4096*(3+1) = 16384 clk_ref cycles at this prescale)
    set_channel(0, 12'd512, 12'd3584, 1'b0, 1'b0);   // 3072/4096 duty, normal range
    set_channel(1, 12'd3072, 12'd1024, 1'b0, 1'b0);  // wraparound range
    resume_after_settle(2 * 16384);

    // full-on / full-off overrides (full_off must win over full_on per
    // Section 10/15 -- channel 2 sets both)
    set_channel(2, 12'd100, 12'd200, 1'b1, 1'b1);   // full_off wins
    set_channel(3, 12'd100, 12'd200, 1'b1, 1'b0);   // full_on only
    resume_after_settle(16384);

    // SEMFONIX per-channel enable gate: disable channel 0 without
    // touching its stored ON/OFF counts
    do_write(8'h50, 8'hFE);  // CHAN_ENABLE_L: channel 0 disabled, 1..7 enabled
    resume_after_settle(16384);
    do_write(8'h50, 8'hFF);  // re-enable

    // SEMFONIX per-channel polarity + global MODE2.INVRT, on independent
    // channels so their interaction (XOR of both) is actually exercised
    do_write(8'h52, 8'h08);  // CHAN_POLARITY_L: channel 3 inverted
    do_write(8'h01, 8'h14);  // MODE2: INVRT=1, OCH=0, OUTDRV=0, OUTNE=00
    resume_after_settle(16384);
    do_write(8'h52, 8'h00);
    do_write(8'h01, 8'h04);  // back to reset-default MODE2

    // oe_n_i / OUTNE forced-state mux: assert OE (outputs disabled),
    // sweep all four OUTNE encodings, each with both OUTDRV settings
    oe_n_i = 1'b1;
    for (int outdrv = 0; outdrv <= 1; outdrv++) begin
      for (int outne = 0; outne < 4; outne++) begin
        do_write(8'h01, {3'b000, 1'b1, 1'b0, outdrv[0], outne[1:0]}); // INVRT=1(don't-care here),OCH=0,OUTDRV,OUTNE
        resume_after_settle(200);
      end
    end
    oe_n_i = 1'b0;
    do_write(8'h01, 8'h04);  // restore MODE2 default

    // --- Group 5: Atomic update ---
    do_reset();
    do_enable_ai();
    do_write(8'hFE, 8'h03);
    do_wake(8'h21);

    // 5a. OCH=0 (default) STOP-commit glitch-freedom: mid-burst writes to
    // channel 4 must not change led_o/led_oe until the STOP that ends the
    // transaction. Checked by pausing the background checker only for the
    // transaction itself (as always) but taking an explicit manual sample
    // immediately after the 4th byte's ACK, BEFORE this task's own stop()
    // -- i.e. bypassing do_write_burst so the STOP can be deferred.
    begin
      bit ack_addr, ack_ctrl, ack0, ack1, ack2, ack3;
      logic [NUM_CHANNELS-1:0] led_before, led_oe_before;
      pause_checking();
      led_before    = dut_led;
      led_oe_before = dut_led_oe;
      bfm.start();
      bfm.write_byte({DEV_ADDR7, 1'b0}, ack_addr);
      bfm.write_byte(8'h06 + 8'(4*4), ack_ctrl);   // channel 4 base
      bfm.write_byte(8'h00, ack0);
      bfm.write_byte(8'h00, ack1);
      bfm.write_byte(8'hFF, ack2);  // off_count[7:0]=0xFF
      bfm.write_byte(8'h10, ack3);  // off_count[11:8]=0, full_off=1 -- deliberately distinct from led_before
      expect_true(ack_addr & ack_ctrl & ack0 & ack1 & ack2 & ack3, "t5a_burst_acked");
      // no STOP yet: real hardware (OCH=0) must not have committed
      expect_eq(dut_led,    led_before,    "t5a_led_unchanged_before_stop");
      expect_eq(dut_led_oe, led_oe_before, "t5a_led_oe_unchanged_before_stop");
      bfm.stop();
      model.reg_write(8'h06 + 8'(4*4), 8'h00);
      model.reg_write(8'h07 + 8'(4*4), 8'h00);
      model.reg_write(8'h08 + 8'(4*4), 8'hFF);
      model.reg_write(8'h09 + 8'(4*4), 8'h10);
      model.stop_commit();
      resume_after_settle(2000);
    end

    // 5b. OCH=1 ACK-commit: committed strictly before the following STOP.
    do_write(8'h01, 8'h0C);  // MODE2: OCH=1, OUTDRV=1, OUTNE=00, INVRT=0
    begin
      bit ack_addr, ack_ctrl, ack0, ack1, ack2, ack3;
      pause_checking();
      bfm.start();
      bfm.write_byte({DEV_ADDR7, 1'b0}, ack_addr);
      bfm.write_byte(8'h06 + 8'(4*5), ack_ctrl);  // channel 5 base
      bfm.write_byte(8'hFF, ack0);   // on_count[7:0]
      bfm.write_byte(8'h00, ack1);   // on_count[11:8]=0,full_on=0
      bfm.write_byte(8'h00, ack2);   // off_count[7:0]
      bfm.write_byte(8'h00, ack3);   // off_count[11:8]=0,full_off=0 -- this ACK is the group's 4th byte
      expect_true(ack_addr & ack_ctrl & ack0 & ack1 & ack2 & ack3, "t5b_burst_acked");
      model.reg_write(8'h06 + 8'(4*5), 8'hFF);
      model.reg_write(8'h07 + 8'(4*5), 8'h00);
      model.reg_write(8'h08 + 8'(4*5), 8'h00);
      model.reg_write(8'h09 + 8'(4*5), 8'h00);  // model auto-commits here (OCH=1, group-last-byte)
      #1;
      // still no STOP sent yet -- sample now, before bfm.stop()
      expect_eq(dut_led[5],    model_led[5],    "t5b_led_committed_before_stop");
      expect_eq(dut_led_oe[5], model_led_oe[5], "t5b_led_oe_committed_before_stop");
      bfm.stop();
      resume_after_settle(2000);
    end
    do_write(8'h01, 8'h04);  // back to OCH=0 default

    // 5c. GROUP_UPDATE: commits without any STOP-driven trigger at all --
    // stage channel 6 (OCH=0, so the staging writes' own STOPs do NOT
    // commit as long as GROUP_UPDATE's dirty-clearing hasn't happened yet;
    // to actually observe "commits without STOP" we check state
    // immediately after the GROUP_UPDATE byte's ACK, before ITS transaction's
    // own STOP too).
    set_channel(6, 12'd10, 12'd20, 1'b0, 1'b0);  // staged + committed via its own STOP (OCH=0, dirty)
    begin
      bit ack_addr, ack_ctrl, ack_data;
      pause_checking();
      // re-stage a DIFFERENT value into the shadow only (do_write_burst
      // would STOP-commit it under OCH=0, so drive the transaction
      // manually and check the sample point precedes this transaction's
      // own STOP as well, isolating GROUP_UPDATE as the trigger, not the
      // STOP that happens to follow it).
      bfm.start();
      bfm.write_byte({DEV_ADDR7, 1'b0}, ack_addr);
      bfm.write_byte(8'h08 + 8'(4*6), ack_ctrl);       // channel 6 OFF_L
      bfm.write_byte(8'd40, ack_data);                 // new off_count[7:0]=40 (not yet committed)
      expect_true(ack_addr & ack_ctrl & ack_data, "t5c_stage_acked");
      model.reg_write(8'h08 + 8'(4*6), 8'd40);
      // (model.dirty_o at this point is a property of THIS model's own
      // bookkeeping, not something semfonix_pwm16_top.sv exposes at its
      // top-level ports -- Section 5.1 does not bring register_bank's
      // internal dirty_o out to any pin, so it cannot be checked against
      // the DUT here. The real DUT-observable check for this whole group
      // is the led_o/led_oe_o comparison after the final resume_after_
      // settle() below, once the background checker is watching again.)
      // still mid-transaction (no STOP sent) -- issue GROUP_UPDATE's
      // register write inline (real hardware allows any address next,
      // it is simply the next byte of a fresh transaction after this
      // one's own STOP; issue that STOP first since a single I2C
      // transaction only ever targets one auto-incrementing pointer walk)
      bfm.stop();
      model.stop_commit();  // OCH=0 dirty -> this STOP already commits it
      // Re-stage again, this time verifying GROUP_UPDATE specifically:
      // write a value that would NOT yet be committed by its own STOP if
      // OCH-independent GROUP_UPDATE didn't exist -- switch to OCH=1 with
      // a non-group-last-byte field so its own STOP/ACK never auto-commits
      // it, then commit purely via GROUP_UPDATE.
      resume_after_settle(5);
      do_write(8'h01, 8'h08);  // MODE2: OCH=1, OUTDRV=0, OUTNE=00
      pause_checking();
      bfm.write_reg(DEV_ADDR7, 8'h06 + 8'(4*6), 8'd99, ok);  // ON_L only, not group-last-byte
      expect_true(ok, "t5c_restage_acked");
      model.reg_write(8'h06 + 8'(4*6), 8'd99);
      bfm.write_reg(DEV_ADDR7, 8'h54, 8'h01, ok);  // GROUP_UPDATE=1
      expect_true(ok, "t5c_group_update_acked");
      model.reg_write(8'h54, 8'h01);  // model commits immediately (write-time source)
      // DUT-observable check: resume the background led_o/led_oe_o
      // comparator below -- if the real GROUP_UPDATE path failed to
      // commit (or committed at the wrong time), channel 6's real output
      // will diverge from the model's (which committed exactly at this
      // write per Section 13 source #3) and the background checker will
      // flag it.
      resume_after_settle(2000);
    end
    do_write(8'h01, 8'h04);  // back to OCH=0 default

    // 5d. sync_update_i: commits an OCH=1-staged, not-yet-committed change
    // with NO I2C activity at all for the commit itself.
    do_write(8'h01, 8'h08);  // MODE2: OCH=1
    do_write(8'h06 + 8'(4*7), 8'd7);  // channel 7 ON_L only (not group-last-byte, OCH=1 doesn't auto-commit)
    model.reg_write(8'h06 + 8'(4*7), 8'd7);
    // (as in 5c: dirty_o is model-internal-only bookkeeping, not a DUT
    // port -- the real check is the post-settle led_o/led_oe_o compare
    // below, once sync_update_i has been the ONLY trigger since the
    // staging write above.)
    pause_checking();
    sync_update_i = 1'b1;
    repeat (5) @(posedge clk_ref);  // hold well past shadow_active_ctrl's 2-FF sync + edge-detect
    sync_update_i = 1'b0;
    repeat (5) @(posedge clk_ref);
    model.sync_pulse();
    resume_after_settle(2000);
    do_write(8'h01, 8'h04);  // back to OCH=0 default

    // --- Group 6: Stress (short randomized multi-channel sweep) ---
    do_reset();
    do_enable_ai();
    do_write(8'hFE, 8'h03);
    do_wake(8'h21);
    for (int iter = 0; iter < 4; iter++) begin
      for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
        logic [11:0] on_v, off_v;
        on_v  = $urandom_range(0, 4095);
        off_v = $urandom_range(0, 4095);
        set_channel(ch, on_v, off_v, $urandom_range(0,1), $urandom_range(0,1), 0);
      end
      resume_after_settle(4096);
    end

    // ---------------------------------------------------------------
    if (errors == 0) begin
      $display("PASS: semfonix_pwm16_tb - %0d checks (%0d background), 0 errors",
                checks, bg_check_count);
      $finish(0);
    end else begin
      $display("FAIL: semfonix_pwm16_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout -- generous, this tb includes several multi-period
  // (16384+ cycle) settle windows and a 64-channel-iteration stress loop
  initial begin
    #50000000;
    $display("FAIL: semfonix_pwm16_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
