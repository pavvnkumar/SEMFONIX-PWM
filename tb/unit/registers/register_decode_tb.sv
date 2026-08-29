`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// register_decode_tb.sv
//
// Unit testbench for the CURRENT register_decode architecture.
//
// Current architecture:
//   - ptr_q is the register pointer.
//   - rb_addr_o follows ptr_q combinationally.
//   - rb_wr_en_o / rb_rd_en_o are transaction enables.
//   - AI increments ptr_q on the transaction clock edge.
//   - ACK4 is combinational from the CURRENT pointer.
//   - rd_data_o is a REGISTERED read-data holding value.
//
// IMPORTANT READ-DATA TIMING:
//
//   During a read transaction:
//       BEFORE clock:
//           rb_addr_o = current pointer
//           rb_rdata_i = data for current pointer
//           rd_data_o = previously captured read value
//
//       AT clock edge:
//           rd_data_q captures rb_rdata_i
//           ptr_q may increment when AI is enabled
//
//       AFTER clock:
//           rd_data_o = captured current-register value
//
// This testbench therefore does NOT expect rd_data_o to change
// combinationally when rb_rdata_i changes.
//
// Tests:
//   1. Reset
//   2. Pointer set
//   3. Write uses current pointer
//   4. AI write increment
//   5. AI read increment
//   6. AI disabled pointer hold
//   7. Channel 0 ACK4
//   8. Channel 1 ACK4
//   9. Non-group-ending LED addresses
//  10. Last channel OFF_H + wrap
//  11. ALL_LED_OFF_H broadcast ACK4
//  12. PRE_SCALE wrap
//  13. ptr_set priority
//  14. ACK4 before pointer increment
//  15. Registered read response
//  16. AI read data survives pointer increment
//  17. No transaction
// =============================================================================

module register_decode_tb;

  // ===========================================================================
  // DUT inputs
  // ===========================================================================

  logic       clk_ref;
  logic       rst_n;

  logic       ptr_set_i;
  logic [7:0] ptr_set_data_i;

  logic       wr_byte_i;
  logic [7:0] wr_byte_data_i;

  logic       rd_byte_i;

  logic       ai_en_i;

  logic [7:0] rb_rdata_i;

  // ===========================================================================
  // DUT outputs
  // ===========================================================================

  logic [7:0] rb_addr_o;
  logic       rb_wr_en_o;
  logic       rb_rd_en_o;
  logic [7:0] rb_wdata_o;

  logic [7:0] rd_data_o;

  logic       ack4_event_o;

  logic [7:0] ptr_o;

  // ===========================================================================
  // DUT
  // ===========================================================================

  register_decode dut (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),

    .ptr_set_i      (ptr_set_i),
    .ptr_set_data_i (ptr_set_data_i),

    .wr_byte_i      (wr_byte_i),
    .wr_byte_data_i (wr_byte_data_i),

    .rd_byte_i      (rd_byte_i),

    .ai_en_i        (ai_en_i),

    .rb_addr_o      (rb_addr_o),
    .rb_wr_en_o     (rb_wr_en_o),
    .rb_rd_en_o     (rb_rd_en_o),
    .rb_wdata_o     (rb_wdata_o),

    .rb_rdata_i     (rb_rdata_i),
    .rd_data_o      (rd_data_o),

    .ack4_event_o   (ack4_event_o),

    .ptr_o          (ptr_o)
  );

  // ===========================================================================
  // Clock
  // ===========================================================================

  initial begin
    clk_ref = 1'b0;
    forever #5 clk_ref = ~clk_ref;
  end

  // ===========================================================================
  // Counters
  // ===========================================================================

  integer checks;
  integer errors;

  initial begin
    checks = 0;
    errors = 0;
  end

  // ===========================================================================
  // Generic 8-bit check
  // ===========================================================================

  task automatic expect8(
    input logic [7:0] actual,
    input logic [7:0] expected,
    input string name
  );
    begin

      checks = checks + 1;

      if (actual !== expected) begin

        errors = errors + 1;

        $display(
          "FAIL [%s]: got=0x%02h expected=0x%02h",
          name,
          actual,
          expected
        );

      end
      else begin

        $display(
          "PASS [%s]: 0x%02h",
          name,
          actual
        );

      end

    end
  endtask

  // ===========================================================================
  // Generic 1-bit check
  // ===========================================================================

  task automatic expect1(
    input logic actual,
    input logic expected,
    input string name
  );
    begin

      checks = checks + 1;

      if (actual !== expected) begin

        errors = errors + 1;

        $display(
          "FAIL [%s]: got=%0b expected=%0b",
          name,
          actual,
          expected
        );

      end
      else begin

        $display(
          "PASS [%s]: %0b",
          name,
          actual
        );

      end

    end
  endtask

  // ===========================================================================
  // Clock helper
  // ===========================================================================

  task automatic tick;
    begin
      @(posedge clk_ref);
      #1;
    end
  endtask

  // ===========================================================================
  // Clear transaction inputs
  // ===========================================================================

  task automatic clear_inputs;
    begin

      ptr_set_i      = 1'b0;
      ptr_set_data_i = 8'h00;

      wr_byte_i      = 1'b0;
      wr_byte_data_i = 8'h00;

      rd_byte_i      = 1'b0;

      ai_en_i        = 1'b0;

    end
  endtask

  // ===========================================================================
  // Reset
  // ===========================================================================

  task automatic reset_dut;
    begin

      clear_inputs();

      rb_rdata_i = 8'h00;

      rst_n = 1'b0;

      repeat (2)
        tick();

      rst_n = 1'b1;

      #1;

      expect8(
        ptr_o,
        8'h00,
        "reset_pointer"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "reset_ack4"
      );

      expect8(
        rd_data_o,
        8'h00,
        "reset_read_data"
      );

    end
  endtask

  // ===========================================================================
  // TEST 1: Pointer set
  // ===========================================================================

  task automatic test_pointer_set;
    begin

      $display("");
      $display("=== TEST: pointer set ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h20;

      expect8(
        ptr_o,
        8'h00,
        "ptr_set_before_clock"
      );

      tick();

      expect8(
        ptr_o,
        8'h20,
        "ptr_set_after_clock"
      );

      expect8(
        rb_addr_o,
        8'h20,
        "rb_addr_after_ptr_set"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 2: Write uses current pointer
  // ===========================================================================

  task automatic test_write_current_pointer;
    begin

      $display("");
      $display("=== TEST: write uses current pointer ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h20;

      tick();

      clear_inputs();

      wr_byte_i      = 1'b1;
      wr_byte_data_i = 8'hAB;

      #1;

      expect8(
        rb_addr_o,
        8'h20,
        "write_current_address"
      );

      expect1(
        rb_wr_en_o,
        1'b1,
        "write_enable"
      );

      expect8(
        rb_wdata_o,
        8'hAB,
        "write_data"
      );

      tick();

      expect8(
        ptr_o,
        8'h20,
        "write_ai_disabled_pointer_hold"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 3: AI write increment
  // ===========================================================================

  task automatic test_ai_write_increment;
    begin

      $display("");
      $display("=== TEST: AI write increment ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h20;

      tick();

      clear_inputs();

      ai_en_i        = 1'b1;
      wr_byte_i      = 1'b1;
      wr_byte_data_i = 8'h55;

      #1;

      expect8(
        rb_addr_o,
        8'h20,
        "ai_write_current_address"
      );

      tick();

      expect8(
        ptr_o,
        8'h21,
        "ai_write_increment"
      );

      expect8(
        rb_addr_o,
        8'h21,
        "ai_next_current_address"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 4: AI read increment
  //
  // With the new architecture:
  //
  //   before clock:
  //       rd_data_o still contains previous holding value
  //
  //   after clock:
  //       rd_data_o contains rb_rdata_i captured for current pointer
  //
  // The test explicitly verifies both.
  // ===========================================================================

  task automatic test_ai_read_increment;
    begin

      $display("");
      $display("=== TEST: AI read increment ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h30;

      tick();

      clear_inputs();

      ai_en_i    = 1'b1;
      rd_byte_i  = 1'b1;
      rb_rdata_i = 8'hA5;

      #1;

      expect8(
        rb_addr_o,
        8'h30,
        "read_current_address"
      );

      expect1(
        rb_rd_en_o,
        1'b1,
        "read_enable"
      );

      // No capture has happened yet.
      // rd_data_q still contains reset value.
      expect8(
        rd_data_o,
        8'h00,
        "read_data_before_capture"
      );

      tick();

      // Read data must now contain register 30's value.
      expect8(
        rd_data_o,
        8'hA5,
        "read_data_after_capture"
      );

      // AI increments pointer at the same edge.
      expect8(
        ptr_o,
        8'h31,
        "ai_read_increment"
      );

      expect8(
        rb_addr_o,
        8'h31,
        "read_next_current_address"
      );

      // Captured data must survive pointer increment.
      expect8(
        rd_data_o,
        8'hA5,
        "read_data_survives_ai_increment"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 5: AI disabled
  // ===========================================================================

  task automatic test_ai_disabled;
    begin

      $display("");
      $display("=== TEST: AI disabled ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h40;

      tick();

      clear_inputs();

      ai_en_i   = 1'b0;
      wr_byte_i = 1'b1;

      tick();

      expect8(
        ptr_o,
        8'h40,
        "ai_disabled_write_hold"
      );

      clear_inputs();

      ai_en_i    = 1'b0;
      rd_byte_i  = 1'b1;
      rb_rdata_i = 8'h66;

      tick();

      expect8(
        ptr_o,
        8'h40,
        "ai_disabled_read_hold"
      );

      expect8(
        rd_data_o,
        8'h66,
        "ai_disabled_read_capture"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 6: Channel 0 ACK4
  // ===========================================================================

  task automatic test_channel0_ack4;
    begin

      $display("");
      $display("=== TEST: channel 0 ACK4 ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h06;

      tick();

      clear_inputs();

      ai_en_i   = 1'b1;
      wr_byte_i = 1'b1;

      #1;

      expect8(
        rb_addr_o,
        8'h06,
        "ch0_byte0_addr"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "ch0_byte0_ack4"
      );

      tick();

      #1;

      expect8(
        rb_addr_o,
        8'h07,
        "ch0_byte1_addr"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "ch0_byte1_ack4"
      );

      tick();

      #1;

      expect8(
        rb_addr_o,
        8'h08,
        "ch0_byte2_addr"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "ch0_byte2_ack4"
      );

      tick();

      #1;

      expect8(
        rb_addr_o,
        8'h09,
        "ch0_byte3_addr"
      );

      expect1(
        ack4_event_o,
        1'b1,
        "ch0_byte3_ack4"
      );

      tick();

      expect8(
        ptr_o,
        8'h0A,
        "ch0_after_fourth_byte"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "ch0_ack4_after_write"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 7: Channel 1 ACK4
  // ===========================================================================

  task automatic test_channel1_ack4;
    begin

      $display("");
      $display("=== TEST: channel 1 ACK4 ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h0D;

      tick();

      clear_inputs();

      wr_byte_i = 1'b1;

      #1;

      expect8(
        rb_addr_o,
        8'h0D,
        "ch1_off_h_address"
      );

      expect1(
        ack4_event_o,
        1'b1,
        "ch1_off_h_ack4"
      );

      clear_inputs();

      tick();

    end
  endtask

  // ===========================================================================
  // TEST 8: Non-group-ending LED addresses
  // ===========================================================================

  task automatic test_non_group_ending_led;
    begin

      $display("");
      $display("=== TEST: non-group-ending LED addresses ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h08;

      tick();

      clear_inputs();

      wr_byte_i = 1'b1;

      #1;

      expect1(
        ack4_event_o,
        1'b0,
        "0x08_not_ack4"
      );

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h0A;

      tick();

      clear_inputs();

      wr_byte_i = 1'b1;

      #1;

      expect1(
        ack4_event_o,
        1'b0,
        "0x0A_not_ack4"
      );

      clear_inputs();

      tick();

    end
  endtask

  // ===========================================================================
  // TEST 9: Last channel OFF_H
  // ===========================================================================

  task automatic test_last_channel;
    begin

      $display("");
      $display("=== TEST: last channel OFF_H ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h45;

      tick();

      clear_inputs();

      ai_en_i   = 1'b1;
      wr_byte_i = 1'b1;

      #1;

      expect8(
        rb_addr_o,
        8'h45,
        "last_channel_off_h_address"
      );

      expect1(
        ack4_event_o,
        1'b1,
        "last_channel_ack4"
      );

      tick();

      expect8(
        ptr_o,
        8'h00,
        "last_channel_wrap"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "last_channel_ack4_after_write"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 10: ALL_LED_OFF_H broadcast
  // ===========================================================================

  task automatic test_broadcast_ack4;
    begin

      $display("");
      $display("=== TEST: ALL_LED_OFF_H broadcast ACK4 ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'hFD;

      tick();

      clear_inputs();

      ai_en_i   = 1'b1;
      wr_byte_i = 1'b1;

      #1;

      expect8(
        rb_addr_o,
        8'hFD,
        "broadcast_current_address"
      );

      expect1(
        ack4_event_o,
        1'b1,
        "broadcast_ack4"
      );

      tick();

      expect8(
        ptr_o,
        8'hFE,
        "broadcast_pointer_increment"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 11: PRE_SCALE wrap
  // ===========================================================================

  task automatic test_prescale_wrap;
    begin

      $display("");
      $display("=== TEST: PRE_SCALE wrap ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'hFE;

      tick();

      clear_inputs();

      ai_en_i   = 1'b1;
      wr_byte_i = 1'b1;

      #1;

      expect8(
        rb_addr_o,
        8'hFE,
        "prescale_current_address"
      );

      expect1(
        ack4_event_o,
        1'b0,
        "prescale_no_ack4"
      );

      tick();

      expect8(
        ptr_o,
        8'h00,
        "prescale_wrap_mode1"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 12: ptr_set priority
  // ===========================================================================

  task automatic test_ptr_set_priority;
    begin

      $display("");
      $display("=== TEST: ptr_set priority ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h20;

      tick();

      clear_inputs();

      // Both pointer set and transaction are asserted.
      // Pointer set must win.
      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h50;

      wr_byte_i      = 1'b1;
      wr_byte_data_i = 8'hAA;

      #1;

      // Bus still represents the OLD/current pointer before the edge.
      expect8(
        rb_addr_o,
        8'h20,
        "ptr_set_priority_current_bus_address"
      );

      tick();

      expect8(
        ptr_o,
        8'h50,
        "ptr_set_priority_result"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 13: ACK4 before pointer increment
  // ===========================================================================

  task automatic test_ack4_before_increment;
    begin

      $display("");
      $display("=== TEST: ACK4 before pointer increment ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h09;

      tick();

      clear_inputs();

      ai_en_i   = 1'b1;
      wr_byte_i = 1'b1;

      // BEFORE clock:
      // pointer = 09
      // therefore ACK4 must be asserted.
      #1;

      expect8(
        rb_addr_o,
        8'h09,
        "ack4_current_address"
      );

      expect1(
        ack4_event_o,
        1'b1,
        "ack4_current_pointer"
      );

      tick();

      // AFTER clock:
      // pointer must have advanced to 0A.
      expect8(
        ptr_o,
        8'h0A,
        "ack4_after_increment"
      );

      // ACK4 must disappear because current pointer is now 0A.
      expect1(
        ack4_event_o,
        1'b0,
        "ack4_removed_after_write"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 14: Registered read response
  //
  // This test is intentionally RESET at the beginning.
  //
  // Reason:
  // rd_data_o is a holding register. A previous test may have captured
  // some other value. The reset gives this test a deterministic initial
  // value of 0x00.
  // ===========================================================================

  task automatic test_registered_read_response;
    begin

      $display("");
      $display("=== TEST: registered read response ===");

      // -----------------------------------------------------------------------
      // Isolate this test from all previous transactions.
      // -----------------------------------------------------------------------

      reset_dut();

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h12;

      tick();

      clear_inputs();

      // -----------------------------------------------------------------------
      // First read.
      // -----------------------------------------------------------------------

      rd_byte_i  = 1'b1;
      rb_rdata_i = 8'hBE;

      #1;

      // rb_rdata_i has changed, but no clock edge has captured it yet.
      // Therefore rd_data_o must still be the reset value.
      expect8(
        rd_data_o,
        8'h00,
        "read_response_before_capture_be"
      );

      tick();

      // After the read clock edge, BE is captured.
      expect8(
        rd_data_o,
        8'hBE,
        "read_response_after_capture_be"
      );

      // -----------------------------------------------------------------------
      // Remove read transaction.
      // Holding register must retain BE.
      // -----------------------------------------------------------------------

      clear_inputs();

      rb_rdata_i = 8'hEF;

      #1;

      expect8(
        rd_data_o,
        8'hBE,
        "read_response_holds_without_new_read"
      );

      // -----------------------------------------------------------------------
      // Second read.
      //
      // Before its clock edge, old BE must still be visible.
      // -----------------------------------------------------------------------

      rd_byte_i = 1'b1;

      #1;

      expect8(
        rd_data_o,
        8'hBE,
        "read_response_second_read_before_capture"
      );

      tick();

      // After the edge, EF must replace BE.
      expect8(
        rd_data_o,
        8'hEF,
        "read_response_after_capture_ef"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // TEST 15: AI read data survives pointer increment
  //
  // This directly verifies the architectural reason for rd_data_q.
  //
  // Current pointer = 06
  // rb_rdata_i     = 11
  //
  // At read clock edge:
  //   rd_data_q <- 11
  //   ptr_q      <- 07
  //
  // After the edge:
  //   rb_addr_o = 07
  //   rd_data_o = 11
  //
  // Thus TX can consume the data belonging to address 06 even though
  // the pointer has already advanced to 07.
  // ===========================================================================

  task automatic test_ai_read_data_survives_increment;
    begin

      $display("");
      $display("=== TEST: AI read data survives pointer increment ===");

      // Start from a deterministic state.
      reset_dut();

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h06;

      tick();

      clear_inputs();

      ai_en_i    = 1'b1;
      rd_byte_i  = 1'b1;
      rb_rdata_i = 8'h11;

      #1;

      expect8(
        rb_addr_o,
        8'h06,
        "ai_read_data_current_address"
      );

      tick();

      expect8(
        ptr_o,
        8'h07,
        "ai_read_data_pointer_increment"
      );

      expect8(
        rb_addr_o,
        8'h07,
        "ai_read_data_next_address"
      );

      // Must still be data from address 06.
      expect8(
        rd_data_o,
        8'h11,
        "ai_read_data_captured_old_address"
      );

      // Keep rb_rdata_i different to prove rd_data_o is not combinational.
      clear_inputs();

      rb_rdata_i = 8'h22;

      #1;

      expect8(
        rd_data_o,
        8'h11,
        "ai_read_data_holds_until_next_read"
      );

    end
  endtask

  // ===========================================================================
  // TEST 16: No transaction
  // ===========================================================================

  task automatic test_no_transaction;
    begin

      $display("");
      $display("=== TEST: no transaction ===");

      clear_inputs();

      ptr_set_i      = 1'b1;
      ptr_set_data_i = 8'h09;

      tick();

      clear_inputs();

      #1;

      expect1(
        ack4_event_o,
        1'b0,
        "no_write_no_ack4"
      );

      expect1(
        rb_wr_en_o,
        1'b0,
        "no_write_disabled"
      );

      expect1(
        rb_rd_en_o,
        1'b0,
        "no_read_disabled"
      );

      clear_inputs();

    end
  endtask

  // ===========================================================================
  // Main
  // ===========================================================================

  initial begin

    rst_n = 1'b1;

    clear_inputs();

    rb_rdata_i = 8'h00;

    // -------------------------------------------------------------------------
    // Run all tests.
    // -------------------------------------------------------------------------

    reset_dut();

    test_pointer_set();

    test_write_current_pointer();

    test_ai_write_increment();

    test_ai_read_increment();

    test_ai_disabled();

    test_channel0_ack4();

    test_channel1_ack4();

    test_non_group_ending_led();

    test_last_channel();

    test_broadcast_ack4();

    test_prescale_wrap();

    test_ptr_set_priority();

    test_ack4_before_increment();

    test_registered_read_response();

    test_ai_read_data_survives_increment();

    test_no_transaction();

    // -------------------------------------------------------------------------
    // Final result.
    // -------------------------------------------------------------------------

    $display("");
    $display("============================================================");
    $display("register_decode_tb COMPLETE");
    $display("Checks : %0d", checks);
    $display("Errors : %0d", errors);
    $display("============================================================");

    if (errors != 0) begin

      $display(
        "FAIL: register_decode_tb - %0d errors",
        errors
      );

      $fatal(1);

    end
    else begin

      $display("PASS: register_decode_tb");

      $finish;

    end

  end

endmodule

`default_nettype wire

