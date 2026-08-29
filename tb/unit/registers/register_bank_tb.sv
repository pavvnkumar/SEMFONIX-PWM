// =============================================================================
// register_bank_tb.sv
//
// Self-checking unit testbench for rtl/registers/register_bank.sv.
//
// Verifies:
//   1. Reset values.
//   2. Single-buffered register writes/readback.
//   3. Active MODE1/MODE2/control exports.
//   4. LED shadow storage.
//   5. Shadow -> active atomic commit.
//   6. Dirty tracking.
//   7. ALL_LED broadcast writes.
//   8. PRE_SCALE write guard.
//   9. GROUP_UPDATE command pulse.
//  10. Reserved-address behavior.
//  11. DEVICE_ID / REVISION_ID read-only behavior.
//  12. Same-cycle shadow-write + commit behavior.
//
// Designed for Verilator 5.032.
// =============================================================================

`timescale 1ns/1ps

module register_bank_tb;

  import semfonix_regmap_pkg::*;

  localparam int NUM_CHANNELS = 16;
  localparam time CLK_PERIOD = 10ns;

  // ---------------------------------------------------------------------------
  // Clock / reset
  // ---------------------------------------------------------------------------

  logic clk_ref;
  logic rst_n;

  // ---------------------------------------------------------------------------
  // Register bus
  // ---------------------------------------------------------------------------

  logic       rb_wr_en;
  logic       rb_rd_en;
  logic [7:0] rb_addr;
  logic [7:0] rb_wdata;
  logic [7:0] rb_rdata;

  // ---------------------------------------------------------------------------
  // Commit control
  // ---------------------------------------------------------------------------

  logic commit_pulse;

  // ---------------------------------------------------------------------------
  // PRE_SCALE write guard
  // ---------------------------------------------------------------------------

  logic presc_write_allow_i;

  // ---------------------------------------------------------------------------
  // Control outputs
  // ---------------------------------------------------------------------------

  logic dirty_o;
  logic group_update_req_o;

  // ---------------------------------------------------------------------------
  // Active configuration
  // ---------------------------------------------------------------------------

  pwm_chan_cfg_t active_cfg_o [NUM_CHANNELS];

  logic [7:0] active_prescale_o;

  logic       active_sleep_o;
  logic       active_ai_o;
  logic       active_allcall_o;

  logic [2:0] active_subx_en_o;

  logic [1:0] active_outne_o;
  logic       active_outdrv_o;
  logic       active_invrt_o;
  logic       active_och_o;

  logic [6:0] active_allcalladr_o;
  logic [6:0] active_subadr_o [3];

  // ---------------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------------

  register_bank #(
    .NUM_CHANNELS(NUM_CHANNELS)
  ) dut (
    .clk_ref              (clk_ref),
    .rst_n                (rst_n),

    .rb_wr_en             (rb_wr_en),
    .rb_rd_en             (rb_rd_en),
    .rb_addr              (rb_addr),
    .rb_wdata             (rb_wdata),
    .rb_rdata             (rb_rdata),

    .commit_pulse         (commit_pulse),

    .presc_write_allow_i  (presc_write_allow_i),

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

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  initial begin
    clk_ref = 1'b0;
  end

  always #(CLK_PERIOD / 2) clk_ref = ~clk_ref;

  // ---------------------------------------------------------------------------
  // Test accounting
  // ---------------------------------------------------------------------------

  int errors = 0;
  int checks = 0;

  // ---------------------------------------------------------------------------
  // Check helpers
  // ---------------------------------------------------------------------------

  task automatic expect_eq8(
    input logic [7:0] got,
    input logic [7:0] exp,
    input string      tag
  );
    begin
      checks++;

      if (got !== exp) begin
        errors++;
        $display(
          "FAIL [%s]: got=0x%02h expected=0x%02h",
          tag,
          got,
          exp
        );
      end
    end
  endtask

  task automatic expect_eq12(
    input logic [11:0] got,
    input logic [11:0] exp,
    input string       tag
  );
    begin
      checks++;

      if (got !== exp) begin
        errors++;
        $display(
          "FAIL [%s]: got=0x%03h expected=0x%03h",
          tag,
          got,
          exp
        );
      end
    end
  endtask

  task automatic expect_bit(
    input logic got,
    input logic exp,
    input string tag
  );
    begin
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
    end
  endtask

  task automatic expect_eq3(
    input logic [2:0] got,
    input logic [2:0] exp,
    input string      tag
  );
    begin
      checks++;

      if (got !== exp) begin
        errors++;
        $display(
          "FAIL [%s]: got=0x%01h expected=0x%01h",
          tag,
          got,
          exp
        );
      end
    end
  endtask

  task automatic expect_eq7(
    input logic [6:0] got,
    input logic [6:0] exp,
    input string      tag
  );
    begin
      checks++;

      if (got !== exp) begin
        errors++;
        $display(
          "FAIL [%s]: got=0x%02h expected=0x%02h",
          tag,
          got,
          exp
        );
      end
    end
  endtask

  // ---------------------------------------------------------------------------
  // One synchronous register write
  // ---------------------------------------------------------------------------

  task automatic wr(
    input logic [7:0] addr,
    input logic [7:0] data
  );
    begin
      @(negedge clk_ref);

      rb_addr  = addr;
      rb_wdata = data;
      rb_wr_en = 1'b1;

      @(posedge clk_ref);

      @(negedge clk_ref);

      rb_wr_en = 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Combinational register read
  // ---------------------------------------------------------------------------

  task automatic rd(
    input  logic [7:0] addr,
    output logic [7:0] data
  );
    begin
      rb_addr  = addr;
      rb_rd_en = 1'b1;

      #1;

      data = rb_rdata;

      rb_rd_en = 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // One-cycle commit pulse
  // ---------------------------------------------------------------------------

  task automatic pulse_commit();
    begin
      @(negedge clk_ref);

      commit_pulse = 1'b1;

      @(posedge clk_ref);

      @(negedge clk_ref);

      commit_pulse = 1'b0;
    end
  endtask

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  task automatic do_reset();
    begin
      rst_n = 1'b0;

      rb_wr_en = 1'b0;
      rb_rd_en = 1'b0;

      rb_addr  = 8'h00;
      rb_wdata = 8'h00;

      commit_pulse = 1'b0;

      presc_write_allow_i = 1'b1;

      repeat (3) @(posedge clk_ref);

      rst_n = 1'b1;

      @(posedge clk_ref);

      @(negedge clk_ref);
    end
  endtask

  logic [7:0] rdval;

  // ===========================================================================
  // TEST SEQUENCE
  // ===========================================================================

  initial begin

    // -------------------------------------------------------------------------
    // Reset
    // -------------------------------------------------------------------------

    do_reset();

    // -------------------------------------------------------------------------
    // 1. RESET VALUES
    // -------------------------------------------------------------------------

    rd(8'h00, rdval);
    expect_eq8(rdval, 8'h11, "reset_MODE1");

    rd(8'h01, rdval);
    expect_eq8(rdval, 8'h04, "reset_MODE2");

    rd(8'h02, rdval);
    expect_eq8(rdval, 8'hE2, "reset_SUBADR1");

    rd(8'h03, rdval);
    expect_eq8(rdval, 8'hE4, "reset_SUBADR2");

    rd(8'h04, rdval);
    expect_eq8(rdval, 8'hE8, "reset_SUBADR3");

    rd(8'h05, rdval);
    expect_eq8(rdval, 8'hE0, "reset_ALLCALLADR");

    rd(8'hFE, rdval);
    expect_eq8(rdval, 8'h1E, "reset_PRE_SCALE");

    rd(8'h50, rdval);
    expect_eq8(rdval, 8'hFF, "reset_CHAN_ENABLE_L");

    rd(8'h51, rdval);
    expect_eq8(rdval, 8'hFF, "reset_CHAN_ENABLE_H");

    rd(8'h52, rdval);
    expect_eq8(rdval, 8'h00, "reset_CHAN_POLARITY_L");

    rd(8'h53, rdval);
    expect_eq8(rdval, 8'h00, "reset_CHAN_POLARITY_H");

    rd(8'h54, rdval);
    expect_eq8(rdval, 8'h00, "reset_GROUP_UPDATE_READ");

    rd(8'h55, rdval);
    expect_eq8(rdval, 8'h53, "reset_DEVICE_ID");

    rd(8'h56, rdval);
    expect_eq8(rdval, 8'h01, "reset_REVISION_ID");

    // LED0 reset values
    rd(8'h06, rdval);
    expect_eq8(rdval, 8'h00, "reset_LED0_ON_L");

    rd(8'h07, rdval);
    expect_eq8(rdval, 8'h00, "reset_LED0_ON_H");

    rd(8'h08, rdval);
    expect_eq8(rdval, 8'h00, "reset_LED0_OFF_L");

    rd(8'h09, rdval);
    expect_eq8(rdval, 8'h10, "reset_LED0_OFF_H");

    // LED15 reset OFF_H
    rd(8'h45, rdval);
    expect_eq8(rdval, 8'h10, "reset_LED15_OFF_H");

    expect_bit(dirty_o, 1'b0, "reset_dirty");

    // -------------------------------------------------------------------------
    // Reset active configuration
    // -------------------------------------------------------------------------

    for (int i = 0; i < NUM_CHANNELS; i++) begin

      expect_bit(
        active_cfg_o[i].full_on,
        1'b0,
        $sformatf("reset_full_on_ch%0d", i)
      );

      expect_bit(
        active_cfg_o[i].full_off,
        1'b1,
        $sformatf("reset_full_off_ch%0d", i)
      );

      expect_eq12(
        active_cfg_o[i].on_count,
        12'h000,
        $sformatf("reset_on_count_ch%0d", i)
      );

      expect_eq12(
        active_cfg_o[i].off_count,
        12'h000,
        $sformatf("reset_off_count_ch%0d", i)
      );

      expect_bit(
        active_cfg_o[i].enable,
        1'b1,
        $sformatf("reset_enable_ch%0d", i)
      );

      expect_bit(
        active_cfg_o[i].polarity,
        1'b0,
        $sformatf("reset_polarity_ch%0d", i)
      );

    end

    // MODE1 = 0x11
    // bit4 sleep = 1
    // bit5 AI = 0
    // bit0 ALLCALL = 1
    // bits3:1 SUBADR enable = 000
    expect_bit(active_sleep_o,   1'b1, "reset_active_sleep");
    expect_bit(active_ai_o,      1'b0, "reset_active_ai");
    expect_bit(active_allcall_o, 1'b1, "reset_active_allcall");

    expect_eq3(
      active_subx_en_o,
      3'b000,
      "reset_active_subx_enable"
    );

    // MODE2 = 0x04
    expect_eq3(
      {active_invrt_o, active_och_o, active_outdrv_o},
      3'b001,
      "reset_active_mode2_control"
    );

    expect_bit(
      active_outdrv_o,
      1'b1,
      "reset_active_outdrv"
    );

    expect_bit(
      active_och_o,
      1'b0,
      "reset_active_och"
    );

    expect_bit(
      active_invrt_o,
      1'b0,
      "reset_active_invrt"
    );

    expect_eq8(
      active_prescale_o,
      8'h1E,
      "reset_active_prescale"
    );

    expect_eq7(
      active_allcalladr_o,
      7'h70,
      "reset_active_allcalladr"
    );

    expect_eq7(
      active_subadr_o[0],
      7'h71,
      "reset_active_subadr1"
    );

    expect_eq7(
      active_subadr_o[1],
      7'h72,
      "reset_active_subadr2"
    );

    expect_eq7(
      active_subadr_o[2],
      7'h74,
      "reset_active_subadr3"
    );

    // -------------------------------------------------------------------------
    // 2. SINGLE-BUFFERED REGISTERS
    // -------------------------------------------------------------------------

    wr(8'h00, 8'hA5);
    rd(8'h00, rdval);
    expect_eq8(rdval, 8'hA5, "write_MODE1");

    expect_bit(
      active_sleep_o,
      1'b0,
      "MODE1_sleep_updates"
    );

    expect_bit(
      active_ai_o,
      1'b1,
      "MODE1_ai_updates"
    );

    expect_bit(
      active_allcall_o,
      1'b1,
      "MODE1_allcall_updates"
    );

    expect_eq3(
      active_subx_en_o,
      3'b010,
      "MODE1_subadr_enable_updates"
    );

    wr(8'h01, 8'h3C);
    rd(8'h01, rdval);
    expect_eq8(rdval, 8'h3C, "write_MODE2");

    expect_bit(
      active_outdrv_o,
      1'b1,
      "MODE2_outdrv_updates"
    );

    expect_bit(
      active_och_o,
      1'b1,
      "MODE2_och_updates"
    );

    expect_bit(
      active_invrt_o,
      1'b1,
      "MODE2_invrt_updates"
    );

    expect_eq8(
      {6'b0, active_outne_o},
      8'h00,
      "MODE2_outne_updates"
    );

    wr(8'h02, 8'h12);
    rd(8'h02, rdval);
    expect_eq8(rdval, 8'h12, "write_SUBADR1");

    wr(8'h03, 8'h34);
    rd(8'h03, rdval);
    expect_eq8(rdval, 8'h34, "write_SUBADR2");

    wr(8'h04, 8'h56);
    rd(8'h04, rdval);
    expect_eq8(rdval, 8'h56, "write_SUBADR3");

    wr(8'h05, 8'h78);
    rd(8'h05, rdval);
    expect_eq8(rdval, 8'h78, "write_ALLCALLADR");

    expect_eq7(
      active_allcalladr_o,
      7'h3C,
      "ALLCALLADR_active_updates"
    );

    expect_eq7(
      active_subadr_o[0],
      7'h09,
      "SUBADR1_active_updates"
    );

    expect_eq7(
      active_subadr_o[1],
      7'h1A,
      "SUBADR2_active_updates"
    );

    expect_eq7(
      active_subadr_o[2],
      7'h2B,
      "SUBADR3_active_updates"
    );

    wr(8'h50, 8'h00);
    rd(8'h50, rdval);
    expect_eq8(rdval, 8'h00, "write_CHAN_ENABLE_L");

    wr(8'h51, 8'h00);
    rd(8'h51, rdval);
    expect_eq8(rdval, 8'h00, "write_CHAN_ENABLE_H");

    expect_bit(
      active_cfg_o[0].enable,
      1'b0,
      "CHAN_ENABLE_ch0"
    );

    expect_bit(
      active_cfg_o[15].enable,
      1'b0,
      "CHAN_ENABLE_ch15"
    );

    wr(8'h52, 8'hFF);
    rd(8'h52, rdval);
    expect_eq8(rdval, 8'hFF, "write_CHAN_POL_L");

    wr(8'h53, 8'h00);
    rd(8'h53, rdval);
    expect_eq8(rdval, 8'h00, "write_CHAN_POL_H");

    expect_bit(
      active_cfg_o[0].polarity,
      1'b1,
      "CHAN_POLARITY_ch0"
    );

    expect_bit(
      active_cfg_o[7].polarity,
      1'b1,
      "CHAN_POLARITY_ch7"
    );

    expect_bit(
      active_cfg_o[8].polarity,
      1'b0,
      "CHAN_POLARITY_ch8"
    );

    // -------------------------------------------------------------------------
    // Start clean for shadow tests
    // -------------------------------------------------------------------------

    do_reset();

    // -------------------------------------------------------------------------
    // 3. LED SHADOW -> ACTIVE COMMIT
    // -------------------------------------------------------------------------

    // Channel 2:
    // base = 0x06 + (2 * 4) = 0x0E
    //
    // ON_L  = 0x0E
    // ON_H  = 0x0F
    // OFF_L = 0x10
    // OFF_H = 0x11

    wr(8'h0E, 8'hAB);

    // count[11:8] = C, full_on = 0
    wr(8'h0F, 8'h0C);

    wr(8'h10, 8'h34);

    // count[11:8] = 5, full_off = 0
    wr(8'h11, 8'h05);

    rd(8'h0E, rdval);
    expect_eq8(
      rdval,
      8'hAB,
      "shadow_ch2_ON_L"
    );

    rd(8'h0F, rdval);
    expect_eq8(
      rdval,
      8'h0C,
      "shadow_ch2_ON_H"
    );

    rd(8'h10, rdval);
    expect_eq8(
      rdval,
      8'h34,
      "shadow_ch2_OFF_L"
    );

    rd(8'h11, rdval);
    expect_eq8(
      rdval,
      8'h05,
      "shadow_ch2_OFF_H"
    );

    // Active must remain unchanged before commit.
    expect_eq12(
      active_cfg_o[2].on_count,
      12'h000,
      "active_ch2_on_before_commit"
    );

    expect_eq12(
      active_cfg_o[2].off_count,
      12'h000,
      "active_ch2_off_before_commit"
    );

    expect_bit(
      active_cfg_o[2].full_on,
      1'b0,
      "active_ch2_full_on_before_commit"
    );

    expect_bit(
      active_cfg_o[2].full_off,
      1'b1,
      "active_ch2_full_off_before_commit"
    );

    expect_bit(
      dirty_o,
      1'b1,
      "dirty_after_shadow_write"
    );

    // Commit.
    pulse_commit();

    expect_eq12(
      active_cfg_o[2].on_count,
      12'hCAB,
      "active_ch2_on_after_commit"
    );

    expect_eq12(
      active_cfg_o[2].off_count,
      12'h534,
      "active_ch2_off_after_commit"
    );

    expect_bit(
      active_cfg_o[2].full_on,
      1'b0,
      "active_ch2_full_on_after_commit"
    );

    expect_bit(
      active_cfg_o[2].full_off,
      1'b0,
      "active_ch2_full_off_after_commit"
    );

    expect_bit(
      dirty_o,
      1'b0,
      "dirty_after_commit"
    );

    // Untouched channel remains default.
    expect_eq12(
      active_cfg_o[5].on_count,
      12'h000,
      "untouched_ch5_on"
    );

    expect_bit(
      active_cfg_o[5].full_off,
      1'b1,
      "untouched_ch5_full_off"
    );

    // -------------------------------------------------------------------------
    // 4. ALL_LED BROADCAST
    // -------------------------------------------------------------------------

    do_reset();

    wr(8'hFA, 8'h11); // ALL_LED_ON_L
    wr(8'hFB, 8'h02); // ON_H count[11:8]=2, full_on=0

    wr(8'hFC, 8'h33); // ALL_LED_OFF_L
    wr(8'hFD, 8'h04); // OFF_H count[11:8]=4, full_off=0

    expect_bit(
      dirty_o,
      1'b1,
      "broadcast_sets_dirty"
    );

    // Shadow readback on broadcast addresses is defined as zero.
    rd(8'hFA, rdval);
    expect_eq8(
      rdval,
      8'h00,
      "broadcast_ON_L_read_zero"
    );

    rd(8'hFD, rdval);
    expect_eq8(
      rdval,
      8'h00,
      "broadcast_OFF_H_read_zero"
    );

    pulse_commit();

    for (int i = 0; i < NUM_CHANNELS; i++) begin

      expect_eq12(
        active_cfg_o[i].on_count,
        12'h211,
        $sformatf("broadcast_on_ch%0d", i)
      );

      expect_eq12(
        active_cfg_o[i].off_count,
        12'h433,
        $sformatf("broadcast_off_ch%0d", i)
      );

      expect_bit(
        active_cfg_o[i].full_on,
        1'b0,
        $sformatf("broadcast_full_on_ch%0d", i)
      );

      expect_bit(
        active_cfg_o[i].full_off,
        1'b0,
        $sformatf("broadcast_full_off_ch%0d", i)
      );

    end

    expect_bit(
      dirty_o,
      1'b0,
      "broadcast_dirty_cleared"
    );

    // -------------------------------------------------------------------------
    // 5. PRE_SCALE WRITE GUARD
    // -------------------------------------------------------------------------

    do_reset();

    presc_write_allow_i = 1'b0;

    wr(8'hFE, 8'h55);

    rd(8'hFE, rdval);

    expect_eq8(
      rdval,
      8'h1E,
      "prescale_write_blocked"
    );

    expect_eq8(
      active_prescale_o,
      8'h1E,
      "prescale_active_blocked"
    );

    presc_write_allow_i = 1'b1;

    wr(8'hFE, 8'h55);

    rd(8'hFE, rdval);

    expect_eq8(
      rdval,
      8'h55,
      "prescale_write_allowed"
    );

    expect_eq8(
      active_prescale_o,
      8'h55,
      "prescale_active_updated"
    );

    // -------------------------------------------------------------------------
    // 6. GROUP_UPDATE
    // -------------------------------------------------------------------------

    do_reset();

    @(negedge clk_ref);

    rb_addr  = 8'h54;
    rb_wdata = 8'h01;
    rb_wr_en = 1'b1;

    #1;

    expect_bit(
      group_update_req_o,
      1'b1,
      "group_update_asserted"
    );

    @(posedge clk_ref);

    @(negedge clk_ref);

    rb_wr_en = 1'b0;

    #1;

    expect_bit(
      group_update_req_o,
      1'b0,
      "group_update_deasserted"
    );

    rd(8'h54, rdval);

    expect_eq8(
      rdval,
      8'h00,
      "group_update_read_zero"
    );

    // -------------------------------------------------------------------------
    // 7. RESERVED ADDRESSES
    // -------------------------------------------------------------------------

    rd(8'h60, rdval);

    expect_eq8(
      rdval,
      8'h00,
      "reserved_read_zero"
    );

    wr(8'h60, 8'hFF);

    rd(8'h60, rdval);

    expect_eq8(
      rdval,
      8'h00,
      "reserved_write_no_effect"
    );

    rd(8'hFF, rdval);

    expect_eq8(
      rdval,
      8'h00,
      "address_FF_read_zero"
    );

    // -------------------------------------------------------------------------
    // 8. DEVICE_ID / REVISION_ID READ ONLY
    // -------------------------------------------------------------------------

    wr(8'h55, 8'hFF);

    rd(8'h55, rdval);

    expect_eq8(
      rdval,
      8'h53,
      "device_id_write_ignored"
    );

    wr(8'h56, 8'hFF);

    rd(8'h56, rdval);

    expect_eq8(
      rdval,
      8'h01,
      "revision_id_write_ignored"
    );

    // -------------------------------------------------------------------------
    // 9. SAME-CYCLE SHADOW WRITE + COMMIT
    //
    // The corrected RTL explicitly states:
    //   "A same-cycle new shadow write wins over a commit."
    //
    // Therefore the newly written shadow value is NOT expected to appear in
    // active storage until the following commit.
    // -------------------------------------------------------------------------

    do_reset();

    @(negedge clk_ref);

    rb_addr  = 8'h06;
    rb_wdata = 8'hAA;
    rb_wr_en = 1'b1;

    commit_pulse = 1'b1;

    @(posedge clk_ref);

    @(negedge clk_ref);

    rb_wr_en = 1'b0;
    commit_pulse = 1'b0;

    // New shadow write must be dirty.
    expect_bit(
      dirty_o,
      1'b1,
      "same_cycle_write_wins_dirty"
    );

    // Active value must still be reset value because commit captured the old
    // shadow value.
    expect_eq12(
      active_cfg_o[0].on_count,
      12'h000,
      "same_cycle_commit_does_not_capture_new_shadow"
    );

    // Now commit again.
    pulse_commit();

    expect_eq12(
      active_cfg_o[0].on_count,
      12'h0AA,
      "second_commit_captures_shadow"
    );

    expect_bit(
      dirty_o,
      1'b0,
      "second_commit_clears_dirty"
    );

    // -------------------------------------------------------------------------
    // FINAL RESULT
    // -------------------------------------------------------------------------

    if (errors == 0) begin

      $display(
        "PASS: register_bank_tb - %0d checks, 0 errors",
        checks
      );

      $finish(0);

    end else begin

      $display(
        "FAIL: register_bank_tb - %0d checks, %0d errors",
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

    $display("FAIL: register_bank_tb - TIMEOUT");

    $fatal(1);

  end

endmodule

`default_nettype wire


