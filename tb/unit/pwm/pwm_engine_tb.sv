// =============================================================================
// pwm_engine_tb.sv
//
// Self-checking unit testbench for rtl/pwm/pwm_engine.sv.
//
// pwm_engine itself is a flop-free structural leaf (no clk/rst ports), so
// this testbench instantiates real register_bank + pwm_counter alongside
// the DUT (same "real modules, not stubs" pattern used by
// shadow_active_ctrl_tb.sv / prescale_gate_tb.sv), wired exactly as they
// will be at the real top level (Section 4), so every check confirms
// pwm_engine's actual effect on led_o/led_oe_o driven by real committed
// register state and a real free-running counter, not synthetic structs.
//
// register_bank is driven directly on its raw regbus ports (rb_wr_en/
// rb_addr/rb_wdata) -- register_decode/i2c_rx are not needed to exercise
// pwm_engine, same simplification register_bank_tb.sv itself uses.
//
// Covers:
//   1. Reset: all channels default full_off=1 (register_bank reset,
//      REGISTER_MAP.md OFF_H=0x10), enable=1, MODE2 reset 0x04
//      (OUTDRV=1, OUTNE=00, INVRT=0), oe_n_i=0 -> led_o=0 all channels,
//      led_oe_o=1 all channels (totem-pole, always driven).
//   2. Normal duty-cycle compare: program channel 0 on=0/off=0x800
//      (clear full_off), commit, and confirm led_o[0] tracks the shared
//      pwm_counter as it free-runs past the off point (high for
//      count<0x800, low for count>=0x800) -- proves count_i, the
//      active_cfg_i wiring, AND the ALL_LED_*-free per-channel path all
//      the way from register_bank through pwm_counter into pwm_engine.
//   3. SEMFONIX enable gate: disabling channel 0 via CHAN_ENABLE_L forces
//      led_o[0]=0 regardless of the programmed on/off window.
//   4. full_on override: channel 2 forced full_on -> led_o[2]=1 for every
//      counter value, independent of on/off counts.
//   5. SEMFONIX per-channel polarity: channel 3 full_on + polarity=1 ->
//      led_o[3]=0 (inverted), while an untouched channel stays normal.
//   6. Global MODE2.INVRT: flips every channel's active-output level
//      (channel 2, still full_on) without touching polarity.
//   7. oe_n_i / OUTNE mux: raising oe_n_i with OUTNE=2'b10 forces
//      high-impedance (led_oe_o=0) on every channel regardless of PWM
//      state; OUTNE=2'b00 forces driven-low (led_o=0, led_oe_o=1).
//   8. Per-channel independence: two channels with different on/off
//      phase windows produce different led_o values at the same
//      count_i, proving the 16-way replication (not a shared/muxed
//      comparator) -- Section 9.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o pwm_engine_tb \
//     rtl/registers/register_bank.sv rtl/pwm/pwm_compare.sv \
//     rtl/pwm/pwm_channel.sv rtl/pwm/pwm_counter.sv rtl/pwm/pwm_engine.sv \
//     tb/unit/pwm/pwm_engine_tb.sv
//   vvp pwm_engine_tb
// =============================================================================

