// =============================================================================
// shadow_active_ctrl.sv
//
// Generates the single-cycle commit_pulse used by register_bank to transfer
// shadow PWM configuration into the active configuration.
//
// Commit sources:
//   1. STOP commit when OCH=0 and dirty=1
//   2. ACK4 commit when OCH=1
//   3. GROUP_UPDATE write
//   4. synchronized rising edge of external sync_update_i
//
// All event sources are sampled on clk_ref and produce a clean one-clock
// commit_pulse_o. This avoids combinational pulse disappearance between the
// source event and the register_bank sequential commit operation.
// =============================================================================

`default_nettype none

module shadow_active_ctrl (
  input  logic clk_ref,
  input  logic rst_n,

  input  logic dirty_i,
  input  logic group_update_req_i,
  input  logic ack4_event_i,
  input  logic stop_event_i,
  input  logic och_i,

  input  logic sync_update_i,

  output logic commit_pulse_o
);

  // ---------------------------------------------------------------------------
  // Synchronizer for external asynchronous sync_update_i
  // ---------------------------------------------------------------------------

  logic sync_meta_q;
  logic sync_sync_q;
  logic sync_prev_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      sync_meta_q <= 1'b0;
      sync_sync_q <= 1'b0;
      sync_prev_q <= 1'b0;
    end else begin
      sync_meta_q <= sync_update_i;
      sync_sync_q <= sync_meta_q;
      sync_prev_q <= sync_sync_q;
    end
  end

  wire sync_update_pulse =
      sync_sync_q & ~sync_prev_q;

  // ---------------------------------------------------------------------------
  // Commit-source qualification
  // ---------------------------------------------------------------------------

  wire stop_commit =
      (!och_i) && stop_event_i && dirty_i;

  wire ack_commit =
      och_i && ack4_event_i;

  wire group_commit =
      group_update_req_i;

  wire sync_commit =
      sync_update_pulse;

  wire commit_request =
      stop_commit |
      ack_commit |
      group_commit |
      sync_commit;

  // ---------------------------------------------------------------------------
  // Registered commit pulse
  //
  // A request is sampled at the active clock edge and commit_pulse_o is held
  // for exactly the following clk_ref cycle.
  //
  // This makes the pulse deterministic and gives register_bank a full cycle
  // in which the commit command is asserted.
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      commit_pulse_o <= 1'b0;
    end else begin
      commit_pulse_o <= commit_request;
    end
  end

endmodule

`default_nettype wire