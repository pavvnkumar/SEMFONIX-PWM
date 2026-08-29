// =============================================================================
// address_decode_tb.sv
//
// Self-checking unit testbench for rtl/registers/address_decode.sv.
//
// address_decode is purely combinational (no clk/rst), so this
// testbench just drives the input ports and checks outputs after a
// settling delay -- no clock generator needed.
//
// Covers:
//   1. Regular hardware+programmable slave address: matches
//      {1'b1, hw_addr_i} and only that pattern; always active (no
//      enable qualifier), across a randomized sweep of hw_addr_i values.
//   2. General-Call/SWRST address (0000000): matches only when R/W=0;
//      a read (R/W=1) to the same 7 bits does NOT match.
//   3. LED All-Call address: matches active_allcalladr_i only when
//      active_allcall_i=1; disabled => no match even on an exact byte
//      hit.
//   4. Sub-Call 1/2/3 addresses: each matches its own
//      active_subadr_i[n] only when its own active_subx_en_i bit is
//      set, independently of the other two -- including the documented
//      index/bit-order mapping (active_subx_en_i[2]=SUB1 gates
//      active_subadr_i[0], down to active_subx_en_i[0]=SUB3 gates
//      active_subadr_i[2]).
//   5. addr_match_o is the OR of all five per-type matches: asserted
//      when any one type matches, deasserted when none do.
//   6. No false-positive cross-talk: a byte that matches one address
//      type does not spuriously assert a different type's match output
//      (spot-checked across all six comparator categories).
//   7. Simultaneous-match coincidence (ALLCALLADR programmed equal to
//      the regular address): both allcall_match_o and regular_match_o
//      assert together, and addr_match_o still reads as a clean single
//      OR (Section 11: no priority resolution needed for the shared
//      write path).
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o address_decode_tb rtl/registers/address_decode.sv \
//     tb/unit/registers/address_decode_tb.sv
//   vvp address_decode_tb
// =============================================================================

