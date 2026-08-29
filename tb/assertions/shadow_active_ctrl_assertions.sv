// =============================================================================
// shadow_active_ctrl_assertions.sv
//
// SVA invariants for rtl/control/shadow_active_ctrl.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale.
//
// Checks the module's own documented composition (Section 13 / this
// module's own header):
//   (a) commit_pulse_o is exactly the combinational OR of the four
//       commit sources: OCH-selected (ack4_event_i when och_i=1,
//       stop_event_i && dirty_i when och_i=0) OR'd with the two
//       always-active SEMFONIX extension sources (group_update_req_i,
//       the internally-generated sync_update_pulse). No FSM, no extra
//       state -- a pure gate-level equality (Section 18 point 2).
//   (b) sync_update_pulse (the synchronized+edge-detected form of the
//       external sync_update_i pin) is always exactly one clk_ref cycle
//       wide, per the 2-FF-sync + edge-detect chain this module owns.
//
// Bound via `bind` into every instance of shadow_active_ctrl.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module shadow_active_ctrl_assertions (
  input logic clk_ref,
  input logic rst_n,

  input logic dirty_i,
  input logic group_update_req_i,
  input logic ack4_event_i,
  input logic stop_event_i,
  input logic och_i,

  input logic commit_pulse_o,

  input logic sync_sync_q,        // internal: resolved sync_update_i sample
  input logic sync_prev_q,        // internal: previous-cycle sample
  input logic sync_update_pulse   // internal: edge-detected 1-cycle pulse
);

  // (a) commit_pulse_o is a pure combinational OR of the four sources,
  // per this module's own documented composition -- checked
  // combinationally (always @*) since the RTL itself is purely
  // combinational here (no FSM, no registered commit_pulse_o).
  always @* begin
    automatic logic och_commit_expected;
    och_commit_expected = och_i ? ack4_event_i : (stop_event_i & dirty_i);
    assert (commit_pulse_o === (och_commit_expected | group_update_req_i | sync_update_pulse))
      else $error("shadow_active_ctrl_assertions: commit_pulse_o did not equal the documented OR of its four commit sources");
  end

  // (b) sync_update_pulse is exactly one clk_ref cycle wide: once it
  // fires, sync_prev_q catches up to sync_sync_q the very next cycle, so
  // the pulse cannot still be asserted a second consecutive cycle unless
  // a brand-new rising edge on the synchronized signal re-triggers it
  // (which would itself require sync_prev_q to have gone low again
  // first -- structurally impossible on back-to-back cycles here).
  property p_sync_pulse_one_cycle;
    @(posedge clk_ref) disable iff (!rst_n)
      sync_update_pulse |=> !sync_update_pulse;
  endproperty
  assert property (p_sync_pulse_one_cycle)
    else $error("shadow_active_ctrl_assertions: sync_update_pulse held for more than one clk_ref cycle");

  // sync_update_pulse's own defining equation, restated as a direct
  // check on the two flops that compose it.
  always @* begin
    assert (sync_update_pulse === (sync_sync_q & ~sync_prev_q))
      else $error("shadow_active_ctrl_assertions: sync_update_pulse did not equal sync_sync_q & ~sync_prev_q");
  end

endmodule

bind shadow_active_ctrl shadow_active_ctrl_assertions u_shadow_active_ctrl_assertions (.*);

`endif // SIMULATION
