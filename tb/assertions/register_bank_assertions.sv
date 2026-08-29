// =============================================================================
// register_bank_assertions.sv
//
// SVA invariants for rtl/registers/register_bank.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23, and
// docs/architecture/REGISTER_MAP.md for the address constants used below
// (repeated here as literals, not bound to the RTL's own localparams --
// SystemVerilog `bind`'s implicit `.*` port connection only matches
// nets/variables in the target module's scope, not localparams, so the
// handful of addresses these properties need are duplicated as literals,
// matching REGISTER_MAP.md exactly).
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale.
//
// Covers the invariants that make register_bank.sv's storage semantics
// (Sections 8/12/13/16) the single source of truth downstream modules
// rely on:
//   (a) atomic commit: on commit_pulse, ALL 16 channels' active_* storage
//       takes on exactly the shadow_* values as they stood the cycle the
//       commit fired (Section 13's glitch-freedom guarantee).
//   (b) dirty tracking: any_shadow_write sets dirty_o the following
//       cycle; a commit with no concurrent write clears it (Section 13
//       source #1 gating).
//   (c) PRE_SCALE write guard: a write while presc_write_allow_i=0 is a
//       silent no-op -- prescale_r must not change (Section 12).
//   (d) GROUP_UPDATE is a true edge-triggered command, never stored: the
//       request pulse only ever fires exactly when qualified by a real
//       bit0=1 write to that address (Section 13 source #3), and reads
//       of that address always return 0.
//   (e) DEVICE_ID / REVISION_ID read back their fixed constants
//       (Section 17).
//   (f) A representative sample of reserved addresses (Section 16) reads
//       as 0x00 -- not every reserved address, since register_bank_tb.sv
//       already sweeps the full reserved space; these are a documented
//       spot-check per range (core-reserved 0x46-0x4F, SEMFONIX-reserved
//       0x57-0x5F, and the top-of-map test-mode reserved byte 0xFF).
//
// Bound via `bind` into every instance of register_bank.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module register_bank_assertions #(
  parameter int NUM_CHANNELS = 16
) (
  input logic                  clk_ref,
  input logic                  rst_n,

  input logic                  rb_wr_en,
  input logic [7:0]            rb_addr,
  input logic [7:0]            rb_rdata,

  input logic                  commit_pulse,
  input logic                  presc_write_allow_i,

  input logic                  dirty_o,
  input logic                  group_update_req_o,
  input logic                  any_shadow_write,     // internal: this-cycle shadow-write flag

  input logic [7:0]            rb_wdata,
  input logic [7:0]            prescale_r,           // internal single-buffered storage

  input logic [11:0]           shadow_on_count  [NUM_CHANNELS], // internal
  input logic [11:0]           shadow_off_count [NUM_CHANNELS], // internal
  input logic                  shadow_full_on   [NUM_CHANNELS], // internal
  input logic                  shadow_full_off  [NUM_CHANNELS], // internal
  input logic [11:0]           active_on_count  [NUM_CHANNELS], // internal
  input logic [11:0]           active_off_count [NUM_CHANNELS], // internal
  input logic                  active_full_on   [NUM_CHANNELS], // internal
  input logic                  active_full_off  [NUM_CHANNELS]  // internal
);

  localparam logic [7:0] ADDR_PRE_SCALE    = 8'hFE;
  localparam logic [7:0] ADDR_GROUP_UPDATE = 8'h54;
  localparam logic [7:0] ADDR_DEVICE_ID    = 8'h55;
  localparam logic [7:0] ADDR_REVISION_ID  = 8'h56;
  localparam logic [7:0] DEVICE_ID_CONST   = 8'h53;
  localparam logic [7:0] REVISION_ID_CONST = 8'h01;

  // (a) Atomic commit: shadow -> active copy for every channel, exactly
  // as the shadow storage stood the cycle commit_pulse asserted.
  property p_commit_copies_on_count;
    @(posedge clk_ref) disable iff (!rst_n)
      commit_pulse |=> (active_on_count == $past(shadow_on_count));
  endproperty
  assert property (p_commit_copies_on_count)
    else $error("register_bank_assertions: active_on_count did not atomically copy shadow_on_count on commit_pulse");

  property p_commit_copies_off_count;
    @(posedge clk_ref) disable iff (!rst_n)
      commit_pulse |=> (active_off_count == $past(shadow_off_count));
  endproperty
  assert property (p_commit_copies_off_count)
    else $error("register_bank_assertions: active_off_count did not atomically copy shadow_off_count on commit_pulse");

  property p_commit_copies_full_on;
    @(posedge clk_ref) disable iff (!rst_n)
      commit_pulse |=> (active_full_on == $past(shadow_full_on));
  endproperty
  assert property (p_commit_copies_full_on)
    else $error("register_bank_assertions: active_full_on did not atomically copy shadow_full_on on commit_pulse");

  property p_commit_copies_full_off;
    @(posedge clk_ref) disable iff (!rst_n)
      commit_pulse |=> (active_full_off == $past(shadow_full_off));
  endproperty
  assert property (p_commit_copies_full_off)
    else $error("register_bank_assertions: active_full_off did not atomically copy shadow_full_off on commit_pulse");

  // (b) Dirty tracking.
  property p_dirty_set_on_write;
    @(posedge clk_ref) disable iff (!rst_n)
      any_shadow_write |=> dirty_o;
  endproperty
  assert property (p_dirty_set_on_write)
    else $error("register_bank_assertions: dirty_o not set the cycle after a shadow write");

  property p_dirty_cleared_on_clean_commit;
    @(posedge clk_ref) disable iff (!rst_n)
      (commit_pulse && !any_shadow_write) |=> !dirty_o;
  endproperty
  assert property (p_dirty_cleared_on_clean_commit)
    else $error("register_bank_assertions: dirty_o not cleared after a commit with no concurrent write");

  // (c) PRE_SCALE write guard: a disallowed write is a true no-op.
  property p_prescale_write_guarded;
    @(posedge clk_ref) disable iff (!rst_n)
      (rb_wr_en && (rb_addr == ADDR_PRE_SCALE) && !presc_write_allow_i) |=> $stable(prescale_r);
  endproperty
  assert property (p_prescale_write_guarded)
    else $error("register_bank_assertions: prescale_r changed despite presc_write_allow_i being low");

  // (d) GROUP_UPDATE: request pulse only ever fires when directly
  // qualified by the write that caused it (combinational, same cycle),
  // and the address always reads back 0.
  always @* begin
    if (group_update_req_o) begin
      assert (rb_wr_en && (rb_addr == ADDR_GROUP_UPDATE) && rb_wdata[0])
        else $error("register_bank_assertions: group_update_req_o asserted without a qualifying GROUP_UPDATE bit0=1 write");
    end
    if (rb_addr == ADDR_GROUP_UPDATE) begin
      assert (rb_rdata === 8'h00)
        else $error("register_bank_assertions: GROUP_UPDATE address did not read back 0x00");
    end
  end

  // (e) Read-only ID constants.
  always @* begin
    if (rb_addr == ADDR_DEVICE_ID) begin
      assert (rb_rdata === DEVICE_ID_CONST)
        else $error("register_bank_assertions: DEVICE_ID did not read back its fixed constant");
    end
    if (rb_addr == ADDR_REVISION_ID) begin
      assert (rb_rdata === REVISION_ID_CONST)
        else $error("register_bank_assertions: REVISION_ID did not read back its fixed constant");
    end
  end

  // (f) Reserved-address spot-check (full sweep already covered by
  // register_bank_tb.sv) -- reads as 0x00 regardless of write history.
  always @* begin
    if (rb_addr inside {[8'h46:8'h4F]}) begin
      assert (rb_rdata === 8'h00)
        else $error("register_bank_assertions: core-reserved address (0x46-0x4F) did not read 0x00");
    end
    if (rb_addr inside {[8'h57:8'h5F]}) begin
      assert (rb_rdata === 8'h00)
        else $error("register_bank_assertions: SEMFONIX-reserved address (0x57-0x5F) did not read 0x00");
    end
    if (rb_addr == 8'hFF) begin
      assert (rb_rdata === 8'h00)
        else $error("register_bank_assertions: reserved test-mode address 0xFF did not read 0x00");
    end
  end

endmodule

bind register_bank register_bank_assertions #(.NUM_CHANNELS(NUM_CHANNELS))
  u_register_bank_assertions (.*);

`endif // SIMULATION
