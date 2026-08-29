// =============================================================================
// i2c_slave_tb.sv
//
// Self-checking unit testbench for rtl/i2c/i2c_slave.sv (Checkpoint 4,
// step 10 of Section 22's implementation order -- "next task" per
// docs/IMPLEMENTATION_STATUS.md at the time this file was written:
// "rtl/i2c/i2c_slave.sv + its unit tb -- next task ... Closes out
// Checkpoint 4").
//
// i2c_slave.sv is a pure wiring wrapper around three already-unit-tested
// children (i2c_bus_sync.sv, i2c_rx.sv, i2c_tx.sv) -- this testbench does
// NOT re-derive their internal correctness (spike-filter algorithm,
// shift-register bit timing, etc. are already exhaustively covered by
// i2c_bus_sync_tb.sv/i2c_rx_tb.sv/i2c_tx_tb.sv). Its job is to prove the
// WIRING ITSELF is correct: that this module's sda_o/sda_oe mux on
// tx_drive_en correctly reproduces the exact manual mux
// tb/unit/i2c/i2c_tx_tb.sv's integration group previously performed by
// hand (`combined_sda_oe = tx_drive_en ? tx_sda_oe : rx_sda_oe`) as a
// stand-in for this not-yet-built module, that addr7_o/rw_o/
// addr_match_i/gc_match_i correctly connect a real sibling
// address_decode.sv (proving the general-call path specifically, since
// that is the one place gc_match_i feeds a real FSM branch decision), that
// the byte-stream event contract reaches a real sibling register_decode.sv
// + register_bank.sv unchanged, and that SPIKE_FILTER_CYCLES/
// I2C_TIMEOUT_CYCLES actually reach the internal i2c_rx.sv instance.
//
// Single DUT grouping (no bare-instance group needed -- unlike
// i2c_rx_tb.sv/i2c_tx_tb.sv, there is no isolated sub-property of this
// module to test without its children, since the module IS the wiring):
// one real i2c_slave DUT plus real address_decode.sv + register_decode.sv
// + register_bank.sv (the same three top-level siblings
// docs/MASTER_ARCHITECTURE.md Section 4 places beside i2c_slave.sv),
// driven by the same behavioral bit-banged I2C master task library used
// throughout tb/unit/i2c/*.sv, plus a second, separate i2c_slave instance
// (`dut_to`) with a small I2C_TIMEOUT_CYCLES override to prove parameter
// passthrough.
//
// Verifies:
//   1. Reset state: sda_oe/stop_event_o/swrst_o all deasserted.
//   2. Address mismatch -> NACK, bus recovers cleanly.
//   3. Single-byte write into real register_bank storage, then read back
//      over a real I2C read transaction -- exercising the full write path
//      (i2c_slave -> register_decode -> register_bank) and the full read
//      path (register_bank -> register_decode.rd_data_o -> i2c_slave's
//      tx_data_i -> internal i2c_tx -> the sda_o/sda_oe mux) end to end.
//   4. Two-byte MODE1.AI auto-incrementing read (master ACKs the first
//      byte, NACKs the second) against two independently-written register
//      values at consecutive addresses -- proves the mux tracks
//      tx_drive_en correctly across multiple bytes within one
//      transaction, not just a single byte.
//   5. stop_event_o pulses exactly once per real STOP condition.
//   6. General-call SWRST: correct data byte (0x06) is ACKed and
//      swrst_o pulses on the following STOP (not the ACK); a malformed
//      data byte is NOT ACKed and swrst_o never pulses. This specifically
//      exercises the addr7_o/rw_o -> (real) address_decode -> gc_match_i
//      round trip, which only exists as an external loop now that
//      address_decode is correctly wired as this module's sibling rather
//      than a child.
//   7. Immediate-NACK single-byte read leaves the bus/mux cleanly
//      released, confirmed by a subsequent fresh write transaction still
//      ACKing correctly.
//   8. I2C_TIMEOUT_CYCLES parameter passthrough: a second i2c_slave
//      instance (`dut_to`) built with a small timeout value recovers from
//      a stuck-low SCL mid-transaction, proving the parameter genuinely
//      reaches the internal i2c_rx.sv rather than being silently dropped
//      by this wrapper's port list.
//
// Run with (once a toolchain is available):
//   iverilog -g2012 -o i2c_slave_tb \
//     rtl/i2c/i2c_bus_sync.sv rtl/i2c/i2c_rx.sv rtl/i2c/i2c_tx.sv \
//     rtl/i2c/i2c_slave.sv rtl/registers/address_decode.sv \
//     rtl/registers/register_decode.sv rtl/registers/register_bank.sv \
//     tb/unit/i2c/i2c_slave_tb.sv
//   vvp i2c_slave_tb
// =============================================================================

