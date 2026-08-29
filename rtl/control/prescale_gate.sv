// =============================================================================
// prescale_gate.sv
//
// PRE_SCALE write-guard, per docs/MASTER_ARCHITECTURE.md Section 12.
//
// Purely combinational, no clk/rst ports -- same pattern as
// address_decode.sv (Checkpoint 2 step 3): this module has no state of
// its own, so there is nothing to reset and nothing to clock.
//
// Per Section 12, this module's entire job is the write-guard policy:
// PRE_SCALE register writes in register_bank are only accepted while the
// internal oscillator is stopped (MODE1.SLEEP=1), matching the reference
// datasheet's Section 7.3.5 "can only be set when the SLEEP bit ... is
// set to logic 1." register_bank consumes this as `presc_write_allow_i`
// and, when it is low, silently drops the write (ACKed on the bus for
// protocol correctness, but the stored value doesn't change) -- see
// register_bank.sv's own header and Section 16's "defined, safe" no-op
// philosophy. This module does not implement that drop behavior itself;
// it only produces the qualifying signal.
//
// Explicitly NOT this module's job (see Section 12 and Section 9's
// sharing analysis):
//   - The prescale tick generator itself (the actual "divide clk_ref by
//     (prescale+1)*4096" counter) lives in pwm_counter.sv, instantiated
//     once, alongside the frame counter it feeds -- kept together rather
//     than split across an extra cross-module bus for a single enable
//     pulse (Section 12).
//   - SLEEP-gating of the oscillator/frame-counter ticking itself:
//     pwm_counter.sv consumes `active_sleep_o` directly as its own
//     `sleep_i` input and freezes its tick divider + frame counter when
//     asleep. That is a *different* consumer of the same MODE1.SLEEP bit
//     for a *different* purpose (stopping PWM ticks, not gating a
//     register write) and is correctly independent wiring at the top
//     level, not something this module should also touch or duplicate.
//
// This module is intentionally this small: Section 20's PPA analysis
// treats the register/control blocks as cheap relative to the 16-channel
// shadow/active storage, and a single-bit combinational passthrough with
// its own module boundary (rather than wiring register_bank.active_sleep_o
// straight into itself) keeps register_bank a pure storage element with
// no write-guard *policy* embedded in it (per register_bank.sv's own
// header comment) and gives this policy a single, obviously-testable,
// independently-documented home matching every other control block in
// rtl/control/.
// =============================================================================

`default_nettype none

module prescale_gate (
  // --- live MODE1.SLEEP, from register_bank (Section 5.3-adjacent
  //     live output, already implemented and exposed as active_sleep_o) ---
  input  logic sleep_i,

  // --- to register_bank's PRE_SCALE write-guard input (Section 5.2-
  //     adjacent) ---
  output logic presc_write_allow_o
);

  // Section 12: PRE_SCALE writes are accepted only while the oscillator
  // is stopped (SLEEP=1). No debounce/registration needed -- SLEEP is
  // already a live, glitch-free single-buffered register output
  // (register_bank.sv Section 8: single-buffered registers take effect
  // the same cycle as their own write, and this consumer only needs its
  // *current* value, not an edge or a delayed copy of it).
  assign presc_write_allow_o = sleep_i;

endmodule

`default_nettype wire
