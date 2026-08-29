// =============================================================================
// semfonix_pwm16_top.sv
//
// Top-level integration for SEMFONIX PWM16, per
// docs/MASTER_ARCHITECTURE.md Section 4 (Module Hierarchy) and Section 5.1
// (top-level port list). This is step 12 of the Section 22 implementation
// order -- the first file of Checkpoint 5.
//
// Every child instantiated here already exists, is already unit-tested
// (structurally, per this repo's standing toolchain-availability note),
// and is unchanged by this module. Per the same "thin integration
// wrapper, no new behavior" pattern pwm_engine.sv (Checkpoint 3) and
// i2c_slave.sv (Checkpoint 4) already established one level down, this
// module owns exactly two pieces of actual logic -- the scl_o/scl_oe
// tie-off below -- and otherwise performs pure structural wiring per
// Section 4's hierarchy diagram:
//
//   semfonix_pwm16_top
//   ├── clk_reset_sync      -- rst_n (raw pin) -> rst_n_sync (fanned out
//   |                          to every other child's rst_n port, per
//   |                          Section 6)
//   ├── i2c_slave           -- scl_i/sda_i (raw pins) in; combined
//   |                          sda_o/sda_oe out directly to the top-level
//   |                          pins (Section 4: i2c_bus_sync/i2c_rx/
//   |                          i2c_tx are i2c_slave's own children, not
//   |                          wired here)
//   ├── address_decode      -- sibling of i2c_slave (Section 4), not a
//   |                          child -- consumes i2c_slave's addr7_o/rw_o
//   |                          and register_bank's live MODE1/address
//   |                          fields, produces addr_match_o/gc_match_o
//   |                          fed back into i2c_slave
//   ├── register_decode     -- sibling of i2c_slave, consumes its
//   |                          byte-stream event contract
//   |                          (ptr_set_o/wr_byte_o/rd_byte_o/...)
//   ├── register_bank       -- regbus request side from register_decode,
//   |                          commit_pulse from shadow_active_ctrl,
//   |                          presc_write_allow from prescale_gate
//   ├── shadow_active_ctrl  -- commit sources: register_bank.dirty_o +
//   |                          group_update_req_o, register_decode's
//   |                          ack4_event_o, i2c_slave's stop_event_o,
//   |                          register_bank's active_och_o, and the
//   |                          top-level sync_update_i pin
//   ├── prescale_gate       -- SLEEP-gated PRE_SCALE write guard
//   ├── pwm_counter         -- shared free-running timebase, clocked by
//   |                          register_bank's active_prescale_o/
//   |                          active_sleep_o
//   └── pwm_engine          -- 16x pwm_channel, driven by pwm_counter's
//                              count_o and register_bank's active_cfg_o
//                              array, producing the final led_o/led_oe_o
//
// --- Ports intentionally left unconnected at this level ---
// A few child outputs have no consumer anywhere in this design yet;
// per this repository's standing practice of not inventing new RTL
// behavior beyond what a checkpoint's own scope covers, they are left
// unconnected here (a bare SystemVerilog port-connection omission,
// not a dummy wire) rather than wired into speculative new logic:
//   - i2c_slave.swrst_o -- General-Call/SWRST detection (Section 7.6/16)
//     is already implemented inside i2c_rx.sv (a child of i2c_slave.sv)
//     and surfaced here, but no consumer exists: register_bank.sv has no
//     soft-reset input port. This exact gap was already called out by
//     ADR-0002 ("its consumer (i2c_rx soft-reset handling) doesn't exist
//     yet ... revisit then") and by i2c_slave.sv's own header ("consumer
//     TBD at top-level integration"). Wiring it up would mean adding a
//     new port + new reset-handling logic to the already-complete,
//     already-unit-tested register_bank.sv -- a register_bank.sv design
//     change, not top-level structural wiring, and squarely out of this
//     step's scope. Tracked as a known, documented gap in
//     docs/IMPLEMENTATION_STATUS.md rather than silently implemented
//     here.
//   - pwm_counter.frame_tick_o -- a 1-cycle wrap pulse with no documented
//     consumer anywhere in Section 4's hierarchy (shadow_active_ctrl's
//     commit sources are fully enumerated in Section 5.2/13 and this is
//     not one of them). Left unconnected.
//   - address_decode.allcall_match_o / .sub_match_o / .regular_match_o --
//     per-type diagnostic breakdowns; address_decode.addr_match_o already
//     aggregates them (per that module's own header) into the single
//     signal i2c_slave actually needs. Left unconnected.
//   - extclk_sel_i (top-level input) -- per Section 6 ("both clock
//     sources resolve to the same clk_ref pin at RTL level") and
//     Section 24, this pin has zero RTL effect in this phase; it is a
//     documented architectural placeholder only, not wired to any
//     internal logic here. MODE1.EXTCLK itself is a plain sticky
//     register bit inside register_bank.sv, set only via the normal
//     I²C register-write path, not from this pin.
//
// --- scl_o/scl_oe tie-off ---
// Per Section 5.1 ("scl_o -- reserved for clock stretching (unused v1,
// tie 1)"): no child in this design ever drives or stretches SCL
// (i2c_bus_sync.sv only ever synchronizes the incoming scl_i for
// sampling; neither i2c_rx.sv nor i2c_tx.sv has an scl_o/scl_oe port),
// so this module ties scl_oe low (never actively drive/stretch the
// clock line) and scl_o high (the idle/released level, matching
// sda_o's own tie-to-0-when-not-driving convention one level down in
// i2c_slave.sv, just inverted since SCL's un-driven state is the
// logic-1 tie value called out explicitly in Section 5.1).
// =============================================================================

