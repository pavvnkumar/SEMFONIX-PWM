// =============================================================================
// address_decode.sv
//
// Purely combinational 7-bit I2C address matcher, per
// docs/MASTER_ARCHITECTURE.md Section 11 and docs/architecture/
// ADDRESSING.md (authoritative priority-order writeup lives there; this
// header only summarizes).
//
// Sits between i2c_rx (not yet built -- Checkpoint 4) and the live MODE1
// enable bits / programmable address registers already exposed by
// register_bank.sv (Checkpoint 2 step 1). i2c_rx latches the received
// address+R/W byte and feeds the 7 address bits (and the R/W bit, needed
// only for the general-call qualifier below) into this module; this
// module reports which address type(s), if any, matched, so i2c_rx knows
// whether to ACK the address byte and, for the general-call case, which
// FSM branch to take (Section 7.1: `GC_BYTE -> GC_ACK -> SWRST_BYTE ...`
// vs the regular `CTRL_BYTE` path).
//
// Five independent 7-bit equality comparators (Section 11 -- "already
// minimal; no further sharing opportunity exists without adding mux
// latency to a bus-timing-sensitive path"), not a priority-encoded chain:
//   1. General-Call / SWRST address: fixed `0000000`, and only qualifies
//      as a match when the R/W bit of the same byte is 0 (Section 7.1 /
//      product notes: General Call is a write-only address on the
//      reference part -- a read to `0000000` is simply unmatched here).
//   2. LED All-Call address: `ALLCALLADR[7:1]` (register_bank's
//      `active_allcalladr_o`), qualified by live `MODE1.ALLCALL`
//      (`active_allcall_o` bit0).
//   3-5. Sub-Call 1/2/3 addresses: `SUBADR{1,2,3}[7:1]`
//      (`active_subadr_o[0..2]`), each independently qualified by its own
//      live `MODE1.SUB{1,2,3}` bit. NOTE the deliberate index/bit-order
//      mismatch inherited from register_bank.sv and carried through
//      unchanged here (not remapped, to avoid a silent-miswire risk from
//      "fixing" it in only one of the two modules):
//        active_subadr_i[0..2]  = SUB1, SUB2, SUB3 addr, in that order
//        active_subx_en_i[2:0]  = {SUB1, SUB2, SUB3} enable, MSB-first
//      i.e. `active_subx_en_i[2]` gates `active_subadr_i[0]` (SUB1),
//      `active_subx_en_i[1]` gates `active_subadr_i[1]` (SUB2), and
//      `active_subx_en_i[0]` gates `active_subadr_i[2]` (SUB3). Written
//      out explicitly below (three named comparisons, not a generate
//      loop) specifically so this index mapping is visible at the call
//      site rather than buried in loop-index arithmetic.
//   6. Regular hardware+programmable slave address: `{1'b1, hw_addr_i}`
//      (Section 5.1 top-level `hw_addr_i[5:0]` = A5..A0), fixed MSB=1 per
//      reference Fig. 4 -- always active, no enable qualifier (there is
//      no MODE1 bit that can disable the device's own fixed address).
//
// `addr_match_o` is the plain OR of all five per-type match outputs --
// the single bit i2c_rx actually needs to decide address-byte ACK/NACK
// (Section 7.1: "sda_oe low for one bit time ... if address_decode/
// register_decode reports the transaction is valid"). The five
// individual outputs are kept as separate ports (not collapsed
// internally) because `gc_match_o` specifically is also needed on its
// own by i2c_rx's FSM to pick the general-call branch vs the regular
// control-byte branch; `allcall_match_o`/`sub_match_o` have no separate
// consumer today but are exposed for verification visibility and because
// Section 11 explicitly calls out 5 independent comparators as the
// intended structure (collapsing them into one output internally would
// hide that structure from anything downstream that later needs it).
//
// No priority resolution is performed between the five match types if
// more than one matches simultaneously (possible only via deliberate
// address-register programming, e.g. ALLCALLADR set equal to the fixed
// regular address) -- `addr_match_o` is simply asserted, and the ACK
// behavior is identical regardless of which type(s) matched (Section 8:
// all-call/sub-call/regular addressing all reach the same shared
// register space through the same write path; the reference part does
// not define any behavioral difference between them beyond the address
// byte itself). Only the general-call case has behaviorally distinct
// downstream handling, and it can never collide with the other four
// (its fixed `0000000` pattern has a hard-wired MSB=0, while the regular
// address's MSB is hard-wired 1 by construction; ALLCALLADR/SUBADR could
// in principle be programmed to `0000000` by software, but General-Call
// is qualified additionally by R/W=0 and by definition addr7_i==0 in
// that case, so `gc_match_o` and any of the other four asserting
// together is still a safe, harmless coincidence -- i2c_rx's FSM only
// looks at `gc_match_o` to pick its branch).
// =============================================================================

