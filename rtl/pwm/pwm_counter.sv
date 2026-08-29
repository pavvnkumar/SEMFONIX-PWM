// =============================================================================
// pwm_counter.sv
//
// Shared 12-bit free-running PWM frame counter and prescale tick generator.
//
// Architecture:
//   - ONE shared instance for all 16 PWM channels.
//   - count_o runs from 0 through 4095.
//   - prescale_i is the active PRE_SCALE register value.
//   - PWM frame counter advances once every (prescale_i + 1) clk_ref cycles.
//   - sleep_i freezes the PWM state.
//   - frame_tick_o is a registered one-cycle pulse when count_o wraps
//     from 4095 to 0.
//
// Frequency relationship:
//
//   f_pwm = f_clk_ref / (4096 * (prescale + 1))
//
// =============================================================================

`default_nettype none

module pwm_counter #(
  parameter int PWM_WIDTH      = 12,
  parameter int PRESCALE_WIDTH = 8
) (
  input  logic                      clk_ref,
  input  logic                      rst_n,

  input  logic [PRESCALE_WIDTH-1:0] prescale_i,
  input  logic                      sleep_i,

  output logic [PWM_WIDTH-1:0]      count_o,
  output logic                      frame_tick_o
);

  // ---------------------------------------------------------------------------
  // Prescale divider
  //
  // Counts:
  //
  //   prescale = 0 : 0 -> tick -> 0
  //   prescale = 3 : 0 -> 1 -> 2 -> 3 -> tick -> 0
  //
  // Therefore a PWM tick occurs every (prescale + 1) clk_ref cycles.
  // ---------------------------------------------------------------------------

  logic [PRESCALE_WIDTH-1:0] tick_div_cnt;
  logic                      prescale_match;
  logic                      pwm_tick_en;

  assign prescale_match = (tick_div_cnt == prescale_i);
  assign pwm_tick_en    = prescale_match && !sleep_i;

  // ---------------------------------------------------------------------------
  // Prescale divider state
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      tick_div_cnt <= '0;
    end
    else if (sleep_i) begin
      // Oscillator/PWM stopped.
      //
      // Reset divider to zero so the first tick after wake is deterministic.
      tick_div_cnt <= '0;
    end
    else if (prescale_match) begin
      tick_div_cnt <= '0;
    end
    else begin
      tick_div_cnt <= tick_div_cnt + 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // Shared PWM frame counter + frame tick
  //
  // frame_tick_o is REGISTERED.
  //
  // On the clock where:
  //
  //     count_o == 4095
  //     pwm_tick_en == 1
  //
  // the counter wraps to zero and frame_tick_o becomes 1 for that cycle.
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
      count_o      <= '0;
      frame_tick_o <= 1'b0;
    end
    else begin
      // Default: frame tick is a one-cycle pulse.
      frame_tick_o <= 1'b0;

      if (pwm_tick_en) begin
        if (count_o == {PWM_WIDTH{1'b1}}) begin
          count_o      <= '0;
          frame_tick_o <= 1'b1;
        end
        else begin
          count_o <= count_o + 1'b1;
        end
      end
      // If sleep_i is asserted, count_o holds.
    end
  end

endmodule

`default_nettype wire