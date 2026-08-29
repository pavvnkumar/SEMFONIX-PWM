// =============================================================================
// pwm_compare_tb.sv
//
// Self-checking unit testbench for rtl/pwm/pwm_compare.sv.
//
// Strategy: an independent reference function (`ref_raw_level`, written
// from the specification text, NOT by copying the RTL's expression) is
// used to compute expected output for a wide set of directed cases plus a
// randomized sweep, and compared against the DUT.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o pwm_compare_tb rtl/pwm/pwm_compare.sv tb/unit/pwm/pwm_compare_tb.sv
//   vvp pwm_compare_tb
// =============================================================================

`timescale 1ns/1ps

module pwm_compare_tb;

  localparam int PWM_WIDTH = 12;

  logic [PWM_WIDTH-1:0] count;
  logic [PWM_WIDTH-1:0] on_count;
  logic [PWM_WIDTH-1:0] off_count;
  logic                 full_on;
  logic                 full_off;
  logic                 raw_level;

  int errors = 0;
  int checks = 0;

  pwm_compare #(.PWM_WIDTH(PWM_WIDTH)) dut (
    .count     (count),
    .on_count  (on_count),
    .off_count (off_count),
    .full_on   (full_on),
    .full_off  (full_off),
    .raw_level (raw_level)
  );

  // Independent reference model (deliberately written from the spec, not
  // from the RTL source, to avoid "self-fulfilling" verification).
  function automatic bit ref_raw_level(
    input bit [PWM_WIDTH-1:0] c,
    input bit [PWM_WIDTH-1:0] on_v,
    input bit [PWM_WIDTH-1:0] off_v,
    input bit                 fon,
    input bit                 foff
  );
    bit in_range;
    begin
      if (foff) return 1'b0;
      if (fon)  return 1'b1;
      if (on_v <= off_v) begin
        in_range = (c >= on_v) && (c < off_v);
      end else begin
        in_range = (c >= on_v) || (c < off_v);
      end
      return in_range;
    end
  endfunction

  task automatic check_case(
    input bit [PWM_WIDTH-1:0] c,
    input bit [PWM_WIDTH-1:0] on_v,
    input bit [PWM_WIDTH-1:0] off_v,
    input bit                 fon,
    input bit                 foff,
    input string              tag
  );
    bit expected;
    begin
      count     = c;
      on_count  = on_v;
      off_count = off_v;
      full_on   = fon;
      full_off  = foff;
      #1; // allow combinational settle
      expected = ref_raw_level(c, on_v, off_v, fon, foff);
      checks++;
      if (raw_level !== expected) begin
        errors++;
        $display("FAIL [%s]: count=%0d on=%0d off=%0d full_on=%0b full_off=%0d -> got=%0b expected=%0b",
                  tag, c, on_v, off_v, fon, foff, raw_level, expected);
      end
    end
  endtask

  initial begin
    // --- Directed: reference datasheet Example 1 (LED0, 10% delay, 20% duty) ---
    // on=410 (0x19A per datasheet's -1 adjustment => 409 used below as
    // "delay count to 409"), off=1228. We test boundary + interior points.
    check_case(12'd0,    12'd409, 12'd1228, 0, 0, "ex1_before_on");
    check_case(12'd408,  12'd409, 12'd1228, 0, 0, "ex1_just_before_on");
    check_case(12'd409,  12'd409, 12'd1228, 0, 0, "ex1_at_on");
    check_case(12'd800,  12'd409, 12'd1228, 0, 0, "ex1_mid_on");
    check_case(12'd1227, 12'd409, 12'd1228, 0, 0, "ex1_just_before_off");
    check_case(12'd1228, 12'd409, 12'd1228, 0, 0, "ex1_at_off");
    check_case(12'd2000, 12'd409, 12'd1228, 0, 0, "ex1_after_off");
    check_case(12'd4095, 12'd409, 12'd1228, 0, 0, "ex1_end_of_frame");

    // --- Directed: reference datasheet Example 2 (LED4, 90% delay, 90% duty,
    //     wraps past end of frame) on=3685, off=3275 ---
    check_case(12'd0,    12'd3685, 12'd3275, 0, 0, "ex2_start_of_frame_in_wrap");
    check_case(12'd3274, 12'd3685, 12'd3275, 0, 0, "ex2_just_before_wrap_off");
    check_case(12'd3275, 12'd3685, 12'd3275, 0, 0, "ex2_at_wrap_off");
    check_case(12'd3500, 12'd3685, 12'd3275, 0, 0, "ex2_between_off_and_on");
    check_case(12'd3684, 12'd3685, 12'd3275, 0, 0, "ex2_just_before_on");
    check_case(12'd3685, 12'd3685, 12'd3275, 0, 0, "ex2_at_on");
    check_case(12'd4095, 12'd3685, 12'd3275, 0, 0, "ex2_end_of_frame_in_on_range");

    // --- Directed: 0% duty cycle (on==off) ---
    check_case(12'd0,    12'd100, 12'd100, 0, 0, "zero_duty_at_100");
    check_case(12'd100,  12'd100, 12'd100, 0, 0, "zero_duty_at_boundary");
    check_case(12'd4095, 12'd100, 12'd100, 0, 0, "zero_duty_at_end");

    // --- Directed: full_on / full_off override precedence ---
    check_case(12'd0,    12'd100, 12'd200, 1, 0, "full_on_forces_high_outside_range");
    check_case(12'd150,  12'd100, 12'd200, 1, 0, "full_on_forces_high_inside_range_too");
    check_case(12'd150,  12'd100, 12'd200, 0, 1, "full_off_forces_low_inside_range");
    check_case(12'd150,  12'd100, 12'd200, 1, 1, "full_off_takes_precedence_over_full_on");

    // --- Directed: 100% duty cycle representative (on=0, off=4095: high
    //     almost the whole frame except last count) ---
    check_case(12'd0,    12'd0, 12'd4095, 0, 0, "near_full_duty_start");
    check_case(12'd4094, 12'd0, 12'd4095, 0, 0, "near_full_duty_last_high");
    check_case(12'd4095, 12'd0, 12'd4095, 0, 0, "near_full_duty_last_count_low");

    // --- Randomized sweep across the full state space ---
    for (int i = 0; i < 20000; i++) begin
      bit [PWM_WIDTH-1:0] rc, ron, roff;
      bit rfon, rfoff;
      rc    = $urandom_range(0, 4095);
      ron   = $urandom_range(0, 4095);
      roff  = $urandom_range(0, 4095);
      rfon  = $urandom_range(0, 1);
      rfoff = $urandom_range(0, 1);
      check_case(rc, ron, roff, rfon, rfoff, $sformatf("rand_%0d", i));
    end

    if (errors == 0) begin
      $display("PASS: pwm_compare_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: pwm_compare_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

endmodule
