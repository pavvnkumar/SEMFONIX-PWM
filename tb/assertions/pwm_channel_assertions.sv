// =============================================================================
// pwm_channel_assertions.sv
//
// SVA invariants for rtl/pwm/pwm_channel.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale.
//
// Purely combinational. Checks the two documented forced-output regimes
// at the port boundary, both read directly from this module's own file
// header:
//   (a) normal mode (oe_n_i=0): full_off or enable=0 forces the raw
//       compare level to 0 before polarity/invert composition
//       (`gated_level = raw_level & enable`), so led_level_o must equal
//       (invrt ^ polarity) exactly.
//   (b) OE=1 (oe_n_i=1): Table 11's OUTNE forced-state mux.
// Does not re-derive the general normal-mode duty-cycle level itself
// (enable=1, full_on=0, full_off=0) -- already covered by
// tb/unit/pwm/pwm_channel_tb.sv's directed cases and 5,000-iteration
// randomized sweep.
//
// Bound via `bind` into every instance of pwm_channel (including the 16
// instances inside pwm_engine.sv's generate loop -- bind is by module
// type, not instance path).
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module pwm_channel_assertions (
  input logic full_on,
  input logic full_off,
  input logic enable,
  input logic polarity,
  input logic invrt,
  input logic oe_n_i,
  input logic [1:0] outne,
  input logic outdrv,
  input logic led_level_o,
  input logic led_drive_o
);

  always @* begin
    // (a) normal-mode forced-low compose (full_off or enable=0).
    if (!oe_n_i && (full_off || !enable)) begin
      assert (led_level_o === (invrt ^ polarity))
        else $error("pwm_channel_assertions: normal-mode forced-low path did not compose invrt^polarity correctly");
    end

    // (b) Table 11, OE=1 forced-state mux.
    if (oe_n_i) begin
      case (outne)
        2'b00: begin
          assert (led_drive_o === 1'b1 && led_level_o === 1'b0)
            else $error("pwm_channel_assertions: OE=1 OUTNE=00 did not drive LEDn low");
        end
        2'b01: begin
          if (outdrv) begin
            assert (led_drive_o === 1'b1 && led_level_o === 1'b1)
              else $error("pwm_channel_assertions: OE=1 OUTNE=01 OUTDRV=1 did not drive LEDn high");
          end
        end
        default: begin // 2'b10, 2'b11 -> high-impedance regardless of OUTDRV
          assert (led_drive_o === 1'b0)
            else $error("pwm_channel_assertions: OE=1 OUTNE=1X did not release (high-Z) LEDn");
        end
      endcase
    end
  end

endmodule

bind pwm_channel pwm_channel_assertions u_pwm_channel_assertions (.*);

`endif // SIMULATION