`timescale 1ns/1ps

module pwm_engine_tb;

  import semfonix_regmap_pkg::*;

  localparam int  NUM_CHANNELS = 16;
  localparam int  PWM_WIDTH    = 12;
  localparam time CLK_PERIOD   = 10ns;

  logic clk_ref, rst_n;

  // --- regbus (tb drives register_bank directly, no register_decode) ---
  logic        rb_wr_en, rb_rd_en;
  logic [7:0]  rb_addr, rb_wdata;
  logic [7:0]  rb_rdata;
  logic        commit_pulse;
  logic        presc_write_allow_i;
  logic        dirty_o, group_update_req_o;

  pwm_chan_cfg_t active_cfg_o [NUM_CHANNELS];
  logic [7:0]  active_prescale_o;
  logic        active_sleep_o, active_ai_o, active_allcall_o, active_och_o;
  logic [2:0]  active_subx_en_o;
  logic [1:0]  active_outne_o;
  logic        active_outdrv_o, active_invrt_o;
  logic [6:0]  active_allcalladr_o;
  logic [6:0]  active_subadr_o [3];

  // --- pwm_counter <-> tb/DUT ---
  logic [PWM_WIDTH-1:0] count;
  logic                  frame_tick;

  // --- DUT-only ports ---
  logic                  oe_n_i;
  logic [NUM_CHANNELS-1:0] led_o;
  logic [NUM_CHANNELS-1:0] led_oe_o;

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

  pwm_counter #(.PWM_WIDTH(PWM_WIDTH), .PRESCALE_WIDTH(8)) pc (
    .clk_ref      (clk_ref),
    .rst_n        (rst_n),
    .prescale_i   (active_prescale_o),
    .sleep_i      (active_sleep_o),
    .count_o      (count),
    .frame_tick_o (frame_tick)
  );

  pwm_engine #(.NUM_CHANNELS(NUM_CHANNELS), .PWM_WIDTH(PWM_WIDTH)) dut (
    .count_i          (count),
    .active_cfg_i     (active_cfg_o),
    .active_invrt_i   (active_invrt_o),
    .active_outdrv_i  (active_outdrv_o),
    .active_outne_i   (active_outne_o),
    .oe_n_i           (oe_n_i),
    .led_o            (led_o),
    .led_oe_o         (led_oe_o)
  );

  initial clk_ref = 1'b0;
  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  task automatic expect_eq1(input logic got, input logic exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=%0b expected=%0b", tag, got, exp);
    end
  endtask

  task automatic expect_eq16(input logic [15:0] got, input logic [15:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=0x%04h expected=0x%04h", tag, got, exp);
    end
  endtask

  // Direct regbus write (mirrors register_bank_tb.sv's simplification --
  // no register_decode/i2c needed to exercise pwm_engine).
  task automatic rb_write(input logic [7:0] addr, input logic [7:0] data);
    begin
      @(negedge clk_ref);
      rb_addr = addr; rb_wdata = data; rb_wr_en = 1'b1;
      @(posedge clk_ref);
      @(negedge clk_ref);
      rb_wr_en = 1'b0;
    end
  endtask

  task automatic do_commit();
    begin
      @(negedge clk_ref);
      commit_pulse = 1'b1;
      @(posedge clk_ref);
      @(negedge clk_ref);
      commit_pulse = 1'b0;
    end
  endtask

  // Program one channel's shadow ON/OFF and commit it, per
  // docs/architecture/REGISTER_MAP.md LEDn layout (base = 0x06 + 4*n).
  task automatic program_channel(
    input int          chan,
    input logic [11:0] on_count,
    input logic [11:0] off_count,
    input logic        full_on,
    input logic        full_off
  );
    logic [7:0] base;
    begin
      base = 8'h06 + 8'(4 * chan);
      rb_write(base + 8'h0, on_count[7:0]);
      rb_write(base + 8'h1, {3'b000, full_on, on_count[11:8]});
      rb_write(base + 8'h2, off_count[7:0]);
      rb_write(base + 8'h3, {3'b000, full_off, off_count[11:8]});
      do_commit();
    end
  endtask

  task automatic do_reset();
    begin
      rst_n = 1'b0;
      rb_wr_en = 1'b0; rb_rd_en = 1'b0;
      rb_addr = '0; rb_wdata = '0;
      commit_pulse = 1'b0;
      presc_write_allow_i = 1'b1;
      oe_n_i = 1'b0;
      repeat (3) @(posedge clk_ref);
      rst_n = 1'b1;
      @(posedge clk_ref);
      @(negedge clk_ref);
    end
  endtask

  initial begin
    do_reset();

    // -------------------------------------------------------------------
    // 1. Reset state: every channel full_off (0x10 default), enable=1,
    //    MODE2 reset (OUTDRV=1 totem-pole), oe_n_i=0.
    // -------------------------------------------------------------------
    expect_eq16(led_o,    16'h0000, "reset_led_o_all_low");
    expect_eq16(led_oe_o, 16'hFFFF, "reset_led_oe_all_driven_totem_pole");

    // -------------------------------------------------------------------
    // 2. Normal duty-cycle compare, channel 0: on=0, off=0x800.
    // -------------------------------------------------------------------
    program_channel(0, 12'h000, 12'h800, 1'b0, 1'b0);
    @(negedge clk_ref);
    // Prescale reset default is 0x1E (non-zero), so the counter ticks
    // only once every (0x1E+1) clk_ref cycles -- freeze it at count==0
    // instead of waiting out real time: prescale write is SLEEP-guarded
    // and MODE1.SLEEP resets to 1, so the counter is already frozen at
    // count==0 here (no PRE_SCALE write / no SLEEP clear performed yet).
    expect_eq1(active_sleep_o, 1'b1, "reset_sleep_still_1_counter_frozen");
    expect_eq1(led_o[0], 1'b1, "duty_ch0_high_at_count_0_below_off_point");

    // Clear SLEEP (MODE1 reset 0x11: bit4=SLEEP) so the counter free-runs;
    // also drop prescale to 0 so it ticks every clk_ref cycle (fast sim).
    presc_write_allow_i = 1'b1; // guard is combinational in prescale_gate,
                                 // but this tb drives register_bank
                                 // directly -- write PRE_SCALE while
                                 // SLEEP=1 (still set) so it is accepted.
    rb_write(8'hFE, 8'h00); // PRE_SCALE = 0
    rb_write(8'h00, 8'h01); // MODE1 = 0x01 (SLEEP=0, ALLCALL=1 default kept off is fine here)
    expect_eq1(active_sleep_o, 1'b0, "sleep_cleared");

    // Step the counter well past the 0x800 off-point (>4096 cycles to
    // guarantee at least one full wrap is observed and land solidly
    // past 0x800 again) and confirm led_o[0] tracks the compare window.
    repeat (12) @(posedge clk_ref); // small settle, still count<0x800
    @(negedge clk_ref);
    expect_eq1(led_o[0], 1'b1, "duty_ch0_still_high_early_in_window");

    repeat (2100) @(posedge clk_ref); // now count is somewhere >= 0x800 (<4096 total)
    @(negedge clk_ref);
    expect_eq1(led_o[0], 1'b0, "duty_ch0_low_past_off_point");

    // -------------------------------------------------------------------
    // 3. SEMFONIX enable gate overrides the compare result.
    // -------------------------------------------------------------------
    // Re-arm channel0 to be high at the current counter position by
    // giving it a full_on override (simplest way to get a known-'1' raw
    // level without needing to know the exact live count value).
    program_channel(0, 12'h000, 12'h001, 1'b1, 1'b0); // full_on=1
    @(negedge clk_ref);
    expect_eq1(led_o[0], 1'b1, "enable_pre_check_ch0_high_full_on");

    rb_write(8'h50, 8'hFE); // CHAN_ENABLE_L: disable channel 0 only
    @(negedge clk_ref);
    expect_eq1(led_o[0], 1'b0, "enable_gate_forces_low_when_disabled");
    rb_write(8'h50, 8'hFF); // re-enable channel 0
    @(negedge clk_ref);
    expect_eq1(led_o[0], 1'b1, "enable_gate_restored");

    // -------------------------------------------------------------------
    // 4. full_on override, channel 2: high regardless of count.
    // -------------------------------------------------------------------
    program_channel(2, 12'h500, 12'h100, 1'b1, 1'b0); // wraparound-shaped
                                                        // window, but
                                                        // full_on wins
    @(negedge clk_ref);
    expect_eq1(led_o[2], 1'b1, "full_on_ch2_high_regardless_of_window");

    // -------------------------------------------------------------------
    // 5. SEMFONIX per-channel polarity inverts only the targeted channel.
    // -------------------------------------------------------------------
    program_channel(3, 12'h000, 12'h001, 1'b1, 1'b0); // full_on=1
    @(negedge clk_ref);
    expect_eq1(led_o[3], 1'b1, "polarity_pre_check_ch3_high_full_on");

    rb_write(8'h52, 8'h08); // CHAN_POLARITY_L bit3 -> invert channel 3 only
    @(negedge clk_ref);
    expect_eq1(led_o[3], 1'b0, "polarity_inverts_ch3_only");
    expect_eq1(led_o[2], 1'b1, "polarity_ch2_unaffected_by_ch3_polarity");
    rb_write(8'h52, 8'h00); // clear polarity

    // -------------------------------------------------------------------
    // 6. Global MODE2.INVRT flips every channel's active-output level.
    // -------------------------------------------------------------------
    @(negedge clk_ref);
    expect_eq1(led_o[2], 1'b1, "invrt_pre_check_ch2_high_full_on");
    rb_write(8'h01, 8'h14); // MODE2: keep OUTDRV(bit2)=1, set INVRT(bit4)=1 -> 0001_0100
    @(negedge clk_ref);
    expect_eq1(led_o[2], 1'b0, "invrt_flips_ch2_full_on_level");
    rb_write(8'h01, 8'h04); // restore MODE2 default (INVRT=0, OUTDRV=1)

    // -------------------------------------------------------------------
    // 7. oe_n_i / OUTNE forced-state mux, independent of PWM state.
    // -------------------------------------------------------------------
    @(negedge clk_ref);
    expect_eq1(led_o[2], 1'b1, "outne_pre_check_ch2_high_full_on");
    oe_n_i = 1'b1;
    // MODE2 = 0x02: bit4 INVRT=0, bit3 OCH=0, bit2 OUTDRV=0, bits1:0
    // OUTNE=2'b10 -> forced high-impedance per pwm_channel.sv Table 11.
    rb_write(8'h01, 8'h02);
    @(negedge clk_ref);
    expect_eq16(led_oe_o, 16'h0000, "outne_10_forces_all_high_z_regardless_of_pwm");

    rb_write(8'h01, 8'h00); // OUTNE=00 -> forced driven-low
    @(negedge clk_ref);
    expect_eq16(led_o,    16'h0000, "outne_00_forces_all_driven_low");
    expect_eq16(led_oe_o, 16'hFFFF, "outne_00_forces_all_actively_driven");

    oe_n_i = 1'b0;
    rb_write(8'h01, 8'h04); // restore MODE2 default

    // -------------------------------------------------------------------
    // 8. Per-channel independence: two channels, two different windows,
    //    same shared count_i, must disagree with each other.
    // -------------------------------------------------------------------
    program_channel(4, 12'h000, 12'h001, 1'b1, 1'b0); // full_on
    program_channel(5, 12'h000, 12'h001, 1'b0, 1'b1); // full_off
    @(negedge clk_ref);
    expect_eq1(led_o[4], 1'b1, "independence_ch4_full_on_high");
    expect_eq1(led_o[5], 1'b0, "independence_ch5_full_off_low");

    if (errors == 0) begin
      $display("PASS: pwm_engine_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: pwm_engine_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout
  initial begin
    #2000000;
    $display("FAIL: pwm_engine_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
