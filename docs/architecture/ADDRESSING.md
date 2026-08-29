# SEMFONIX PWM16 — I²C Addressing

Authoritative writeup for `rtl/registers/address_decode.sv`. Generated
alongside that module per `docs/MASTER_ARCHITECTURE.md` Section 11 (this
file is the "documented priority order" Section 11 refers to).

`address_decode.sv` is purely combinational: it takes the 7-bit address
value (and R/W bit) that `i2c_rx` (not yet built, Checkpoint 4) latches
off the bus during the address phase, and reports which of five
independent address types, if any, matches. It performs no bus timing,
ACK shifting, or byte-stream state of its own — see Section 7.1 for
where those live in `i2c_rx`.

## Address types (5 comparators)

| # | Type | Compared against | Enable qualifier | Notes |
|---|---|---|---|---|
| 1 | General-Call / SWRST | fixed `0000000` | none (but see R/W note) | Only matches when the byte's R/W bit is 0 — General Call is a write-only address on the reference part. A read to `0000000` is simply unmatched. |
| 2 | LED All-Call | `ALLCALLADR[7:1]` (`active_allcalladr_o`) | live `MODE1.ALLCALL` | Reset: enabled (`MODE1` resets to `0x11`, ALLCALL=1), address resets to `0xE0` per `REGISTER_MAP.md`. |
| 3 | Sub-Call 1 | `SUBADR1[7:1]` (`active_subadr_o[0]`) | live `MODE1.SUB1` | Reset: disabled, address resets to `0xE2`. |
| 4 | Sub-Call 2 | `SUBADR2[7:1]` (`active_subadr_o[1]`) | live `MODE1.SUB2` | Reset: disabled, address resets to `0xE4`. |
| 5 | Sub-Call 3 | `SUBADR3[7:1]` (`active_subadr_o[2]`) | live `MODE1.SUB3` | Reset: disabled, address resets to `0xE8`. |
| 6 | Regular (fixed) | `{1'b1, hw_addr_i[5:0]}` | always active | Fixed MSB=1 per reference Fig. 4 pattern `1 A5 A4 A3 A2 A1 A0`; no MODE1 bit can disable a device's own fixed address. |

(Six rows, five *comparators* — General-Call and Regular are each a
single fixed/semi-fixed pattern; All-Call and the three Sub-Calls are
the programmable ones. Section 11's "5 total" count groups General-Call,
All-Call, Sub1, Sub2, Sub3, Regular as five *logically distinct*
comparator instances, matching the five `assign` statements in the RTL.)

## Priority / simultaneous-match behavior

No priority encoding is performed between the five comparators. All are
evaluated independently and OR'd into a single `addr_match_o` bit, which
is the only signal `i2c_rx` needs to decide address-byte ACK/NACK
(Section 7.1). This is safe because:

- All-Call, Sub-Call 1/2/3, and Regular addressing all reach the exact
  same shared register space through the exact same write path (Section
  8) — the reference part defines no behavioral difference between them
  beyond which address byte was used to get there. If more than one
  happens to match simultaneously (only possible via deliberate
  address-register programming, e.g. `ALLCALLADR` set equal to the
  fixed regular address), asserting both match bits together is
  harmless — the write still proceeds exactly once, exactly as normal.
- General-Call is the one type with behaviorally distinct downstream
  handling (the `GC_BYTE -> GC_ACK -> SWRST_BYTE -> SWRST_ACK -> STOP`
  FSM branch, Section 7.1, vs. the regular `CTRL_BYTE` branch for
  everything else) and is reported on its own dedicated `gc_match_o`
  output specifically so `i2c_rx` can branch on it directly without
  needing any priority logic. It cannot collide with the Regular match
  (MSB is hard-wired 0 vs. 1 respectively) but could in principle
  collide with All-Call/Sub-Call if one of those is programmed to
  `0000000` — again harmless, since `i2c_rx` only reads `gc_match_o` to
  pick its branch and does not look at whether another bit is also set.

## Register-bit-order mapping carried through from `register_bank.sv`

`register_bank.sv` exposes the three Sub-Call enables and addresses with
a deliberate index/bit-order mismatch (`active_subx_en_o[2:0]` is
MSB-first `{SUB1,SUB2,SUB3}` per `MODE1`'s own bit layout, while
`active_subadr_o[0..2]` is natural-order `SUB1,SUB2,SUB3`).
`address_decode.sv` carries this mapping through unchanged rather than
"fixing" it locally, to avoid a silent miswire risk from two modules
each doing their own reordering:

```
active_subx_en_i[2]  gates  active_subadr_i[0]   (SUB1)
active_subx_en_i[1]  gates  active_subadr_i[1]   (SUB2)
active_subx_en_i[0]  gates  active_subadr_i[2]   (SUB3)
```

Written out as three explicit named comparisons in the RTL (not a
`generate` loop), specifically so this mapping is visible at the call
site.

## What this module does *not* do

- It does not validate the General-Call SWRST **data byte** (must be
  exactly `0x06` per the reference sequence) — that check belongs to
  whichever module owns the `SWRST_BYTE`/`SWRST_ACK` FSM states
  (`i2c_rx`, Checkpoint 4), since it is a data-byte-value check, not an
  address-byte check.
- It does not generate `sda_oe`/ACK timing itself — it only reports a
  combinational match; `i2c_rx` is the ACK-timing owner (Section 7.1).
- It does not read or write any register storage — purely a comparator
  bank against register_bank's already-live outputs.
