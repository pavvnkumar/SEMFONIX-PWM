// =============================================================================
// pwm_engine.sv
//
// 16-channel PWM integration, per docs/MASTER_ARCHITECTURE.md Sections 4,
// 5.3 and 9.
//
// Owns NO flops and no clk/rst ports: this module's entire job is
// instantiating NUM_CHANNELS x pwm_channel (itself flop-free, per that
// module's header comment) against the single shared `count_i` from
// pwm_counter and register_bank's `active_cfg_o` array, plus the global
// MODE2 fields and the output-enable pin. It is a pure structural
// fan-out/integration leaf, the same "combinational leaf" pattern already
// used by address_decode.sv and prescale_gate.sv.
//
// ALL_LED_* broadcast (ALL_LED_ON/OFF_L/H) is NOT re-implemented here: per
// Section 9, that fan-out already lives inside register_bank.sv as a
// 16-way shadow-write-enable fan-out from one decoded address. By the
// time `active_cfg_i` reaches this module, a broadcast write is
// indistinguishable from 16 individual per-channel writes -- this module
// never needs to know the difference.
//
// Every channel gets the identical shared `count_i` (Section 9: exactly
// one pwm_counter instance in the whole chip) and the identical global
// MODE2 fields (`active_invrt_i`, `active_outdrv_i`, `active_outne_i`)
// and `oe_n_i` pin; only the per-channel `active_cfg_i[n]` struct differs
// between instances.
// =============================================================================

`default_nettype none

module pwm_engine
  import semfonix_regmap_pkg::*;
#(
  parameter int NUM_CHANNELS = 16,
  parameter int PWM_WIDTH    = 12
) (
  input  logic [PWM_WIDTH-1:0]  count_i,          // shared frame counter, from pwm_counter

  // active (post-commit) per-channel configuration, from register_bank
  input  pwm_chan_cfg_t         active_cfg_i [NUM_CHANNELS],

  // active MODE2 fields, from register_bank (shared by every channel)
  input  logic                  active_invrt_i,
  input  logic                  active_outdrv_i,
  input  logic [1:0]            active_outne_i,

  // active-low output-enable pin (post-sync, from top level)
  input  logic                  oe_n_i,

  // LED PWM outputs -- same (level, drive-enable) pair pattern as
  // semfonix_pwm16_top's led_o/led_oe_o (Section 5.1), one bit per
  // channel per array, so this module can be wired straight through at
  // the top level with no repacking.
  output logic [NUM_CHANNELS-1:0] led_o,
  output logic [NUM_CHANNELS-1:0] led_oe_o
);

  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i++) begin : g_chan
      pwm_channel #(.PWM_WIDTH(PWM_WIDTH)) u_chan (
        .count       (count_i),
        .on_count    (active_cfg_i[i].on_count),
        .off_count   (active_cfg_i[i].off_count),
        .full_on     (active_cfg_i[i].full_on),
        .full_off    (active_cfg_i[i].full_off),
        .enable      (active_cfg_i[i].enable),
        .polarity    (active_cfg_i[i].polarity),
        .invrt       (active_invrt_i),
        .oe_n_i      (oe_n_i),
        .outne       (active_outne_i),
        .outdrv      (active_outdrv_i),
        .led_level_o (led_o[i]),
        .led_drive_o (led_oe_o[i])
      );
    end
  endgenerate

endmodule

`default_nettype wire