`default_nettype none

module address_decode (
  // --- received address+R/W byte, from i2c_rx (latched, stable for the
  //     duration of the address phase) ---
  input  logic [6:0]  addr7_i,   // 7 address bits, A6..A0 (Fig. 4 bit order)
  input  logic         rw_i,      // R/W bit of the same byte (1 = read)

  // --- hardware address pins (Section 5.1 top-level port) ---
  input  logic [5:0]   hw_addr_i, // A5..A0

  // --- live MODE1 enables + programmable addresses, from register_bank
  //     (Section 5.3-adjacent live outputs, already implemented) ---
  input  logic          active_allcall_i,     // = active MODE1.ALLCALL
  input  logic [2:0]    active_subx_en_i,     // = active MODE1.{SUB1,SUB2,SUB3}, MSB-first (see header)
  input  logic [6:0]    active_allcalladr_i,
  input  logic [6:0]    active_subadr_i [3],  // [0]=SUB1, [1]=SUB2, [2]=SUB3 (see header)

  // --- per-type match outputs (Section 11: 5 independent comparators) ---
  output logic          gc_match_o,       // General-Call/SWRST address (0000000, R/W=0 only)
  output logic          allcall_match_o,  // LED All-Call address (only if ALLCALL enabled)
  output logic [2:0]    sub_match_o,      // [0]=SUB1,[1]=SUB2,[2]=SUB3 (only if respective SUBx enabled)
  output logic          regular_match_o,  // fixed hw+programmable slave address (always active)

  // --- aggregate: "this device should ACK the address byte", to i2c_rx ---
  output logic          addr_match_o
);

  localparam logic [6:0] GENERAL_CALL_ADDR7 = 7'h00;

  // 1. General-Call / SWRST: address 0000000, write-only (R/W=0).
  assign gc_match_o = (addr7_i == GENERAL_CALL_ADDR7) && (rw_i == 1'b0);

  // 2. LED All-Call.
  assign allcall_match_o = active_allcall_i && (addr7_i == active_allcalladr_i);

  // 3-5. Sub-Call 1/2/3 -- explicit, not looped (see header note on the
  // deliberate index/bit-order mismatch between active_subadr_i and
  // active_subx_en_i inherited from register_bank.sv).
  assign sub_match_o[0] = active_subx_en_i[2] && (addr7_i == active_subadr_i[0]); // SUB1
  assign sub_match_o[1] = active_subx_en_i[1] && (addr7_i == active_subadr_i[1]); // SUB2
  assign sub_match_o[2] = active_subx_en_i[0] && (addr7_i == active_subadr_i[2]); // SUB3

  // 6. Regular hardware+programmable slave address: fixed MSB=1, then
  // hw_addr_i[5:0] (Fig. 4: `1 A5 A4 A3 A2 A1 A0`).
  assign regular_match_o = (addr7_i == {1'b1, hw_addr_i});

  // Aggregate ACK/NACK decision for i2c_rx (Section 7.1).
  assign addr_match_o = gc_match_o || allcall_match_o || (|sub_match_o) || regular_match_o;

endmodule

`default_nettype wire
