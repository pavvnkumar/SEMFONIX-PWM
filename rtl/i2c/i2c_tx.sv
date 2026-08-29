// =============================================================================
// i2c_tx.sv
//
// SEMFONIX-PWM I2C transmit-path (read-data) module.
//
// Owns:
//   - read-data shift register
//   - MSB-first byte shifting
//   - open-drain SDA data-bit drive
//
// IMPORTANT TIMING CONTRACT
// -------------------------
// i2c_rx generates tx_load_i together with rd_byte_o.
//
// register_decode receives rd_byte_o and updates tx_data_i (rd_data_o)
// synchronously. Therefore tx_load_i and the new tx_data_i occur on the
// SAME clk_ref edge.
//
// The TX must NOT capture tx_data_i on that same edge.
//
// Instead:
//
//   cycle N:
//       tx_load_i = 1
//       rd_byte_o = 1
//       register_decode schedules new rd_data
//
//   cycle N+1:
//       tx_data_i contains the requested read value
//       TX captures tx_data_i
//
// The first data bit is then driven while SCL is LOW, before the master
// samples SDA on the following SCL HIGH period.
//
// Bit timing:
//   - MSB is presented at shift_reg_q[7]
//   - data changes only while SCL is low
//   - each SCL falling edge advances to the next bit
//
// Open-drain semantics:
//   - data 0 -> sda_oe = 1, actively pull SDA low
//   - data 1 -> sda_oe = 0, release SDA
//   - sda_oe is always gated by tx_drive_en_i
// =============================================================================

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
      !scl_sync_i &&
       scl_sync_prev_q;


  // ===========================================================================
  // DELAYED TX LOAD
  //
  // tx_load_i is generated at the same clock edge that register_decode
  // captures rd_byte_i and updates rd_data_o.
  //
  // Therefore:
  //
  //     tx_load_i = 1  -> remember that a load is required
  //     next cycle     -> capture the now-valid tx_data_i
  //
  // This is the critical fix for the integration readback failures.
  // ===========================================================================

  logic tx_load_pending_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      tx_load_pending_q <= 1'b0;

    end
    else begin

      // A new request starts a pending load.
      if (tx_load_i) begin

        tx_load_pending_q <= 1'b1;

      end
      else begin

        // Pending request is consumed on the following clock.
        tx_load_pending_q <= 1'b0;

      end

    end

  end


  // ===========================================================================
  // TX SHIFT REGISTER
  // ===========================================================================

  logic [7:0] shift_reg_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      shift_reg_q <= 8'h00;

    end

    // Capture AFTER register_decode has had one clk_ref cycle to update
    // tx_data_i.
    else if (tx_load_pending_q) begin

      shift_reg_q <= tx_data_i;

    end

    // Advance to the next bit on SCL falling edges.
    else if (tx_drive_en_i && scl_fall) begin

      shift_reg_q <= {
        shift_reg_q[6:0],
        1'b0
      };

    end

  end


  // ===========================================================================
  // OPEN-DRAIN SDA DRIVE
  //
  // MSB remains stable throughout the SCL HIGH phase.
  //
  //   shift_reg_q[7] = 0 -> pull SDA LOW
  //   shift_reg_q[7] = 1 -> release SDA
  // ===========================================================================

  assign sda_o = 1'b0;

  assign sda_oe =
      tx_drive_en_i &&
      !shift_reg_q[7];

  `ifndef SYNTHESIS
    always @(posedge clk_ref) begin
      if (tx_load_i || tx_load_pending_q) begin
        $display(
          "[TX DEBUG] load=%b pending=%b enable=%b tx_data=0x%02h shift=0x%02h scl=%b",
          tx_load_i,
          tx_load_pending_q,
          tx_drive_en_i,
          tx_data_i,
          shift_reg_q,
          scl_sync_i
        );
      end
    end
  `endif

endmodule

`default_nettype wire

