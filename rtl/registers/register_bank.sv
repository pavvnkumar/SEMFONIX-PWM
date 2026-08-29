// =============================================================================
// register_bank.sv
//
// Register storage for SEMFONIX PWM16.
//
// Single-buffered:
//   MODE1
//   MODE2
//   SUBADR1-3
//   ALLCALLADR
//   PRE_SCALE
//   CHAN_ENABLE
//   CHAN_POLARITY
//
// Shadow/active:
//   LEDn_ON_L
//   LEDn_ON_H
//   LEDn_OFF_L
//   LEDn_OFF_H
//
// commit_pulse transfers ALL shadow LED configuration into active storage
// atomically.
//
// GROUP_UPDATE is a command/strobe and is never stored as a persistent bit.
// =============================================================================

`default_nettype none

module register_bank
  import semfonix_regmap_pkg::*;
#(
  parameter int NUM_CHANNELS = 16
) (
  input  logic                  clk_ref,
  input  logic                  rst_n,

  // ---------------------------------------------------------------------------
  // Register bus
  // ---------------------------------------------------------------------------

  input  logic                  rb_wr_en,
  input  logic                  rb_rd_en,
  input  logic [7:0]            rb_addr,
  input  logic [7:0]            rb_wdata,
  output logic [7:0]            rb_rdata,

  // ---------------------------------------------------------------------------
  // Commit control
  // ---------------------------------------------------------------------------

  input  logic                  commit_pulse,

  // ---------------------------------------------------------------------------
  // PRE_SCALE write guard
  // ---------------------------------------------------------------------------

  input  logic                  presc_write_allow_i,

  // ---------------------------------------------------------------------------
  // Control events
  // ---------------------------------------------------------------------------

  output logic                  dirty_o,
  output logic                  group_update_req_o,

  // ---------------------------------------------------------------------------
  // Active configuration
  // ---------------------------------------------------------------------------

  output pwm_chan_cfg_t         active_cfg_o [NUM_CHANNELS],

  output logic [7:0]            active_prescale_o,

  output logic                  active_sleep_o,
  output logic                  active_ai_o,
  output logic                  active_allcall_o,

  output logic [2:0]            active_subx_en_o,

  output logic [1:0]            active_outne_o,
  output logic                  active_outdrv_o,
  output logic                  active_invrt_o,
  output logic                  active_och_o,

  output logic [6:0]            active_allcalladr_o,
  output logic [6:0]            active_subadr_o [3]
);

  // ---------------------------------------------------------------------------
  // Address map
  // ---------------------------------------------------------------------------

  localparam logic [7:0] ADDR_MODE1         = 8'h00;
  localparam logic [7:0] ADDR_MODE2         = 8'h01;

  localparam logic [7:0] ADDR_SUBADR1       = 8'h02;
  localparam logic [7:0] ADDR_SUBADR2       = 8'h03;
  localparam logic [7:0] ADDR_SUBADR3       = 8'h04;
  localparam logic [7:0] ADDR_ALLCALLADR    = 8'h05;

  localparam logic [7:0] ADDR_LED_BASE      = 8'h06;
  localparam logic [7:0] ADDR_LED_LAST      = 8'h45;

  localparam logic [7:0] ADDR_CHAN_EN_L     = 8'h50;
  localparam logic [7:0] ADDR_CHAN_EN_H     = 8'h51;
  localparam logic [7:0] ADDR_CHAN_POL_L    = 8'h52;
  localparam logic [7:0] ADDR_CHAN_POL_H    = 8'h53;

  localparam logic [7:0] ADDR_GROUP_UPDATE  = 8'h54;

  localparam logic [7:0] ADDR_DEVICE_ID     = 8'h55;
  localparam logic [7:0] ADDR_REVISION_ID   = 8'h56;

  localparam logic [7:0] ADDR_ALL_LED_ON_L  = 8'hFA;
  localparam logic [7:0] ADDR_ALL_LED_ON_H  = 8'hFB;
  localparam logic [7:0] ADDR_ALL_LED_OFF_L = 8'hFC;
  localparam logic [7:0] ADDR_ALL_LED_OFF_H = 8'hFD;

  localparam logic [7:0] ADDR_PRE_SCALE     = 8'hFE;

  localparam logic [7:0] DEVICE_ID_CONST    = 8'h53;
  localparam logic [7:0] REVISION_ID_CONST  = 8'h01;

  // ---------------------------------------------------------------------------
  // Single-buffered storage
  // ---------------------------------------------------------------------------

  logic [7:0]  mode1_r;
  logic [7:0]  mode2_r;

  logic [7:0]  subadr1_r;
  logic [7:0]  subadr2_r;
  logic [7:0]  subadr3_r;

  logic [7:0]  allcalladr_r;
  logic [7:0]  prescale_r;

  logic [15:0] chan_enable_r;
  logic [15:0] chan_polarity_r;

  // ---------------------------------------------------------------------------
  // Shadow storage
  // ---------------------------------------------------------------------------

  logic [11:0] shadow_on_count  [NUM_CHANNELS];
  logic [11:0] shadow_off_count [NUM_CHANNELS];

  logic        shadow_full_on   [NUM_CHANNELS];
  logic        shadow_full_off  [NUM_CHANNELS];

  // ---------------------------------------------------------------------------
  // Active storage
  // ---------------------------------------------------------------------------

  logic [11:0] active_on_count  [NUM_CHANNELS];
  logic [11:0] active_off_count [NUM_CHANNELS];

  logic        active_full_on   [NUM_CHANNELS];
  logic        active_full_off  [NUM_CHANNELS];

  // ---------------------------------------------------------------------------
  // Dirty state
  // ---------------------------------------------------------------------------

  logic dirty_q;

  // ---------------------------------------------------------------------------
  // LED address decode
  // ---------------------------------------------------------------------------

  logic       is_led_addr;
  logic [3:0] led_chan;
  logic [1:0] led_field;

  logic [7:0] led_offset;

  assign is_led_addr =
      (rb_addr >= ADDR_LED_BASE) &&
      (rb_addr <= ADDR_LED_LAST);

  assign led_offset =
      rb_addr - ADDR_LED_BASE;

  // Explicit truncation to intended widths.
  assign led_chan =
      led_offset[5:2];

  assign led_field =
      led_offset[1:0];

  // ---------------------------------------------------------------------------
  // GROUP_UPDATE detection
  // ---------------------------------------------------------------------------

  assign group_update_req_o =
      rb_wr_en &&
      (rb_addr == ADDR_GROUP_UPDATE) &&
      rb_wdata[0];

  // ---------------------------------------------------------------------------
  // Write path
  // ---------------------------------------------------------------------------

  logic any_shadow_write;

  always_ff @(posedge clk_ref or negedge rst_n) begin

    if (!rst_n) begin

      mode1_r         <= 8'h11;
      mode2_r         <= 8'h04;

      subadr1_r       <= 8'hE2;
      subadr2_r       <= 8'hE4;
      subadr3_r       <= 8'hE8;

      allcalladr_r    <= 8'hE0;

      prescale_r      <= 8'h1E;

      chan_enable_r   <= 16'hFFFF;
      chan_polarity_r <= 16'h0000;

      dirty_q         <= 1'b0;

      for (int i = 0; i < NUM_CHANNELS; i++) begin

        shadow_on_count[i]  <= 12'h000;
        shadow_off_count[i] <= 12'h000;

        shadow_full_on[i]   <= 1'b0;
        shadow_full_off[i]  <= 1'b1;

        active_on_count[i]  <= 12'h000;
        active_off_count[i] <= 12'h000;

        active_full_on[i]   <= 1'b0;
        active_full_off[i]  <= 1'b1;

      end

    end else begin

      // Default for this clock.
      any_shadow_write = 1'b0;

      // -----------------------------------------------------------------------
      // Normal register write
      // -----------------------------------------------------------------------

      if (rb_wr_en) begin

        if (rb_addr == ADDR_MODE1) begin

          mode1_r <= rb_wdata;

        end else if (rb_addr == ADDR_MODE2) begin

          mode2_r <= rb_wdata;

        end else if (rb_addr == ADDR_SUBADR1) begin

          subadr1_r <= rb_wdata;

        end else if (rb_addr == ADDR_SUBADR2) begin

          subadr2_r <= rb_wdata;

        end else if (rb_addr == ADDR_SUBADR3) begin

          subadr3_r <= rb_wdata;

        end else if (rb_addr == ADDR_ALLCALLADR) begin

          allcalladr_r <= rb_wdata;

        end else if (rb_addr == ADDR_PRE_SCALE) begin

          if (presc_write_allow_i)
            prescale_r <= rb_wdata;

        end else if (rb_addr == ADDR_CHAN_EN_L) begin

          chan_enable_r[7:0] <= rb_wdata;

        end else if (rb_addr == ADDR_CHAN_EN_H) begin

          chan_enable_r[15:8] <= rb_wdata;

        end else if (rb_addr == ADDR_CHAN_POL_L) begin

          chan_polarity_r[7:0] <= rb_wdata;

        end else if (rb_addr == ADDR_CHAN_POL_H) begin

          chan_polarity_r[15:8] <= rb_wdata;

        end else if (rb_addr == ADDR_GROUP_UPDATE) begin

          // Command only. No persistent storage.

        end else if (rb_addr == ADDR_DEVICE_ID) begin

          // Read-only.

        end else if (rb_addr == ADDR_REVISION_ID) begin

          // Read-only.

        end else if (is_led_addr) begin

          // -------------------------------------------------------------------
          // Per-channel shadow registers
          // -------------------------------------------------------------------

          case (led_field)

            2'd0: begin

              shadow_on_count[led_chan][7:0] <= rb_wdata;

            end

            2'd1: begin

              shadow_on_count[led_chan][11:8] <= rb_wdata[3:0];
              shadow_full_on[led_chan]        <= rb_wdata[4];

            end

            2'd2: begin

              shadow_off_count[led_chan][7:0] <= rb_wdata;

            end

            2'd3: begin

              shadow_off_count[led_chan][11:8] <= rb_wdata[3:0];
              shadow_full_off[led_chan]        <= rb_wdata[4];

            end

            default: begin
            end

          endcase

          any_shadow_write = 1'b1;

        end else if (rb_addr == ADDR_ALL_LED_ON_L) begin

          // -------------------------------------------------------------------
          // Broadcast ON_L
          // -------------------------------------------------------------------

          for (int i = 0; i < NUM_CHANNELS; i++) begin
            shadow_on_count[i][7:0] <= rb_wdata;
          end

          any_shadow_write = 1'b1;

        end else if (rb_addr == ADDR_ALL_LED_ON_H) begin

          // -------------------------------------------------------------------
          // Broadcast ON_H
          // -------------------------------------------------------------------

          for (int i = 0; i < NUM_CHANNELS; i++) begin

            shadow_on_count[i][11:8] <= rb_wdata[3:0];
            shadow_full_on[i]        <= rb_wdata[4];

          end

          any_shadow_write = 1'b1;

        end else if (rb_addr == ADDR_ALL_LED_OFF_L) begin

          // -------------------------------------------------------------------
          // Broadcast OFF_L
          // -------------------------------------------------------------------

          for (int i = 0; i < NUM_CHANNELS; i++) begin
            shadow_off_count[i][7:0] <= rb_wdata;
          end

          any_shadow_write = 1'b1;

        end else if (rb_addr == ADDR_ALL_LED_OFF_H) begin

          // -------------------------------------------------------------------
          // Broadcast OFF_H
          // -------------------------------------------------------------------

          for (int i = 0; i < NUM_CHANNELS; i++) begin

            shadow_off_count[i][11:8] <= rb_wdata[3:0];
            shadow_full_off[i]        <= rb_wdata[4];

          end

          any_shadow_write = 1'b1;

        end

      end

      // -----------------------------------------------------------------------
      // Dirty tracking
      //
      // A same-cycle new shadow write wins over a commit. This prevents losing
      // the information that a newly written shadow value has not yet been
      // committed.
      // -----------------------------------------------------------------------

      if (any_shadow_write) begin

        dirty_q <= 1'b1;

      end else if (commit_pulse) begin

        dirty_q <= 1'b0;

      end

      // -----------------------------------------------------------------------
      // Atomic shadow -> active commit
      // -----------------------------------------------------------------------

      if (commit_pulse) begin

        for (int i = 0; i < NUM_CHANNELS; i++) begin

          active_on_count[i]  <= shadow_on_count[i];
          active_off_count[i] <= shadow_off_count[i];

          active_full_on[i]   <= shadow_full_on[i];
          active_full_off[i]  <= shadow_full_off[i];

        end

      end

    end

  end

  // ---------------------------------------------------------------------------
  // Read path
  // ---------------------------------------------------------------------------

  always_comb begin

    rb_rdata = 8'h00;

    if (rb_addr == ADDR_MODE1) begin

      rb_rdata = mode1_r;

    end else if (rb_addr == ADDR_MODE2) begin

      rb_rdata = mode2_r;

    end else if (rb_addr == ADDR_SUBADR1) begin

      rb_rdata = subadr1_r;

    end else if (rb_addr == ADDR_SUBADR2) begin

      rb_rdata = subadr2_r;

    end else if (rb_addr == ADDR_SUBADR3) begin

      rb_rdata = subadr3_r;

    end else if (rb_addr == ADDR_ALLCALLADR) begin

      rb_rdata = allcalladr_r;

    end else if (rb_addr == ADDR_PRE_SCALE) begin

      rb_rdata = prescale_r;

    end else if (rb_addr == ADDR_CHAN_EN_L) begin

      rb_rdata = chan_enable_r[7:0];

    end else if (rb_addr == ADDR_CHAN_EN_H) begin

      rb_rdata = chan_enable_r[15:8];

    end else if (rb_addr == ADDR_CHAN_POL_L) begin

      rb_rdata = chan_polarity_r[7:0];

    end else if (rb_addr == ADDR_CHAN_POL_H) begin

      rb_rdata = chan_polarity_r[15:8];

    end else if (rb_addr == ADDR_GROUP_UPDATE) begin

      rb_rdata = 8'h00;

    end else if (rb_addr == ADDR_DEVICE_ID) begin

      rb_rdata = DEVICE_ID_CONST;

    end else if (rb_addr == ADDR_REVISION_ID) begin

      rb_rdata = REVISION_ID_CONST;

    end else if (is_led_addr) begin

      case (led_field)

        2'd0:
          rb_rdata =
              shadow_on_count[led_chan][7:0];

        2'd1:
          rb_rdata =
              {
                3'b000,
                shadow_full_on[led_chan],
                shadow_on_count[led_chan][11:8]
              };

        2'd2:
          rb_rdata =
              shadow_off_count[led_chan][7:0];

        2'd3:
          rb_rdata =
              {
                3'b000,
                shadow_full_off[led_chan],
                shadow_off_count[led_chan][11:8]
              };

        default:
          rb_rdata = 8'h00;

      endcase

    end else begin

      // Reserved / broadcast readback = zero.

      rb_rdata = 8'h00;

    end

  end

  // ---------------------------------------------------------------------------
  // Active configuration export
  // ---------------------------------------------------------------------------

  always_comb begin

    for (int i = 0; i < NUM_CHANNELS; i++) begin

      active_cfg_o[i].full_on   = active_full_on[i];
      active_cfg_o[i].full_off  = active_full_off[i];

      active_cfg_o[i].on_count  = active_on_count[i];
      active_cfg_o[i].off_count = active_off_count[i];

      active_cfg_o[i].enable    = chan_enable_r[i];
      active_cfg_o[i].polarity  = chan_polarity_r[i];

    end

  end

  // ---------------------------------------------------------------------------
  // Active scalar exports
  // ---------------------------------------------------------------------------

  assign dirty_o = dirty_q;

  assign active_prescale_o = prescale_r;

  assign active_sleep_o    = mode1_r[4];
  assign active_ai_o       = mode1_r[5];
  assign active_allcall_o  = mode1_r[0];

  assign active_subx_en_o  = mode1_r[3:1];

  assign active_outne_o    = mode2_r[1:0];
  assign active_outdrv_o   = mode2_r[2];
  assign active_och_o      = mode2_r[3];
  assign active_invrt_o    = mode2_r[4];

  assign active_allcalladr_o = allcalladr_r[7:1];

  assign active_subadr_o[0] = subadr1_r[7:1];
  assign active_subadr_o[1] = subadr2_r[7:1];
  assign active_subadr_o[2] = subadr3_r[7:1];

endmodule

`default_nettype wire