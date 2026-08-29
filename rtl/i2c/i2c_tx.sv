// ============================================================================
// i2c_tx.sv
//
// SEMFONIX-PWM I2C transmit-path (read-data) module.
//
// Owns:
//   - read-data shift register
//   - MSB-first byte shifting
//   - open-drain SDA data-bit drive
//
// TIMING CONTRACT
// ---------------
// i2c_rx generates rd_byte_o first and intentionally delays tx_load_o.
//
//   cycle N:
//       rd_byte_o  = 1
//       register_decode captures rb_rdata_i
//       tx_load_i  = 0
//
//   cycle N+1:
//       tx_load_i  = 1
//       tx_data_i  = registered read value
//       TX captures tx_data_i
//
// The first data bit (MSB) must then be available while SCL is LOW and
// remain stable through the following SCL HIGH sampling interval.
//
// Bit timing:
//   - MSB is presented by shift_reg_q[7]
//   - data advances on SCL falling edges
//   - no data shifting occurs merely because TX is enabled
//
// Open-drain semantics:
//   - data 0 -> sda_oe = 1, actively pull SDA low
//   - data 1 -> sda_oe = 0, release SDA
//   - sda_oe is gated by tx_drive_en_i
// ============================================================================

`default_nettype none

module i2c_tx (
  input  logic clk_ref,
  input  logic rst_n,

  // Synchronized SCL from i2c_bus_sync.sv.
  input  logic scl_sync_i,

  // Control from i2c_rx.sv.
  input  logic       tx_load_i,
  input  logic       tx_drive_en_i,

  // Read-data byte from register_decode.sv.
  input  logic [7:0] tx_data_i,

  // Open-drain SDA contribution.
  output logic sda_o,
  output logic sda_oe
);

  // ===========================================================================
  // SCL FALLING-EDGE DETECTION
  // ===========================================================================

  logic scl_sync_prev_q;
  logic scl_fall;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n)
      scl_sync_prev_q <= 1'b1;
    else
      scl_sync_prev_q <= scl_sync_i;
  end

  assign scl_fall =
      scl_sync_prev_q &&
      !scl_sync_i;


  // ===========================================================================
  // TX SHIFT REGISTER
  // ===========================================================================
  //
  // tx_load_i is the ONLY event that loads a new read byte.
  //
  // This is intentionally independent of tx_drive_en_i and scl_fall.
  // tx_drive_en_i is a bus-drive qualification signal, not a load request.
  //
  // Once loaded:
  //
  //       shift_reg_q[7]
  //
  // is the first bit presented to SDA.
  //
  // Subsequent bits are advanced on SCL falling edges.
  //
  // Priority:
  //
  //   1. reset
  //   2. tx_load_i
  //   3. SCL falling edge while TX is enabled
  //
  // If tx_load_i and scl_fall happen on the same clk_ref edge, loading wins.
  // This prevents the newly loaded byte from being shifted immediately.
  // ===========================================================================

  logic [7:0] shift_reg_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      shift_reg_q <= 8'h00;

    end

    else if (tx_load_i) begin

      shift_reg_q <= tx_data_i;

    end

    else if (tx_drive_en_i && scl_fall) begin

      shift_reg_q <= {
        shift_reg_q[6:0],
        1'b0
      };

    end

  end


  // ===========================================================================
  // OPEN-DRAIN SDA DRIVE
  // ===========================================================================
  //
  // The current MSB is continuously presented while TX is enabled.
  //
  //   shift_reg_q[7] = 0 -> pull SDA LOW
  //   shift_reg_q[7] = 1 -> release SDA
  //
  // SDA is therefore stable throughout every SCL HIGH phase.
  //
  // sda_o is tied LOW because this interface represents an open-drain
  // contribution. The actual bus value is obtained externally through the
  // wired-AND/open-drain connection.
  // ===========================================================================

  assign sda_o = 1'b0;

  assign sda_oe =
      tx_drive_en_i &&
      !shift_reg_q[7];


  // ===========================================================================
  // DEBUG
  // ===========================================================================

  `ifndef SYNTHESIS

    always @(posedge clk_ref) begin

      if (tx_load_i) begin
        $display(
          "[TX DEBUG] TX LOAD: tx_load=%b enable=%b tx_data=0x%02h shift_before=0x%02h shift_after=0x%02h scl=%b",
          tx_load_i,
          tx_drive_en_i,
          tx_data_i,
          shift_reg_q,
          tx_data_i,
          scl_sync_i
        );
      end

      if (tx_drive_en_i && scl_fall && !tx_load_i) begin
        $display(
          "[TX DEBUG] SHIFT: shift_before=0x%02h shift_after=0x%02h scl=%b",
          shift_reg_q,
          {shift_reg_q[6:0], 1'b0},
          scl_sync_i
        );
      end

    end

  `endif

endmodule

`default_nettype wire



