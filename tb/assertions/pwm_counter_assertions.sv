// =============================================================================
// pwm_counter_assertions.sv
//
// SVA invariants for rtl/pwm/pwm_counter.sv, per
// docs/MASTER_ARCHITECTURE.md Section 22 step 14 / Section 23.
//
// Split into its own file -- see pwm_compare_assertions.sv's header for
// the per-module-file rationale (each unit test compiles only the RTL
// module types it instantiates, so each `bind` needs its own file).
//
// frame_tick_o only pulses when count_o is at its max value and the
// module is awake (Section 12); count_o itself freezes entirely while
// asleep, per this module's own header ("no PWM ticks are generated at
// all ... both the internal tick counter and the frame counter freeze").
//
// Bound via `bind` into every instance of pwm_counter.
// Guarded by `ifdef SIMULATION`.
// =============================================================================

`ifdef SIMULATION

`default_nettype none

module pwm_counter_assertions #(
  parameter int PWM_WIDTH = 12
) (
  input logic                  clk_ref,
  input logic                  rst_n,
  input logic                  sleep_i,
  input logic [PWM_WIDTH-1:0]  count_o,
  input logic                  frame_tick_o
);

  property p_sleep_freezes_count;
    @(posedge clk_ref) disable iff (!rst_n)
      sleep_i |=> $stable(count_o);
  endproperty
  assert property (p_sleep_freezes_count)
    else $error("pwm_counter_assertions: count_o changed on a cycle following sleep_i asserted");

  property p_frame_tick_requires_max;
    @(posedge clk_ref) disable iff (!rst_n)
      frame_tick_o |-> (count_o == {PWM_WIDTH{1'b1}});
  endproperty
  assert property (p_frame_tick_requires_max)
    else $error("pwm_counter_assertions: frame_tick_o pulsed but count_o was not at its max value");

  property p_frame_tick_requires_awake;
    @(posedge clk_ref) disable iff (!rst_n)
      frame_tick_o |-> !sleep_i;
  endproperty
  assert property (p_frame_tick_requires_awake)
    else $error("pwm_counter_assertions: frame_tick_o pulsed while sleep_i was asserted");

  property p_frame_tick_causes_wrap;
    @(posedge clk_ref) disable iff (!rst_n)
      frame_tick_o |=> (count_o == '0);
  endproperty
  assert property (p_frame_tick_causes_wrap)
    else $error("pwm_counter_assertions: frame_tick_o pulsed but count_o did not wrap to 0 next cycle");

endmodule

bind pwm_counter pwm_counter_assertions #(.PWM_WIDTH(PWM_WIDTH))
  u_pwm_counter_assertions (.*);

`endif // SIMULATION