`timescale 1ns/1ps

module i2c_slave_tb;

  localparam time CLK_PERIOD      = 10ns;
  localparam int  HALF_BIT_CYCLES = 20;

  localparam bit [5:0] HW_ADDR = 6'h15;  // regular address = 7'b1_010101 = 7'h55

  localparam bit [7:0] ADDR_MODE1     = 8'h00;
  localparam bit [7:0] ADDR_LED0_ON_L = 8'h06;

  int errors = 0;
  int checks = 0;

  task automatic expect_eq(input logic [31:0] got, input logic [31:0] exp, input string tag);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("FAIL [%s]: got=0x%0h expected=0x%0h", tag, got, exp);
    end
  endtask

  task automatic expect_true(input logic cond, input string tag);
    checks++;
    if (cond !== 1'b1) begin
      errors++;
      $display("FAIL [%s]: expected true", tag);
    end
  endtask

  // ---------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------
  logic clk_ref;
  initial clk_ref = 1'b0;
  always #(CLK_PERIOD/2) clk_ref = ~clk_ref;

  logic rst_n;

  // =======================================================================
  // Main integration group: i2c_slave DUT + real address_decode +
  // register_decode + register_bank siblings (Section 4 hierarchy).
  // =======================================================================
  logic master_scl;
  logic master_sda_drive;
  logic master_sda_val;

  logic slave_sda_o, slave_sda_oe;

  wire scl_line = master_scl;
  wire sda_line = (master_sda_drive && !master_sda_val) ? 1'b0
                 : slave_sda_oe                          ? 1'b0
                 : 1'b1;

  logic [6:0] dut_addr7;
  logic       dut_rw;
  logic       addr_match, gc_match;
  logic [2:0] unused_sub_match;
  logic       unused_allcall_match, unused_regular_match;

  logic [6:0] tied_subadr [3];
  initial begin
    tied_subadr[0] = 7'h00;
    tied_subadr[1] = 7'h00;
    tied_subadr[2] = 7'h00;
  end

  address_decode addr_dec (
    .addr7_i             (dut_addr7),
    .rw_i                (dut_rw),
    .hw_addr_i            (HW_ADDR),
    .active_allcall_i     (1'b0),
    .active_subx_en_i     (3'b000),
    .active_allcalladr_i  (7'h00),
    .active_subadr_i      (tied_subadr),
    .gc_match_o           (gc_match),
    .allcall_match_o      (unused_allcall_match),
    .sub_match_o          (unused_sub_match),
    .regular_match_o      (unused_regular_match),
    .addr_match_o         (addr_match)
  );

  logic       ptr_set, wr_byte, rd_byte;
  logic [7:0] ptr_set_data, wr_byte_data;
  logic [7:0] rd_data;
  logic       stop_event, swrst_event;

  i2c_slave dut (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),
    .scl_i          (scl_line),
    .sda_i          (sda_line),
    .sda_o          (),           // tied 0 by construction (open-drain); unused
    .sda_oe         (slave_sda_oe),
    .addr7_o        (dut_addr7),
    .rw_o           (dut_rw),
    .addr_match_i   (addr_match),
    .gc_match_i     (gc_match),
    .ptr_set_o      (ptr_set),
    .ptr_set_data_o (ptr_set_data),
    .wr_byte_o      (wr_byte),
    .wr_byte_data_o (wr_byte_data),
    .rd_byte_o      (rd_byte),
    .tx_data_i      (rd_data),
    .stop_event_o   (stop_event),
    .swrst_o        (swrst_event)
  );

  logic [7:0] rb_addr, rb_wdata, rb_rdata;
  logic       rb_wr_en, rb_rd_en;
  logic [7:0] ptr_val;
  logic       ai_en, ack4_event;

  register_decode rdec (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),
    .ptr_set_i      (ptr_set),
    .ptr_set_data_i (ptr_set_data),
    .wr_byte_i      (wr_byte),
    .wr_byte_data_i (wr_byte_data),
    .rd_byte_i      (rd_byte),
    .ai_en_i        (ai_en),
    .rb_addr_o      (rb_addr),
    .rb_wr_en_o     (rb_wr_en),
    .rb_rd_en_o     (rb_rd_en),
    .rb_wdata_o     (rb_wdata),
    .rb_rdata_i     (rb_rdata),
    .rd_data_o      (rd_data),
    .ack4_event_o   (ack4_event),
    .ptr_o          (ptr_val)
  );

  register_bank rbank (
    .clk_ref              (clk_ref),
    .rst_n                (rst_n),
    .rb_wr_en             (rb_wr_en),
    .rb_rd_en             (rb_rd_en),
    .rb_addr              (rb_addr),
    .rb_wdata             (rb_wdata),
    .rb_rdata             (rb_rdata),
    .commit_pulse         (1'b0),
    .presc_write_allow_i  (1'b1),
    .dirty_o              (),
    .group_update_req_o   (),
    .active_cfg_o         (),
    .active_prescale_o    (),
    .active_sleep_o       (),
    .active_ai_o          (ai_en),
    .active_allcall_o     (),
    .active_subx_en_o     (),
    .active_outne_o       (),
    .active_outdrv_o      (),
    .active_invrt_o       (),
    .active_och_o         (),
    .active_allcalladr_o  (),
    .active_subadr_o      ()
  );

  // stop/swrst pulse-catch monitor (accumulate-until-cleared)
  logic stop_seen, swrst_seen;
  int   stop_count;

  always @(posedge clk_ref) begin
    if (stop_event)  begin stop_seen  <= 1'b1; stop_count <= stop_count + 1; end
    if (swrst_event) swrst_seen <= 1'b1;
  end

  task automatic clear_event_monitors();
    stop_seen  = 1'b0;
    swrst_seen = 1'b0;
    stop_count = 0;
  endtask

  // ---------------------------------------------------------------------
  // Behavioral I2C master (bit-banged) -- same task shapes used throughout
  // tb/unit/i2c/*.sv. Invariant: every task is entered/exited with
  // master_scl == 0.
  // ---------------------------------------------------------------------
  task automatic m_send_bit(input bit val);
    master_sda_drive = 1'b1;
    master_sda_val   = val;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b0;
  endtask

  task automatic m_send_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) m_send_bit(data[i]);
  endtask

  task automatic m_read_ack(output bit nack);
    master_sda_drive = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b1;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    nack = sda_line;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    master_scl = 1'b0;
  endtask

  task automatic m_send_ack_bit(input bit nack_val);
    m_send_bit(nack_val);
  endtask

  task automatic m_read_byte(output logic [7:0] data, input bit master_nack);
    data = 8'h00;
    for (int i = 7; i >= 0; i--) begin
      master_sda_drive = 1'b0;
      repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
      master_scl = 1'b1;
      repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
      #1;
      data[i] = sda_line;
      repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
      master_scl = 1'b0;
    end
    m_send_ack_bit(master_nack);
  endtask

  task automatic m_start();
    master_sda_drive = 1'b0;
    master_scl       = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_sda_drive = 1'b1;
    master_sda_val   = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
  endtask

  task automatic m_stop();
    master_sda_drive = 1'b1;
    master_sda_val   = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_scl = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    master_sda_drive = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
  endtask

  task automatic m_write_byte(input logic [7:0] data, output bit ack_ok);
    bit nack;
    m_send_byte(data);
    m_read_ack(nack);
    ack_ok = ~nack;
  endtask

  task automatic do_reset();
    rst_n            = 1'b0;
    master_scl       = 1'b1;
    master_sda_drive = 1'b0;
    clear_event_monitors();
    repeat (5) @(posedge clk_ref);
    rst_n = 1'b1;
    repeat (5) @(posedge clk_ref);
  endtask

  // =======================================================================
  // Second i2c_slave instance: I2C_TIMEOUT_CYCLES parameter passthrough
  // (Test 8). Fully independent bus/master signals -- never driven
  // together with the main DUT's bus.
  // =======================================================================
  localparam int TIMEOUT_CYCLES = 40;

  logic to_scl, to_sda_drive, to_sda_val;
  logic to_sda_oe;
  wire  to_scl_line = to_scl;
  wire  to_sda_line = (to_sda_drive && !to_sda_val) ? 1'b0
                     : to_sda_oe                     ? 1'b0
                     : 1'b1;

  i2c_slave #(
    .SPIKE_FILTER_CYCLES (2),
    .I2C_TIMEOUT_CYCLES  (TIMEOUT_CYCLES)
  ) dut_to (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),
    .scl_i          (to_scl_line),
    .sda_i          (to_sda_line),
    .sda_o          (),
    .sda_oe         (to_sda_oe),
    .addr7_o        (),
    .rw_o           (),
    .addr_match_i   (1'b1),   // always "matches": isolates the timeout property alone
    .gc_match_i     (1'b0),
    .ptr_set_o      (),
    .ptr_set_data_o (),
    .wr_byte_o      (),
    .wr_byte_data_o (),
    .rd_byte_o      (),
    .tx_data_i      (8'h00),
    .stop_event_o   (),
    .swrst_o        ()
  );

  // Bit-bang helpers for dut_to's raw scl_i/sda_i pins (this instance
  // includes a real i2c_bus_sync internally, unlike i2c_rx_tb.sv's bare
  // dut_timeout which drove scl_sync_i/sda_sync_i directly -- so these
  // helpers drive the actual top-level-shaped pins, one level further out,
  // mirroring i2c_rx_tb.sv's b_start/b_send_bit/b_send_byte shape).
  task automatic to_send_bit(input bit val);
    to_sda_drive = 1'b1;
    to_sda_val   = val;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    to_scl = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    to_scl = 1'b0;
  endtask

  task automatic to_send_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) to_send_bit(data[i]);
  endtask

  task automatic to_start();
    to_sda_drive = 1'b0;
    to_scl       = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    to_scl = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    to_sda_drive = 1'b1;
    to_sda_val   = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    to_scl = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
  endtask

  // =======================================================================
  // Test sequence
  // =======================================================================
  initial begin
    bit ack_ok;
    logic [7:0] got, got2;

    // --- Test 1: reset state ---
    do_reset();
    expect_eq(slave_sda_oe, 1'b0, "reset_sda_oe");
    expect_eq(stop_event,   1'b0, "reset_stop_event");
    expect_eq(swrst_event,  1'b0, "reset_swrst_event");

    // --- Test 2: address mismatch -> NACK, bus recovers ---
    m_start();
    m_write_byte({1'b1, 6'h3F, 1'b0}, ack_ok);   // wrong address
    expect_eq(ack_ok, 1'b0, "t2_mismatch_nacked");
    m_stop();

    // --- Test 3: single-byte write + real I2C readback ---
    do_reset();
    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);   // address + W
    expect_eq(ack_ok, 1'b1, "t3_addr_acked");
    m_write_byte(ADDR_LED0_ON_L, ack_ok);          // control/pointer byte
    expect_eq(ack_ok, 1'b1, "t3_ctrl_acked");
    m_write_byte(8'h3C, ack_ok);                   // data byte
    expect_eq(ack_ok, 1'b1, "t3_data_acked");
    m_stop();

    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b1}, ack_ok);   // address + R
    expect_eq(ack_ok, 1'b1, "t3_read_addr_acked");
    m_read_byte(got, 1'b1);                        // NACK: single-byte read
    expect_eq(got, 8'h3C, "t3_readback_matches_written");
    m_stop();

    // --- Test 4: two-byte auto-incrementing read ---
    do_reset();
    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);
    m_write_byte(ADDR_MODE1, ack_ok);
    m_write_byte(8'h20, ack_ok);   // AI=1 (bit5)
    expect_eq(ack_ok, 1'b1, "t4_ai_write_acked");
    m_stop();
    repeat (5) @(posedge clk_ref); #1;
    expect_eq(ai_en, 1'b1, "t4_ai_now_active");

    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);
    m_write_byte(ADDR_LED0_ON_L, ack_ok);
    m_write_byte(8'h11, ack_ok);
    m_write_byte(8'h22, ack_ok);
    m_stop();

    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b1}, ack_ok);
    expect_eq(ack_ok, 1'b1, "t4_read_addr_acked");
    m_read_byte(got,  1'b0);   // ACK: continue reading
    m_read_byte(got2, 1'b1);   // NACK: end after 2nd byte
    expect_eq(got,  8'h11, "t4_first_byte_matches");
    expect_eq(got2, 8'h22, "t4_second_byte_matches_incremented_addr");
    m_stop();

    // --- Test 5: stop_event_o pulses exactly once per STOP ---
    do_reset();
    clear_event_monitors();
    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);
    m_write_byte(ADDR_LED0_ON_L, ack_ok);
    m_write_byte(8'h01, ack_ok);
    m_stop();
    repeat (3) @(posedge clk_ref);
    expect_eq(stop_count, 1, "t5_exactly_one_stop_pulse");

    // --- Test 6: general-call SWRST, correct sequence (exercises the
    //     addr7_o/rw_o -> real address_decode -> gc_match_i round trip) ---
    do_reset();
    clear_event_monitors();
    m_start();
    m_write_byte(8'h00, ack_ok);           // general-call address + W
    expect_eq(ack_ok, 1'b1, "t6_gc_addr_acked");
    m_write_byte(8'h06, ack_ok);           // correct SWRST data byte
    expect_eq(ack_ok, 1'b1, "t6_swrst_data_acked");
    expect_eq(swrst_seen, 1'b0, "t6_swrst_not_yet_on_ack");
    m_stop();
    expect_true(swrst_seen, "t6_swrst_pulses_on_stop");

    // --- Test 6b: general-call, malformed data byte -> no ACK, no swrst ---
    do_reset();
    clear_event_monitors();
    m_start();
    m_write_byte(8'h00, ack_ok);
    m_write_byte(8'h07, ack_ok);           // wrong SWRST data byte
    expect_eq(ack_ok, 1'b0, "t6b_bad_swrst_data_not_acked");
    m_stop();
    expect_eq(swrst_seen, 1'b0, "t6b_no_swrst_on_malformed_sequence");

    // --- Test 7: immediate-NACK read leaves the mux clean for a fresh
    //     write transaction ---
    do_reset();
    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);
    m_write_byte(ADDR_LED0_ON_L, ack_ok);
    m_write_byte(8'h99, ack_ok);
    m_stop();

    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b1}, ack_ok);
    m_read_byte(got, 1'b1);   // immediate NACK
    expect_eq(got, 8'h99, "t7_readback_before_nack");
    m_stop();

    m_start();
    m_write_byte({1'b1, HW_ADDR, 1'b0}, ack_ok);
    expect_eq(ack_ok, 1'b1, "t7_fresh_write_after_nacked_read_still_acked");
    m_write_byte(ADDR_LED0_ON_L, ack_ok);
    m_write_byte(8'h55, ack_ok);
    expect_eq(ack_ok, 1'b1, "t7_fresh_write_data_acked");
    m_stop();

    // --- Test 8: I2C_TIMEOUT_CYCLES parameter passthrough on the second
    //     (dut_to) instance -- a stuck-low SCL mid-byte is force-recovered
    //     to IDLE after TIMEOUT_CYCLES, proven by a subsequent fresh
    //     transaction ACKing correctly rather than one bit early/late
    //     (mirrors i2c_rx_tb.sv's own Test 8 shape, one level further out
    //     at the raw scl_i/sda_i pins instead of scl_sync_i/sda_sync_i,
    //     since this instance's i2c_bus_sync sits between the two). ---
    begin
      rst_n        = 1'b0;
      to_scl       = 1'b1;
      to_sda_drive = 1'b0;
      repeat (5) @(posedge clk_ref);
      rst_n = 1'b1;
      repeat (5) @(posedge clk_ref);

      // START, then only ONE address bit clocked in, leaving the FSM
      // mid-byte (bit_cnt_q == 1) with SCL held low indefinitely -- long
      // enough to cross TIMEOUT_CYCLES plus this instance's internal
      // bus_sync + spike-filter latency before scl_filt_q itself reads low.
      to_start();
      to_send_bit(1'b1);   // one bit only; leaves SCL low after (invariant)
      repeat (TIMEOUT_CYCLES + 20) @(posedge clk_ref);
      expect_eq(to_sda_oe, 1'b0, "t8_timeout_forced_idle_no_stray_drive");

      // Fresh START + a full, correctly-timed 8-bit address byte. If the
      // timeout had NOT reset the bit counter, byte_complete would fire
      // one bit early (stale bit_cnt_q==1 carried in) and this ACK would
      // land in the wrong bit-time / never assert during the correct one.
      to_start();
      to_send_byte(8'hFF);   // value irrelevant: addr_match_i tied 1'b1
      repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
      to_scl = 1'b1;
      repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
      #1;
      expect_true(to_sda_oe, "t8_post_timeout_fresh_byte_acked_on_time");
      repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
      to_scl = 1'b0;
    end

    // ---------------------------------------------------------------
    if (errors == 0) begin
      $display("PASS: i2c_slave_tb - %0d checks, 0 errors", checks);
      $finish(0);
    end else begin
      $display("FAIL: i2c_slave_tb - %0d checks, %0d errors", checks, errors);
      $fatal(1);
    end
  end

  // safety timeout
  initial begin
    #10000000;
    $display("FAIL: i2c_slave_tb - TIMEOUT");
    $fatal(1);
  end

endmodule
