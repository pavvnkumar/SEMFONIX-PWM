# SEMFONIX PWM16 — 2026 Competitive Feature / PPA Review

Status: COMPLETE. Performed at the CHECKPOINT 2 boundary (after
`register_bank.sv`, `register_decode.sv`, `address_decode.sv`,
`shadow_active_ctrl.sv`; before `prescale_gate.sv`), per explicit
instruction to gate-check the architecture against the current
competitive landscape before continuing implementation.

Decision rule applied (as given):

1. Reasonably expected by customers of a 16-ch general-purpose PWM IC,
   AND negligible/small area+timing+power+verification cost -> **ADD**.
2. Meaningful competitive differentiation with small PPA cost ->
   **CONSIDER/ADD**.
3. Substantial area, timing/fanout, power, or verification cost, or
   major analog/output circuitry -> **REJECT for this product**.
4. No TLC59116-style analog functionality (constant-current sinks,
   high-voltage outputs, thermal sensing, analog open-load detection) —
   hard rule, not a cost/benefit judgment call.
5. Preserve the shared-counter + per-channel-compare architecture
   (ADR-0001) unless a serious architectural flaw is found.

**Outcome: no RTL, register-map, or architecture changes.** The
existing register/PWM architecture (Sections 1, 9, 13 of
`MASTER_ARCHITECTURE.md`) already covers what a 2026 general-purpose
16-channel PWM/LED-driver customer reasonably expects, at a PPA point
the reviewed candidates could only worsen, not improve, for this
product. See ADR-0002 in `MASTER_ARCHITECTURE.md` for the recorded
decision. This review is not a rubber stamp: three candidates were
seriously evaluated (not just listed and dismissed) and are documented
below with the specific reason each falls to REJECT/DEFER rather than
ADD.

---

## Candidate 1: TLC59116-style group dimming (GRPPWM) + group blinking
## (GRPFREQ/DMBLNK)

This is the headline TLC59116-family feature explicitly called out for
evaluation. It is a **digital** feature (no analog constant-current
circuitry), so it clears the Rule 4 gate and has to be judged on
PPA/verification cost like anything else.

**What it would require, mechanically:** TLC59116 realizes group
dimming/blinking as a *second, independent, slower free-running
counter* (8-bit, its own tick generator off a `/15`-ish prescale from
the reference clock) driving an 8-bit comparator whose result is
AND-ed onto every channel's output after the normal PWM decision.
Blink mode reuses the identical counter/comparator hardware at a much
slower tick rate (period range roughly 42 ms .. 10.7 s) selected by a
mode bit (`DMBLNK`). Mapped onto this codebase, that is:

- A new shared 8-bit counter, structurally a close cousin of
  `pwm_counter.sv` (own tick generator, own compare-and-reset).
- A new shared 8-bit comparator, structurally a close cousin of
  `pwm_compare.sv`.
- Two new registers (`GRPPWM`, `GRPFREQ`) plus a mode bit — cheap by
  itself, and there is room (`0x57-0x5F`, 9 free addresses in the
  extension block).
