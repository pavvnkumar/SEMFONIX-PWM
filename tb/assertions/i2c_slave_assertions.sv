// =============================================================================
// i2c_slave_assertions.sv
//
// SVA invariants for rtl/i2c/i2c_slave.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale. Bound at the i2c_slave.sv level (not
// separately on i2c_bus_sync/i2c_rx/i2c_tx) since this is the single
// integration point where this repository's I2C-specific invariants --
// open-drain drive discipline and the rx/tx mux -- actually live, per
// this module's own header ("This module owns no state and no logic of
// its own beyond the three instantiations and the mux").
//
// Checks this module's own documented behavior:
//   (a) Open-drain discipline: sda_o is permanently tied to 1'b0
//       (Section 7.1's open-drain semantics -- this design only ever
//       actively pulls SDA low via sda_oe, never drives it high).
//   (b) rx/tx mux consistency: sda_oe always equals the currently-
//       selected child's own sda_oe (tx_sda_oe while tx_drive_en,
//       rx_sda_oe otherwise) -- the exact "plain mux on tx_drive_en_o"
//       this module's header documents, restated as a direct check.
//   (c) swrst_o only ever pulses on the same cycle as stop_event_o
//       (i2c_rx.sv's own header/RTL: `swrst_o = stop_cond &&
//       swrst_armed_q`, i.e. general-call SWRST always fires on STOP,
//       never on the ACK or any other cycle).
//
// Bound via `bind` into every instance of i2c_slave.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module i2c_slave_assertions (
  input logic sda_o,
  input logic sda_oe,

  input logic tx_drive_en,   // internal: rx/tx mux select
  input logic rx_sda_oe,     // internal: i2c_rx's own sda_oe contribution
  input logic tx_sda_oe,     // internal: i2c_tx's own sda_oe contribution

  input logic stop_event_o,
  input logic swrst_o
);

  always @* begin
    // (a) Open-drain discipline.
    assert (sda_o === 1'b0)
      else $error("i2c_slave_assertions: sda_o was not tied 1'b0 (open-drain violation -- must never actively drive SDA high)");

    // (b) rx/tx mux consistency.
    assert (sda_oe === (tx_drive_en ? tx_sda_oe : rx_sda_oe))
      else $error("i2c_slave_assertions: sda_oe did not match the documented tx_drive_en-selected mux");

    // (c) SWRST only ever coincides with STOP.
    if (swrst_o) begin
      assert (stop_event_o)
        else $error("i2c_slave_assertions: swrst_o pulsed without a coincident stop_event_o");
    end
  end

endmodule

bind i2c_slave i2c_slave_assertions u_i2c_slave_assertions (.*);

`endif // SIMULATION
