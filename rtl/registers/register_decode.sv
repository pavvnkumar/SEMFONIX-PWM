`timescale 1ns/1ps
`default_nettype none

// =============================================================================
// register_decode.sv
//
// I2C register-pointer / register-bus decoder.
//
// Transaction model:
//   ptr_set_i : load pointer directly; highest priority.
//   wr_byte_i : write current pointer address.
//   rd_byte_i : read current pointer address.
//   ai_en_i   : increment pointer AFTER a read/write transaction.
//
// ACK4:
//   Asserted while wr_byte_i is active and the CURRENT pointer is:
//     09, 0D, 11, 15, ... 45
//   or:
//     FD (ALL_LED_OFF_H)
//
// Read-data timing:
//   rb_rdata_i is combinationally generated from rb_addr_o. When AI is
//   enabled, ptr_q advances at the same clock edge that completes a
//   read transaction. Therefore rd_data_o must not simply follow
//   rb_rdata_i continuously, otherwise the read response can move to
//   the incremented address before i2c_tx.sv consumes it.
//
//   A read-data holding register captures the value associated with the
//   current pointer during rd_byte_i and keeps that value available to
//   the TX path until the next read.
//
// Architecture:
//   - pointer state remains in ptr_q
//   - register bus remains combinational
//   - AI pointer increment behavior is unchanged
//   - ACK4 remains combinational from the CURRENT pointer
//   - only the read-response timing is registered
// =============================================================================

