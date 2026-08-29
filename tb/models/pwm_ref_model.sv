// =============================================================================
// pwm_ref_model.sv
//
// Independent software reference model of SEMFONIX PWM16's register +
// shadow/active + timebase + output-stage behavior, per
// docs/MASTER_ARCHITECTURE.md Section 23 ("`tb/models/pwm_ref_model.sv` ...
// independently computes expected `led_o` from a mirrored copy of ON/OFF/
// full-on/full-off/enable/polarity/count state, *without* reusing the RTL's
// comparator code, so it is a true independent check"). This is the second
// of the two new files closing out step 13 of the Section 22 implementation
// order (alongside `tb/models/i2c_bfm.sv`).
//
// This model is deliberately NOT built by importing `semfonix_regmap_pkg`
// (defined inside `rtl/registers/register_bank.sv`) or by instantiating any
// `rtl/*` module: every field layout, address mapping, and comparator
// expression below is independently transcribed from
// `docs/architecture/REGISTER_MAP.md` and `docs/MASTER_ARCHITECTURE.md`
// Sections 8/9/10/12/13/14/15 (the specification documents), not from the
// RTL source, so a bug shared between this model and the RTL would have to
// be a bug shared between the RTL and the *specification*, not merely a
// copy-paste of the same implementation -- the actual independence Section
// 23 asks for.
//
// --- How this model is driven (important simplification, documented) ---
// This model does NOT implement its own I2C slave protocol decode. Section
// 23 only requires it to "independently compute expected led_o from a
// mirrored copy of state" -- it does not require re-deriving that state from
// raw SCL/SDA edges a second time (that would just be a second, redundant
// I2C slave implementation, adding verification risk of its own rather than
// removing it, without changing what's actually being checked: the
// register-to-LED datapath). Instead, `tb/integration/semfonix_pwm16_tb.sv`
// calls this model's `reg_write()`/`stop_commit()`/`sync_pulse()` tasks in
// lock-step with each real I2C transaction it drives via `i2c_bfm.sv`,
// mirroring exactly the register-level effect that transaction is expected
// to have -- the same "mirrored copy of state" Section 23 describes, kept in
// sync by the testbench rather than by a second protocol decoder. The I2C
// *protocol* itself (address matching, ACK/NACK, auto-increment, general-
// call SWRST framing) is exactly what the unit-level I2C testbenches
// (`i2c_rx_tb.sv`/`i2c_tx_tb.sv`/`i2c_slave_tb.sv`) already independently
// verify byte-for-byte against real register_bank storage; this model does
// not need to re-verify that layer, only the register-to-LED datapath layer
// on top of it, so integration coverage is not weakened by this split.
//
// The free-running timebase (`count_m`/`tick_div_m` below) is the one part
// of this model that genuinely IS clocked (`always_ff` on `clk_ref`/
// `rst_n`, the same two nets driving the DUT), so it free-runs in lockstep
// with the DUT's own `pwm_counter.sv` automatically -- no task call needed
// to keep it synchronized, since it re-derives its own tick/wrap timing
// independently from `prescale_m`/`mode1_m[4]` (SLEEP) each cycle exactly as
// Section 12's formula specifies (`f_pwm = f_ref / (4096*(prescale+1))`,
// realized here as its own from-scratch tick-divider comparator, not
// `pwm_counter.sv`'s).
//
// Everything else (mode1_m, mode2_m, subadr*_m, allcalladr_m, prescale_m,
// chan_enable_m/chan_polarity_m, and the shadow/active LEDn arrays) is a
// plain (non-clocked) variable updated immediately (blocking assignment)
// inside `reg_write()`/commit tasks -- an intentional software-model
// simplification: by the time the testbench's call to a task like
// `reg_write()` returns, the corresponding real I2C transaction has already
// completed in simulation time (the testbench issues them back-to-back, in
// order), so the model's state transitions land at the same *simulation-time
// point* the DUT's real register_bank/shadow_active_ctrl already committed
// to, even though this model doesn't reproduce the DUT's own cycle-by-cycle
// internal pulse timing to get there. `exp_led_o`/`exp_led_oe_o` below are
// continuously (`always_comb`) re-derived from this state plus the live
// `oe_n_i`/`count_m`, so once a transaction settles, the model's outputs
// track the DUT's real outputs cycle-for-cycle for as long as no further
// register write/commit occurs -- exactly the window the integration
// testbench's `checking_enabled` background comparator (see that file) uses.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module pwm_ref_model #(
  parameter int NUM_CHANNELS = 16,
  parameter int PWM_WIDTH    = 12
) (
  input  logic                     clk_ref,
  input  logic                     rst_n,

  // live top-level output-enable pin, same net the DUT's oe_n_i consumes
  input  logic                     oe_n_i,

  // continuously-computed expected outputs (see header)
  output logic [NUM_CHANNELS-1:0]  exp_led_o,
  output logic [NUM_CHANNELS-1:0]  exp_led_oe_o,

  // exposed for the testbench's own sanity checks / debug visibility only
  output logic [PWM_WIDTH-1:0]     count_o,
  output logic                     dirty_o
);

  // ---------------------------------------------------------------------
  // Address map constants -- independently transcribed from
  // docs/architecture/REGISTER_MAP.md (not shared with register_bank.sv's
  // own localparams -- see header).
  // ---------------------------------------------------------------------
  localparam logic [7:0] A_MODE1        = 8'h00;
  localparam logic [7:0] A_MODE2        = 8'h01;
  localparam logic [7:0] A_SUBADR1      = 8'h02;
  localparam logic [7:0] A_SUBADR2      = 8'h03;
  localparam logic [7:0] A_SUBADR3      = 8'h04;
  localparam logic [7:0] A_ALLCALLADR   = 8'h05;
  localparam logic [7:0] A_LED_BASE     = 8'h06;
  localparam logic [7:0] A_LED_LAST     = 8'h45;
  localparam logic [7:0] A_CHAN_EN_L    = 8'h50;
  localparam logic [7:0] A_CHAN_EN_H    = 8'h51;
  localparam logic [7:0] A_CHAN_POL_L   = 8'h52;
  localparam logic [7:0] A_CHAN_POL_H   = 8'h53;
  localparam logic [7:0] A_GROUP_UPDATE = 8'h54;
  localparam logic [7:0] A_DEVICE_ID    = 8'h55;
  localparam logic [7:0] A_REVISION_ID  = 8'h56;
  localparam logic [7:0] A_ALL_LED_ON_L = 8'hFA;
  localparam logic [7:0] A_ALL_LED_ON_H = 8'hFB;
  localparam logic [7:0] A_ALL_LED_OFF_L= 8'hFC;
  localparam logic [7:0] A_ALL_LED_OFF_H= 8'hFD;
  localparam logic [7:0] A_PRE_SCALE    = 8'hFE;

  // ---------------------------------------------------------------------
  // Mirrored register storage (plain variables -- see header). Reset by
  // the explicit reset_model() task below, called by the testbench
  // alongside every real DUT reset, NOT by an always_ff block, so its
  // reset timing is under direct testbench control (paired 1:1 with the
  // real do_reset() sequence the testbench already uses).
  // ---------------------------------------------------------------------
  logic [7:0]  mode1_m, mode2_m;
  logic [7:0]  subadr1_m, subadr2_m, subadr3_m, allcalladr_m;
  logic [7:0]  prescale_m;
  logic [15:0] chan_enable_m, chan_polarity_m;

  logic [11:0] shadow_on_m  [NUM_CHANNELS];
  logic [11:0] shadow_off_m [NUM_CHANNELS];
  logic        shadow_fon_m [NUM_CHANNELS];
  logic        shadow_foff_m[NUM_CHANNELS];

  logic [11:0] active_on_m  [NUM_CHANNELS];
  logic [11:0] active_off_m [NUM_CHANNELS];
  logic        active_fon_m [NUM_CHANNELS];
  logic        active_foff_m[NUM_CHANNELS];

  logic        dirty_m;

  assign dirty_o = dirty_m;

  task automatic reset_model();
    mode1_m       = 8'h11;
    mode2_m       = 8'h04;
    subadr1_m     = 8'hE2;
    subadr2_m     = 8'hE4;
    subadr3_m     = 8'hE8;
    allcalladr_m  = 8'hE0;
    prescale_m    = 8'h1E;
    chan_enable_m = 16'hFFFF;
    chan_polarity_m = 16'h0000;
    dirty_m       = 1'b0;
    for (int i = 0; i < NUM_CHANNELS; i++) begin
      shadow_on_m[i]   = 12'h000;
      shadow_off_m[i]  = 12'h000;
      shadow_fon_m[i]  = 1'b0;
      shadow_foff_m[i] = 1'b1;  // matches OFF_H reset default 0x10 (Section/REGISTER_MAP.md)
      active_on_m[i]   = 12'h000;
      active_off_m[i]  = 12'h000;
      active_fon_m[i]  = 1'b0;
      active_foff_m[i] = 1'b1;
    end
  endtask

  // is `addr` a channel's OFF_H byte (the group's 4th/last byte), or the
  // ALL_LED_OFF_H broadcast equivalent? independently re-derived from
  // REGISTER_MAP.md, same semantics register_decode.sv's
  // is_group_last_byte() implements for ack4_event_o.
  function automatic logic is_group_last_byte(input logic [7:0] addr);
    logic in_led_range;
    in_led_range = (addr >= A_LED_BASE) && (addr <= A_LED_LAST);
    is_group_last_byte = (in_led_range && (((addr - A_LED_BASE) & 8'h03) == 8'h03))
                          || (addr == A_ALL_LED_OFF_H);
  endfunction

  // Commit: shadow -> active, all channels, atomically (same-simulation-
  // -time semantics -- see header). Mirrors register_bank.sv's commit
  // behavior as specified by MASTER_ARCHITECTURE.md Section 13, not its
  // RTL.
  task automatic model_commit();
    for (int i = 0; i < NUM_CHANNELS; i++) begin
      active_on_m[i]   = shadow_on_m[i];
      active_off_m[i]  = shadow_off_m[i];
      active_fon_m[i]  = shadow_fon_m[i];
      active_foff_m[i] = shadow_foff_m[i];
    end
    dirty_m = 1'b0;
  endtask

  // Called by the testbench once per real register write it issues via
  // i2c_bfm.sv, with the same (addr,data) the real transaction carried.
  // Applies REGISTER_MAP.md's write semantics, including the two
  // write-time-immediate commit sources (GROUP_UPDATE and, when
  // MODE2.OCH=1, a group's 4th/last byte) -- Section 13 sources #2 and #3,
  // both combinational-same-cycle in the real hardware, so applied
  // immediately here too rather than requiring a separate task call.
  task automatic reg_write(input logic [7:0] addr, input logic [7:0] data);
    logic        in_led_range;
    logic [3:0]  chan;
    logic [1:0]  field;

    in_led_range = (addr >= A_LED_BASE) && (addr <= A_LED_LAST);
    chan  = (addr - A_LED_BASE) >> 2;
    field = (addr - A_LED_BASE) & 8'h3;

    unique case (1'b1)
      (addr == A_MODE1):      mode1_m      = data;
      (addr == A_MODE2):      mode2_m      = data;
      (addr == A_SUBADR1):    subadr1_m    = data;
      (addr == A_SUBADR2):    subadr2_m    = data;
      (addr == A_SUBADR3):    subadr3_m    = data;
      (addr == A_ALLCALLADR): allcalladr_m = data;

      (addr == A_PRE_SCALE): begin
        if (mode1_m[4]) prescale_m = data;  // SLEEP-guarded (Section 12)
        // else: silently dropped, matches prescale_gate.sv's spec'd policy
      end

      (addr == A_CHAN_EN_L):  chan_enable_m[7:0]    = data;
      (addr == A_CHAN_EN_H):  chan_enable_m[15:8]   = data;
      (addr == A_CHAN_POL_L): chan_polarity_m[7:0]  = data;
      (addr == A_CHAN_POL_H): chan_polarity_m[15:8] = data;

      (addr == A_GROUP_UPDATE): begin
        if (data[0]) model_commit();  // write-time-immediate (Section 13 #3)
      end

      (addr == A_DEVICE_ID):   ; // RO
      (addr == A_REVISION_ID): ; // RO

      (in_led_range): begin
        unique case (field)
          2'd0: shadow_on_m[chan][7:0]   = data;
          2'd1: begin
                  shadow_on_m[chan][11:8] = data[3:0];
                  shadow_fon_m[chan]      = data[4];
                end
          2'd2: shadow_off_m[chan][7:0]  = data;
          2'd3: begin
                  shadow_off_m[chan][11:8] = data[3:0];
                  shadow_foff_m[chan]      = data[4];
                end
          default: ;
        endcase
        dirty_m = 1'b1;
        if (mode2_m[3] && is_group_last_byte(addr)) model_commit();  // OCH=1, Section 13 #2
      end

      (addr == A_ALL_LED_ON_L): begin
        for (int i = 0; i < NUM_CHANNELS; i++) shadow_on_m[i][7:0] = data;
        dirty_m = 1'b1;
      end
      (addr == A_ALL_LED_ON_H): begin
        for (int i = 0; i < NUM_CHANNELS; i++) begin
          shadow_on_m[i][11:8] = data[3:0];
          shadow_fon_m[i]      = data[4];
        end
        dirty_m = 1'b1;
      end
      (addr == A_ALL_LED_OFF_L): begin
        for (int i = 0; i < NUM_CHANNELS; i++) shadow_off_m[i][7:0] = data;
        dirty_m = 1'b1;
      end
      (addr == A_ALL_LED_OFF_H): begin
        for (int i = 0; i < NUM_CHANNELS; i++) begin
          shadow_off_m[i][11:8] = data[3:0];
          shadow_foff_m[i]      = data[4];
        end
        dirty_m = 1'b1;
        if (mode2_m[3]) model_commit();  // OCH=1, ALL_LED_OFF_H also a group-last-byte (Section 13 #2)
      end

      default: ; // reserved: write silently dropped (Section 16)
    endcase
  endtask

  // Called by the testbench right after issuing a real STOP condition,
  // ONLY implements source #1 (STOP-commit, OCH=0 default) -- the caller
  // is expected to have already applied any OCH=1 commit at write time
  // via reg_write() above (the two sources are mutually exclusive per
  // Section 13, same as shadow_active_ctrl.sv's och_i mux).
  task automatic stop_commit();
    if (!mode2_m[3]) begin  // OCH=0
      if (dirty_m) model_commit();
    end
  endtask

  // Called by the testbench to model one GROUP_UPDATE-equivalent external
  // sync_update_i pulse (Section 13 source #4) -- unconditional commit,
  // independent of OCH, matching shadow_active_ctrl.sv's spec'd behavior.
  task automatic sync_pulse();
    model_commit();
  endtask

  // ---------------------------------------------------------------------
  // Free-running timebase -- the one genuinely clocked part of this model
  // (see header). Independently re-derived tick-divider + wraparound
  // counter, not pwm_counter.sv's.
  // ---------------------------------------------------------------------
  logic [7:0]           tick_div_m;
  logic [PWM_WIDTH-1:0] count_m;

  assign count_o = count_m;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      tick_div_m <= 8'h00;
      count_m    <= '0;
    end else if (mode1_m[4]) begin
      tick_div_m <= 8'h00;  // SLEEP: freeze, same "restart clean" policy as pwm_counter.sv's spec
    end else if (tick_div_m == prescale_m) begin
      tick_div_m <= 8'h00;
      count_m    <= count_m + 1'b1;
    end else begin
      tick_div_m <= tick_div_m + 1'b1;
    end
  end

  // ---------------------------------------------------------------------
  // Expected output-stage computation (Section 15's 7-stage priority
  // order), continuously re-derived, independent expression forms from
  // pwm_compare.sv/pwm_channel.sv (own comparator, own mux tree).
  // ---------------------------------------------------------------------
  always_comb begin
    for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
      logic in_range;
      logic raw, gated, inv;
      logic enable_bit, polarity_bit, invrt_bit, outdrv_bit;
      logic [1:0] outne_bits;

      enable_bit   = chan_enable_m[ch];
      polarity_bit = chan_polarity_m[ch];
      invrt_bit    = mode2_m[4];
      outdrv_bit   = mode2_m[2];
      outne_bits   = mode2_m[1:0];

      // 1/2/3: full_off > full_on > compare (Section 10/15)
      if (active_on_m[ch] <= active_off_m[ch])
        in_range = (count_m >= active_on_m[ch]) && (count_m < active_off_m[ch]);
      else
        in_range = (count_m >= active_on_m[ch]) || (count_m < active_off_m[ch]);

      if (active_foff_m[ch])      raw = 1'b0;
      else if (active_fon_m[ch])  raw = 1'b1;
      else                        raw = in_range;

      // 4: SEMFONIX enable gate
      gated = raw & enable_bit;

      // 5/6: global INVRT XOR per-channel polarity
      inv = gated ^ invrt_bit ^ polarity_bit;

      // 7: oe_n_i / OUTNE forced-state mux
      if (oe_n_i) begin
        unique case (outne_bits)
          2'b00: begin
            exp_led_o[ch]    = 1'b0;
            exp_led_oe_o[ch] = 1'b1;
          end
          2'b01: begin
            exp_led_o[ch]    = 1'b1;
            exp_led_oe_o[ch] = outdrv_bit;
          end
          default: begin // 2'b10, 2'b11 -> high-impedance
            exp_led_o[ch]    = 1'b0;
            exp_led_oe_o[ch] = 1'b0;
          end
        endcase
      end else begin
        exp_led_o[ch]    = inv;
        exp_led_oe_o[ch] = outdrv_bit ? 1'b1 : ~inv;
      end
    end
  end

endmodule

`default_nettype wire
