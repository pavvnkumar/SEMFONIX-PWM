// =============================================================================
// i2c_bus_sync.sv
//
// 2-FF metastability synchronizer for the async SCL/SDA bus inputs, per
// docs/MASTER_ARCHITECTURE.md Section 6 ("Async SCL/SDA inputs are
// double-flopped ... before any use, since they originate off-chip and
// are asynchronous to clk_ref ... a standard 2-FF synchronizer, not a
// real clock-domain crossing (single clock still)") and Section 4's
// module hierarchy entry ("i2c_bus_sync.sv (2-FF metastability sync for
// SDA/SCL)").
//
// This is the first module of Checkpoint 4 (step 10 of the Section 22
// implementation order) -- the lowest-level, dependency-free leaf of the
// i2c/ subtree. i2c_rx (not yet built) consumes this module's two
// synchronized outputs and does its own edge/spike-filter detection on
// top of them (Section 7.2: "SCL edges are detected by comparing
// synchronized-SCL against its previous-cycle value ... a small counter
// debounces spikes"); that edge-detect/debounce logic is explicitly
// i2c_rx's job, not this module's -- this module's entire job is
// metastability safety on the two raw async pins, nothing more, matching
// the same one-job-per-module pattern used throughout rtl/control/ and
// rtl/registers/ (e.g. prescale_gate.sv, address_decode.sv).
//
// Two independent 2-FF chains (one for scl_i, one for sda_i) rather than
// a single shared chain, since SCL and SDA are electrically independent
// signals on the bus and there is no correctness requirement (or even a
// meaningful one) that they be synchronized "together" -- each pin's
// synchronizer only needs to resolve that pin's own metastability.
// Sharing a single 2-FF-wide bus for both would save zero area (still
// 4 flops total either way) and would not be a "shared" resource in any
// meaningful sense, so two clearly-named independent chains are used
// instead for readability at the call site.
//
// No reset value guarantee is required for correctness on the
// synchronizer flops themselves (a synchronizer's job is to resolve
// whatever the pin is doing *now*, not to hold a particular value out of
// reset), but `rst_n` is still wired in and applied uniformly, matching
// every other sequential module in this design (Section 6: "All
// sequential logic in the design uses this synchronized reset") and
// giving the synchronized outputs a deterministic, known state
// immediately out of reset for simulation/lint cleanliness (both idle-
// high, matching the bus's actual idle state -- SCL and SDA are both
// pulled high when idle).
// =============================================================================

`default_nettype none

module i2c_bus_sync (
  input  logic clk_ref,
  input  logic rst_n,

  // --- raw, asynchronous, off-chip bus pins (Section 5.1 top-level ports) ---
  input  logic scl_i,
  input  logic sda_i,

  // --- synchronized, metastability-safe versions for i2c_rx/i2c_tx ---
  output logic scl_sync_o,
  output logic sda_sync_o
);

  // SCL synchronizer: 2 flops, first stage may go metastable, second
  // stage is the resolved, safe-to-use value.
  logic scl_meta_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      scl_meta_q <= 1'b1; // idle bus state
      scl_sync_o <= 1'b1;
    end else begin
      scl_meta_q <= scl_i;
      scl_sync_o <= scl_meta_q;
    end
  end

  // SDA synchronizer: independent 2-flop chain, same structure.
  logic sda_meta_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      sda_meta_q <= 1'b1; // idle bus state
      sda_sync_o <= 1'b1;
    end else begin
      sda_meta_q <= sda_i;
      sda_sync_o <= sda_meta_q;
    end
  end

endmodule

`default_nettype wire