`default_nettype none

module semfonix_pwm16_top
  import semfonix_regmap_pkg::*;
#(
  parameter int NUM_CHANNELS = 16,
  parameter int PWM_WIDTH    = 12
) (
  input  logic                    clk_ref,
  input  logic                    rst_n,

  // I2C bus (open-drain style: *_o is drive-low request, tri-state modeled as _oe)
  input  logic                    scl_i,
  input  logic                    sda_i,
  output logic                    sda_o,
  output logic                    sda_oe,
  output logic                    scl_o,
  output logic                    scl_oe,

  // hardware address pins
  input  logic [5:0]              hw_addr_i,

  // active-low output enable pin (PCA9685 OE)
  input  logic                    oe_n_i,

  // external clock input alternative (architectural placeholder --
  // deliberately unwired in this RTL-only phase, see file header)
  input  logic                    extclk_sel_i,

  // optional external synchronized-commit strobe (SEMFONIX extension)
  input  logic                    sync_update_i,

  // LED PWM outputs
  output logic [NUM_CHANNELS-1:0] led_o,
  output logic [NUM_CHANNELS-1:0] led_oe_o
);

  // ---------------------------------------------------------------------
  // Silence "unused port" lint for extclk_sel_i without giving it any
  // functional effect -- see file header. A bare unread input port is
  // valid SystemVerilog and expected to lint-warn under strict settings;
  // this explicit self-assignment-free acknowledgement is just a comment
  // anchor for reviewers, not logic. (Left as a comment only -- no
  // statement needed; SystemVerilog does not require every input to be
  // consumed.)
  // ---------------------------------------------------------------------

  // ---------------------------------------------------------------------
  // 0. Reset synchronizer -- the sole clock-domain-boundary module,
  //    instantiated once and fanned out to every other child below.
  // ---------------------------------------------------------------------
  logic rst_n_sync;

  clk_reset_sync u_clk_reset_sync (
    .clk_ref      (clk_ref),
    .rst_n        (rst_n),
    .rst_n_sync_o (rst_n_sync)
  );

  // ---------------------------------------------------------------------
  // 1. i2c_slave -- protocol FSM + read shift register + bus-sync,
  //    already fully self-contained (Checkpoint 4).
  // ---------------------------------------------------------------------
  logic [6:0] addr7;
  logic       rw;
  logic       addr_match, gc_match;

  logic          ptr_set;
  logic [7:0]    ptr_set_data;
  logic          wr_byte;
  logic [7:0]    wr_byte_data;
  logic          rd_byte;
  logic [7:0]    tx_data;

  logic stop_event;

  i2c_slave u_i2c_slave (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n_sync),
    .scl_i          (scl_i),
    .sda_i          (sda_i),
    .sda_o          (sda_o),
    .sda_oe         (sda_oe),
    .addr7_o        (addr7),
    .rw_o           (rw),
    .addr_match_i   (addr_match),
    .gc_match_i     (gc_match),
    .ptr_set_o      (ptr_set),
    .ptr_set_data_o (ptr_set_data),
    .wr_byte_o      (wr_byte),
    .wr_byte_data_o (wr_byte_data),
    .rd_byte_o      (rd_byte),
    .tx_data_i      (tx_data),
    .stop_event_o   (stop_event)
    // .swrst_o intentionally left unconnected -- see file header.
  );

  // scl_o/scl_oe tie-off -- see file header.
  assign scl_o  = 1'b1;
  assign scl_oe = 1'b0;

  // ---------------------------------------------------------------------
  // 2. address_decode -- sibling of i2c_slave, not a child (Section 4).
  // ---------------------------------------------------------------------
  address_decode u_address_decode (
    .addr7_i             (addr7),
    .rw_i                (rw),
    .hw_addr_i           (hw_addr_i),
    .active_allcall_i    (active_allcall),
    .active_subx_en_i    (active_subx_en),
    .active_allcalladr_i (active_allcalladr),
    .active_subadr_i     (active_subadr),
    .gc_match_o          (gc_match),
    .addr_match_o        (addr_match)
    // .allcall_match_o / .sub_match_o / .regular_match_o intentionally
    // left unconnected -- see file header (addr_match_o already
    // aggregates them).
  );

  // ---------------------------------------------------------------------
  // 3. register_decode -- sibling of i2c_slave, consumes its
  //    byte-stream event contract.
  // ---------------------------------------------------------------------
  logic [7:0] rb_addr;
  logic       rb_wr_en;
  logic       rb_rd_en;
  logic [7:0] rb_wdata;
  logic [7:0] rb_rdata;
  logic       ack4_event;

  register_decode u_register_decode (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n_sync),
    .ptr_set_i      (ptr_set),
    .ptr_set_data_i (ptr_set_data),
    .wr_byte_i      (wr_byte),
    .wr_byte_data_i (wr_byte_data),
    .rd_byte_i      (rd_byte),
    .ai_en_i        (active_ai),
    .rb_addr_o      (rb_addr),
    .rb_wr_en_o     (rb_wr_en),
    .rb_rd_en_o     (rb_rd_en),
    .rb_wdata_o     (rb_wdata),
    .rb_rdata_i     (rb_rdata),
    .rd_data_o      (tx_data),
    .ack4_event_o   (ack4_event)
    // .ptr_o (debug/verification-only output) intentionally left
    // unconnected -- no functional consumer at this level.
  );

  // ---------------------------------------------------------------------
  // 4. register_bank -- shadow/active storage, single instantiation of
  //    the package-defining module (semfonix_regmap_pkg lives inside
  //    register_bank.sv itself, per that file).
  // ---------------------------------------------------------------------
  logic dirty;
  logic group_update_req;

  pwm_chan_cfg_t active_cfg [NUM_CHANNELS];
  logic [7:0]    active_prescale;
  logic          active_sleep;
  logic          active_ai;
  logic          active_allcall;
  logic [2:0]    active_subx_en;
  logic [1:0]    active_outne;
  logic          active_outdrv;
  logic          active_invrt;
  logic          active_och;
  logic [6:0]    active_allcalladr;
  logic [6:0]    active_subadr [3];

  logic commit_pulse;
  logic presc_write_allow;

  register_bank #(
    .NUM_CHANNELS (NUM_CHANNELS)
  ) u_register_bank (
    .clk_ref              (clk_ref),
    .rst_n                (rst_n_sync),
    .rb_wr_en             (rb_wr_en),
    .rb_rd_en             (rb_rd_en),
    .rb_addr              (rb_addr),
    .rb_wdata             (rb_wdata),
    .rb_rdata             (rb_rdata),
    .commit_pulse         (commit_pulse),
    .presc_write_allow_i  (presc_write_allow),
    .dirty_o              (dirty),
    .group_update_req_o   (group_update_req),
    .active_cfg_o         (active_cfg),
    .active_prescale_o    (active_prescale),
    .active_sleep_o       (active_sleep),
    .active_ai_o          (active_ai),
    .active_allcall_o     (active_allcall),
    .active_subx_en_o     (active_subx_en),
    .active_outne_o       (active_outne),
    .active_outdrv_o      (active_outdrv),
    .active_invrt_o       (active_invrt),
    .active_och_o         (active_och),
    .active_allcalladr_o  (active_allcalladr),
    .active_subadr_o      (active_subadr)
  );

  // ---------------------------------------------------------------------
  // 5. shadow_active_ctrl -- atomic commit FSM (Section 13 sources).
  // ---------------------------------------------------------------------
  shadow_active_ctrl u_shadow_active_ctrl (
    .clk_ref            (clk_ref),
    .rst_n              (rst_n_sync),
    .dirty_i            (dirty),
    .group_update_req_i (group_update_req),
    .ack4_event_i       (ack4_event),
    .stop_event_i       (stop_event),
    .och_i              (active_och),
    .sync_update_i      (sync_update_i),
    .commit_pulse_o     (commit_pulse)
  );

  // ---------------------------------------------------------------------
  // 6. prescale_gate -- SLEEP-gated PRE_SCALE write guard.
  // ---------------------------------------------------------------------
  prescale_gate u_prescale_gate (
    .sleep_i             (active_sleep),
    .presc_write_allow_o (presc_write_allow)
  );

  // ---------------------------------------------------------------------
  // 7. pwm_counter -- shared free-running timebase.
  // ---------------------------------------------------------------------
  logic [PWM_WIDTH-1:0] pwm_count;

  pwm_counter #(
    .PWM_WIDTH (PWM_WIDTH)
  ) u_pwm_counter (
    .clk_ref     (clk_ref),
    .rst_n       (rst_n_sync),
    .prescale_i  (active_prescale),
    .sleep_i     (active_sleep),
    .count_o     (pwm_count)
    // .frame_tick_o intentionally left unconnected -- see file header.
  );

  // ---------------------------------------------------------------------
  // 8. pwm_engine -- 16x pwm_channel integration, final LED outputs.
  //    Flop-free structural leaf: no clk_ref/rst_n ports.
  // ---------------------------------------------------------------------
  pwm_engine #(
    .NUM_CHANNELS (NUM_CHANNELS),
    .PWM_WIDTH    (PWM_WIDTH)
  ) u_pwm_engine (
    .count_i          (pwm_count),
    .active_cfg_i     (active_cfg),
    .active_invrt_i   (active_invrt),
    .active_outdrv_i  (active_outdrv),
    .active_outne_i   (active_outne),
    .oe_n_i           (oe_n_i),
    .led_o            (led_o),
    .led_oe_o         (led_oe_o)
  );

endmodule

`default_nettype wire
