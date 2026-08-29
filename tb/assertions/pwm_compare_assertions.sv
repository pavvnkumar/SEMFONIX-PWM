// =============================================================================
// pwm_compare_assertions.sv
//
// SVA invariant for rtl/pwm/pwm_compare.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file (rather than one shared pwm_assertions.sv
// covering pwm_compare/pwm_counter/pwm_channel together) so that each
// unit test's `iverilog` invocation only needs to compile the `bind` for
// the RTL module(s) it actually includes -- e.g.
// tb/unit/pwm/pwm_compare_tb.sv compiles only rtl/pwm/pwm_compare.sv, and
// a `bind` referencing an undeclared module type (pwm_counter/
// pwm_channel) would be a compile error in that context.
//
// Purely combinational: full_off takes precedence over full_on (Section
// 10 / this module's own header, "full_off takes precedence over
// full_on when both are asserted"). Does not re-derive the general
// normal-window/wraparound compare formula, already covered by
// tb/unit/pwm/pwm_compare_tb.sv's 20,000-iteration randomized sweep.
//
// Bound via `bind` into every instance of pwm_compare.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module pwm_compare_assertions (
  input logic full_on,
  input logic full_off,
  input logic raw_level
);

  always @* begin
    if (full_off) begin
      assert (raw_level === 1'b0)
        else $error("pwm_compare_assertions: full_off asserted but raw_level not forced low");
    end else if (full_on) begin
      assert (raw_level === 1'b1)
        else $error("pwm_compare_assertions: full_on asserted (full_off clear) but raw_level not forced high");
    end
  end

endmodule

bind pwm_compare pwm_compare_assertions u_pwm_compare_assertions (.*);

`endif // SIMULATION