- A new AND tap in **every** `pwm_channel.sv` instance, inserted into
  an output-composition chain that already has seven ordered stages
  (full_off -> full_on -> compare -> enable AND -> invert XOR ->
  polarity XOR -> OE/OUTNE mux, see that file's header comment). Group
  dimming/blink has to be slotted into that chain at a specific,
  semantically-defined point, and interacts with existing rules that
  currently have clean, independently-testable answers:
  - Does group blink override `full_on`? (Reference parts: yes — the
    entire point of blink mode is a heartbeat/indicator effect that
    still applies to a channel forced fully on.) That means the new
    tap has to sit *after* the full_on/full_off mux, not fold into
    `pwm_compare`, which changes where in the chain it lands relative
    to `enable`.
  - Does it interact with `enable`/`polarity` (both SEMFONIX
    extensions, not present on TLC59116) in a way that needs new,
    product-specific semantics with no reference behavior to copy?
    Yes — this is genuinely new design work, not a port.

**Assessment against the required criteria:**

- *Customer usefulness:* real, for a specific segment — status/
  indicator LEDs (heartbeat blink, breathing fade) benefit from
  hardware-driven group blink so the host doesn't have to bit-bang a
  slow timer over I²C.
- *Application/customer expansion:* modest. SEMFONIX PWM16 is
  positioned as a general-purpose 16-channel PWM/LED controller (fan
  control, solenoid/servo PWM, general actuation, in addition to LED
  indication — see Section 1), not an LED-indicator-only part. Group
  blink mainly sells the indicator-LED subset of that market; it does
  little for the PWM/actuation subset, which is likely at least half
  the addressable customer base for a PCA9685-class part.
- *RTL area impact:* small in isolation (one more 8-bit counter/
  comparator pair, two 8-bit registers), but **not free** — it is a
  second timebase generator, i.e. a second instance of a structure
  (`pwm_counter`-class + `prescale`-class hardware) the architecture
  currently keeps deliberately singular (Section 9: "exactly one
  instance in the whole chip").
- *Timing/fanout impact:* the new group-compare result fans out to all
  16 channels, exactly like `pwm_counter`'s existing 192-load fanout
  (Section 21) — not a new *category* of concern, but it does add a
  second high-fanout control signal to a design that already flags
  `pwm_counter` and `commit_pulse` as its two synthesis-attention
  fanout points.
- *Power impact:* small but nonzero — a second always-on free-running
  counter, on a design whose Section 20 power case rests specifically
  on "no free-running comparators other than `pwm_counter` and the
  prescale tick counter." Adding a third changes that stated
  invariant, however slightly.
- *Verification burden:* the real cost driver. It is not "add a
  comparator and test it" — it requires re-verifying the *entire*
  `pwm_channel` composition chain with one more axis crossed into an
  already multi-dimensional space (full_on/full_off x enable x
  polarity x invrt x OUTNE x OUTDRV x OE, per the existing
  `pwm_channel_tb.sv` cross-product) *and* deciding/documenting new
  semantics with no reference datasheet to check against for at least
  two of those interactions (enable, polarity — SEMFONIX-only bits
  that don't exist on the TLC59116 this feature is borrowed from).
  That is materially more than the other three SEMFONIX extensions
  already in the design (enable/polarity/GROUP_UPDATE), each of which
  is a single well-defined tap with no new interaction matrix.
- *Manufacturability/die cost:* negligible on its own (a few hundred
  gates + 16 bytes of flops), but it is duplicated per the "second
  timebase" concern above, not a one-off addition.

**Decision: REJECT for this product**, under Rule 3 — not because any
single line item is expensive, but because the combination (second
free-running timebase generator + new interaction semantics threaded
through all 16 channels' already-ordered output-composition chain +
no reference behavior to anchor the new SEMFONIX-specific
interactions against) is a real increase in verification surface and
a dilution of the "exactly one shared timebase" PPA story that is this
architecture's core sharing argument (Section 9), for a feature that
differentiates for one sub-segment of the target market and does
nothing for the rest. This is exactly the case the product rule
("do not add features just to increase feature count") is meant to
catch — TLC59116-family and PCA9685-family general-purpose PWM ICs
genuinely occupy different market niches on this specific feature, and
SEMFONIX PWM16 is explicitly scoped as the PCA9685-compatible one
(Section 1). If a future product variant is explicitly positioned as
an LED-indicator part, this is worth revisiting as its own checkpoint
with its own dedicated verification plan — not folded in here.

---

## Candidate 2: Register-triggered software reset (alternative to
## general-call SWRST)

Some general-purpose I²C peripherals offer a plain register write as
a simpler alternative to a full general-call SWRST sequence, since
some host stacks make general-call awkward to issue.

- *Customer usefulness:* minor convenience; general-call SWRST
  (already architected, Sections 7.1/16) is a well-understood,
  standard I²C mechanism and is not a real pain point for the target
  customer base.
- *RTL area/timing/power impact:* would be negligible (one
  self-clearing register bit, same pattern as `GROUP_UPDATE`, OR'd
  into the same reset-pulse consumer `i2c_rx`/`i2c_slave` will own).
- *Verification burden:* negligible, same shape as `GROUP_UPDATE`'s
  existing test pattern.
- *Manufacturability/die cost:* negligible.

**Decision: DEFER, not rejected on merits.** The consumer of this
signal (`i2c_rx`'s soft-reset handling, Checkpoint 4) doesn't exist
yet in this repository — there is no reset-pulse wire to OR into
today. Building the register-bank side now would mean adding a
dangling output with no consumer and no way to unit-test its actual
effect, which is exactly the kind of premature, speculative addition
this review is supposed to screen out. Revisit at Checkpoint 4/5 when
`i2c_rx`/top-level reset handling exists to wire it into; the extension
block (`0x57-0x5F`) already has room reserved for it if adopted then.
No architecture change needed now.

---

## Candidate 3: Active (post-commit) value readback for `LEDn_*`
## registers

Currently, reads of the 64 `LEDn_ON/OFF` registers always return the
**shadow** (last-written) value (`REGISTER_MAP.md`, "Read semantics"
section), matching normal "read back what you wrote" software
expectations. A debug-oriented alternative would let a host
distinguish "what I last wrote" from "what's actually driving the
PWM engine right now" (relevant only in OCH=1 / STOP-commit windows
where the two can differ).

- *Customer usefulness:* real but niche — bring-up/debug tooling only;
  normal application code never needs this distinction.
- *RTL area/timing impact:* small (one more read-data mux input,
  gated by a new mode bit or address alias).
- *Verification burden:* small but nonzero (new read-path cases
  crossing shadow-vs-active timing).
- *Manufacturability/die cost:* negligible.

**Decision: REJECT for now**, under the product rule rather than Rule
3 — this is a small-cost feature with no clear customer pull behind
it (no PCA9685-class part exposes this; it would be a novel,
undemonstrated ask). Adding it would be adding a feature because it's
cheap and technically differentiated, not because a customer needs
it, which is precisely what "do not add features just to increase
feature count" rules out. Not reserved against, not blocked — just
not justified today.

---

## Candidates rejected outright (brief, Rule 3 / Rule 4)

- **16-bit PWM resolution (vs. current 12-bit):** wider counter,
  wider comparators x16, wider shadow/active storage (doubles a good
  fraction of the design's dominant area block, Section 20), wider
  register map (needs a 3rd data byte per channel field, breaking
  PCA9685 register-map compatibility, which is a stated product
  requirement). Substantial area + verification cost, some benefit —
  REJECT (Rule 3).
- **I²C Ultra Fast-mode / push-pull unidirectional bus:** different
  bus topology and protocol family from the Fast-mode Plus
  open-drain model the whole I²C architecture (Section 7) is built
  around; would not be an incremental change but a second protocol
  implementation. REJECT (Rule 3).
- **Constant-current LED sinks, high-voltage outputs, thermal
  sensing, analog open-load detection (TLC59116 analog family):**
  explicitly excluded by Rule 4 regardless of cost/benefit — not
  evaluated further.
- **On-chip gamma/LUT correction, CPU/DMA/waveform memory:** already
  explicitly out of scope per Section 1's "Explicitly out of scope"
  list; re-confirmed here, no change.

---

## What was *not* touched by this review

Per Rule 5, the shared-counter + per-channel-compare architecture
(ADR-0001, Section 9) was re-examined for flaws and none were found —
no change. The existing SEMFONIX extension set (per-channel enable,
per-channel polarity, GROUP_UPDATE, `sync_update_i`, DEVICE_ID/
REVISION_ID, I²C bus-hang timeout) was re-checked against the same six
criteria used above and remains justified: each is a single,
low-interaction tap with negligible cost and a clear, general
(not niche-segment) customer benefit — the same bar Candidate 1 failed
to clear.

## Conclusion

The architecture is sufficiently competitive as documented in
`MASTER_ARCHITECTURE.md` today. No features are added by this review.
See ADR-0002 for the recorded decision entry. Implementation resumes
at the already-current next task, `rtl/control/prescale_gate.sv`
(Checkpoint 2, step 5 of 5 — see `IMPLEMENTATION_STATUS.md`).
