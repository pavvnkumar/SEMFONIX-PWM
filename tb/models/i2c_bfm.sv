// =============================================================================
// i2c_bfm.sv
//
// Behavioral I2C master bus-functional model, per docs/MASTER_ARCHITECTURE.md
// Section 23 ("`tb/models/i2c_bfm.sv` (or a SystemVerilog class/`*.svh`) ...
// used by both unit-level I2C tests and the integration testbench"). This is
// step 13 of the Section 22 implementation order (first of two files closing
// out that step, alongside `pwm_ref_model.sv`).
//
// This module extracts and generalizes the bit-banged master task library
// every unit-level I2C testbench (`tb/unit/i2c/i2c_rx_tb.sv`,
// `tb/unit/i2c/i2c_tx_tb.sv`, `tb/unit/i2c/i2c_slave_tb.sv`) has been
// hand-rolling per-file up to this point, so `tb/integration/
// semfonix_pwm16_tb.sv` (this step's other new file) gets a single,
// register-level API instead of repeating byte/bit-level plumbing again.
// The existing unit tbs are NOT retrofitted to use this module -- per this
// repository's standing "don't touch already-complete, already-unit-tested
// files outside a step's own scope" practice (see e.g.
// `docs/IMPLEMENTATION_STATUS.md`'s Checkpoint 5 notes on
// `semfonix_pwm16_top.sv`), that refactor is out of scope here and is not
// planned; this file is new, additive infrastructure for the integration
// testbench only.
//
// Bus drive convention (matches the pattern already established by
// `i2c_rx_tb.sv`'s `master_scl`/`master_sda_drive`/`master_sda_val` and the
// wired-AND `sda_line` it computes at the call site):
//   - `scl_o` is driven DIRECTLY (not open-drain) by this module. This
//     matches Section 5.1's `scl_o`/`scl_oe` tie-off on the DUT side
//     ("reserved for clock stretching (unused v1, tie 1)") -- no slave in
//     this design ever stretches SCL, so the master fully owns SCL timing
//     and a plain driven output is sufficient. (A real open-drain SCL would
//     still combine safely with this signal at the instantiation site the
//     same way `sda_o`/`sda_oe` do below, since a tied-off `scl_oe=0` slave
//     never contests it -- this module does not preclude that, it simply
//     doesn't need it for this design.)
//   - `sda_drive_o`/`sda_val_o` follow the same open-drain convention used
//     everywhere else in this design (`sda_o`/`sda_oe` at the top level,
//     `master_sda_drive`/`master_sda_val` in the unit tbs): `sda_drive_o=1`
//     means "actively pulling the bus to `sda_val_o`"; `sda_drive_o=0`
//     means "released". The instantiating testbench is responsible for
//     wired-ANDing this against the DUT's own `sda_o`/`sda_oe` onto a single
//     resolved bus wire and feeding that resolved value back in as `sda_i`
//     (this module never resolves the bus itself, so it can be reused
//     against any DUT/child-driver combination without modification -- same
//     reasoning `i2c_bus_sync.sv`'s header gives for not resolving SCL/SDA
//     itself).
//
// Timing: `HALF_BIT_CYCLES` (default 20, matching every existing unit tb's
// `HALF_BIT_CYCLES` -- Section 7.2's stated `clk_ref >= 20*f_SCL_max`
// oversampling ratio) sets the half-bit-period in `clk_ref` cycles. Every
// task is entered and exited with `scl_o == 0`, exactly the invariant
// `i2c_rx_tb.sv`'s header already documents for its own hand-rolled tasks --
// preserved here so sequential task calls compose correctly with no extra
// bookkeeping at the call site.
//
// Register-level API (built on the byte/bit-level primitives below, new in
// this module -- no unit tb needed one before because they only ever
// exercised single addressed transactions by hand):
//   - `write_reg`    : one register, one transaction (ctrl byte + 1 data
//                      byte + STOP).
//   - `write_burst`  : N consecutive registers in one transaction (ctrl byte
//                      + N data bytes + STOP), relying on the DUT's own
//                      MODE1.AI auto-increment -- this task does NOT
//                      re-send the control byte between data bytes, so the
//                      caller is responsible for having AI enabled first if
//                      more than one byte is passed (matches real I2C
//                      master behavior -- this is not a testbench-only
//                      shortcut, it is the actual burst-write protocol
//                      shape the reference part expects, Fig. 6).
//   - `read_reg`     : write-pointer-then-repeated-START-read of exactly
//                      one register, master NACKs after the single byte
//                      (Fig. 6's read-termination convention).
//   - `read_burst`   : same repeated-START shape, master ACKs every byte
//                      except the last (again relies on AI being enabled by
//                      the caller for more than one byte).
//   - `general_call_swrst` : general-call address (`0000000`) + the
//                      SWRST data byte (`8'h06`, Section 7.6), + STOP.
// All register-level tasks use a fixed MAX_BURST_LEN=64-entry array (the
// largest any real transaction in this register map needs -- a full
// LED0..LED15 ON/OFF sweep is exactly 64 bytes) with an explicit `len`
// count, rather than a SystemVerilog dynamic array, matching this
// repository's established preference for plain fixed-size arrays over
// more advanced SV constructs (see e.g. `i2c_rx_tb.sv`'s
// `wr_hist_addr[0:15]`) for maximum Icarus Verilog `-g2012` portability.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module i2c_bfm #(
  parameter int HALF_BIT_CYCLES = 20
) (
  input  logic       clk_ref,

  // --- bus drive (see header for the open-drain/direct-drive convention) ---
  output logic       scl_o,
  output logic       sda_drive_o,
  output logic       sda_val_o,

  // --- resolved bus value, fed back in by the instantiating testbench
  //     after combining this module's sda_drive_o/sda_val_o with every
  //     slave's own sda_o/sda_oe on the shared net (see header) ---
  input  logic       sda_i
);

  localparam int MAX_BURST_LEN = 64;

  // ---------------------------------------------------------------------
  // Idle / initial drive state: released bus, SCL low (matches every
  // existing unit tb's own `master_scl = 1'b0; master_sda_drive = 1'b0;`
  // reset-time convention).
  // ---------------------------------------------------------------------
  initial begin
    scl_o       = 1'b0;
    sda_drive_o = 1'b0;
    sda_val_o   = 1'b0;
  end

  // ---------------------------------------------------------------------
  // Bit/byte-level primitives (direct generalization of i2c_rx_tb.sv's
  // m_send_bit/m_send_byte/m_read_ack/m_send_ack_bit/m_start/m_stop).
  // ---------------------------------------------------------------------
  task automatic idle_release();
    sda_drive_o = 1'b0;
    scl_o       = 1'b0;
  endtask

  task automatic send_bit(input bit val);
    sda_drive_o = 1'b1;
    sda_val_o   = val;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b0;
  endtask

  task automatic send_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) send_bit(data[i]);
  endtask

  // master releases SDA and samples the slave's ACK(0)/NACK(1) bit
  task automatic read_ack(output bit nack);
    sda_drive_o = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b1;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    nack = sda_i;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    scl_o = 1'b0;
  endtask

  // master drives ACK(0)/NACK(1) for a byte it is receiving (read path)
  task automatic send_ack_bit(input bit nack_val);
    send_bit(nack_val);
  endtask

  task automatic read_bit(output bit val);
    sda_drive_o = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b1;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    val = sda_i;
    repeat (HALF_BIT_CYCLES/2) @(posedge clk_ref);
    scl_o = 1'b0;
  endtask

  task automatic read_byte_raw(output logic [7:0] data);
    bit b;
    for (int i = 7; i >= 0; i--) begin
      read_bit(b);
      data[i] = b;
    end
  endtask

  task automatic start();
    sda_drive_o = 1'b0;   // release -> idles high
    scl_o       = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    sda_drive_o = 1'b1;
    sda_val_o   = 1'b0;   // falling edge while SCL high = START
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
  endtask

  task automatic stop();
    sda_drive_o = 1'b1;
    sda_val_o   = 1'b0;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    scl_o = 1'b1;
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
    sda_drive_o = 1'b0;   // release -> rising edge while SCL high = STOP
    repeat (HALF_BIT_CYCLES) @(posedge clk_ref);
  endtask

  task automatic write_byte(input logic [7:0] data, output bit ack_ok);
    bit nack;
    send_byte(data);
    read_ack(nack);
    ack_ok = ~nack;
  endtask

  // send_nack=1 -> master NACKs this byte (normal mid/last-byte-of-read
  // termination convention); send_nack=0 -> master ACKs (more bytes follow)
  task automatic read_byte(input bit send_nack, output logic [7:0] data);
    read_byte_raw(data);
    send_ack_bit(send_nack);
  endtask

  // ---------------------------------------------------------------------
  // Register-level API (see header).
  // ---------------------------------------------------------------------
  task automatic write_reg(
    input  logic [6:0] dev_addr7,
    input  logic [7:0] reg_addr,
    input  logic [7:0] data,
    output bit         ok
  );
    bit ack_addr, ack_ctrl, ack_data;
    start();
    write_byte({dev_addr7, 1'b0}, ack_addr);
    write_byte(reg_addr, ack_ctrl);
    write_byte(data, ack_data);
    stop();
    ok = ack_addr & ack_ctrl & ack_data;
  endtask

  task automatic write_burst(
    input  logic [6:0] dev_addr7,
    input  logic [7:0] reg_addr,
    input  logic [7:0] data [MAX_BURST_LEN],
    input  int         len,
    output bit         ok
  );
    bit ack_addr, ack_ctrl, ack_byte;
    ok = 1'b1;
    start();
    write_byte({dev_addr7, 1'b0}, ack_addr);
    ok = ok & ack_addr;
    write_byte(reg_addr, ack_ctrl);
    ok = ok & ack_ctrl;
    for (int i = 0; i < len; i++) begin
      write_byte(data[i], ack_byte);
      ok = ok & ack_byte;
    end
    stop();
  endtask

  task automatic read_reg(
    input  logic [6:0] dev_addr7,
    input  logic [7:0] reg_addr,
    output logic [7:0] data,
    output bit         ok
  );
    bit ack_addr, ack_ctrl, ack_raddr;
    start();
    write_byte({dev_addr7, 1'b0}, ack_addr);
    write_byte(reg_addr, ack_ctrl);
    start();  // repeated START
    write_byte({dev_addr7, 1'b1}, ack_raddr);
    read_byte(1'b1, data);  // single byte -> NACK to terminate
    stop();
    ok = ack_addr & ack_ctrl & ack_raddr;
  endtask

  task automatic read_burst(
    input  logic [6:0] dev_addr7,
    input  logic [7:0] reg_addr,
    input  int         len,
    output logic [7:0] data [MAX_BURST_LEN],
    output bit         ok
  );
    bit ack_addr, ack_ctrl, ack_raddr;
    start();
    write_byte({dev_addr7, 1'b0}, ack_addr);
    write_byte(reg_addr, ack_ctrl);
    start();  // repeated START
    write_byte({dev_addr7, 1'b1}, ack_raddr);
    for (int i = 0; i < len; i++) begin
      read_byte((i == len - 1) ? 1'b1 : 1'b0, data[i]);  // NACK only the last byte
    end
    stop();
    ok = ack_addr & ack_ctrl & ack_raddr;
  endtask

  task automatic general_call_swrst(output bit ok);
    bit ack_addr, ack_data;
    start();
    write_byte(8'h00, ack_addr);   // general-call address, W
    write_byte(8'h06, ack_data);   // SWRST data byte (Section 7.6)
    stop();
    ok = ack_addr & ack_data;
  endtask

endmodule

`default_nettype wire
