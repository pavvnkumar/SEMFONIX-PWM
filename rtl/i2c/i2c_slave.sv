// =============================================================================
// i2c_slave.sv
//
// I2C slave top-level wrapper, per docs/MASTER_ARCHITECTURE.md Section 4's
// module hierarchy entry:
//   rtl/i2c/i2c_slave.sv
//   ├── rtl/i2c/i2c_bus_sync.sv
//   ├── rtl/i2c/i2c_rx.sv
//   └── rtl/i2c/i2c_tx.sv
// This is the fourth and final sub-module of Checkpoint 4 (step 10 of the
// Section 22 implementation order), closing out Checkpoint 4. All three
// children (i2c_bus_sync.sv, i2c_rx.sv, i2c_tx.sv) already exist and are
// unchanged by this module -- i2c_slave.sv performs exactly the wiring
// i2c_rx.sv's and i2c_tx.sv's own headers already documented as "the
// not-yet-built i2c_slave.sv"'s job, and nothing more:
//
//   1. Instantiates i2c_bus_sync.sv on the raw async scl_i/sda_i pins
//      (Section 6), feeding its two synchronized outputs to both i2c_rx.sv
//      and i2c_tx.sv (i2c_tx.sv's header: "the same i2c_bus_sync.sv-
//      synchronized signal i2c_rx.sv consumes -- sibling top-level wiring,
//      not routed through i2c_rx.sv"; that "top-level" wiring now lives
//      here instead of directly at semfonix_pwm16_top, since this module IS
//      the sibling-wiring point per the Section 4 hierarchy).
//   2. Instantiates i2c_rx.sv and i2c_tx.sv, connecting i2c_rx.sv's
//      tx_load_o/tx_drive_en_o directly to i2c_tx.sv's tx_load_i/
//      tx_drive_en_i (the documented forward contract, now realized as
//      internal wiring instead of two separate top-level nets).
//   3. Combines i2c_rx.sv's sda_o/sda_oe (ACK bits) and i2c_tx.sv's
//      sda_o/sda_oe (read-data bits) onto the single external sda_o/sda_oe
//      pair with "a plain mux on tx_drive_en_o" -- the exact phrase both
//      children's headers use, and the exact mux tb/unit/i2c/i2c_tx_tb.sv's
//      integration group already performed manually (`combined_sda_oe`)
//      as a stand-in for this not-yet-built module. i2c_rx.sv's own header
//      establishes these two are "mutually exclusive by construction of
//      this FSM" (tx_drive_en_o is exactly i2c_rx.sv's ST_RD_DATA level),
//      so the mux never needs to arbitrate a genuine conflict -- it only
//      needs to pick the currently-active driver.
//
// --- What this module deliberately does NOT own ---
// address_decode.sv is explicitly documented (i2c_rx.sv's own header) as
// "NOT a child of this module -- Section 4's module hierarchy instantiates
// address_decode.sv as a sibling of i2c_slave.sv at the top level." This
// module therefore exposes addr7_o/rw_o (to feed the sibling
// address_decode) and addr_match_i/gc_match_i (address_decode's match
// results, fed back in) as plain ports, exactly mirroring i2c_rx.sv's own
// port names/semantics one level up -- it does not instantiate
// address_decode.sv itself. Likewise, register_decode.sv/register_bank.sv
// are also top-level siblings (Section 4), not children: this module
// exposes the same byte-stream event contract i2c_rx.sv already produces
// (ptr_set_o/ptr_set_data_o/wr_byte_o/wr_byte_data_o/rd_byte_o) and takes
// tx_data_i as a plain input, wired directly from register_decode.sv's
// rd_data_o at the top level -- exactly the "NOT through i2c_rx.sv"
// routing i2c_tx.sv's own header already specifies, now simply passed
// through this module unchanged rather than terminating at it.
// scl_o/scl_oe (Section 5.1, "reserved for clock stretching (unused v1,
// tie 1)") are a top-level tie-off, not a function this or any child
// module implements, so they are not ports here either.
//
// This module owns no state and no logic of its own beyond the three
// instantiations and the mux -- it is pure structural wiring, matching the
// same "thin integration wrapper, no new behavior" pattern
// rtl/pwm/pwm_engine.sv already established for the PWM side (Checkpoint
// 3): pwm_engine.sv wires together 16x pwm_channel with no flops of its
// own; i2c_slave.sv wires together the three I2C sub-modules with no flops
// of its own (all three children already own every flop that exists in
// this path).
//
// SPIKE_FILTER_CYCLES and I2C_TIMEOUT_CYCLES are passed straight through
// to the internal i2c_rx.sv instance (its own two parameters, Section 7.2
// / Section 16), so a top-level instantiation of i2c_slave.sv can still
// tune or disable the SCL-held-low timeout without reaching inside this
// wrapper.
// =============================================================================

