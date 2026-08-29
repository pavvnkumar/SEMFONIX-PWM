// =============================================================================
// i2c_rx.sv
//
// SEMFONIX-PWM I2C receive/protocol engine.
//
// Responsibilities:
//   - Filter synchronized SCL/SDA inputs
//   - Detect START / repeated START / STOP
//   - Receive I2C address + R/W
//   - Generate address ACK/NACK
//   - Receive register pointer byte
//   - Receive write data bytes
//   - Receive general-call SWRST command
//   - Generate registered protocol events
//   - Optional SCL-low timeout recovery
//
// Event contract:
//
//   ptr_set_o      : one-cycle pulse when register pointer byte is received
//   ptr_set_data_o : pointer value associated with ptr_set_o
//
//   wr_byte_o      : one-cycle pulse when write-data byte is received
//   wr_byte_data_o : data value associated with wr_byte_o
//
//   rd_byte_o      : one-cycle read transaction request. This is consumed by
//                    register_decode.sv to capture the register-bank response.
//
//   tx_load_o      : one-cycle pulse to i2c_tx.sv requesting that the
//                    already-captured read response be loaded.
//
// IMPORTANT READ TIMING:
//
//   rd_byte_o and tx_load_o are intentionally NOT asserted in the same
//   clk_ref cycle.
//
//   On the first falling edge of SCL for a read byte:
//
//       rd_byte_o  = 1
//       tx_load_o  = 0
//
//   register_decode.sv captures rb_rdata_i into rd_data_q on that clock.
//
//   On the following clk_ref cycle:
//
//       rd_byte_o  = 0
//       tx_load_o  = 1
//
//   i2c_tx.sv therefore sees the newly registered rd_data_o.
//
//   This one-cycle separation is required because register_decode.sv now
//   owns a registered read-response holding register. Without this separation,
//   i2c_tx would capture the previous read-data value.
//
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module i2c_rx #(
  parameter int SPIKE_FILTER_CYCLES = 2,
  parameter int I2C_TIMEOUT_CYCLES  = 0
) (
  input  logic clk_ref,
  input  logic rst_n,

  // Already synchronized SCL/SDA inputs.
  input  logic scl_sync_i,
  input  logic sda_sync_i,

  // Open-drain SDA output.
  output logic sda_o,
  output logic sda_oe,

  // Received address.
  output logic [6:0] addr7_o,
  output logic       rw_o,

  // Address qualification from external address decoder.
  input  logic       addr_match_i,
  input  logic       gc_match_i,

  // Register pointer event.
  output logic       ptr_set_o,
  output logic [7:0] ptr_set_data_o,

  // Write-data event.
  output logic       wr_byte_o,
  output logic [7:0] wr_byte_data_o,

  // Read-data request / TX interface.
  output logic       rd_byte_o,
  output logic       tx_load_o,
  output logic       tx_drive_en_o,

  // Protocol events.
  output logic       stop_event_o,
  output logic       swrst_o
);

  // ===========================================================================
  // PARAMETERS
  // ===========================================================================

  localparam int FILTER_CYCLES =
      (SPIKE_FILTER_CYCLES < 1) ? 1 : SPIKE_FILTER_CYCLES;

  localparam int unsigned FILTER_LAST_INT =
      FILTER_CYCLES - 1;

  localparam bit TIMEOUT_EN =
      (I2C_TIMEOUT_CYCLES > 0);

  localparam int unsigned TIMEOUT_LIMIT_INT =
      (I2C_TIMEOUT_CYCLES > 0) ? I2C_TIMEOUT_CYCLES : 1;

  // ===========================================================================
  // INPUT FILTERING
  // ===========================================================================

  logic        scl_filt_q;
  logic        sda_filt_q;

  logic [31:0] scl_stable_cnt_q;
  logic [31:0] sda_stable_cnt_q;

  // ---------------------------------------------------------------------------
  // SCL filter
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin

      scl_filt_q       <= 1'b1;
      scl_stable_cnt_q <= 32'd0;

    end
    else if (scl_sync_i == scl_filt_q) begin

      scl_stable_cnt_q <= 32'd0;

    end
    else if (scl_stable_cnt_q >= FILTER_LAST_INT) begin

      scl_filt_q       <= scl_sync_i;
      scl_stable_cnt_q <= 32'd0;

    end
    else begin

      scl_stable_cnt_q <= scl_stable_cnt_q + 32'd1;

    end
  end

  // ---------------------------------------------------------------------------
  // SDA filter
  // ---------------------------------------------------------------------------

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin

      sda_filt_q       <= 1'b1;
      sda_stable_cnt_q <= 32'd0;

    end
    else if (sda_sync_i == sda_filt_q) begin

      sda_stable_cnt_q <= 32'd0;

    end
    else if (sda_stable_cnt_q >= FILTER_LAST_INT) begin

      sda_filt_q       <= sda_sync_i;
      sda_stable_cnt_q <= 32'd0;

    end
    else begin

      sda_stable_cnt_q <= sda_stable_cnt_q + 32'd1;

    end
  end

  // ===========================================================================
  // FILTERED EDGE DETECTION
  // ===========================================================================

  logic scl_prev_q;
  logic sda_prev_q;

  always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin

      scl_prev_q <= 1'b1;
      sda_prev_q <= 1'b1;

    end
    else begin

      scl_prev_q <= scl_filt_q;
      sda_prev_q <= sda_filt_q;

    end
  end

  wire scl_rise =
      scl_filt_q && !scl_prev_q;

  wire scl_fall =
      !scl_filt_q && scl_prev_q;

  wire sda_rise =
      sda_filt_q && !sda_prev_q;

  wire sda_fall =
      !sda_filt_q && sda_prev_q;

  // START / STOP occur when SDA changes while SCL is HIGH.
  wire start_cond =
      sda_fall && scl_filt_q;

  wire stop_cond =
      sda_rise && scl_filt_q;

  // ===========================================================================
  // SCL LOW TIMEOUT
  // ===========================================================================

  logic [31:0] timeout_cnt_q;
  logic        timeout_hit;

  generate

    if (TIMEOUT_EN) begin : gen_timeout_enabled

      always_ff @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin

          timeout_cnt_q <= 32'd0;

        end
        else if (scl_filt_q) begin

          timeout_cnt_q <= 32'd0;

        end
        else if (timeout_cnt_q < TIMEOUT_LIMIT_INT) begin

          timeout_cnt_q <= timeout_cnt_q + 32'd1;

        end
      end

      assign timeout_hit =
          !scl_filt_q &&
          (timeout_cnt_q >= (TIMEOUT_LIMIT_INT - 1));

    end
    else begin : gen_timeout_disabled

      always_ff @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n)
          timeout_cnt_q <= 32'd0;
        else
          timeout_cnt_q <= 32'd0;
      end

      assign timeout_hit = 1'b0;

    end

  endgenerate

  // ===========================================================================
  // FSM
  // ===========================================================================

  typedef enum logic [3:0] {
    ST_IDLE,
    ST_ADDR_BYTE,
    ST_ADDR_ACK,
    ST_CTRL_BYTE,
    ST_CTRL_ACK,
    ST_WR_DATA,
    ST_WR_ACK,
    ST_RD_DATA,
    ST_RD_ACK_WAIT,
    ST_SWRST_BYTE,
    ST_SWRST_ACK
  } rx_state_e;

  rx_state_e state_q;

  // ===========================================================================
  // RECEIVE REGISTERS
  // ===========================================================================

  logic [7:0] shift_reg_q;
  logic [3:0] bit_cnt_q;

  logic [6:0] addr7_q;
  logic       rw_q;

  logic swrst_armed_q;
  logic master_nack_q;

  // ---------------------------------------------------------------------------
  // Completed-byte latch.
  // ---------------------------------------------------------------------------

  logic [7:0] byte_latched_q;

  // ---------------------------------------------------------------------------
  // Event pending information.
  //
  // 0 = none
  // 1 = pointer byte
  // 2 = write-data byte
  // ---------------------------------------------------------------------------

  logic [1:0] byte_event_pending_q;

  localparam logic [1:0] EVENT_NONE = 2'd0;
  localparam logic [1:0] EVENT_PTR  = 2'd1;
  localparam logic [1:0] EVENT_WR   = 2'd2;

  // ---------------------------------------------------------------------------
  // Read TX load pending.
  //
  // This separates rd_byte_o from tx_load_o by one clk_ref cycle.
  //
  // rd_byte_o:
  //   tells register_decode.sv to capture rb_rdata_i.
  //
  // tx_load_pending_q:
  //   remembers that i2c_tx.sv must load the captured response.
  //
  // tx_load_o:
  //   is generated from the previous value of tx_load_pending_q, therefore
  //   it occurs one clk_ref cycle after rd_byte_o.
  // ---------------------------------------------------------------------------

  logic tx_load_pending_q;

  // ===========================================================================
  // STATE CLASSIFICATION
  // ===========================================================================

  wire capture_state =
       (state_q == ST_ADDR_BYTE)  ||
       (state_q == ST_CTRL_BYTE)  ||
       (state_q == ST_WR_DATA)    ||
       (state_q == ST_RD_DATA)    ||
       (state_q == ST_SWRST_BYTE);

  wire ack_state =
       (state_q == ST_ADDR_ACK)    ||
       (state_q == ST_CTRL_ACK)    ||
       (state_q == ST_WR_ACK)      ||
       (state_q == ST_RD_ACK_WAIT) ||
       (state_q == ST_SWRST_ACK);

  // The byte is complete at the falling edge following the eighth
  // sampled data bit.
  wire byte_complete =
      capture_state &&
      scl_fall &&
      (bit_cnt_q == 4'd8);

  wire ack_end =
      ack_state &&
      scl_fall;

  // ===========================================================================
  // ACK QUALIFICATION
  // ===========================================================================

  wire address_ack_ok =
      addr_match_i || gc_match_i;

  wire swrst_ack_ok =
      (byte_latched_q == 8'h06);

  wire ack_drive =
      (state_q == ST_ADDR_ACK)  ? address_ack_ok :
      (state_q == ST_CTRL_ACK)  ? 1'b1 :
      (state_q == ST_WR_ACK)    ? 1'b1 :
      (state_q == ST_SWRST_ACK) ? swrst_ack_ok :
                                   1'b0;

  // ===========================================================================
  // BIT COUNTER
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      bit_cnt_q <= 4'd0;

    end
    else if (start_cond || stop_cond || timeout_hit) begin

      bit_cnt_q <= 4'd0;

    end
    else if (byte_complete) begin

      bit_cnt_q <= 4'd0;

    end
    else if (capture_state && scl_rise) begin

      if (bit_cnt_q < 4'd8)
        bit_cnt_q <= bit_cnt_q + 4'd1;

    end

  end

  // ===========================================================================
  // RECEIVE SHIFT REGISTER
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      shift_reg_q <= 8'h00;

    end
    else if (start_cond || stop_cond || timeout_hit) begin

      shift_reg_q <= 8'h00;

    end
    else if (capture_state && scl_rise) begin

      shift_reg_q <= {
        shift_reg_q[6:0],
        sda_filt_q
      };

    end

  end

  // ===========================================================================
  // COMPLETED BYTE LATCH
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      byte_latched_q       <= 8'h00;
      byte_event_pending_q <= EVENT_NONE;

    end
    else if (start_cond || stop_cond || timeout_hit) begin

      byte_latched_q       <= 8'h00;
      byte_event_pending_q <= EVENT_NONE;

    end
    else begin

      // Default: consume pending event after one cycle.
      if (byte_event_pending_q != EVENT_NONE)
        byte_event_pending_q <= EVENT_NONE;

      if (byte_complete) begin

        byte_latched_q <= shift_reg_q;

        if (state_q == ST_CTRL_BYTE)
          byte_event_pending_q <= EVENT_PTR;

        else if (state_q == ST_WR_DATA)
          byte_event_pending_q <= EVENT_WR;

        else
          byte_event_pending_q <= EVENT_NONE;

      end

    end

  end

  // ===========================================================================
  // MASTER ACK/NACK AFTER READ
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      master_nack_q <= 1'b1;

    end
    else if ((state_q == ST_RD_ACK_WAIT) && scl_rise) begin

      master_nack_q <= sda_filt_q;

    end

  end

  // ===========================================================================
  // MAIN FSM
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      state_q       <= ST_IDLE;
      addr7_q       <= 7'h00;
      rw_q          <= 1'b0;
      swrst_armed_q <= 1'b0;

    end
    else if (timeout_hit) begin

      state_q       <= ST_IDLE;
      swrst_armed_q <= 1'b0;

    end
    else if (stop_cond) begin

      state_q <= ST_IDLE;

      swrst_armed_q <= 1'b0;

    end
    else if (start_cond) begin

      state_q       <= ST_ADDR_BYTE;
      swrst_armed_q <= 1'b0;

    end
    else begin

      case (state_q)

        // ---------------------------------------------------------------------
        // IDLE
        // ---------------------------------------------------------------------

        ST_IDLE: begin
        end

        // ---------------------------------------------------------------------
        // ADDRESS
        // ---------------------------------------------------------------------

        ST_ADDR_BYTE: begin

          if (byte_complete) begin

            addr7_q <= shift_reg_q[7:1];
            rw_q    <= shift_reg_q[0];

            state_q <= ST_ADDR_ACK;

          end

        end

        // ---------------------------------------------------------------------
        // ADDRESS ACK/NACK
        // ---------------------------------------------------------------------

        ST_ADDR_ACK: begin

          if (ack_end) begin

            if (!address_ack_ok) begin

              state_q <= ST_IDLE;

            end
            else if (gc_match_i) begin

              state_q <= ST_SWRST_BYTE;

            end
            else if (rw_q) begin

              state_q <= ST_RD_DATA;

            end
            else begin

              state_q <= ST_CTRL_BYTE;

            end

          end

        end

        // ---------------------------------------------------------------------
        // REGISTER POINTER
        // ---------------------------------------------------------------------

        ST_CTRL_BYTE: begin

          if (byte_complete)
            state_q <= ST_CTRL_ACK;

        end

        ST_CTRL_ACK: begin

          if (ack_end)
            state_q <= ST_WR_DATA;

        end

        // ---------------------------------------------------------------------
        // WRITE DATA
        // ---------------------------------------------------------------------

        ST_WR_DATA: begin

          if (byte_complete)
            state_q <= ST_WR_ACK;

        end

        ST_WR_ACK: begin

          if (ack_end)
            state_q <= ST_WR_DATA;

        end

        // ---------------------------------------------------------------------
        // READ DATA
        // ---------------------------------------------------------------------

        ST_RD_DATA: begin

          if (byte_complete)
            state_q <= ST_RD_ACK_WAIT;

        end

        ST_RD_ACK_WAIT: begin

          if (ack_end) begin

            if (master_nack_q)
              state_q <= ST_IDLE;
            else
              state_q <= ST_RD_DATA;

          end

        end

        // ---------------------------------------------------------------------
        // GENERAL CALL SWRST
        // ---------------------------------------------------------------------

        ST_SWRST_BYTE: begin

          if (byte_complete)
            state_q <= ST_SWRST_ACK;

        end

        ST_SWRST_ACK: begin

          if (ack_end) begin

            if (swrst_ack_ok)
              swrst_armed_q <= 1'b1;
            else
              swrst_armed_q <= 1'b0;

            state_q <= ST_IDLE;

          end

        end

        // ---------------------------------------------------------------------
        // DEFAULT
        // ---------------------------------------------------------------------

        default: begin

          state_q       <= ST_IDLE;
          swrst_armed_q <= 1'b0;

        end

      endcase

    end

  end

  // ===========================================================================
  // REGISTERED PROTOCOL EVENTS
  // ===========================================================================
  //
  // IMPORTANT READ SEQUENCE:
  //
  //   Cycle N:
  //       rd_byte_o  <= 1
  //       tx_load_o  <= 0
  //       tx_load_pending_q <= 1
  //
  //       register_decode captures rb_rdata_i into rd_data_q.
  //
  //   Cycle N+1:
  //       rd_byte_o  <= 0
  //       tx_load_o  <= 1
  //
  //       i2c_tx captures the now-updated rd_data_o.
  //
  // ===========================================================================

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      addr7_o        <= 7'h00;
      rw_o           <= 1'b0;

      ptr_set_o      <= 1'b0;
      ptr_set_data_o <= 8'h00;

      wr_byte_o      <= 1'b0;
      wr_byte_data_o <= 8'h00;

      rd_byte_o      <= 1'b0;
      tx_load_o      <= 1'b0;

      tx_load_pending_q <= 1'b0;

      stop_event_o   <= 1'b0;
      swrst_o        <= 1'b0;

    end
    else begin

      // All events are one clk_ref cycle pulses.
      ptr_set_o    <= 1'b0;
      wr_byte_o    <= 1'b0;
      rd_byte_o    <= 1'b0;
      tx_load_o    <= 1'b0;
      stop_event_o <= 1'b0;
      swrst_o      <= 1'b0;

      // -----------------------------------------------------------------------
      // Delayed TX load.
      //
      // tx_load_pending_q contains the read request generated during the
      // previous clk_ref cycle.
      //
      // Therefore tx_load_o is exactly one cycle later than rd_byte_o.
      // -----------------------------------------------------------------------

      tx_load_o <= tx_load_pending_q;

      // Default: no pending TX load.
      tx_load_pending_q <= 1'b0;

      // -----------------------------------------------------------------------
      // ADDRESS EVENT
      // -----------------------------------------------------------------------

      if (byte_complete &&
          (state_q == ST_ADDR_BYTE)) begin

        addr7_o <= shift_reg_q[7:1];
        rw_o    <= shift_reg_q[0];

      end

      // -----------------------------------------------------------------------
      // POINTER EVENT
      // -----------------------------------------------------------------------

      if (byte_event_pending_q == EVENT_PTR) begin

        ptr_set_o      <= 1'b1;
        ptr_set_data_o <= byte_latched_q;

      end

      // -----------------------------------------------------------------------
      // WRITE DATA EVENT
      // -----------------------------------------------------------------------

      if (byte_event_pending_q == EVENT_WR) begin

        wr_byte_o      <= 1'b1;
        wr_byte_data_o <= byte_latched_q;

      end

      // -----------------------------------------------------------------------
      // READ BYTE REQUEST
      //
      // rd_byte_o is generated immediately when the read byte begins.
      //
      // tx_load_pending_q is set at the same time, but tx_load_o itself
      // does not become asserted until the following clk_ref cycle.
      // -----------------------------------------------------------------------

      if ((state_q == ST_RD_DATA) &&
          scl_fall &&
          (bit_cnt_q == 4'd0)) begin

        rd_byte_o          <= 1'b1;
        tx_load_pending_q  <= 1'b1;

      end

      // -----------------------------------------------------------------------
      // STOP EVENT
      // -----------------------------------------------------------------------

      if (stop_cond)
        stop_event_o <= 1'b1;

      // -----------------------------------------------------------------------
      // SWRST EVENT
      // -----------------------------------------------------------------------

      if (stop_cond && swrst_armed_q)
        swrst_o <= 1'b1;

    end

  end

  // ===========================================================================
  // SDA OUTPUT
  // ===========================================================================

  // I2C open-drain behavior: only ever pull SDA LOW.
  assign sda_o = 1'b0;

  assign sda_oe = ack_drive;

  // ===========================================================================
  // READ TRANSMIT ENABLE
  // ===========================================================================

  assign tx_drive_en_o =
      (state_q == ST_RD_DATA);

  // ===========================================================================
  // DEBUG
  // ===========================================================================

  `ifndef SYNTHESIS

    always @(posedge clk_ref) begin

      if (byte_complete) begin
        $display(
          "[I2C DEBUG] BYTE COMPLETE: state=%0d shift_reg=0x%02h bit_cnt=%0d scl=%b sda=%b",
          state_q,
          shift_reg_q,
          bit_cnt_q,
          scl_filt_q,
          sda_filt_q
        );
      end

      if (ptr_set_o) begin
        $display(
          "[I2C DEBUG] PTR EVENT: ptr_set_data_o=0x%02h",
          ptr_set_data_o
        );
      end

      if (wr_byte_o) begin
        $display(
          "[I2C DEBUG] WR EVENT: wr_byte_data_o=0x%02h",
          wr_byte_data_o
        );
      end

      if (rd_byte_o) begin
        $display(
          "[I2C DEBUG] RD EVENT: rd_byte_o=1 tx_load_pending=1"
        );
      end

      if (tx_load_o) begin
        $display(
          "[I2C DEBUG] TX LOAD: tx_load_o=1"
        );
      end

    end

  `endif

endmodule

`default_nettype wire