# Reference Notes — NXP PCA9685 (functional baseline)

SEMFONIX PWM16 uses the NXP PCA9685 (Rev. 4, 16 April 2015) product data
sheet as its functional reference baseline for register semantics, timing
formulas and protocol behavior. This file records the specific facts used
to derive `docs/MASTER_ARCHITECTURE.md`; it is a design note, not a copy of
the datasheet.

Key facts carried into SEMFONIX PWM16's architecture:

- 16 channels, 12-bit (4096-step) PWM, one 12-bit free-running counter
  shared by all channels, counting 0..4095 continuously.
- Two 12-bit registers per channel (ON, OFF); values 0-4095; comparator
  logic per the reference's Examples 1-4 (Figures 7-11) including the
  wraparound case where `ON > OFF`.
- `LEDn_ON_H[4]` = full-ON override, `LEDn_OFF_H[4]` = full-OFF override;
  full-OFF takes precedence if both set.
- `PRE_SCALE` register (address 0xFE): `prescale = round(osc_clk /
  (4096*update_rate)) - 1`; minimum value forced to 3 by hardware; default
  0x1E = 200 Hz @ 25 MHz; can only be written while `MODE1.SLEEP=1`.
- `MODE1` (0x00): RESTART(7), EXTCLK(6), AI(5), SLEEP(4), SUB1(3), SUB2(2),
  SUB3(1), ALLCALL(0). Reset value 0x11 (SLEEP=1, ALLCALL=1, rest 0).
- `MODE2` (0x01): bits 7:5 reserved, INVRT(4), OCH(3), OUTDRV(2),
  OUTNE[1:0]. Reset value 0x04 (OUTDRV=1 totem-pole default).
- `SUBADR1/2/3` (0x02-0x04) reset E2h/E4h/E8h, disabled by default (SUBx=0
  in MODE1). `ALLCALLADR` (0x05) reset E0h, enabled by default
  (ALLCALL=1 in MODE1).
- Regular slave address format: fixed MSB `1`, then `A5 A4 A3 A2 A1 A0`,
  then R/W bit (Fig. 4).
- General-Call Software Reset: address byte `0000 0000` (General Call,
  R/W=0), then data byte must be exactly `0000 0110` (0x06), then STOP ->
  reset. Any deviation aborts without resetting.
- `ALL_LED_ON_L/H`, `ALL_LED_OFF_L/H` (0xFA-0xFD): write-only, fan out to
  all 16 channels' ON/OFF registers in one 4-byte burst.
- Auto-increment (`MODE1.AI`): control-register pointer increments after
  each byte; wraps from 69 back to 0; also wraps 250-254 back to 0
  (explicit remark in register table).
- Output stage: `OUTDRV` selects open-drain vs totem-pole; `INVRT` inverts
  output logic (only meaningful when `OE=0`); `OUTNE[1:0]` defines forced
  output value when `OE=1` (active-low output-enable pin), per Table 11.
- I²C targeted at Fast-mode Plus, up to 1 MHz SCL, with a 25 MHz internal
  oscillator giving a >=25x oversampling margin.
- Reserved register addresses: "writes to this register may cause
  unpredictable results" per the datasheet footnote — SEMFONIX PWM16
  intentionally replaces this with a **defined, safe** no-op (see
  MASTER_ARCHITECTURE.md Section 16) rather than reproducing undefined
  behavior.

These notes are used only to keep SEMFONIX PWM16 software/register-map
compatible where practical; SEMFONIX PWM16 is an independent RTL
implementation, not a copy of any NXP source code (none was available —
only the public data sheet text was used), and it adds several extensions
(Section 1 of the master architecture) beyond the reference part.