`default_nettype none

module i2c_slave #(
  parameter int SPIKE_FILTER_CYCLES = 2,
  parameter int I2C_TIMEOUT_CYCLES  = 0    // 0 = disabled (Section 16)
) (
  input  logic clk_ref,
  input  logic rst_n,

  // --- raw, asynchronous, off-chip bus pins (Section 5.1 top-level ports,
  //     passed straight through to the internal i2c_bus_sync.sv) ---
  input  logic scl_i,
  input  logic sda_i,

  // --- combined open-drain SDA drive for the external bus (this module's
  //     one piece of actual logic: the i2c_rx/i2c_tx mux, see header) ---
  output logic sda_o,
  output logic sda_oe,       // 1 = actively pulling SDA low

  // --- to the sibling address_decode.sv (NOT a child -- see header) ---
  output logic [6:0] addr7_o,
  output logic       rw_o,
  input  logic        addr_match_i,  // address_decode.addr_match_o, combinational
  input  logic         gc_match_i,   // address_decode.gc_match_o, combinational

  // --- byte-stream event contract for the sibling register_decode.sv
  //     (see that module's header -- i2c_slave.sv is simply the point
  //     where i2c_rx.sv's own producer-side signals now surface) ---
  output logic          ptr_set_o,
  output logic [7:0]    ptr_set_data_o,
  output logic          wr_byte_o,
  output logic [7:0]    wr_byte_data_o,
  output logic          rd_byte_o,

  // --- byte to shift out on a read; wired directly from
  //     register_decode.sv's rd_data_o at the top level, NOT through any
  //     internal FSM (see header) ---
  input  logic [7:0]    tx_data_i,

  // --- to the sibling shadow_active_ctrl.sv (already documents this as
  //     stop_event_i) ---
  output logic          stop_event_o,

  // --- general-call software reset (Section 7.6/16); consumer TBD at
  //     top-level integration (Checkpoint 5) ---
  output logic          swrst_o
);

  // ---------------------------------------------------------------------
  // 1. i2c_bus_sync.sv -- 2-FF metastability sync on the raw async pins.
  // ---------------------------------------------------------------------
  logic scl_sync, sda_sync;

  i2c_bus_sync bus_sync (
    .clk_ref    (clk_ref),
    .rst_n      (rst_n),
    .scl_i      (scl_i),
    .sda_i      (sda_i),
    .scl_sync_o (scl_sync),
    .sda_sync_o (sda_sync)
  );

  // ---------------------------------------------------------------------
  // 2. i2c_rx.sv -- receive-path protocol FSM.
  // ---------------------------------------------------------------------
  logic rx_sda_o, rx_sda_oe;
  logic tx_load, tx_drive_en;

  i2c_rx #(
    .SPIKE_FILTER_CYCLES (SPIKE_FILTER_CYCLES),
    .I2C_TIMEOUT_CYCLES  (I2C_TIMEOUT_CYCLES)
  ) rx (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),
    .scl_sync_i     (scl_sync),
    .sda_sync_i     (sda_sync),
    .sda_o          (rx_sda_o),
    .sda_oe         (rx_sda_oe),
    .addr7_o        (addr7_o),
    .rw_o           (rw_o),
    .addr_match_i   (addr_match_i),
    .gc_match_i     (gc_match_i),
    .ptr_set_o      (ptr_set_o),
    .ptr_set_data_o (ptr_set_data_o),
    .wr_byte_o      (wr_byte_o),
    .wr_byte_data_o (wr_byte_data_o),
    .rd_byte_o      (rd_byte_o),
    .tx_load_o      (tx_load),
    .tx_drive_en_o  (tx_drive_en),
    .stop_event_o   (stop_event_o),
    .swrst_o        (swrst_o)
  );

  // ---------------------------------------------------------------------
  // 3. i2c_tx.sv -- transmit-path (read-data) shift register + drive.
  // ---------------------------------------------------------------------
  logic tx_sda_o, tx_sda_oe;

  i2c_tx tx (
    .clk_ref       (clk_ref),
    .rst_n         (rst_n),
    .scl_sync_i    (scl_sync),
    .tx_load_i     (tx_load),
    .tx_drive_en_i (tx_drive_en),
    .tx_data_i     (tx_data_i),
    .sda_o         (tx_sda_o),
    .sda_oe        (tx_sda_oe)
  );

  // ---------------------------------------------------------------------
  // Combine i2c_rx.sv's and i2c_tx.sv's contributions to the open-drain
  // SDA bus with a plain mux on tx_drive_en (Section 7.1's open-drain
  // semantics: both children only ever drive '0'/oe, never sda_o=1, so
  // sda_o is tied 0 here too -- only sda_oe selects which driver, if any,
  // is currently pulling the bus low). Mutually exclusive by construction
  // of i2c_rx.sv's FSM (see header), so no arbitration beyond the select
  // is needed.
  // ---------------------------------------------------------------------
  assign sda_o  = 1'b0;
  assign sda_oe = tx_drive_en ? tx_sda_oe : rx_sda_oe;

endmodule

`default_nettype wire
