// =============================================================================
// pwm_channel_tb.sv
//
// Self-checking unit testbench for rtl/pwm/pwm_channel.sv.
//
// Independent reference function computes expected (led_level, led_drive)
// from the specification (docs/MASTER_ARCHITECTURE.md Sections 10, 15),
// not from the RTL source.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o pwm_channel_tb rtl/pwm/pwm_compare.sv rtl/pwm/pwm_channel.sv tb/unit/pwm/pwm_channel_tb.sv
//   vvp pwm_channel_tb
// =============================================================================

`timescale 1ns/1ps

module pwm_channel_tb;

  localparam int PWM_WIDTH = 12;

  logic [PWM_WIDTH-1:0] count;
  logic [PWM_WIDTH-1:0] on_count, off_count;
  logic full_on, full_off, enable, polarity;
  logic invrt, oe_n_i, outdrv;
  logic [1:0] outne;
  logic led_level_o, led_drive_o;

  int errors = 0;
  int checks = 0;

  pwm_channel #(.PWM_WIDTH(PWM_WIDTH)) dut (
    .count       (count),
    .on_count    (on_count),
    .off_count   (off_count),
    .full_on     (full_on),
    .full_off    (full_off),
    .enable      (enable),
    .polarity    (polarity),
    .invrt       (invrt),
    .oe_n_i      (oe_n_i),
    .outne       (outne),
    .outdrv      (outdrv),
    .led_level_o (led_level_o),
    .led_drive_o (led_drive_o)
  );

  // Independent reference model for raw PWM compare (same spec as
  // pwm_compare_tb's, kept separate/duplicated deliberately so this
  // testbench does not depend on pwm_compare_tb.sv).
  function automatic bit ref_raw(
    input bit [PWM_WIDTH-1:0] c, input bit [PWM_WIDTH-1:0] onv,
    input bit [PWM_WIDTH-1:0] offv, input bit fon, input bit foff
  );
    begin
      if (foff) return 0;
      if (fon)  return 1;
      if (onv <= offv) return (c >= onv) && (c < offv);
      else              return (c >= onv) || (c < offv);
    end
  endfunction

  task automatic check_case(
    input bit [PWM_WIDTH-1:0] c, on_v, off_v,
    input bit fon, foff, en, pol, inv, oen, drv,
    input bit [1:0] one,
    input string tag
  );
    bit raw, gated, inverted;
    bit exp_level, exp_drive;
    begin
      count = c; on_count = on_v; off_count = off_v;
      full_on = fon; full_off = foff; enable = en; polarity = pol;
      invrt = inv; oe_n_i = oen; outdrv = drv; outne = one;
      #1;

      raw      = ref_raw(c, on_v, off_v, fon, foff);
      gated    = raw & en;
      inverted = gated ^ inv ^ pol;

      if (oen) begin
        unique case (one)
          2'b00: begin exp_level = 0; exp_drive = 1; end
          2'b01: begin exp_level = 1; exp_drive = drv; end
          default: begin exp_level = 1'bx; exp_drive = 0; end
        endcase
      end else begin
        exp_level = inverted;
        exp_drive = drv ? 1'b1 : ~inverted;
      end

      checks++;
      if (led_drive_o !== exp_drive) begin
        errors++;
        $display("FAIL(drive) [%s]: got_drive=%0b expected=%0b", tag, led_drive_o, exp_drive);
      end
      // Only check level when a drive is actually expected/asserted --
      // undriven ("don't care") levels are not compared.
      if (exp_drive && (led_level_o !== exp_level)) begin
        errors++;
        $display("FAIL(level) [%s]: got_level=%0b expected=%0b", tag, led_level_o, exp_level);
      end
    end
  endtask

  initial begin
    // --- Baseline: normal operation, totem-pole, no invert/polarity, OE=0 ---
    check_case(12'd0,   12'd100, 12'd200, 0,0, 1,0, 0,0,1, 2'b00, "baseline_before_on");
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,0,1, 2'b00, "baseline_in_range");

    // --- enable gating ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 0,0, 0,0,1, 2'b00, "disabled_channel_forces_low");

    // --- full_on / full_off ---
    check_case(12'd0,   12'd100, 12'd200, 1,0, 1,0, 0,0,1, 2'b00, "full_on_forces_high");
    check_case(12'd150, 12'd100, 12'd200, 0,1, 1,0, 0,0,1, 2'b00, "full_off_forces_low");
    check_case(12'd150, 12'd100, 12'd200, 1,1, 1,0, 0,0,1, 2'b00, "full_off_precedence_over_full_on");

    // --- polarity (SEMFONIX) ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,1, 0,0,1, 2'b00, "polarity_inverts_active_channel");
    check_case(12'd0,   12'd100, 12'd200, 0,0, 1,1, 0,0,1, 2'b00, "polarity_inverts_inactive_channel");

    // --- global invert (MODE2.INVRT) ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 1,0,1, 2'b00, "global_invert_applies_when_oe_low");

    // --- polarity + invert compose (double invert = back to normal) ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,1, 1,0,1, 2'b00, "invert_and_polarity_compose_cancel");

    // --- OE=1 forcing, OUTNE=00 -> driven low always ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,1,1, 2'b00, "oe1_outne00_driven_low");

    // --- OE=1, OUTNE=01, OUTDRV=1 -> driven high ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,1,1, 2'b01, "oe1_outne01_outdrv1_driven_high");

    // --- OE=1, OUTNE=01, OUTDRV=0 -> released (open-drain, no drive) ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,1,0, 2'b01, "oe1_outne01_outdrv0_released");

    // --- OE=1, OUTNE=10/11 -> always released regardless of OUTDRV ---
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,1,1, 2'b10, "oe1_outne10_released");
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,1,0, 2'b11, "oe1_outne11_released");

    // --- open-drain normal operation: only actively drives LOW ---
    check_case(12'd0,   12'd100, 12'd200, 0,0, 1,0, 0,0,0, 2'b00, "opendrain_low_phase_driven");
    check_case(12'd150, 12'd100, 12'd200, 0,0, 1,0, 0,0,0, 2'b00, "opendrain_high_phase_released");

    // --- randomized sweep ---
    for (int i = 0; i < 5000; i++) begin
      check_case(
        $urandom_range(0,4095), $urandom_range(0,4095), $urandom_range(0,4095),
        $urandom_range(0,1), $urandom_range(0,1), $urandom_range(0,1), $urandom_range(0,1),
        $urandom_range(0,1), $urandom_range(0,1), $urandom_range(0,1),
        $urandom_range(0,3),
        $sformatf("rand_%0d", i)
      );
    end

    if (errors == 0) begin
      $display("PASS: pwm_channel_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: pwm_channel_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

endmodule
