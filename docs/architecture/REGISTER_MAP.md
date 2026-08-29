# SEMFONIX PWM16 — Register Map

Authoritative address-level register map for `rtl/registers/register_bank.sv`.
Generated alongside that module per `docs/MASTER_ARCHITECTURE.md` Section 17.
PCA9685-compatible register semantics/addresses are preserved where a
reference-equivalent register exists (see `docs/product/PCA9685_reference_notes.md`);
SEMFONIX-specific extensions occupy the reserved block `0x50-0x5F` per
Section 24.

All addresses are the internal control-register pointer value (`rb_addr`),
i.e. the byte following the control-register byte in an I²C write, before
any auto-increment logic (owned by `register_decode.sv`, not this file).

## Core registers (PCA9685-compatible)

| Addr | Name | Access | Reset | Buffering | Notes |
|---|---|---|---|---|---|
| 0x00 | MODE1 | RW | 0x11 | single | bit7 RESTART, bit6 EXTCLK (status-only), bit5 AI, bit4 SLEEP, bit3 SUB1, bit2 SUB2, bit1 SUB3, bit0 ALLCALL |
| 0x01 | MODE2 | RW | 0x04 | single | bits7:5 reserved, bit4 INVRT, bit3 OCH, bit2 OUTDRV, bits1:0 OUTNE |
| 0x02 | SUBADR1 | RW | 0xE2 | single | active only if MODE1.SUB1=1 |
| 0x03 | SUBADR2 | RW | 0xE4 | single | active only if MODE1.SUB2=1 |
| 0x04 | SUBADR3 | RW | 0xE8 | single | active only if MODE1.SUB3=1 |
| 0x05 | ALLCALLADR | RW | 0xE0 | single | active only if MODE1.ALLCALL=1 |
| 0x06 + 4n .. 0x06+4n+3 (n=0..15) | LEDn_ON_L, LEDn_ON_H, LEDn_OFF_L, LEDn_OFF_H | RW | ON=0x00/0x00, OFF=0x00/0x10 | **shadow/active** | `_H` bit4 = full_on (ON reg) / full_off (OFF reg); bits3:0 = count[11:8]. Reads return **shadow** (last-written) value, not active/committed value. |
| 0x46-0x4F | reserved | RW | n/a | n/a | reads 0x00; writes silently dropped |

LEDn base address = `0x06 + 4*n`. Last core register: LED15_OFF_H = `0x06 + 4*15 + 3 = 0x45` (69 decimal) — matches the reference auto-increment wrap point.

## SEMFONIX extension block (0x50-0x5F)

| Addr | Name | Access | Reset | Buffering | Notes |
|---|---|---|---|---|---|
| 0x50 | CHAN_ENABLE_L | RW | 0xFF | single | channels 7:0 enable, 1=enabled |
| 0x51 | CHAN_ENABLE_H | RW | 0xFF | single | channels 15:8 enable |
| 0x52 | CHAN_POLARITY_L | RW | 0x00 | single | channels 7:0 polarity, 1=inverted |
| 0x53 | CHAN_POLARITY_H | RW | 0x00 | single | channels 15:8 polarity |
| 0x54 | GROUP_UPDATE | W (self-clearing) | 0x00 | n/a | bit0=1 requests one `commit_pulse` via `shadow_active_ctrl`; always reads back 0x00 |
| 0x55 | DEVICE_ID | RO | 0x53 ('S') | n/a | fixed constant |
| 0x56 | REVISION_ID | RO | 0x01 | n/a | bump on RTL revision |
| 0x57-0x5F | reserved | RW | n/a | n/a | reads 0x00; writes silently dropped. Room reserved for a possible future register-triggered soft-reset bit (deferred, not designed — see `docs/product/COMPETITIVE_REVIEW_2026.md` Candidate 2); no other allocation planned as of the 2026 competitive review (same doc) — group dimming/blinking was evaluated and rejected, so no registers are reserved for it. |

CHAN_ENABLE/CHAN_POLARITY are deliberately **single-buffered** (not
shadow/active) per Section 8: they gate the output stage directly
(`pwm_channel.enable` / `.polarity`) and are not part of the
glitch-sensitive PWM timing path the shadow/active split protects.

## Broadcast / prescale / reserved tail

| Addr | Name | Access | Reset | Buffering | Notes |
|---|---|---|---|---|---|
| 0x60-0xF9 | reserved | RW | n/a | n/a | reads 0x00; writes silently dropped |
| 0xFA | ALL_LED_ON_L | W-only | n/a | shadow (broadcast) | fans out to all 16 channels' `on_count[7:0]` shadow; reads 0x00 |
| 0xFB | ALL_LED_ON_H | W-only | n/a | shadow (broadcast) | fans out `on_count[11:8]` + `full_on` to all 16 channels; reads 0x00 |
| 0xFC | ALL_LED_OFF_L | W-only | n/a | shadow (broadcast) | fans out `off_count[7:0]` to all 16 channels; reads 0x00 |
| 0xFD | ALL_LED_OFF_H | W-only | n/a | shadow (broadcast) | fans out `off_count[11:8]` + `full_off` to all 16 channels; reads 0x00 |
| 0xFE | PRE_SCALE | RW (guarded) | 0x1E | single | write accepted only while `MODE1.SLEEP=1` (see `prescale_gate.sv`, Section 12); silently dropped otherwise |
| 0xFF | reserved (test mode) | RW | n/a | n/a | reads 0x00; writes silently dropped |

## Reserved-address policy (Section 16)

Every address not listed above reads as `0x00` and silently discards
writes. This is implemented as the `default` arm of `register_bank`'s
address-decode case statements — there is no dedicated reserved-address
storage; the absence of a matching storage element is itself the
defined, safe behavior (no "unpredictable results," per the reference
datasheet's own footnote on this point).

## Read semantics for shadow/active split registers

For the 64 `LEDn_*` registers, an I²C read returns the **shadow**
(most-recently-written) value, not the committed/active value the PWM
engine is currently using. This matches normal software expectations
(read back what you wrote) while keeping `active_cfg_o` — what actually
drives `pwm_engine` — isolated until a `commit_pulse` occurs. See
`docs/MASTER_ARCHITECTURE.md` Section 13 for the full atomic-update
rationale and `dirty_o`'s role in STOP-commit gating.
