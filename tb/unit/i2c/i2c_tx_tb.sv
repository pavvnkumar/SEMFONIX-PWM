// =============================================================================
// i2c_tx_tb.sv
//
// SEMFONIX-PWM I2C TX verification.
//
// Verifies:
//
//   1. Bare TX reset.
//   2. Bare MSB-first transfer.
//   3. Immediate disable/release.
//   4. Load while disabled.
//   5. 5,000 randomized TX bytes.
//
// Integration:
//
//   i2c_bus_sync
//       |
//       v
//   i2c_rx
//       |
//       +--> register_decode
//       |        |
//       |        v
//       |    register_bank
//       |
//       +--> i2c_tx
//
// The integration tests verify:
//
//   6. Single-byte write/readback.
//   7. Two-byte auto-increment readback.
//   8. Read/NACK followed by fresh write.
//
// IMPORTANT:
//
// The master leaves SDA released for a full SCL-low period before raising
// SCL for every read bit. This is required because the SEMFONIX register
// read path is synchronous:
//
//     rd_byte
//       -> register_decode
//       -> register_bank
//       -> rd_data
//       -> i2c_tx
//
// The DUT therefore has the complete SCL-low interval to prepare SDA.
// =============================================================================

`timescale 1ns/1ps

module i2c_tx_tb;

  localparam time CLK_PERIOD       = 10ns;
  localparam int HALF_BIT_CYCLES  = 20;
  localparam int HALF_BIT_BARE    = 6;

  localparam bit [6:0] HW_ADDR = 7'h15;

  localparam bit [7:0] ADDR_MODE1     = 8'h00;
  localparam bit [7:0] ADDR_LED0_ON_L = 8'h06;

  int errors = 0;
  int checks = 0;

  // ===========================================================================
  // CHECK HELPERS
  // ===========================================================================

  task automatic expect_eq(
    input logic [31:0] got,
    input logic [31:0] exp,
    input string tag
  );
    checks++;

    if (got !== exp) begin
      errors++;

      $display(
        "FAIL [%s]: got=0x%0h expected=0x%0h",
        tag,
        got,
        exp
      );
    end
    else begin
      $display(
        "PASS [%s]: 0x%0h",
        tag,
        got
      );
    end
  endtask


  task automatic expect_true(
    input logic cond,
    input string tag
  );
    checks++;

    if (cond !== 1'b1) begin
      errors++;
      $display(
        "FAIL [%s]: expected true",
        tag
      );
    end
    else begin
      $display(
        "PASS [%s]",
        tag
      );
    end
  endtask


  // ===========================================================================
  // CLOCK
  // ===========================================================================

  logic clk_ref;

  initial clk_ref = 1'b0;

  always #(CLK_PERIOD/2)
    clk_ref = ~clk_ref;

  logic rst_n;


  // ===========================================================================
  // BARE TX INSTANCE
  // ===========================================================================

  logic       bare_scl;
  logic       bare_tx_load;
  logic       bare_tx_drive_en;
  logic [7:0] bare_tx_data;
  logic       bare_sda_o;
  logic       bare_sda_oe;

  i2c_tx dut_bare (
    .clk_ref       (clk_ref),
    .rst_n         (rst_n),
    .scl_sync_i    (bare_scl),
    .tx_load_i     (bare_tx_load),
    .tx_drive_en_i (bare_tx_drive_en),
    .tx_data_i     (bare_tx_data),
    .sda_o         (bare_sda_o),
    .sda_oe        (bare_sda_oe)
  );


  // ===========================================================================
  // BARE TX CLOCKING
  // ===========================================================================

  task automatic bare_clock_bit(
    output bit sampled_bit
  );

    repeat (HALF_BIT_BARE)
      @(posedge clk_ref);

    bare_scl = 1'b1;

    repeat (HALF_BIT_BARE/2)
      @(posedge clk_ref);

    #1;

    sampled_bit = !bare_sda_oe;

    repeat (HALF_BIT_BARE/2)
      @(posedge clk_ref);

    bare_scl = 1'b0;

  endtask


  task automatic bare_reset();

    rst_n            = 1'b0;
    bare_scl         = 1'b1;
    bare_tx_load     = 1'b0;
    bare_tx_drive_en = 1'b0;
    bare_tx_data     = 8'h00;

    repeat (5)
      @(posedge clk_ref);

    rst_n = 1'b1;

    repeat (5)
      @(posedge clk_ref);

  endtask


  task automatic bare_shift_out_byte(
    input  logic [7:0] data,
    output logic [7:0] got
  );

    bit b;

    bare_tx_data = data;
    bare_tx_load = 1'b1;

    @(posedge clk_ref);

    bare_tx_load     = 1'b0;
    bare_tx_drive_en = 1'b1;

    got = 8'h00;

    for (int i = 7; i >= 0; i--) begin

      bare_clock_bit(b);

      got[i] = b;

    end

    bare_tx_drive_en = 1'b0;

  endtask


  // ===========================================================================
  // INTEGRATION BUS
  // ===========================================================================

  logic master_scl;
  logic master_sda_drive;
  logic master_sda_val;

  logic rx_sda_o;
  logic rx_sda_oe;

  logic tx_sda_o;
  logic tx_sda_oe;

  logic tx_drive_en;

  wire scl_line = master_scl;

  // During TX read-data phase, TX owns SDA.
  // Otherwise RX owns SDA for ACK generation.
  wire combined_sda_oe =
      tx_drive_en ? tx_sda_oe :
                    rx_sda_oe;

  wire sda_line =
      (master_sda_drive && !master_sda_val) ? 1'b0 :
      combined_sda_oe                       ? 1'b0 :
                                              1'b1;


  // ===========================================================================
  // BUS SYNCHRONIZER
  // ===========================================================================

  logic scl_sync;
  logic sda_sync;

  i2c_bus_sync bus_sync (
    .clk_ref    (clk_ref),
    .rst_n      (rst_n),
    .scl_i      (scl_line),
    .sda_i      (sda_line),
    .scl_sync_o (scl_sync),
    .sda_sync_o (sda_sync)
  );


  // ===========================================================================
  // ADDRESS DECODE
  // ===========================================================================

  logic [6:0] dut_addr7;
  logic       dut_rw;

  logic addr_match;
  logic gc_match;

  logic [2:0] unused_sub_match;
  logic       unused_allcall_match;
  logic       unused_regular_match;

  logic [6:0] tied_subadr [3];

  initial begin
    tied_subadr[0] = 7'h00;
    tied_subadr[1] = 7'h00;
    tied_subadr[2] = 7'h00;
  end


  address_decode addr_dec (
    .addr7_i             (dut_addr7),
    .rw_i                (dut_rw),
    .hw_addr_i           (HW_ADDR),
    .active_allcall_i    (1'b0),
    .active_subx_en_i    (3'b000),
    .active_allcalladr_i (7'h00),
    .active_subadr_i     (tied_subadr),
    .gc_match_o          (gc_match),
    .allcall_match_o     (unused_allcall_match),
    .sub_match_o         (unused_sub_match),
    .regular_match_o     (unused_regular_match),
    .addr_match_o        (addr_match)
  );


  // ===========================================================================
  // RX
  // ===========================================================================

  logic       ptr_set;
  logic       wr_byte;
  logic       rd_byte;

  logic [7:0] ptr_set_data;
  logic [7:0] wr_byte_data;

  logic       tx_load;

  logic       stop_event;
  logic       swrst_event;


  i2c_rx rx_dut (
    .clk_ref        (clk_ref),
    .rst_n          (rst_n),
    .scl_sync_i     (scl_sync),
    .sda_sync_i     (sda_sync),

    .sda_o          (rx_sda_o),
    .sda_oe         (rx_sda_oe),

    .addr7_o        (dut_addr7),
    .rw_o           (dut_rw),

    .addr_match_i   (addr_match),
    .gc_match_i     (gc_match),

    .ptr_set_o      (ptr_set),
    .ptr_set_data_o (ptr_set_data),

    .wr_byte_o      (wr_byte),
    .wr_byte_data_o (wr_byte_data),

    .rd_byte_o      (rd_byte),
    .tx_load_o      (tx_load),
    .tx_drive_en_o  (tx_drive_en),

    .stop_event_o   (stop_event),
    .swrst_o        (swrst_event)
  );


  // ===========================================================================
  // REGISTER DECODE
  // ===========================================================================

  logic [7:0] rb_addr;
  logic [7:0] rb_wdata;
  logic [7:0] rb_rdata;

  logic [7:0] rd_data;

  logic rb_wr_en;
  logic rb_rd_en;

  logic [7:0] ptr_val;

  logic ai_en;
  logic ack4_event;


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


  // ===========================================================================
  // REGISTER BANK
  // ===========================================================================

  register_bank rbank (
    .clk_ref             (clk_ref),
    .rst_n               (rst_n),

    .rb_wr_en            (rb_wr_en),
    .rb_rd_en            (rb_rd_en),
    .rb_addr             (rb_addr),
    .rb_wdata            (rb_wdata),
    .rb_rdata            (rb_rdata),

    .commit_pulse        (1'b0),
    .presc_write_allow_i (1'b1),

    .dirty_o             (),
    .group_update_req_o  (),
    .active_cfg_o        (),
    .active_prescale_o   (),
    .active_sleep_o      (),
    .active_ai_o         (ai_en),
    .active_allcall_o    (),
    .active_subx_en_o    (),
    .active_outne_o      (),
    .active_outdrv_o     (),
    .active_invrt_o      (),
    .active_och_o        (),
    .active_allcalladr_o (),
    .active_subadr_o     ()
  );


  // ===========================================================================
  // TX
  // ===========================================================================

  i2c_tx dut (
    .clk_ref       (clk_ref),
    .rst_n         (rst_n),

    .scl_sync_i    (scl_sync),

    .tx_load_i     (tx_load),
    .tx_drive_en_i (tx_drive_en),

    .tx_data_i     (rd_data),

    .sda_o         (tx_sda_o),
    .sda_oe        (tx_sda_oe)
  );


  // ===========================================================================
  // MASTER: SEND BIT
  // ===========================================================================

  task automatic m_send_bit(
    input bit val
  );

    master_sda_drive = 1'b1;
    master_sda_val   = val;

    // SCL LOW.
    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // SCL HIGH.
    master_scl = 1'b1;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // Return SCL LOW.
    master_scl = 1'b0;

  endtask


  // ===========================================================================
  // MASTER: SEND BYTE
  // ===========================================================================

  task automatic m_send_byte(
    input logic [7:0] data
  );

    for (int i = 7; i >= 0; i--)
      m_send_bit(data[i]);

  endtask


  // ===========================================================================
  // MASTER: READ ACK
  // ===========================================================================

  task automatic m_read_ack(
    output bit nack
  );

    master_sda_drive = 1'b0;

    // SCL LOW.
    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // SCL HIGH.
    master_scl = 1'b1;

    repeat (HALF_BIT_CYCLES/2)
      @(posedge clk_ref);

    #1;

    nack = sda_line;

    repeat (HALF_BIT_CYCLES/2)
      @(posedge clk_ref);

    master_scl = 1'b0;

  endtask


  // ===========================================================================
  // MASTER: ACK/NACK BIT
  // ===========================================================================

  task automatic m_send_ack_bit(
    input bit nack_val
  );

    m_send_bit(nack_val);

  endtask


  // ===========================================================================
  // MASTER: READ BYTE
  //
  // IMPORTANT:
  //
  // SDA is released while SCL is LOW for the COMPLETE low period before
  // every rising edge.
  //
  // This allows the synchronous SEMFONIX read pipeline to complete.
  // ===========================================================================

  task automatic m_read_byte(
    output logic [7:0] data,
    input bit master_nack
  );

    data = 8'h00;

    for (int i = 7; i >= 0; i--) begin

      // Master releases SDA before requesting the next data bit.
      master_sda_drive = 1'b0;

      // Complete SCL LOW period.
      repeat (HALF_BIT_CYCLES)
        @(posedge clk_ref);

      // Give one additional reference-clock edge for registered
      // read-data propagation before the sampling edge.
      @(posedge clk_ref);

      // SCL HIGH.
      master_scl = 1'b1;

      repeat (HALF_BIT_CYCLES/2)
        @(posedge clk_ref);

      #1;

      data[i] = sda_line;

      repeat (HALF_BIT_CYCLES/2)
        @(posedge clk_ref);

      // SCL LOW.
      master_scl = 1'b0;

    end

    // Master ACK/NACK after the complete byte.
    m_send_ack_bit(master_nack);

  endtask


  // ===========================================================================
  // MASTER: START
  // ===========================================================================

  task automatic m_start();

    // Bus idle.
    master_sda_drive = 1'b0;
    master_scl       = 1'b1;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // START: SDA HIGH -> LOW while SCL HIGH.
    master_sda_drive = 1'b1;
    master_sda_val   = 1'b0;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // Enter data phase.
    master_scl = 1'b0;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

  endtask


  // ===========================================================================
  // MASTER: STOP
  // ===========================================================================

  task automatic m_stop();

    // SDA LOW while SCL LOW.
    master_sda_drive = 1'b1;
    master_sda_val   = 1'b0;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // SCL HIGH.
    master_scl = 1'b1;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

    // STOP: SDA LOW -> HIGH while SCL HIGH.
    master_sda_drive = 1'b0;

    repeat (HALF_BIT_CYCLES)
      @(posedge clk_ref);

  endtask


  // ===========================================================================
  // MASTER: WRITE BYTE + ACK
  // ===========================================================================

  task automatic m_write_byte(
    input logic [7:0] data,
    output bit ack_ok
  );

    bit nack;

    m_send_byte(data);

    m_read_ack(nack);

    ack_ok = ~nack;

  endtask


  // ===========================================================================
  // RESET
  // ===========================================================================

  task automatic do_reset();

    rst_n            = 1'b0;

    master_scl       = 1'b1;
    master_sda_drive = 1'b0;
    master_sda_val   = 1'b1;

    repeat (5)
      @(posedge clk_ref);

    rst_n = 1'b1;

    repeat (10)
      @(posedge clk_ref);

  endtask


  // ===========================================================================
  // TEST SEQUENCE
  // ===========================================================================

  initial begin

    bit ack_ok;

    logic [7:0] got;
    logic [7:0] got2;


    // ========================================================================
    // TEST 1: BARE RESET
    // ========================================================================

    bare_reset();

    expect_eq(
      bare_sda_oe,
      1'b0,
      "bare_reset_sda_oe"
    );


    // ========================================================================
    // TEST 2: DIRECTED BYTE
    // ========================================================================

    bare_shift_out_byte(
      8'hA5,
      got
    );

    expect_eq(
      got,
      8'hA5,
      "bare_directed_byte_0xA5"
    );


    // ========================================================================
    // TEST 3: DISABLE MID-BYTE
    // ========================================================================

    bare_tx_data = 8'h00;

    bare_tx_load = 1'b1;

    @(posedge clk_ref);

    bare_tx_load     = 1'b0;
    bare_tx_drive_en = 1'b1;

    repeat (HALF_BIT_BARE)
      @(posedge clk_ref);

    bare_scl = 1'b1;

    repeat (HALF_BIT_BARE/2)
      @(posedge clk_ref);

    #1;

    expect_true(
      bare_sda_oe,
      "t3_driving_low_bit_before_disable"
    );

    bare_tx_drive_en = 1'b0;

    #1;

    expect_eq(
      bare_sda_oe,
      1'b0,
      "t3_disable_immediately_releases_bus"
    );

    repeat (HALF_BIT_BARE)
      @(posedge clk_ref);

    bare_scl = 1'b0;

    repeat (HALF_BIT_BARE)
      @(posedge clk_ref);

    bare_shift_out_byte(
      8'hFF,
      got
    );

    expect_eq(
      got,
      8'hFF,
      "t3_fresh_byte_after_interruption"
    );


    // ========================================================================
    // TEST 4: LOAD WHILE DISABLED
    // ========================================================================

    bare_tx_data     = 8'h80;
    bare_tx_drive_en = 1'b0;
    bare_tx_load     = 1'b1;

    @(posedge clk_ref);

    #1;

    expect_eq(
      bare_sda_oe,
      1'b0,
      "t4_no_drive_while_disabled_at_load"
    );

    bare_tx_load     = 1'b0;
    bare_tx_drive_en = 1'b1;

    #1;

    expect_eq(
      bare_sda_oe,
      1'b0,
      "t4_msb1_released_immediately_on_enable"
    );

    bare_tx_drive_en = 1'b0;

    repeat (2)
      @(posedge clk_ref);


    // ========================================================================
    // TEST 5: 5,000 RANDOMIZED BYTES
    // ========================================================================

    for (int iter = 0; iter < 5000; iter++) begin

      logic [7:0] rand_byte;

      rand_byte = $urandom_range(0, 255);

      bare_shift_out_byte(
        rand_byte,
        got
      );

      checks++;

      if (got !== rand_byte) begin

        errors++;

        $display(
          "FAIL [t5_random_iter_%0d]: got=0x%0h expected=0x%0h",
          iter,
          got,
          rand_byte
        );

      end

    end

    $display(
      "PASS [t5_random]: 5000 randomized bytes"
    );


    // ========================================================================
    // TEST 6: SINGLE BYTE READBACK
    // ========================================================================

    do_reset();

    m_start();

    m_write_byte(
      {HW_ADDR, 1'b0},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t6_write_address_acked"
    );

    m_write_byte(
      ADDR_LED0_ON_L,
      ack_ok
    );

    expect_true(
      ack_ok,
      "t6_pointer_acked"
    );

    m_write_byte(
      8'h3C,
      ack_ok
    );

    expect_true(
      ack_ok,
      "t6_data_acked"
    );

    m_stop();


    // Read transaction.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b1},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t6_read_address_acked"
    );

    m_read_byte(
      got,
      1'b1
    );

    expect_eq(
      got,
      8'h3C,
      "t6_readback_matches_written"
    );

    m_stop();


    // ========================================================================
    // TEST 7: TWO BYTE AUTO-INCREMENT READ
    // ========================================================================

    do_reset();

    // Enable MODE1.AI.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b0},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t7_mode1_address_acked"
    );

    m_write_byte(
      ADDR_MODE1,
      ack_ok
    );

    expect_true(
      ack_ok,
      "t7_mode1_pointer_acked"
    );

    m_write_byte(
      8'h20,
      ack_ok
    );

    expect_true(
      ack_ok,
      "t7_ai_write_acked"
    );

    m_stop();

    repeat (5)
      @(posedge clk_ref);

    expect_eq(
      ai_en,
      1'b1,
      "t7_ai_now_active"
    );


    // Write 0x11 and 0x22.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b0},
      ack_ok
    );

    m_write_byte(
      ADDR_LED0_ON_L,
      ack_ok
    );

    m_write_byte(
      8'h11,
      ack_ok
    );

    m_write_byte(
      8'h22,
      ack_ok
    );

    m_stop();


    // Read both bytes.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b1},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t7_read_address_acked"
    );

    m_read_byte(
      got,
      1'b0
    );

    m_read_byte(
      got2,
      1'b1
    );

    expect_eq(
      got,
      8'h11,
      "t7_first_byte_matches"
    );

    expect_eq(
      got2,
      8'h22,
      "t7_second_byte_matches_incremented_addr"
    );

    m_stop();


    // ========================================================================
    // TEST 8: READ/NACK FOLLOWED BY FRESH WRITE
    // ========================================================================

    do_reset();

    m_start();

    m_write_byte(
      {HW_ADDR, 1'b0},
      ack_ok
    );

    m_write_byte(
      ADDR_LED0_ON_L,
      ack_ok
    );

    m_write_byte(
      8'h99,
      ack_ok
    );

    m_stop();


    // Read and NACK.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b1},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t8_read_address_acked"
    );

    m_read_byte(
      got,
      1'b1
    );

    expect_eq(
      got,
      8'h99,
      "t8_readback_before_nack"
    );

    m_stop();


    // Fresh write after NACK.
    m_start();

    m_write_byte(
      {HW_ADDR, 1'b0},
      ack_ok
    );

    expect_true(
      ack_ok,
      "t8_fresh_write_after_nacked_read_still_acked"
    );

    m_write_byte(
      ADDR_LED0_ON_L,
      ack_ok
    );

    m_write_byte(
      8'h55,
      ack_ok
    );

    expect_true(
      ack_ok,
      "t8_fresh_write_data_acked"
    );

    m_stop();


    // ========================================================================
    // FINAL RESULT
    // ========================================================================

    $display("");
    $display("============================================================");
    $display("i2c_tx_tb COMPLETE");
    $display("Checks : %0d", checks);
    $display("Errors : %0d", errors);
    $display("============================================================");

    if (errors == 0) begin

      $display(
        "PASS: i2c_tx_tb - %0d checks, 0 errors",
        checks
      );

      $finish(0);

    end
    else begin

      $display(
        "FAIL: i2c_tx_tb - %0d checks, %0d errors",
        checks,
        errors
      );

      $fatal(1);

    end

  end


  // ===========================================================================
  // SAFETY TIMEOUT
  // ===========================================================================

  initial begin

    #10000000;

    $display(
      "FAIL: i2c_tx_tb - TIMEOUT"
    );

    $fatal(1);

  end

endmodule

