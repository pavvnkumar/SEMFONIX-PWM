// =============================================================================
// clk_reset_sync_assertions.sv
//
// SVA invariants for rtl/clock/clk_reset_sync.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale (each unit test compiles only the RTL
// module types it instantiates, so each `bind` needs its own file).
//
// Checks the two documented properties of the async-assert / sync-release
// reset synchronizer (Section 6 / this module's own header):
//   (a) async assert: whenever rst_n is low, both internal flops
//       (meta_q, rst_n_sync_o) must be low too -- reset dominates
//       combinationally, not waiting for a clk_ref edge.
//   (b) sync release: rst_n_sync_o is always exactly meta_q as it stood
//       one clk_ref cycle earlier (the second stage of the 2-flop
//       release-shift chain) -- i.e. there is no combinational bypass
//       from meta_q or rst_n straight to rst_n_sync_o.
//
// Bound via `bind` into every instance of clk_reset_sync.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module clk_reset_sync_assertions (
  input logic clk_ref,
  input logic rst_n,          // raw, asynchronous, off-chip reset pin
  input logic meta_q,         // internal: first stage of release-shift chain
  input logic rst_n_sync_o    // internal: second stage / module output
);

  // (a) Async assert dominates immediately -- checked combinationally
  // (always @*, not clocked) so it fires the instant rst_n drops, not
  // waiting for the next clk_ref edge.
  always @* begin
    if (!rst_n) begin
      assert (meta_q === 1'b0)
        else $error("clk_reset_sync_assertions: rst_n low but meta_q not forced low");
      assert (rst_n_sync_o === 1'b0)
        else $error("clk_reset_sync_assertions: rst_n low but rst_n_sync_o not forced low");
    end
  end

  // (b) Sync release: rst_n_sync_o always equals the previous cycle's
  // meta_q (the documented second-stage shift), never a combinational
  // shortcut from rst_n or meta_q's current value.
  property p_sync_release_chain;
    @(posedge clk_ref) disable iff (!rst_n)
      rst_n_sync_o == $past(meta_q);
  endproperty
  assert property (p_sync_release_chain)
    else $error("clk_reset_sync_assertions: rst_n_sync_o did not equal meta_q from the prior clk_ref cycle");

endmodule

bind clk_reset_sync clk_reset_sync_assertions u_clk_reset_sync_assertions (.*);

`endif // SIMULATION