module register_decode (
  input  logic clk_ref,
  input  logic rst_n,

  // ---------------------------------------------------------------------------
  // Byte-stream events from I2C RX
  // ---------------------------------------------------------------------------
  input  logic ptr_set_i,
  input  logic [7:0] ptr_set_data_i,

  input  logic wr_byte_i,
  input  logic [7:0] wr_byte_data_i,

  input  logic rd_byte_i,

  // ---------------------------------------------------------------------------
  // Active MODE1.AI
  // ---------------------------------------------------------------------------
  input  logic ai_en_i,

  // ---------------------------------------------------------------------------
  // Register bus
  // ---------------------------------------------------------------------------
  output logic [7:0] rb_addr_o,
  output logic       rb_wr_en_o,
  output logic       rb_rd_en_o,
  output logic [7:0] rb_wdata_o,

  // ---------------------------------------------------------------------------
  // Read response
  // ---------------------------------------------------------------------------
  input  logic [7:0] rb_rdata_i,
  output logic [7:0] rd_data_o,

  // ---------------------------------------------------------------------------
  // Shadow/active control
  // ---------------------------------------------------------------------------
  output logic ack4_event_o,

  // ---------------------------------------------------------------------------
  // Debug
  // ---------------------------------------------------------------------------
  output logic [7:0] ptr_o
);

  // ===========================================================================
  // Register-map constants
  // ===========================================================================

  localparam logic [7:0] ADDR_MODE1         = 8'h00;
  localparam logic [7:0] ADDR_LED_BASE      = 8'h06;
  localparam logic [7:0] ADDR_LED_LAST      = 8'h45;
  localparam logic [7:0] ADDR_ALL_LED_OFF_H = 8'hFD;
  localparam logic [7:0] ADDR_PRE_SCALE     = 8'hFE;

  // ===========================================================================
  // Pointer state
  // ===========================================================================

  logic [7:0] ptr_q;

  // ===========================================================================
  // Read-data holding register
  //
  // This is the important timing fix.
  //
  // rb_rdata_i represents the register selected by rb_addr_o/ptr_q.
  // rd_byte_i identifies the transaction for which that value belongs.
  //
  // Capture the current register-bank response before AI advances ptr_q.
  // The captured value then remains stable for i2c_tx.sv.
  // ===========================================================================

  logic [7:0] rd_data_q;

  // ===========================================================================
  // Pointer increment
  //
  // Normal addresses increment by one.
  //
  // 0x45 -> 0x00
  // 0xFE -> 0x00
  //
  // This intentionally prevents traversal into reserved 0xFF.
  // ===========================================================================

  function automatic logic [7:0] next_ptr_addr(
    input logic [7:0] addr
  );
    begin
      case (addr)

        ADDR_LED_LAST:
          next_ptr_addr = ADDR_MODE1;

        ADDR_PRE_SCALE:
          next_ptr_addr = ADDR_MODE1;

        default:
          next_ptr_addr = addr + 8'h01;

      endcase
    end
  endfunction

  // ===========================================================================
  // Fourth-byte / group-ending detector
  //
  // Each PWM channel occupies four registers:
  //
  //   +0 ON_L
  //   +1 ON_H
  //   +2 OFF_L
  //   +3 OFF_H
  //
  // Channel 0:
  //   06 07 08 09
  //
  // Channel 1:
  //   0A 0B 0C 0D
  //
  // ...
  //
  // Channel 15:
  //   42 43 44 45
  //
  // Therefore:
  //   (addr - 06) % 4 == 3
  //
  // FD is the broadcast ALL_LED_OFF_H equivalent.
  // ===========================================================================

  function automatic logic is_group_last_byte(
    input logic [7:0] addr
  );
    logic [7:0] led_offset;

    begin
      if ((addr >= ADDR_LED_BASE) &&
          (addr <= ADDR_LED_LAST)) begin

        led_offset = addr - ADDR_LED_BASE;

        is_group_last_byte =
          (led_offset[1:0] == 2'b11);

      end
      else if (addr == ADDR_ALL_LED_OFF_H) begin

        is_group_last_byte = 1'b1;

      end
      else begin

        is_group_last_byte = 1'b0;

      end
    end
  endfunction

  // ===========================================================================
  // Pointer register
  //
  // Priority:
  //
  //   1. ptr_set_i
  //   2. read/write with AI
  //   3. hold
  //
  // Pointer update occurs at the clock edge completing the current
  // transaction.
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin

      ptr_q <= ADDR_MODE1;

    end
    else begin

      if (ptr_set_i) begin

        ptr_q <= ptr_set_data_i;

      end
      else if (wr_byte_i || rd_byte_i) begin

        if (ai_en_i) begin
          ptr_q <= next_ptr_addr(ptr_q);
        end

      end

    end
  end

  // ===========================================================================
  // Read-data holding register
  //
  // IMPORTANT:
  //
  // rb_rdata_i is sampled while ptr_q still identifies the CURRENT
  // transaction address. Because both this register and ptr_q update
  // with nonblocking assignments, the RHS rb_rdata_i here corresponds
  // to the old/current ptr_q.
  //
  // Thus for:
  //
  //   ptr = 06, AI = 1
  //
  // the read captures register 06 into rd_data_q, while ptr_q advances
  // to 07. rd_data_q remains 06's value and is presented to TX.
  //
  // On the next rd_byte_i:
  //
  //   ptr = 07
  //
  // register 07 is captured and ptr advances to 08.
  //
  // This preserves the correct byte ordering for multi-byte AI reads.
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin

      rd_data_q <= 8'h00;

    end
    else if (rd_byte_i) begin

      rd_data_q <= rb_rdata_i;

    end

  end

  // ===========================================================================
  // Register-bus outputs
  //
  // Address and enables remain combinational and continue to represent
  // the CURRENT pointer exactly as before.
  // ===========================================================================

  always_comb begin

    rb_addr_o  = ptr_q;
    rb_wr_en_o = wr_byte_i;
    rb_rd_en_o = rd_byte_i;
    rb_wdata_o = wr_byte_data_i;

    // Registered read response.
    rd_data_o  = rd_data_q;

  end

  // ===========================================================================
  // ACK4
  //
  // ACK4 is intentionally combinational.
  //
  // It is based on:
  //   - current pointer
  //   - current write transaction
  //
  // NOT on the incremented pointer.
  // ===========================================================================

  always_comb begin

    ack4_event_o = 1'b0;

    if (wr_byte_i) begin
      ack4_event_o = is_group_last_byte(ptr_q);
    end

  end

  // ===========================================================================
  // Debug pointer output
  // ===========================================================================

  assign ptr_o = ptr_q;

endmodule

`default_nettype wire

