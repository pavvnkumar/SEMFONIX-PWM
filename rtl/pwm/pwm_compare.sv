// =============================================================================
// pwm_compare.sv
//
// Purely combinational 12-bit PWM phase/duty comparator.
//
// Given the shared free-running frame counter and a channel's ON/OFF
// counts, produces the "raw" (pre full-on/full-off override, pre enable,
// pre polarity) PWM output level for that channel, per
// docs/MASTER_ARCHITECTURE.md Section 10.
//
// Handles both the "normal" case (on_count <= off_count: channel is high
// for the half-open interval [on_count, off_count)) and the "wraparound"
// case (on_count > off_count: channel is high for [on_count, 4095] union
// [0, off_count)), matching the reference PCA9685 datasheet Figures 7-11
// examples.
//
// full_off takes precedence over full_on when both are asserted, per the
// reference datasheet's explicit precedence rule.
//
// This module is instantiated once per channel (16x at the pwm_engine
// level) rather than time-multiplexed, because every channel must produce
// a valid output on every single timebase tick simultaneously — see
// MASTER_ARCHITECTURE.md Section 9 for the full sharing-vs-replication
// rationale. It is deliberately small (a handful of 12-bit compares) to
// keep the per-channel replication cost low.
//
// No sequential state: this module owns no flops. All state (on_count,
// off_count, full_on, full_off) lives in register_bank's active register
// array and is simply wired in.
// =============================================================================

`default_nettype none

module pwm_compare #(
  parameter int PWM_WIDTH = 12
) (
  input  logic [PWM_WIDTH-1:0] count,      // shared free-running frame counter value
  input  logic [PWM_WIDTH-1:0] on_count,   // this channel's programmed ON point
  input  logic [PWM_WIDTH-1:0] off_count,  // this channel's programmed OFF point
  input  logic                 full_on,    // force output high regardless of count
  input  logic                 full_off,   // force output low regardless of count (highest priority)
  output logic                 raw_level   // resulting raw PWM level (pre enable/polarity/OE)
);

  logic normal_range_active;
  logic wrap_range_active;
  logic compare_level;

  // Normal case: on_count <= off_count -> high for [on_count, off_count)
  assign normal_range_active = (count >= on_count) && (count < off_count);

  // Wraparound case: on_count > off_count -> high for [on_count,MAX] U [0,off_count)
  assign wrap_range_active = (count >= on_count) || (count < off_count);

  // NOTE: if on_count == off_count the reference datasheet states this
  // combination "should never be programmed." The normal-case expression
  // naturally resolves this to an always-empty interval (raw_level=0
  // whenever not full_on/full_off), which is a safe, deterministic
  // default rather than undefined behavior.
  assign compare_level = (on_count <= off_count) ? normal_range_active
                                                  : wrap_range_active;

  // Override precedence: full_off > full_on > compare_level
  always_comb begin
    if (full_off) begin
      raw_level = 1'b0;
    end else if (full_on) begin
      raw_level = 1'b1;
    end else begin
      raw_level = compare_level;
    end
  end

endmodule

`default_nettype wire
