// =============================================================================
// pwm_channel.sv
//
// Single-channel PWM output stage, per docs/MASTER_ARCHITECTURE.md
// Sections 10 and 15.
//
// Owns NO flops: all configuration (on_count, off_count, full_on,
// full_off, enable, polarity) is wired in combinationally from
// register_bank's active register array. This module is a thin,
// synthesis-friendly leaf so it can be freely replicated 16x (see
// MASTER_ARCHITECTURE.md Section 9) without duplicating storage.
//
// Output-stage priority order (matches reference PCA9685 Table 11 /
// Section 7.4 semantics, with SEMFONIX enable/polarity layered in):
//   1. full_off          -> forces raw PWM level low  (pwm_compare)
//   2. full_on           -> forces raw PWM level high (pwm_compare)
//   3. compare result    -> normal/wraparound PWM duty+phase
//   4. SEMFONIX enable   -> AND-gate after PWM decision
//   5. invert_global XOR -> MODE2.INVRT (applies only while oe_n=0, i.e.
//                            outputs are enabled -- reference semantics)
//   6. SEMFONIX polarity -> per-channel XOR, composes with global invert
//   7. oe_n_i / OUTNE mux-> forced level+drive when output-enable pin is
//                           high (outputs disabled), independent of PWM
//                           state
//
// Digital-core / pad-boundary interface:
// This module drives two signals per channel, (led_level_o, led_drive_o),
// rather than a single wired-logic bit, so that open-drain and
// high-impedance output states (real, meaningful states on the physical
// PCA9685-class part, per reference Section 7.7 / Table 11) are correctly
// represented at the digital boundary instead of being silently collapsed
// to a driven '0'. A pad cell / IO ring (outside this digital core's
// scope) is expected to interpret `led_drive_o=0` as "do not drive this
// pad" (true high-Z / released, matching an open-drain HIGH or a
// high-impedance OUTNE state) and `led_drive_o=1` as "drive led_level_o."
// This mirrors the same pattern already used for the I2C SDA pin
// (sda_o/sda_oe) at the top level, for consistency.
// =============================================================================

`default_nettype none

module pwm_channel #(
  parameter int PWM_WIDTH = 12
) (
  input  logic [PWM_WIDTH-1:0] count,          // shared frame counter (from pwm_counter)

  // active (post-commit) per-channel configuration
  input  logic [PWM_WIDTH-1:0] on_count,
  input  logic [PWM_WIDTH-1:0] off_count,
  input  logic                 full_on,
  input  logic                 full_off,
  input  logic                 enable,         // SEMFONIX per-channel enable
  input  logic                 polarity,       // SEMFONIX per-channel polarity

  // global mode bits (active MODE2 fields)
  input  logic                 invrt,          // MODE2.INVRT, applies when oe_n_i=0
  input  logic                 oe_n_i,         // active-low output-enable pin (post-sync)
  input  logic [1:0]           outne,          // MODE2.OUTNE[1:0], forced state select when oe_n_i=1
  input  logic                 outdrv,         // MODE2.OUTDRV: 1=totem-pole (always driven), 0=open-drain

  output logic                 led_level_o,    // logical level to drive (meaningful only if led_drive_o=1)
  output logic                 led_drive_o     // 1 = actively drive led_level_o, 0 = release/high-Z
);

  logic raw_level;
  logic gated_level;
  logic inverted_level;

  pwm_compare #(.PWM_WIDTH(PWM_WIDTH)) u_compare (
    .count     (count),
    .on_count  (on_count),
    .off_count (off_count),
    .full_on   (full_on),
    .full_off  (full_off),
    .raw_level (raw_level)
  );

  assign gated_level    = raw_level & enable;
  assign inverted_level = gated_level ^ invrt ^ polarity;

  // Normal (OE=0, outputs enabled) drive decision:
  //   OUTDRV=1 (totem-pole): always actively driven, either level.
  //   OUTDRV=0 (open-drain): only actively drives LOW; a logical HIGH is
  //                          represented by releasing the pad (external
  //                          pull-up assumed, standard open-drain usage).
  logic normal_drive_en;
  assign normal_drive_en = outdrv ? 1'b1 : ~inverted_level;

  // Table 11 (reference) forced state when OE=1 (outputs not enabled):
  //   OUTNE=00               -> LEDn = 0            (driven low)
  //   OUTNE=01               -> LEDn = 1 if OUTDRV=1 (driven high);
  //                             high-impedance if OUTDRV=0 (released)
  //   OUTNE=1X (10 or 11)    -> high-impedance (released), any OUTDRV
  logic oe1_level;
  logic oe1_drive_en;
  always_comb begin
    unique case (outne)
      2'b00: begin
        oe1_level    = 1'b0;
        oe1_drive_en = 1'b1;
      end
      2'b01: begin
        oe1_level    = 1'b1;
        oe1_drive_en = outdrv; // driven high if totem-pole, released if open-drain
      end
      default: begin // 2'b10, 2'b11 -> high-impedance
        oe1_level    = 1'b0; // don't-care, not driven
        oe1_drive_en = 1'b0;
      end
    endcase
  end

  assign led_level_o = oe_n_i ? oe1_level    : inverted_level;
  assign led_drive_o  = oe_n_i ? oe1_drive_en : normal_drive_en;

endmodule

`default_nettype wire
