// =============================================================================
// clk_reset_sync.sv
//
// Reset synchronizer cell per docs/MASTER_ARCHITECTURE.md Section 6
// ("Reset (`rst_n`): active-low, asynchronously asserted, synchronously
// released (standard reset-synchronizer cell `clk_reset_sync.sv`
// instantiated once at the top and fanned out as `rst_n_sync`). All
// sequential logic in the design uses this synchronized reset.") and
// Section 4's module hierarchy entry ("rtl/clock/clk_reset_sync.sv
// (reset synchronizer, clock boundary doc)").
//
// This is step 11 of the Section 22 implementation order -- the sole
// file of the "clock" area, and (per Section 6, "No analog oscillator
// in RTL ... A clean boundary (`rtl/clock/clk_reset_sync.sv`) is the
// only clock-related RTL") deliberately does nothing beyond reset
// synchronization: no PLL/oscillator modeling, no clock muxing.
// `extclk_sel_i` (Section 5.1) is explicitly NOT consumed here -- per
// Section 6, both "clock sources" resolve to the same `clk_ref` pin at
// RTL level, and `extclk_sel_i` is wired directly into the register
// bank as a status-only sticky bit (MODE1.EXTCLK) with no RTL effect on
// `clk_ref` itself. Routing it through this module would misleadingly
// imply a real clock-select mux exists here.
//
// Standard async-assert / sync-release 2-flop reset synchronizer:
//   - Asynchronous assert: the async reset in the always_ff block fires
//     on `negedge rst_n`, so `rst_n_sync_o` (and the internal
//     metastability-buffer flop) drop to 0 immediately, combinationally
//     fast, the same clock edge is not required to observe the assert.
//   - Synchronous release: once `rst_n` returns high, the two flops
//     shift a '1' through on successive `clk_ref` edges before
//     `rst_n_sync_o` itself rises, guaranteeing `rst_n_sync_o`'s
//     rising edge is aligned to a `clk_ref` edge (removing any release-
//     time metastability risk on every downstream flop that consumes
//     `rst_n_sync_o`, exactly the single "CDC-like" concern Section 6
//     calls out for the raw `rst_n` pin, mirroring the same async-pin
//     concern `i2c_bus_sync.sv` handles for `scl_i`/`sda_i`).
// Reset value out of reset for the internal meta flop is 0 (matching
// the asserted-low convention), so a glitch-free, fully-defined 0 is
// what a downstream flop would ever see driving its own reset while
// `rst_n` is held low, and the same 0 propagates into `rst_n_sync_o`
// itself via the second flop the very next cycle after assert.
// =============================================================================

`default_nettype none

module clk_reset_sync (
  input  logic clk_ref,
  input  logic rst_n,          // raw, asynchronous, off-chip reset pin
                                // (Section 5.1 top-level port, un-suffixed
                                // to match clk_ref/rst_n's own top-level
                                // naming convention)

  output logic rst_n_sync_o    // synchronized: async assert, sync
                                // release -- this is the `rst_n_sync`
                                // net Section 6 describes as
                                // "instantiated once at the top and
                                // fanned out" to every other sequential
                                // module's `rst_n` port
);

  // Meta flop: first stage of the release shift chain. May itself go
  // metastable on rst_n's rising edge, same tolerance any 2-FF
  // synchronizer relies on -- its own output is never used directly by
  // anything outside this module, only fed into the second stage below.
  logic meta_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      meta_q       <= 1'b0;
      rst_n_sync_o <= 1'b0;
    end else begin
      meta_q       <= 1'b1;
      rst_n_sync_o <= meta_q;
    end
  end

endmodule

`default_nettype wire