`timescale 1ns/1ps

module address_decode_tb;

  logic [6:0] addr7_i;
  logic       rw_i;
  logic [5:0] hw_addr_i;
  logic       active_allcall_i;
  logic [2:0] active_subx_en_i;
  logic [6:0] active_allcalladr_i;
  logic [6:0] active_subadr_i [3];

  logic       gc_match_o;
  logic       allcall_match_o;
  logic [2:0] sub_match_o;
  logic       regular_match_o;
  logic       addr_match_o;

  int errors = 0;
  int checks = 0;

  address_decode dut (
    .addr7_i              (addr7_i),
    .rw_i                 (rw_i),
    .hw_addr_i            (hw_addr_i),
    .active_allcall_i     (active_allcall_i),
    .active_subx_en_i     (active_subx_en_i),
    .active_allcalladr_i  (active_allcalladr_i),
    .active_subadr_i      (active_subadr_i),
    .gc_match_o           (gc_match_o),
    .allcall_match_o      (allcall_match_o),
    .sub_match_o          (sub_match_o),
    .regular_match_o      (regular_match_o),
    .addr_match_o         (addr_match_o)
  );

  task automatic expect_eq(input logic [63:0] got, input logic [63:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=%0d expected=%0d", tag, got, exp);
    end
  endtask

  // Drives every input to a known-quiet default, then lets the caller
  // override just the fields under test -- keeps each check block small
  // and avoids stale state leaking between cases.
  task automatic quiesce();
    begin
      addr7_i             = 7'h7F;  // deliberately un-matchable default (all 1s)
      rw_i                = 1'b0;
      hw_addr_i            = 6'h00;
      active_allcall_i     = 1'b0;
      active_subx_en_i     = 3'b000;
      active_allcalladr_i  = 7'h7E; // != default addr7_i / != 7'h7F, harmless
      active_subadr_i[0]   = 7'h7D;
      active_subadr_i[1]   = 7'h7C;
      active_subadr_i[2]   = 7'h7B;
      #1;
    end
  endtask

  initial begin
    // -------------------------------------------------------------------
    // 1. Regular hardware+programmable slave address
    // -------------------------------------------------------------------
    quiesce();
    for (int i = 0; i < 20; i++) begin
      logic [5:0] hw;
      hw = $urandom_range(0, 63);
      quiesce();
      hw_addr_i = hw;
      addr7_i   = {1'b1, hw};
      #1;
      expect_eq(regular_match_o, 1'b1, "regular_match_hits_own_hw_addr");
      expect_eq(addr_match_o,    1'b1, "regular_match_asserts_addr_match");
      expect_eq(gc_match_o,      1'b0, "regular_match_no_gc_crosstalk");
      expect_eq(allcall_match_o, 1'b0, "regular_match_no_allcall_crosstalk");
      expect_eq(sub_match_o,     3'b000, "regular_match_no_sub_crosstalk");

      // one bit off => no match (still MSB=1, so not a general-call
      // false-positive either)
      addr7_i = {1'b1, hw} ^ 7'h01;
      #1;
      expect_eq(regular_match_o, 1'b0, "regular_mismatch_one_bit_off");
      expect_eq(addr_match_o,    1'b0, "regular_mismatch_addr_match_low");
    end

    // MSB=0 never matches the regular address, regardless of hw_addr_i
    quiesce();
    hw_addr_i = 6'h00;
    addr7_i   = 7'h00; // {1'b0, 6'h00} -- also the general-call pattern
    #1;
    expect_eq(regular_match_o, 1'b0, "regular_never_matches_msb0");

    // -------------------------------------------------------------------
    // 2. General-Call / SWRST address, R/W-qualified
    // -------------------------------------------------------------------
    quiesce();
    addr7_i = 7'h00;
    rw_i    = 1'b0;
    #1;
    expect_eq(gc_match_o,   1'b1, "gc_matches_on_write");
    expect_eq(addr_match_o, 1'b1, "gc_match_asserts_addr_match");
    expect_eq(regular_match_o, 1'b0, "gc_match_no_regular_crosstalk");
    expect_eq(allcall_match_o, 1'b0, "gc_match_no_allcall_crosstalk");
    expect_eq(sub_match_o,     3'b000, "gc_match_no_sub_crosstalk");

    rw_i = 1'b1; // read to the same 7 bits must NOT match
    #1;
    expect_eq(gc_match_o,   1'b0, "gc_no_match_on_read");
    expect_eq(addr_match_o, 1'b0, "gc_no_match_on_read_addr_match_low");

    addr7_i = 7'h01; // any other 7-bit pattern never matches gc, regardless of R/W
    rw_i    = 1'b0;
    #1;
    expect_eq(gc_match_o, 1'b0, "gc_no_match_wrong_addr");

    // -------------------------------------------------------------------
    // 3. LED All-Call address, enable-qualified
    // -------------------------------------------------------------------
    quiesce();
    active_allcalladr_i = 7'h50;
    active_allcall_i    = 1'b0; // disabled
    addr7_i              = 7'h50;
    #1;
    expect_eq(allcall_match_o, 1'b0, "allcall_no_match_when_disabled");
    expect_eq(addr_match_o,    1'b0, "allcall_disabled_addr_match_low");

    active_allcall_i = 1'b1; // enabled
    #1;
    expect_eq(allcall_match_o, 1'b1, "allcall_matches_when_enabled");
    expect_eq(addr_match_o,    1'b1, "allcall_match_asserts_addr_match");
    expect_eq(regular_match_o, 1'b0, "allcall_match_no_regular_crosstalk");
    expect_eq(gc_match_o,      1'b0, "allcall_match_no_gc_crosstalk");
    expect_eq(sub_match_o,     3'b000, "allcall_match_no_sub_crosstalk");

    addr7_i = 7'h51; // wrong byte, still enabled => no match
    #1;
    expect_eq(allcall_match_o, 1'b0, "allcall_no_match_wrong_byte");

    // -------------------------------------------------------------------
    // 4. Sub-Call 1/2/3 addresses, independently enable-qualified
    //    (documented index/bit-order mapping, see address_decode.sv
    //    header: active_subx_en_i[2]=SUB1..[0]=SUB3)
    // -------------------------------------------------------------------
    quiesce();
    active_subadr_i[0] = 7'h60; // SUB1
    active_subadr_i[1] = 7'h61; // SUB2
    active_subadr_i[2] = 7'h62; // SUB3
    active_subx_en_i   = 3'b000; // all disabled

    addr7_i = 7'h60;
    #1;
    expect_eq(sub_match_o, 3'b000, "sub1_no_match_when_disabled");

    active_subx_en_i = 3'b100; // enable SUB1 only (bit2)
    #1;
    expect_eq(sub_match_o[0], 1'b1, "sub1_matches_when_enabled");
    expect_eq(sub_match_o[1], 1'b0, "sub1_enable_no_sub2_crosstalk");
    expect_eq(sub_match_o[2], 1'b0, "sub1_enable_no_sub3_crosstalk");
    expect_eq(addr_match_o,   1'b1, "sub1_match_asserts_addr_match");
    expect_eq(regular_match_o, 1'b0, "sub1_match_no_regular_crosstalk");
    expect_eq(allcall_match_o, 1'b0, "sub1_match_no_allcall_crosstalk");
    expect_eq(gc_match_o,      1'b0, "sub1_match_no_gc_crosstalk");

    addr7_i = 7'h61; // SUB2's byte, but only SUB1 is enabled => no match
    #1;
    expect_eq(sub_match_o, 3'b000, "sub2_byte_no_match_sub1_only_enabled");

    active_subx_en_i = 3'b010; // enable SUB2 only (bit1)
    #1;
    expect_eq(sub_match_o[1], 1'b1, "sub2_matches_when_enabled");
    expect_eq(sub_match_o[0], 1'b0, "sub2_enable_no_sub1_crosstalk");
    expect_eq(sub_match_o[2], 1'b0, "sub2_enable_no_sub3_crosstalk");

    addr7_i = 7'h62; // SUB3
    active_subx_en_i = 3'b001; // enable SUB3 only (bit0)
    #1;
    expect_eq(sub_match_o[2], 1'b1, "sub3_matches_when_enabled");
    expect_eq(sub_match_o[0], 1'b0, "sub3_enable_no_sub1_crosstalk");
    expect_eq(sub_match_o[1], 1'b0, "sub3_enable_no_sub2_crosstalk");

    // all three enabled + a byte matching only SUB2 => exactly sub_match_o[1]
    active_subx_en_i = 3'b111;
    addr7_i           = 7'h61;
    #1;
    expect_eq(sub_match_o, 3'b010, "all_subx_enabled_only_sub2_byte_hits");
    expect_eq(addr_match_o, 1'b1, "all_subx_enabled_addr_match_high");

    // -------------------------------------------------------------------
    // 5/6. addr_match_o is a clean OR; no-match case deasserts everything
    // -------------------------------------------------------------------
    quiesce(); // addr7_i defaults to 7'h7F, everything else quiet/disabled
    #1;
    expect_eq(gc_match_o,      1'b0, "no_match_case_gc_low");
    expect_eq(allcall_match_o, 1'b0, "no_match_case_allcall_low");
    expect_eq(sub_match_o,     3'b000, "no_match_case_sub_low");
    expect_eq(regular_match_o, 1'b0, "no_match_case_regular_low");
    expect_eq(addr_match_o,    1'b0, "no_match_case_addr_match_low");

    // -------------------------------------------------------------------
    // 7. Simultaneous-match coincidence: ALLCALLADR programmed equal to
    //    the regular hw address -- both assert, addr_match_o still just
    //    a clean OR (Section 11: no priority resolution needed).
    // -------------------------------------------------------------------
    quiesce();
    hw_addr_i            = 6'h2A;
    active_allcalladr_i  = {1'b1, 6'h2A}; // same 7 bits as the regular address
    active_allcall_i     = 1'b1;
    addr7_i               = {1'b1, 6'h2A};
    #1;
    expect_eq(regular_match_o, 1'b1, "coincident_regular_still_matches");
    expect_eq(allcall_match_o, 1'b1, "coincident_allcall_still_matches");
    expect_eq(addr_match_o,    1'b1, "coincident_addr_match_still_high");

    if (errors == 0) begin
      $display("PASS: address_decode_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: address_decode_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout
  initial begin
    #1000000;
    $display("FAIL: address_decode_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
