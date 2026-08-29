package semfonix_regmap_pkg;

  typedef struct packed {
    logic        full_on;
    logic        full_off;
    logic [11:0] on_count;
    logic [11:0] off_count;
    logic        enable;
    logic        polarity;
  } pwm_chan_cfg_t;

endpackage : semfonix_regmap_pkg
