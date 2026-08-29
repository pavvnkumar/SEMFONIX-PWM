# SEMFONIX PWM16 — Implementation Status

This file is updated after every completed module/checkpoint. It is the
authoritative "where are we" record for session continuity. Read this file
first on any "CONTINUE" request, along with `docs/MASTER_ARCHITECTURE.md`.

Last updated: CHECKPOINT 6 IN PROGRESS — this session added
`scripts/run_all_unit_tests_verilator.sh` and
`scripts/run_integration_test_verilator.sh`, on explicit request
("Yes we run verilator compilation and simulation for all"): genuine
Verilator compile-AND-run counterparts to the existing
`run_all_unit_tests.sh`/`run_integration_test.sh` (Icarus Verilog), not
lint-only like `verilator_lint.sh`. Both use `verilator --binary
--timing` (Verilator 5.006+, matching this sandbox's own `apt-cache`
candidate version 5.020-1) to build each testbench into a standalone
simulation executable and run it, with PASS/FAIL read from the
executable's own exit code — the same self-checking-testbench
convention (`$fatal(1)`/nonzero exit on failure, `$finish(0)`/exit 0 on
success) `run_all_unit_tests.sh` already relies on for `vvp`'s exit
code. Per-test `SOURCES` lists in both new scripts were copied verbatim
from their Icarus counterparts and then diffed programmatically
(`grep -oE` extraction + `diff`) against the originals to confirm an
exact match, file-for-file and order-for-order — no reduced or
reshuffled dependency set. **No RTL or testbench file was modified**:
this reuses the same 15 RTL files, 7 assertion files, 12 unit
testbenches, and the integration testbench + 2 `tb/models/*.sv` files
exactly as they already exist.
**Compatibility review performed (not a compile):** every file under
`tb/**` was grepped for constructs known to be unsupported or
partially supported under Verilator's `--timing` mode —
`$random`/`class`/`mailbox`/`semaphore`/`virtual interface`/`DPI`/
`fork`-`join` — none were found as actual usages (a few string matches
were comments or unrelated identifiers, e.g. "disable channel 0" in a
code comment, not a `disable` statement). The one genuine randomization
construct found, `$urandom_range` (used in `pwm_compare_tb.sv`'s
20,000-iteration sweep and `pwm_channel_tb.sv`'s/`i2c_tx_tb.sv`'s own
randomized sweeps), is Verilator-supported. **This is explicitly not
the same thing as a successful compile** — both new scripts' own header
comments carry a "COMPATIBILITY CAVEAT" section saying so in detail:
Verilator's SystemVerilog subset support has edges a grep sweep and a
human read-through don't reliably catch (sensitivity-list inference,
packed-struct-array port connections, `bind`-scoping quirks), and the
first real run on a machine with Verilator is expected to surface some
number of fixable issues, to be resolved and recorded at that time —
not pre-emptively guessed at now.
**Toolchain re-check this session:** `verilator` still absent (`which
verilator` → not found); `apt-cache policy verilator` confirms a
candidate (5.020-1) exists in the configured repo but is not
installed, and `apt-get install -y verilator` was attempted live again
and returned the same `403 Forbidden` every prior attempt in this
sandbox has hit. **Neither new script has been executed.** No compile
result, no simulation result, no pass/fail count is known or claimed
for any testbench under Verilator.

Last updated (previous entry): CHECKPOINT 6 IN PROGRESS — this session added
`scripts/verilator_lint.sh`, a Verilator `--lint-only` pass over the
same 15 `rtl/**/*.sv` files (never `tb/**`), added on explicit request
to bring Verilator into the toolchain story alongside the existing
`scripts/synth_yosys.sh` (Yosys) and `scripts/run_all_unit_tests.sh`/
`scripts/run_integration_test.sh` (Icarus Verilog). This is
deliberately a *second, independent* check, not a replacement for
either existing script: Verilator's lint ruleset (`-Wall`:
UNUSED/UNDRIVEN/WIDTH/CASEINCOMPLETE/etc.) differs from and is often
stricter than Yosys's own `check` pass, matching this repository's
established "two independent opinions beat one" pattern already used
for `tb/models/pwm_ref_model.sv` (an independent behavioral reference
model, not reusing RTL comparator code) — applied here to
lint/synthesizability instead of behavior. No existing testbench was
touched or converted to Verilator: Verilator's timing/procedural-code
support differs meaningfully from Icarus Verilog's, and every existing
`tb/unit/`/`tb/integration/` file was authored and reviewed against
Icarus semantics specifically (see every prior session's own notes) —
converting them is a nontrivial undertaking with real behavioral risk,
out of scope for a "lint-only, RTL-source-only" addition, and not
requested. If full Verilator-based simulation (not just lint) is
wanted later, that is new scope to be explicitly requested and planned
as its own checkpoint-sized unit, not folded silently into this one.
**Toolchain check this session:** `verilator` confirmed absent (`which
verilator` → not found); both `apt-get install -y verilator` and `pip
install verilator --break-system-packages` were attempted live and
failed — `apt-get` with the same `403 Forbidden` result (including on
`verilator`'s own `libsystemc`/`libsystemc-dev` build dependencies)
every prior toolchain check in this sandbox has hit, and `pip` failed
with "No matching distribution found" (there is in fact no PyPI
package named `verilator` — Verilator is not Python-distributed; this
was confirmed directly rather than assumed). **Not yet executed** —
script is written, its shell syntax checked with `bash -n`, and its
source list re-derived the same way `synth_yosys.sh`'s was (cross-
checked against actual `rtl/` file/module names) — no lint result,
warning count, or pass/fail is known yet.

Last updated (previous entry): CHECKPOINT 6 IN PROGRESS — `scripts/synth_yosys.sh` +
`yosys/synth.tcl` (Section 22 step 15) written this session: a generic
Yosys synthesis flow (`read_verilog -sv` over all 15 `rtl/**/*.sv`
files, leaf-to-top order matching `run_integration_test.sh`'s own
verified SOURCES order; `hierarchy -check -top semfonix_pwm16_top`;
`synth -top semfonix_pwm16_top -noabc`; `check -noinit`; a `stat`
cell-count report, a synthesized-netlist Verilog dump, and a JSON
netlist, all written to `build/synth/`). `-noabc` is a deliberate
choice, not a workaround forced by this run (see `yosys/synth.tcl`'s
own header): `abc` is a separate binary from `yosys` itself, this
sandbox has neither, and skipping it keeps the flow to exactly the
passes Yosys performs internally (hierarchy check, proc, memory, opt,
fsm, generic techmap) — already sufficient to catch the class of bug
this repository has so far only caught by manual port-by-port review
(unresolved hierarchy, multi-driven nets, combinational loops, latch
inference, width mismatches). `scripts/synth_yosys.sh` checks for
`yosys` on `PATH` first (matching `run_all_unit_tests.sh`'s own
toolchain-check pattern), greps its log for a `SYNTH_TCL_COMPLETE`
sentinel and any `^ERROR` line before trusting a 0 exit code, and
separately counts and prints any `^Warning:` lines — a nonzero count
is flagged as leaving Checkpoint 6 not yet closed (its own title is
"Yosys synthesis, reports, **warning cleanup**"), to be triaged once a
toolchain is reachable, not assumed clean.
**Toolchain check this session:** `yosys` confirmed absent (`which
yosys` → not found) and `apt-get install -y yosys iverilog` was
attempted live and returned `403 Forbidden` fetching from
`archive.ubuntu.com`/`security.ubuntu.com` for every package in the
dependency chain (same no-egress result every prior session's check
found, re-confirmed directly this session, not assumed carried over).
**Not yet executed** — this is "written and reviewed" (RTL source list
manually re-derived from `find rtl -name '*.sv'` and cross-checked
module-name-by-module-name against each file's own `module` line — all
15 match; a grep sweep for `$display`/`$fatal`/`$finish`/delay
(`#N`)/`real`/`time`-typed declarations across `rtl/**` found none —
every hit was a comment containing the word "real" or "time", not an
actual construct; Tcl brace/paren/bracket balance in `synth.tcl`
confirmed programmatically), **not "passed" or "clean"** — no yosys
binary exists in this sandbox to run it, so no cell count, no warning
count, and no synthesizability result are known yet. `docs/verification/`
and Checkpoint 6's own status entries below are updated to match.

Last updated (previous entry): CHECKPOINT 5 COMPLETE (4 of 4 files). This session merged
the last checkpoint-5 ZIP with a set of loose SVA assertion files from a
session that had reached step 14 (`tb/assertions/*`) before hitting its
token limit. Three files arrived intact: `tb/assertions/pwm_compare_assertions.sv`,
`tb/assertions/pwm_counter_assertions.sv`, `tb/assertions/pwm_channel_assertions.sv`
— all three were structurally sanity-checked (module/endmodule,
begin/end, paren/brace balance) and their `bind` port lists were
cross-checked port-by-port against `pwm_compare.sv`/`pwm_counter.sv`/
`pwm_channel.sv`'s actual declarations; no mismatches. The other four
files Section 22 step 14 requires — clock, register, control, and I2C
assertions — did not survive that session's stall and were authored
fresh this session, matching the surviving three files' established
style (per-module file, `` `ifdef SIMULATION ``-guarded, `bind`-based,
header explaining what it checks and why it's split out):
`tb/assertions/clk_reset_sync_assertions.sv` (async-assert/sync-release
reset-chain integrity, bound to `clk_reset_sync`),
`tb/assertions/register_bank_assertions.sv` (atomic shadow→active
commit copy for all 16 channels, `dirty_o` set/clear tracking,
PRE_SCALE write-guard no-op, GROUP_UPDATE edge-trigger/always-reads-0,
DEVICE_ID/REVISION_ID readback, a reserved-address read-0 spot-check;
bound to `register_bank`), `tb/assertions/shadow_active_ctrl_assertions.sv`
(`commit_pulse_o` equals the documented 4-source OR exactly, and the
`sync_update_i` edge-detect pulse is exactly one `clk_ref` cycle wide;
bound to `shadow_active_ctrl`), and `tb/assertions/i2c_slave_assertions.sv`
(open-drain `sda_o` is permanently tied 0, `sda_oe` matches the
documented rx/tx mux on `tx_drive_en`, and `swrst_o` only ever
coincides with `stop_event_o`; bound to `i2c_slave`, the integration
point where this module's own header says its logic — the mux — 
actually lives, rather than one file per `i2c_bus_sync`/`i2c_rx`/
`i2c_tx` child). All four new files were written by reading the actual
target RTL's port lists and internal signal names directly from source
(not assumed), so every `bind ... (.*)` connects by exact name match;
each new property was checked against the RTL's own documented/actual
behavior (e.g. `swrst_o = stop_cond && swrst_armed_q` in `i2c_rx.sv`,
read directly, before asserting `swrst_o |-> stop_event_o`) rather than
against the architecture doc's summary alone. `scripts/run_all_unit_tests.sh`
and `scripts/run_integration_test.sh` were both updated to (a) add
`-DSIMULATION` to their `iverilog` invocations, since every assertion
file is guarded by `` `ifdef SIMULATION `` and was previously dead code
with no define ever set, and (b) add each assertion file to every
`run_test`/integration source list whose DUT set includes the RTL
module that assertion file binds to (e.g. `register_bank_assertions.sv`
is now compiled into every unit test that instantiates a real
`register_bank`, not only `register_bank_tb`). No `tb/unit/*.sv`
testbench file itself was modified — only the two build scripts' source
lists. No RTL, architecture, or register-map file was changed. **Not
yet executed** — no toolchain in this sandbox (see toolchain note
below); this is "merged, authored, and reviewed," not "passed."
**CHECKPOINT 5 IS NOW COMPLETE — all 4 of 4 files for that checkpoint
are written** (`clk_reset_sync.sv`, `semfonix_pwm16_top.sv`, the
integration tb + models, and now `tb/assertions/*`); the next
checkpoint is CHECKPOINT 6 (Yosys synthesis), not yet started.

A prior session merged in step 13's files, authored by a prior session that stalled
before packaging its output: `tb/models/i2c_bfm.sv` (behavioral I2C
master BFM), `tb/models/pwm_ref_model.sv` (independent reference model,
transcribed from `REGISTER_MAP.md`/`MASTER_ARCHITECTURE.md`, not from
RTL), `tb/integration/semfonix_pwm16_tb.sv` (black-box integration
testbench driving the DUT purely through its top-level ports and
comparing `led_o`/`led_oe_o` against the reference model), and
`scripts/run_integration_test.sh`. All four files were structurally
sanity-checked (module/endmodule, begin/end, task/endtask,
paren/brace/bracket balance — all exactly balanced) and every
instantiation (`i2c_bfm`, `pwm_ref_model`, `semfonix_pwm16_top`) was
port-by-port cross-checked against each module's actual declaration —
no mismatches found. No duplicate files or path conflicts introduced;
`scripts/run_all_unit_tests.sh` was not modified (integration kept as
a separate runner, per `run_integration_test.sh`'s own header
rationale). **Not yet executed** — no toolchain in this sandbox (see
toolchain note below); this is "merged and reviewed," not "passed."
No RTL, architecture, or register-map files were changed.

A prior session wrote `rtl/top/semfonix_pwm16_top.sv` (step 12 of the
Section 22 implementation order — top-level integration). No unit tb accompanies
this file by design: per Section 22/23, top-level verification is
`tb/integration/semfonix_pwm16_tb.sv` (step 13, a future session), not
a `tb/unit/top/` testbench. This module performs pure structural wiring
of all 9 already-complete children per Section 4's hierarchy
(`clk_reset_sync`, `i2c_slave`, `address_decode`, `register_decode`,
`register_bank`, `shadow_active_ctrl`, `prescale_gate`, `pwm_counter`,
`pwm_engine`) plus one piece of real logic: the `scl_o`/`scl_oe`
tie-off (Section 5.1: "reserved for clock stretching (unused v1, tie
1)"), since no child in this design drives or stretches SCL. Every
instantiation was port-by-port reviewed against each child's actual
module declaration (not assumed from the architecture doc's interface
sketch), confirming exact name/direction/width matches; see the file's
own header for the full sibling-vs-child wiring rationale.
**A known, deliberate gap, left unconnected rather than silently
implemented:** `i2c_slave.swrst_o` (General-Call/SWRST detection,
already implemented inside `i2c_rx.sv`) has no consumer — `register_bank.sv`
has no soft-reset input port. This is the exact gap ADR-0002 already
flagged ("its consumer ... doesn't exist yet ... revisit then") and
`i2c_slave.sv`'s own header flagged ("consumer TBD at top-level
integration") — now revisited and confirmed still open, since closing
it would mean adding a new port + new reset logic to the already-
complete, already-unit-tested `register_bank.sv`, a design change
outside this step's pure-wiring scope. Also left unconnected, each for
its own documented reason (see file header): `pwm_counter.frame_tick_o`
(no consumer anywhere in Section 4's hierarchy), and
`address_decode.allcall_match_o`/`.sub_match_o`/`.regular_match_o`
(already aggregated into `addr_match_o`, confirmed by reading that
module's own `assign addr_match_o = gc_match_o || allcall_match_o ||
(|sub_match_o) || regular_match_o` line). `extclk_sel_i` remains a
top-level input with zero RTL effect, per Section 6/24 — unchanged
from its existing documented status, not a new decision.
**Per this repository's standing rule, verification was NOT claimed as
executed**: no `iverilog`/`vvp`/`yosys` toolchain is available in this
sandbox, so `semfonix_pwm16_top.sv` has been read through line-by-line
and structurally sanity-checked (module/endmodule and
paren/brace/bracket counts confirmed balanced) — this is "written and
reviewed," not "passed" (and cannot be run standalone yet regardless,
since it has no testbench of its own — see above). No architecture,
register-map, or PPA decisions changed.
**Next within Checkpoint 5 (a future session):
`tb/integration/semfonix_pwm16_tb.sv` + `tb/models/*` reference model
(step 13) — the first point at which `semfonix_pwm16_top.sv` gets any
simulation coverage at all, plus (opportunistically, if a toolchain is
reachable by then) running `scripts/run_all_unit_tests.sh` for real.**

A prior session wrote:
`rtl/clock/clk_reset_sync.sv` + `tb/unit/clock/clk_reset_sync_tb.sv`
(step 11 of the Section 22 implementation order, the sole file of the
"clock" area). Per Section 6 of `MASTER_ARCHITECTURE.md`, this is a
standard active-low async-assert/sync-release reset synchronizer:
`rst_n` (the raw, off-chip, potentially-glitchy top-level pin) drives
an async reset into a 2-flop chain clocked by `clk_ref`; the output
`rst_n_sync_o` drops immediately (asynchronously) when `rst_n` is
asserted, and only rises again on the second `clk_ref` edge after
`rst_n` deasserts, guaranteeing every downstream module's own
`rst_n` port (fed from this net, per Section 6 "instantiated once at
the top and fanned out as `rst_n_sync`") only ever releases aligned to
a clean clock edge. Per Section 6's explicit instruction, this module
deliberately does NOT consume or mux `extclk_sel_i` — that signal
resolves entirely inside the register bank as a status-only sticky bit
with no RTL effect on `clk_ref`, so routing it through the reset
synchronizer would misrepresent it as a real clock-select mux.
`scripts/run_all_unit_tests.sh` was updated to include
`clk_reset_sync_tb`.

An earlier session wrote:
`rtl/i2c/i2c_tx.sv` + `tb/unit/i2c/i2c_tx_tb.sv` (RTL + unit tb in the
same session, per this repository's normal one-module-per-session
granularity — the prior two sessions split `i2c_rx.sv`'s RTL and unit tb
across sessions only because that prior session's own instructions
explicitly deferred the tb; no such deferral applied here). Per
`IMPLEMENTATION_STATUS.md`'s own "Next Module To Implement" entry #9,
this was the next task: the read-path shift register + open-drain SDA
drive for read transactions, honoring the `tx_load_o`/`tx_drive_en_o`
contract `i2c_rx.sv` already documented (and drives) in its own header.
`i2c_tx.sv` owns no protocol-FSM state of its own — it is told WHEN to
load (`tx_load_i`, 1-cycle pulse, same cycle as `i2c_rx.sv`'s
`rd_byte_o`) and WHEN to drive (`tx_drive_en_i`, a level matching
`i2c_rx.sv`'s `ST_RD_DATA` state) and derives its own SCL falling-edge
timing from `scl_sync_i` (sibling top-level wiring from
`i2c_bus_sync.sv`, not routed through `i2c_rx.sv`) to shift out the byte
MSB-first, one bit per SCL low phase. `tx_data_i` is wired directly from
`register_decode.sv`'s `rd_data_o` (not through `i2c_rx.sv`), matching
that contract exactly as documented. `i2c_tx.sv` deliberately does NOT
spike-filter `scl_sync_i` the way `i2c_rx.sv` filters its own copy for
START/STOP detection — documented in the file's own header as a
considered choice (a glitch here can at worst present one momentarily-
wrong bit, gated off entirely whenever `tx_drive_en_i` is low, unlike
`i2c_rx.sv` where an unfiltered glitch could corrupt FSM state via a
false START/STOP).

The unit testbench uses two DUT groupings, per the established
bare-instance + real-dependency pattern (`i2c_rx_tb.sv`,
`prescale_gate_tb.sv`, `pwm_engine_tb.sv`): (1) a bare `i2c_tx` instance
with `scl_sync_i`/`tx_load_i`/`tx_drive_en_i`/`tx_data_i` driven
directly, isolating the shift-register/open-drain-drive property itself
(MSB-first bit order and exact SCL-falling-edge shift timing for a
directed byte, tx_drive_en_i deasserting mid-byte immediately stopping
the drive regardless of remaining shift-register contents, the
documented one-cycle-early `tx_load_i`-before-`tx_drive_en_i` timing
loading silently with no drive until enable, and a 5,000-iteration
randomized byte sweep); and (2) an integration group instantiating the
same five-module dependency chain `i2c_rx_tb.sv` already assembles
(`i2c_bus_sync.sv` + `i2c_rx.sv` + `address_decode.sv` +
`register_decode.sv` + `register_bank.sv`) plus this session's
`i2c_tx.sv`, with `i2c_rx.sv`'s and `i2c_tx.sv`'s `sda_o`/`sda_oe`
combined on the shared bus by a plain mux on `tx_drive_en_o` (exactly
the mux the not-yet-built `i2c_slave.sv` will implement, per
`i2c_rx.sv`'s own header — done manually in the testbench since no such
wrapper exists yet), driven by the same behavioral bit-banged I2C master
task library `i2c_rx_tb.sv` uses, extended with a byte-level read task.
Covers: a single-byte I2C read of a value previously written into real
`register_bank` storage via a real I2C write (not a register_bank
backdoor); a two-byte MODE1.AI auto-incrementing read (master ACKs the
first byte, NACKs the second) against two independently-written
register values; and an immediate-NACK single-byte read followed by a
fresh write transaction, confirming no leftover drive state. `scripts/
run_all_unit_tests.sh` was updated to include `i2c_tx_tb`.
**Per this repository's standing rule, verification was NOT claimed as
executed**: `iverilog`/`vvp`/`yosys` remain unavailable in this sandbox
(network egress still disabled — re-confirmed directly this session via
both `which` and a live `apt-get install iverilog` attempt, which
returned `403 Forbidden` — not assumed carried over from prior sessions'
notes), so `i2c_tx.sv` and `i2c_tx_tb.sv` have been read through
line-by-line and structurally sanity-checked (module/endmodule,
begin/end, task/endtask, and paren/brace/bracket counts balanced — both
files confirmed exactly balanced), and every instantiated module's port
list (`i2c_tx.sv` itself, plus the reused `i2c_bus_sync`/`i2c_rx`/
`address_decode`/`register_decode`/`register_bank` block) was manually
cross-checked name-by-name, direction, and width against each module's
actual declaration in the RTL source (not assumed from `i2c_rx_tb.sv`'s
prior usage) — this is "written and reviewed," not "passed." No
architecture, register-map, or PPA decisions changed.
**Next within Checkpoint 4 (a future session): run
`scripts/run_all_unit_tests.sh` for real the moment a toolchain is
reachable and correct any bugs it surfaces (none are known, but none are
confirmed either — see toolchain note); then `i2c_slave.sv`, the final
file of Checkpoint 4.**

---

## Checkpoint Status

- [x] CHECKPOINT 0 — repository structure, MASTER_ARCHITECTURE.md, product
      spec notes, module hierarchy, implementation plan.
- [x] CHECKPOINT 1 — lowest-level PWM/output modules
      (`pwm_compare`, `pwm_counter`, `pwm_channel`) + unit tests written.
      **Not yet executed in this sandbox** (no iverilog available — see
      toolchain note below). Structural sanity-checked (module/endmodule
      balance) only.
- [x] CHECKPOINT 2 — register/control architecture — **COMPLETE**:
      - [x] `register_bank.sv` + unit tb written (structurally
            sanity-checked, not yet executed).
      - [x] `register_decode.sv` + unit tb written (structurally
            sanity-checked, not yet executed).
      - [x] `address_decode.sv` + unit tb written (structurally
            sanity-checked, not yet executed).
      - [x] `shadow_active_ctrl.sv` + unit tb written (structurally
            sanity-checked, not yet executed).
      - [x] `prescale_gate.sv` + unit tb written this session
            (structurally sanity-checked, not yet executed).
- [x] CHECKPOINT 3 — PWM integration — **COMPLETE**:
      - [x] `pwm_engine.sv` + unit tb written (prior session, structurally
            sanity-checked, not yet executed).
- [x] CHECKPOINT 4 — I²C (`i2c_bus_sync`, `i2c_rx`, `i2c_tx`, `i2c_slave`)
      + unit tests — **COMPLETE**:
      - [x] `i2c_bus_sync.sv` + unit tb written (structurally
            sanity-checked, not yet executed).
      - [x] `i2c_rx.sv` RTL written (prior session, structurally
            sanity-checked, not yet executed).
      - [x] `tb/unit/i2c/i2c_rx_tb.sv` written (prior session,
            structurally sanity-checked and port-by-port reviewed
            against all 5 instantiated modules; **not yet executed** —
            no toolchain in this sandbox).
      - [x] `i2c_tx.sv` + `tb/unit/i2c/i2c_tx_tb.sv` written this
            session (structurally sanity-checked and port-by-port
            reviewed against every instantiated module; **not yet
            executed** — no toolchain in this sandbox).
      - [x] `i2c_slave.sv` + `tb/unit/i2c/i2c_slave_tb.sv` present
            (structurally sanity-checked this session; **not yet
            executed** — no toolchain in this sandbox).
- [x] CHECKPOINT 5 — top-level integration (`semfonix_pwm16_top`) + full
      integration testbench + reference model + assertions. **COMPLETE**:
      - [x] `rtl/clock/clk_reset_sync.sv` + `tb/unit/clock/clk_reset_sync_tb.sv`
            written this session (structurally sanity-checked; **not yet
            executed** — no toolchain in this sandbox). Standard
            async-assert/sync-release 2-flop reset synchronizer per
            Section 6; deliberately does not consume `extclk_sel_i`
            (see file header — that bit is a register-bank status flag,
            not a real clock mux). `scripts/run_all_unit_tests.sh`
            updated to include `clk_reset_sync_tb`.
      - [x] `rtl/top/semfonix_pwm16_top.sv` written this session
            (structurally sanity-checked; **not yet executed** — no
            toolchain in this sandbox, and no unit tb of its own by
            design, see narrative above). Pure structural wiring of all
            9 children per Section 4 + the documented `scl_o`/`scl_oe`
            tie-off; port-by-port reviewed against every instantiated
            module. Known deliberate gap: `i2c_slave.swrst_o` has no
            consumer yet (ADR-0002-flagged, tracked, not silently
            implemented).
      - [x] `tb/integration/semfonix_pwm16_tb.sv` + `tb/models/*`
            reference model (step 13) — merged this session (authored
            by a prior stalled session); **not yet executed** — no
            toolchain in this sandbox.
      - [x] `tb/assertions/*` — SVA invariants (step 14) — **DONE this
            session (7 of 7 files)**: `pwm_compare_assertions.sv`,
            `pwm_counter_assertions.sv`, `pwm_channel_assertions.sv`
            (merged this session, authored by a prior stalled session,
            reviewed and port-cross-checked, no changes needed) plus
            `clk_reset_sync_assertions.sv`, `register_bank_assertions.sv`,
            `shadow_active_ctrl_assertions.sv`, `i2c_slave_assertions.sv`
            (authored fresh this session, since those four did not
            survive the stalled session — see narrative above). All
            bound via `bind`/`` `ifdef SIMULATION ``, all wired into
            `scripts/run_all_unit_tests.sh` (`-DSIMULATION` added) and
            `scripts/run_integration_test.sh`. **Not yet executed** — no
            toolchain in this sandbox.
- [ ] CHECKPOINT 6 — Yosys synthesis, reports, warning cleanup —
      **IN PROGRESS**: `scripts/synth_yosys.sh` + `yosys/synth.tcl`
      (Yosys generic synth), `scripts/verilator_lint.sh` (Verilator
      `--lint-only`), and — this session, on explicit request —
      `scripts/run_all_unit_tests_verilator.sh` +
      `scripts/run_integration_test_verilator.sh` (genuine Verilator
      compile+simulate for every unit and integration testbench,
      `--binary --timing`, exact same source lists as the Icarus
      scripts, diffed to confirm) are all written (structurally/
      compatibility reviewed; **none yet executed** — no `yosys` or
      `verilator` binary in this sandbox). Remaining before this
      checkpoint can close: run all four scripts on a machine with the
      respective tool, review every report/log, fix or document each
      warning/error, and record the actual results here.

---

## Files Completed

### Documentation
- `docs/MASTER_ARCHITECTURE.md` — complete, authoritative. Unchanged this
  session (no architecture, register-map, or PPA decisions changed by
  `i2c_bus_sync.sv`; its behavior already matches Section 6's existing
  description exactly).
- `docs/product/PCA9685_reference_notes.md` — complete, unchanged this
  session.
- `docs/product/COMPETITIVE_REVIEW_2026.md` — **new this session.**
  Full 2026 competitive feature/PPA review at the CHECKPOINT 2
  boundary. Three candidates seriously evaluated against customer
  usefulness / application expansion / RTL area / timing-fanout /
  power / verification burden / manufacturability: TLC59116-style
  group dimming/blinking (REJECTED — second shared timebase generator
  + new interaction semantics with SEMFONIX enable/polarity, serves
  only the LED-indicator subset of the target market), a
  register-triggered software-reset alternative to general-call SWRST
  (DEFERRED — its consumer, `i2c_rx` soft-reset handling, doesn't
  exist yet; revisit at Checkpoint 4), and active/committed-value
  LEDn readback for debug (REJECTED — no demonstrated customer pull).
  Outright-rejected list also covers 16-bit PWM resolution and I²C
  Ultra Fast-mode (Rule 3: substantial cost) and the TLC59116 analog
  family (Rule 4: hard exclusion). Conclusion: architecture is already
  sufficiently competitive; ADR-0001's shared-counter architecture
  re-examined per Rule 5 and confirmed with no flaw found.
- `docs/IMPLEMENTATION_STATUS.md` — this file.
- `docs/architecture/REGISTER_MAP.md` — complete (written alongside
  `register_bank.sv`, prior session). This session: added one
  traceability note on the `0x57-0x5F` reserved row pointing at the
  competitive review (no register allocation changed — the row is
  still fully reserved/read-0/write-dropped).
- `docs/architecture/ADDRESSING.md` — complete (written alongside
  `address_decode.sv`, prior to this session — see Repository State
  Note below). Documents the 5-comparator address matching, the
  no-priority-resolution rationale, and the Sub-Call index/bit-order
  mapping inherited from `register_bank.sv`.
- `docs/verification/*` — TODO (create alongside integration tb).

### RTL
- `rtl/pwm/pwm_compare.sv` — combinational 12-bit ON/OFF/full-on/full-off
  comparator. No flops. Instantiated once per channel.
- `rtl/pwm/pwm_counter.sv` — shared free-running 12-bit frame counter +
  integrated prescale tick divider + SLEEP gating. Exactly one instance
  in the whole chip.
- `rtl/pwm/pwm_channel.sv` — single-channel output stage: instantiates
  `pwm_compare`, adds SEMFONIX enable/polarity, MODE2.INVRT, and
  OE/OUTNE/OUTDRV forced-state logic. Outputs `(led_level_o, led_drive_o)`
  pair (not a single wired bit) so open-drain/high-Z states are modeled
  correctly at the pad boundary — see file header comment and
  MASTER_ARCHITECTURE.md Section 5.1 (top-level port list updated to
  `led_o`/`led_oe_o` to match this pattern).
- `rtl/pwm/pwm_engine.sv` — **new this session.** 16-channel integration:
  instantiates `NUM_CHANNELS` (16) x `pwm_channel` in a `generate` loop
  against the shared `count_i` (from `pwm_counter`) and `register_bank`'s
  `active_cfg_o` array, plus the shared MODE2 fields
  (`active_invrt_i`/`active_outdrv_i`/`active_outne_i`) and `oe_n_i`.
  Owns no flops and no clk/rst ports — pure structural fan-out, per
  Section 9. Does **not** re-implement `ALL_LED_*` broadcast (that
  fan-out already lives inside `register_bank.sv`; by the time
  `active_cfg_i` reaches this module a broadcast write is
  indistinguishable from 16 individual writes). Drives top-level-shaped
  `led_o`/`led_oe_o` arrays directly, matching Section 5.1's port
  pattern with no repacking needed at `semfonix_pwm16_top`.
- `rtl/i2c/i2c_bus_sync.sv` — **new this session.** First sub-module of
  Checkpoint 4 (step 10). Two independent 2-flop synchronizer chains
  (`scl_i`->`scl_sync_o`, `sda_i`->`sda_sync_o`) for the raw async
  top-level bus pins, per Section 6 / Section 4's module hierarchy entry.
  Owns `clk_ref`/`rst_n` ports (unlike the purely combinational leaves
  built so far in `rtl/control/`/`rtl/registers/` — this is the first
  sequential module driven directly off an unsynchronized external pin).
  Resets both synchronized outputs to `1` (idle-bus state). Deliberately
  does **not** perform edge detection, START/STOP detection, or spike
  filtering — that logic belongs to the not-yet-built `i2c_rx.sv` per
  Section 7.2 ("SCL edges are detected by comparing synchronized-SCL
  against its previous-cycle value ... a small counter debounces
  spikes"); this module's only job is the 2-FF metastability boundary
  itself.
- `rtl/i2c/i2c_rx.sv` — Receive-path protocol FSM (Section 7.1/7.2/16/18):
  spike-filters and edge/START/STOP-detects `i2c_bus_sync.sv`'s
  synchronized outputs, implements the full address/control-pointer/
  write-data/read-data/general-call-SWRST byte FSM with ACK generation,
  drives `register_decode.sv`'s already-documented byte-stream event
  contract and `shadow_active_ctrl.sv`'s `stop_event_i`, and documents a
  forward contract (`tx_load_o`/`tx_drive_en_o`) for `i2c_tx.sv`. Folds
  `GC_BYTE`/`GC_ACK` into `ADDR_BYTE`/`ADDR_ACK` (documented deviation,
  see file header — no bus-visible behavior change). Unchanged this
  session.
- `rtl/i2c/i2c_tx.sv` — **new this session.** Read-path shift register +
  open-drain SDA drive (Section 4 module hierarchy: "shift-out for reads,
  open-drain SDA driver control"), implementing exactly the forward
  contract `i2c_rx.sv`'s own header already documented: loads
  `tx_data_i` (wired directly from `register_decode.sv`'s `rd_data_o`,
  not through `i2c_rx.sv`) on `tx_load_i` (1-cycle pulse from
  `i2c_rx.sv`'s `tx_load_o`), then shifts it out MSB-first, one bit per
  SCL low phase, for as long as `tx_drive_en_i` (`i2c_rx.sv`'s
  `tx_drive_en_o`) is asserted. Owns no protocol-FSM state of its own —
  every byte/ACK-boundary decision stays in `i2c_rx.sv`; this module only
  answers "what bit, right now." Derives its own SCL falling-edge timing
  from `scl_sync_i` (sibling top-level wiring from `i2c_bus_sync.sv`, the
  same signal `i2c_rx.sv` consumes, not routed through it) rather than
  reusing `i2c_rx.sv`'s internal filtered copy — deliberately NOT
  spike-filtered (documented rationale in the file's own header: a
  glitch here can at worst present one momentarily-wrong bit, gated off
  entirely whenever `tx_drive_en_i` is low, unlike `i2c_rx.sv` where an
  unfiltered glitch could corrupt FSM state via a false START/STOP).
  Only ever actively pulls SDA low (open-drain convention, matching
  `i2c_rx.sv`'s own ACK/NACK drive); this module's `sda_o`/`sda_oe` and
  `i2c_rx.sv`'s are mutually exclusive by construction of `tx_drive_en_i`
  and are combined by a plain mux in the testbench (standing in for the
  not-yet-built `i2c_slave.sv`, per `i2c_rx.sv`'s header).
- `rtl/registers/register_bank.sv` — full SEMFONIX PWM16 register storage:
  single-buffered MODE1/MODE2/SUBADR1-3/ALLCALLADR/CHAN_ENABLE/
  CHAN_POLARITY/GROUP_UPDATE/DEVICE_ID/REVISION_ID, PRE_SCALE with an
  external SLEEP-guard input (`presc_write_allow_i`, driven by
  `prescale_gate.sv` once that module exists), and the 16-channel
  shadow/active double-buffered LEDn_ON/OFF storage with `commit_pulse`-
  driven atomic update and `dirty_o` tracking. `ALL_LED_*` broadcast
  write-only registers fan out into the same shadow storage. Reserved
  addresses read 0x00 and silently drop writes. Full address map is in
  `docs/architecture/REGISTER_MAP.md`. Exposes the Section 5.3
  `active_cfg_o[16]` struct array plus individual MODE1/MODE2 field
  outputs for downstream modules (`prescale_gate`, `pwm_engine`,
  `i2c_slave`, `shadow_active_ctrl`).
- `rtl/registers/register_decode.sv` — owns the I²C control-register
  pointer sitting between `i2c_rx`/`i2c_tx` (not yet built) and
  `register_bank`. Defines and implements the byte-stream event contract
  i2c_rx will need to honor (`ptr_set_i`/`wr_byte_i`/`rd_byte_i`, each a
  1-cycle pulse), drives `register_bank`'s `rb_addr`/`rb_wr_en`/
  `rb_rd_en`/`rb_wdata` from those events, and passes `rb_rdata` straight
  through as `rd_data_o` for the future `i2c_tx`. Auto-increment
  (MODE1.AI, sourced live from `register_bank`'s `active_ai_o`) uses a
  single table-driven `next_ptr_addr()` function with exactly two special
  wrap cases (LED_LAST 0x45 -> 0x00, PRE_SCALE 0xFE -> 0x00, skipping
  0xFF) — every other address just increments by 1, including through
  the 0x46-0xF9 reserved gap and the 0xFA-0xFD ALL_LED_* addresses.
  Also derives `ack4_event_o` (Section 13 commit source #2: pulses on a
  write to any channel's OFF_H byte, or to `ALL_LED_OFF_H`) for the
  not-yet-built `shadow_active_ctrl.sv` to consume. `ptr_set_i` is
  documented and implemented to take priority over a coincident
  `wr_byte_i`/`rd_byte_i` (plain priority if/else, not `unique case`,
  since that overlap is an intentional documented case rather than a
  genuine multi-match hazard). Pointer resets to 0x00 (not part of the
  PCA9685-compatible memory-mapped register set, so it has no
  REGISTER_MAP.md entry — documented in the module's own header
  instead).
- `rtl/registers/address_decode.sv` — purely combinational 7-bit I²C
  address matcher (no clk/rst ports). Five independent equality
  comparators per `docs/architecture/ADDRESSING.md`/MASTER_ARCHITECTURE
  Section 11: General-Call/SWRST (`0000000`, R/W=0 qualified),
  LED All-Call (`active_allcalladr_o`, `MODE1.ALLCALL`-qualified),
  Sub-Call 1/2/3 (`active_subadr_o[0..2]`, each independently
  `MODE1.SUBx`-qualified), and the fixed Regular address
  (`{1'b1, hw_addr_i}`, always active). Exposes each match individually
  (`gc_match_o`, `allcall_match_o`, `sub_match_o[3]`, `regular_match_o`)
  plus an aggregate `addr_match_o` OR for `i2c_rx`'s ACK/NACK decision.
  No priority resolution between simultaneous matches — documented as
  intentionally unnecessary in `ADDRESSING.md`. Carries through
  `register_bank.sv`'s deliberate Sub-Call index/bit-order mismatch
  unchanged (three explicit named comparisons, not a `generate` loop,
  so the mapping is visible at the call site) rather than silently
  "fixing" it in only one of the two modules.
- `rtl/control/shadow_active_ctrl.sv` — generates the single
  `commit_pulse` consumed by `register_bank` (Section 13). No FSM: a
  purely combinational OR of the four commit sources, per Section 18
  point 2 ("effectively a 1-bit 'dirty' latch [already in
  `register_bank`] + combinational OR of commit sources"). OCH
  (`register_bank`'s `active_och_o`) selects between source #1
  (STOP-commit: `stop_event_i && dirty_i`, `stop_event_i` being an
  as-yet-unbuilt-`i2c_rx` input stand-in) and source #2 (ACK-commit:
  `ack4_event_i` from `register_decode`, already qualified to exactly
  the 4th byte of a channel group or `ALL_LED_OFF_H`). Sources #3
  (`group_update_req_i` from `register_bank`, already a 1-cycle pulse)
  and #4 (`sync_update_i`, an external async top-level pin) are always
  active regardless of OCH. This module owns the 2-FF metastability
  synchronizer + rising-edge detector for `sync_update_i` (3 flops
  total: 2 for sync, 1 more held-previous-value flop for the edge
  compare) since it is the only consumer of that signal and the only
  place in the design an external async pin needs synchronizing.
- `rtl/control/prescale_gate.sv` — **new this session.** Checkpoint 2,
  step 5 of 5 — closes out Checkpoint 2. Purely combinational, no
  clk/rst ports (same pattern as `address_decode.sv`): a single-bit
  passthrough, `presc_write_allow_o = sleep_i`, implementing Section
  12's PRE_SCALE write-guard policy ("writes accepted only while
  `MODE1.SLEEP=1`"). Deliberately does not own the prescale tick
  generator itself (that stays in `pwm_counter.sv`, per Section 12) and
  does not duplicate `pwm_counter.sv`'s own independent consumption of
  `active_sleep_o` for ticking-freeze — this module's only job is the
  register-write-guard signal `register_bank` consumes as
  `presc_write_allow_i`.

### Testbenches
- `tb/unit/pwm/pwm_compare_tb.sv` — directed cases from the reference
  datasheet's own Examples 1 & 2 (Figs. 7/8), zero-duty, full-on/off
  precedence, near-100%-duty boundary, plus a 20,000-iteration randomized
  sweep against an independently-written reference function.
- `tb/unit/pwm/pwm_counter_tb.sv` — reset value, prescale=0 (every-cycle
  tick), prescale=3 (every-4th-cycle tick), 4095->0 wraparound +
  `frame_tick_o` pulse timing, SLEEP freeze/resume.
- `tb/unit/pwm/pwm_channel_tb.sv` — baseline, enable gating, full-on/off
  precedence, polarity, global invert, invert+polarity composition, all
  4 OUTNE forcing cases (crossed with OUTDRV), open-drain normal-operation
  drive behavior, plus a 5,000-iteration randomized sweep.

- `tb/unit/registers/register_bank_tb.sv` — reset values for every
  register (Section 17), single-buffered write+readback, shadow-vs-active
  isolation before `commit_pulse` and atomic update after it, `ALL_LED_*`
  broadcast fan-out, `PRE_SCALE` write-guard gating, `GROUP_UPDATE`
  one-cycle self-clearing strobe behavior, reserved-address read-0/
  write-dropped behavior, and `DEVICE_ID`/`REVISION_ID` read-only
  constants.
- `tb/unit/registers/register_decode_tb.sv` — instantiates
  `register_decode` alongside a real `register_bank` (not a stub) and
  drives the DUT with a small task-based byte-stream driver stand-in for
  the not-yet-built `i2c_rx`. Covers: pointer reset value; direct
  `ptr_set_i` load (no auto-increment); AI=0 write/read holds the
  pointer; AI=1 write/read auto-increments and the written/read bytes
  actually land in/come back from `register_bank`'s real storage; both
  documented wrap points (LED_LAST->0, PRE_SCALE->0 skipping 0xFF);
  a plain walk through the 0x46-0xF9 reserved gap and into the
  0xFA-0xFD ALL_LED_* addresses with no special-casing; `ack4_event_o`
  pulsing on exactly a channel's OFF_H byte or `ALL_LED_OFF_H` and
  nowhere else, for exactly one cycle; and `ptr_set_i` priority over a
  coincident `wr_byte_i`.
- `tb/unit/registers/address_decode_tb.sv` — no clock generator needed
  (DUT is purely combinational). Covers: a randomized sweep of
  `hw_addr_i` values for the Regular address match (plus one-bit-off
  mismatch, and MSB=0 never matching regardless of `hw_addr_i`);
  General-Call matching only on R/W=0 (a same-byte read does not match);
  All-Call and each Sub-Call matching only when their own enable bit is
  set, with no cross-talk between the three Sub-Calls or into the other
  address types; `addr_match_o` as a clean OR (asserted on any single
  match, deasserted when none match); and a deliberate simultaneous-
  match coincidence case (`ALLCALLADR` programmed equal to the fixed
  Regular address) confirming both match bits assert together with no
  priority-logic interference.
- `tb/unit/control/shadow_active_ctrl_tb.sv` — instantiates a real
  `register_bank` + `register_decode` alongside the DUT (same pattern as
  `register_decode_tb.sv`), so every check confirms the actual *effect*
  of `commit_pulse_o` (real `active_cfg_o` data landing, real `dirty_o`
  clearing), not just the pulse in isolation. Covers: reset state;
  STOP-commit gated correctly by `dirty_i` (no commit on a clean
  `stop_event_i`, commit + data landing + dirty-clear on a dirty one);
  ACK-commit firing exactly on a channel's 4th byte (not the first 3)
  and on `ALL_LED_OFF_H`; OCH mode exclusivity in both directions
  (OCH=1 ignores `stop_event_i`, OCH=0 ignores `ack4_event_i`);
  `GROUP_UPDATE` committing a multi-channel staged write atomically,
  independent of OCH; `sync_update_i`'s full 2-FF-sync + edge-detect
  latency (pulse lands the cycle after the *second* post-assertion
  posedge, verified against an independent cycle-by-cycle simulation of
  the chain before the test was written — see file comment), no
  re-trigger while held high, and a correct second pulse on a second
  rising edge; and one-clk_ref-cycle pulse width for every source.
- `tb/unit/control/prescale_gate_tb.sv` — **new this session.** A bare
  DUT instance (no `register_bank` attached) directly proves the module
  is purely combinational — output tracks input within the same
  simulation time step, no clock edge needed. A second, integration
  instance wires the DUT's output straight into a real `register_bank`'s
  `presc_write_allow_i`, exactly as at the top level, so every guard
  check confirms the actual effect on `PRE_SCALE` storage (readback
  *and* `active_prescale_o`), not just the gate signal. Covers: reset
  state (MODE1 SLEEP=1 by default, so a write is accepted immediately,
  no MODE1 write needed first); write dropped while awake (SLEEP=0),
  confirmed unchanged at both the shadow-readback and
  `active_prescale_o` level; write accepted once SLEEP is re-set to 1,
  including the *same* value that was just dropped now landing; and a
  three-cycle awake/asleep/awake sequence confirming the guard is
  stateless (each write's outcome depends only on SLEEP at that exact
  write, no latching of a prior accept/drop decision).
- `tb/unit/pwm/pwm_engine_tb.sv` — **new this session.** Instantiates a
  real `register_bank` + `pwm_counter` alongside the DUT (regbus driven
  directly, no `register_decode`/i2c needed, same simplification
  `register_bank_tb.sv` itself uses), so every check confirms
  `pwm_engine`'s actual effect on `led_o`/`led_oe_o` driven by real
  committed register state and a real free-running counter, not
  synthetic structs. Covers: reset defaults (all channels `full_off`,
  totem-pole always-driven); a normal duty-cycle window (channel 0,
  on=0/off=0x800) tracked correctly as the live counter free-runs past
  the off point; the SEMFONIX enable gate forcing a channel low
  regardless of its programmed window; `full_on` override independent
  of on/off counts (including a wraparound-shaped window where the
  override still wins); per-channel polarity inverting only the
  targeted channel; global `MODE2.INVRT` flipping every channel's
  level; the `oe_n_i`/OUTNE forced-state mux (high-Z and driven-low
  cases) overriding PWM state on every channel uniformly; and two
  channels with different windows disagreeing at the same shared
  `count_i`, proving the 16-way replication rather than a shared/muxed
  comparator (Section 9).
- `tb/unit/i2c/i2c_bus_sync_tb.sv` — **new this session.** Bare DUT
  instance (no other RTL needed — `i2c_bus_sync` has no dependencies).
  Covers: reset value (both synchronized outputs idle-high); the exact
  2-clk_ref-cycle latency from a raw pin change to the synchronized
  output, checked on both SCL and SDA independently; that the two 2-flop
  chains don't perturb each other (toggling one pin leaves the other's
  synchronized value and latency unaffected); that a sub-clk_ref-period
  glitch on a raw pin (asserted and deasserted entirely between two
  posedges) never appears at the synchronized output at all, since it is
  never present at either sample point; and cycle-accurate tracking of a
  rapidly toggling input over 8 consecutive toggles.
- `tb/unit/i2c/i2c_rx_tb.sv` — Two DUT groupings:
  an integration group (real `i2c_bus_sync` + `address_decode` +
  `register_decode` + `register_bank` alongside the `i2c_rx` DUT, driven
  by a behavioral bit-banged I2C master with generous per-bit timing
  margins) and two bare `i2c_rx` instances driven directly at
  `scl_sync_i`/`sda_sync_i` for the spike-filter and SCL-held-low-timeout
  properties. Covers: reset state; address mismatch (NACK, zero write
  events, clean recovery); single write + repeated-START readback
  (register storage checked directly, not just the pulse); MODE1.AI
  multi-byte auto-increment (two data bytes landing at consecutive real
  register addresses); STOP-event pulse count (exactly one per STOP);
  general-call SWRST correct-sequence (ack'd data byte, `swrst_o` on the
  following STOP, not the ACK) and malformed-sequence (data byte NACKed,
  `swrst_o` never pulses) behavior; spike-filter rejection of a
  sub-filter-window glitch vs. acceptance of a held change; and
  SCL-held-low timeout recovery (a stuck mid-byte FSM forced back to
  IDLE, proven via a subsequent fresh transaction ACKing on the correct
  bit boundary rather than one bit early). Address-enable coupling to
  register_bank's live MODE1 bits is deliberately tied off (fixed test
  address + general-call only) — documented in the file header as an
  i2c_slave/top-level (Checkpoint 5) concern, not this module's.
- `tb/unit/i2c/i2c_tx_tb.sv` — **new this session.** Two DUT groupings:
  a bare `i2c_tx` instance with `scl_sync_i`/`tx_load_i`/
  `tx_drive_en_i`/`tx_data_i` driven directly, isolating the shift-
  register/open-drain-drive property itself; and an integration group
  reusing the exact same five-module dependency chain `i2c_rx_tb.sv`
  assembles (`i2c_bus_sync` + `i2c_rx` + `address_decode` +
  `register_decode` + `register_bank`) plus this session's `i2c_tx` DUT,
  with `i2c_rx`'s and `i2c_tx`'s `sda_o`/`sda_oe` combined on the shared
  bus by a plain mux on `tx_drive_en_o` (standing in for the not-yet-
  built `i2c_slave.sv`), driven by the same behavioral bit-banged I2C
  master task library extended with a byte-level read task. Covers
  (bare): reset state; MSB-first bit order and exact SCL-falling-edge
  shift timing for a directed byte (0xA5); `tx_drive_en_i` deasserting
  mid-byte immediately stopping the drive regardless of remaining shift-
  register contents, with a fresh load+enable afterward unaffected; the
  documented one-cycle-early `tx_load_i`-before-`tx_drive_en_i` timing
  loading silently with no drive until enable, then presenting the
  correct MSB the instant it turns on; and a 5,000-iteration randomized
  byte sweep. Covers (integration): a single-byte I2C read of a value
  previously written into real `register_bank` storage via a real I2C
  write (not a register_bank backdoor); a two-byte MODE1.AI auto-
  incrementing read (master ACKs the first byte, NACKs the second)
  against two independently-written register values at consecutive
  addresses; and an immediate-NACK single-byte read followed by a fresh
  write transaction, confirming no leftover drive state on the bus.

### Integration testbench / models — merged this session (step 13)
- `tb/models/i2c_bfm.sv` — behavioral I2C master BFM, register-level
  task API (`write_byte`/`reg_write`/`reg_read_burst`/
  `general_call_swrst`, etc.), generalizing the bit-banged master
  logic each unit-level I2C tb hand-rolled. Direct-drive `scl_o`,
  open-drain `sda_drive_o`/`sda_val_o`. Existing unit tbs deliberately
  NOT retrofitted to use it (out of scope for this step).
- `tb/models/pwm_ref_model.sv` — independent reference model of the
  register/shadow-active/timebase/output-stage behavior, transcribed
  from `REGISTER_MAP.md`/`MASTER_ARCHITECTURE.md` (not from RTL or
  `semfonix_regmap_pkg`). Driven in lock-step with the integration tb's
  I2C transactions via `reg_write()`/`stop_commit()`/`sync_pulse()`
  tasks rather than a second protocol decoder.
- `tb/integration/semfonix_pwm16_tb.sv` — black-box integration tb for
  `semfonix_pwm16_top.sv`: drives the DUT only through its real
  top-level ports via `i2c_bfm.sv`, background-checks `led_o`/
  `led_oe_o` against `pwm_ref_model.sv` every cycle while
  `checking_enabled` (dropped during in-flight I2C transactions to
  avoid spurious commit-boundary mismatches). Covers reset, I2C
  protocol, PWM all-channel/all-duty-cycle, atomic update, addressing,
  and stress, per Section 23's test list.

All thirteen testbenches (twelve unit + this one integration tb) are
self-checking: they print
`PASS: <name> - N checks, 0 errors` and `$finish(0)` on success, or print
per-case `FAIL [...]` lines plus a summary and `$fatal(1)` on any mismatch.

### SVA assertions — step 14, 3 files merged / 4 files authored this session
All seven files live in `tb/assertions/`, one per bound RTL module, each
guarded by `` `ifdef SIMULATION `` and connected via `bind ... (.*)` so
no RTL file itself references them (Section 23: "kept out of the
synthesizable RTL files themselves"). `scripts/run_all_unit_tests.sh`
and `scripts/run_integration_test.sh` both pass `-DSIMULATION` and
include each assertion file alongside every DUT set that instantiates
the RTL module it binds to.

- `pwm_compare_assertions.sv` (merged, prior stalled session) — bound to
  `pwm_compare`: `full_off`/`full_on` precedence forces `raw_level`
  correctly.
- `pwm_counter_assertions.sv` (merged, prior stalled session) — bound to
  `pwm_counter`: `sleep_i` freezes `count_o`; `frame_tick_o` only pulses
  at max count while awake and causes a wrap to 0 the following cycle.
- `pwm_channel_assertions.sv` (merged, prior stalled session) — bound to
  `pwm_channel`: normal-mode forced-low compose (`full_off`/`enable=0`)
  and the full Table 11 OE=1/OUTNE forced-state mux.
- `clk_reset_sync_assertions.sv` (new this session) — bound to
  `clk_reset_sync`: `rst_n` low forces both internal flops low
  combinationally (async assert), and `rst_n_sync_o` always equals the
  prior cycle's `meta_q` (sync-release chain integrity, no bypass).
- `register_bank_assertions.sv` (new this session) — bound to
  `register_bank`: atomic shadow→active copy of `on_count`/`off_count`/
  `full_on`/`full_off` for all `NUM_CHANNELS` on `commit_pulse`;
  `dirty_o` set on any shadow write and cleared on a clean commit;
  `PRE_SCALE` writes are a true no-op when `presc_write_allow_i=0`;
  `GROUP_UPDATE`'s request pulse only ever fires alongside its
  qualifying write and the address always reads 0; `DEVICE_ID`/
  `REVISION_ID` read back their fixed constants; a reserved-address
  spot-check (0x46-0x4F, 0x57-0x5F, 0xFF) reads 0x00.
- `shadow_active_ctrl_assertions.sv` (new this session) — bound to
  `shadow_active_ctrl`: `commit_pulse_o` equals the documented
  4-source OR exactly (OCH-selected STOP/ACK commit, OR'd with
  `group_update_req_i` and the internal `sync_update_pulse`); the
  `sync_update_i` edge-detect pulse is exactly one `clk_ref` cycle
  wide.
- `i2c_slave_assertions.sv` (new this session) — bound to `i2c_slave`:
  `sda_o` is permanently tied `1'b0` (open-drain discipline — never
  actively drives SDA high); `sda_oe` always matches the documented
  `tx_drive_en`-selected rx/tx mux; `swrst_o` only ever pulses
  alongside `stop_event_o` (checked against `i2c_rx.sv`'s own
  `swrst_o = stop_cond && swrst_armed_q` line, read directly from
  source, not assumed from the header prose).

---

## Tests Passed / Failed

**This session:** re-confirmed no toolchain is available (`which
iverilog vvp yosys` → not found, no network egress to install one —
same result as every prior session's check, not assumed carried over).
The seven new/merged `tb/assertions/*.sv` files (and the two build
scripts' updated source lists) have been structurally sanity-checked
and every `bind`'s port list manually cross-checked against its target
RTL module's actual declaration, exactly as every other unexecuted file
in this repository — see the "SVA assertions" subsection above. Still
**not yet run**.

**Prior session (i2c_tx.sv):** see "IMPORTANT — Toolchain Availability"
note below. Re-confirmed that session (`which iverilog vvp yosys` → not found;
additionally, a live `apt-get install -y iverilog` was attempted this
session and returned `403 Forbidden` fetching from
`archive.ubuntu.com` — no network egress available in this sandbox to
install a toolchain — this was checked directly this session, not
assumed carried over). This session added `rtl/i2c/i2c_tx.sv` +
`tb/unit/i2c/i2c_tx_tb.sv` and hooked the testbench into
`scripts/run_all_unit_tests.sh`; all twelve testbenches remain
self-checking and unexecuted, awaiting a toolchain. The new files (and,
for the testbench, its 6-module dependency chain: `i2c_bus_sync.sv`,
`i2c_rx.sv`, `i2c_tx.sv`, `address_decode.sv`, `register_decode.sv`,
`register_bank.sv`) have been structurally sanity-checked
(module/endmodule, begin/end, task/endtask, and paren/brace/bracket
counts balanced after stripping comments — both new files confirmed
exactly balanced) *and* manually port-by-port cross-checked against
each instantiated module's actual port list (name, direction, width)
read directly from its source, not assumed from `i2c_rx_tb.sv`'s prior
usage of the same block. A real compile+simulate pass is the immediate
next action once a toolchain is reachable (locally, in CI, or in a
future session with network/toolchain access); until then, "reviewed,
not yet executed" is the accurate status, not "verified" or "passing."

One correction made *during authoring*, prior session: `shadow_active_ctrl_tb.sv`'s
`sync_update_i` test initially assumed the 2-FF-sync + edge-detect pulse
would land 3 `clk_ref` cycles after the external pin's rising edge; a
standalone cycle-by-cycle Python simulation of the exact flop chain
(done in this sandbox, no Verilog toolchain needed for that) showed
the pulse actually lands after the *2nd* post-edge posedge, not the
3rd, because `sync_prev_q` still lags `sync_sync_q` by one cycle at
that point. The testbench wait counts were corrected before that
checkpoint was called done — flagged there in case a similar
off-by-one intuition recurred when `prescale_gate.sv`'s own guard
timing was unit-tested. It did not recur: `prescale_gate.sv` has no
flop chain at all (purely combinational, no clk/rst ports — see the
module's own header), so there was no clock-relative timing to get
wrong in the first place; `prescale_gate_tb.sv`'s only timing-adjacent
check is the bare-instance combinational-property test (input and
output settle within the same simulation time step, verified with `#1`
delays, no `@(posedge ...)` needed for that specific check).

`scripts/run_all_unit_tests.sh` now includes `i2c_tx_tb` (in addition to
`register_bank_tb`, `register_decode_tb`, `address_decode_tb`,
`shadow_active_ctrl_tb`, `prescale_gate_tb`, `pwm_engine_tb`,
`i2c_bus_sync_tb`, and `i2c_rx_tb`) in its run list, ready to execute
the moment a toolchain is available — no further authoring needed for
the 12 unit tests written so far.

---

## Known Issues Found And Fixed During Review (prior session)

While writing `i2c_rx_tb.sv`, manual port-by-port review (not a tool —
no toolchain available) caught two same-cycle multiple-driver bugs in
the testbench itself before they were ever left in the file: the two
bare `i2c_rx` instances (`dut_filt`, `dut_timeout`) each initially had
`ptr_set_data_o` and `wr_byte_data_o` connected to the *same* unused
8-bit wire, which would have made two DUT output ports drive one net
simultaneously (an `x`/contention bug at simulation time, invisible to a
module/endmodule-balance check). Fixed by giving each unused output its
own dedicated wire. Flagged here specifically because it's the kind of
bug that "structural sanity-checked" would NOT catch, and is exactly
what an actual `iverilog` compile would have caught immediately, which
is one more reason the toolchain gap in this sandbox matters — see the
toolchain note below.

## Known Issues

- None found in RTL review, but **unverified by simulation** — see
  toolchain note. Treat Checkpoints 1-3 and the whole of Checkpoint 4
  written so far (`i2c_bus_sync.sv`, `i2c_rx.sv`, `i2c_tx.sv`, and all
  three of their unit testbenches) as "implementation complete,
  verification pending actual tool run," not as "verified" or "passing."

## Repository State Note (prior session — competitive review)

The competitive-review session's task description assumed the
repository stood at "PWM RTL + unit TBs complete, `register_bank.sv` +
TB complete, `register_decode.sv` + TB complete, next stage
`address_decode.sv`." The actual repository contents (read directly
from the uploaded ZIP at that session's start, not assumed) showed
`address_decode.sv` + `address_decode_tb.sv` **and**
`shadow_active_ctrl.sv` + `shadow_active_ctrl_tb.sv` already
implemented, per the "Files Completed" section above and the
prior-session history already recorded in this file. The
actually-current next task at that point was `prescale_gate.sv`
(Checkpoint 2, step 5 of 5), not `address_decode.sv`. That session
performed the requested competitive review at that (correct, verified)
point instead, and made no RTL changes. This session (a plain
"Continue") read this file's actual content — confirming
`prescale_gate.sv` as the next task exactly as this file already
recorded — and implemented it, closing out Checkpoint 2.

## Repository State Note (prior session)

This session (a plain "Continue") read `MASTER_ARCHITECTURE.md`,
`IMPLEMENTATION_STATUS.md`, `REGISTER_MAP.md`, and
`PCA9685_reference_notes.md` directly from the uploaded ZIP, confirmed
the actual next task was `rtl/pwm/pwm_engine.sv` (Checkpoint 3, its sole
step) exactly as this file already recorded, and implemented it. No
architecture, register-map, or PPA decisions were changed. Per the
standing "stop at one clean unit" practice, that session stopped at the
Checkpoint 3 close-out and did not continue into Checkpoint 4.

## Repository State Note (prior session)

This session (a "CONTINUE" request) read `MASTER_ARCHITECTURE.md`,
`IMPLEMENTATION_STATUS.md`, `REGISTER_MAP.md`, and
`PCA9685_reference_notes.md` directly from the uploaded ZIP first, as
instructed. `IMPLEMENTATION_STATUS.md` recorded Checkpoint 4 (the I²C
block) as next, listing four files — `i2c_bus_sync.sv`, `i2c_rx.sv`,
`i2c_tx.sv`, `i2c_slave.sv` — under a single Section 22 step (step 10),
unlike Checkpoint 2's five separately-numbered steps. Consistent with
every prior checkpoint's granularity (one RTL module + its own unit tb
per session/unit, never multiple modules in one pass) and with Section
22's own dependency order within that step (`i2c_bus_sync` has no
dependency on the other three; `i2c_rx`/`i2c_tx` depend on it), this
session treated `i2c_bus_sync.sv` — the lowest-dependency leaf of the
four — as the next single self-contained unit, implemented it plus its
unit tb, and hooked it into `scripts/run_all_unit_tests.sh`. No
architecture, register-map, or PPA decisions were changed; `rst_n`
handling, reset values, and the "no edge detection here, that's
i2c_rx's job" boundary all match Section 6 / Section 7.2 exactly as
already written. Per the standing "stop at one clean, self-contained
unit" practice, that session stopped there and did not continue into
`i2c_rx.sv`. The following session (also a plain "Continue") then wrote
`i2c_rx.sv`'s RTL only, per that session's explicit instructions leaving
its unit tb, simulation, and any further module for later.

## Repository State Note (prior session)

That session (a "CONTINUE" request) read all four required docs directly
from the uploaded ZIP first. `IMPLEMENTATION_STATUS.md`'s own "Next
Module To Implement" list (entry #8) recorded the next task exactly:
`i2c_rx.sv`'s RTL was already done (an earlier session); its own unit tb
+ verification/simulation were explicitly called out as the next step,
deferred by that earlier session's own explicit instructions rather than
by any dependency or complexity reason. That session wrote
`tb/unit/i2c/i2c_rx_tb.sv` (see "Files Completed" / Testbenches above
for full coverage) and hooked it into `scripts/run_all_unit_tests.sh`.
Toolchain availability (`iverilog`/`vvp`/`yosys`, and network egress to
install them) was re-checked directly that session, not assumed carried
over from prior sessions' notes — still unavailable. Consistent with
this repository's standing rule ("do not claim verification/simulation
unless it was actually executed and produced a result"), that session
did **not** claim the new testbench passed — it claimed exactly what was
done: written, read through, structurally sanity-checked, and manually
port-by-port cross-checked against every instantiated module's real port
list (catching and fixing two multiple-driver bugs in the testbench
itself in the process — see "Known Issues Found And Fixed" above). No
architecture, register-map, or PPA decisions were changed; `i2c_rx.sv`
itself was not modified. Per the standing "stop at one clean,
self-contained unit" practice, that session stopped there and did not
start `i2c_tx.sv`.

## Repository State Note (this session — Verilator addition)

This session's request was explicit: "Continue use verilator." Read
`IMPLEMENTATION_STATUS.md` first, per standing practice, confirming
Checkpoint 6 was already in progress (`scripts/synth_yosys.sh` +
`yosys/synth.tcl` from the prior session, not yet executed). Checked
`verilator` availability directly rather than assuming the prior
sessions' iverilog/yosys toolchain notes extended to it: absent, and
both an `apt-get install -y verilator` and a `pip install verilator
--break-system-packages` attempt failed live (`apt-get` with the same
`403 Forbidden` result every tool in this sandbox has hit; `pip`
because no PyPI package named `verilator` exists — Verilator is not
Python-distributed). Interpreted "use verilator" as adding Verilator to
the toolchain story for Checkpoint 6 — a `--lint-only` synthesizability/
lint pass over the RTL, run as a second independent check alongside the
existing Yosys flow — rather than as an instruction to convert the
project's simulation infrastructure (`run_all_unit_tests.sh`/
`run_integration_test.sh` and every testbench they drive) from Icarus
Verilog to Verilator: that would mean modifying twelve already-complete,
already-reviewed unit testbenches plus the integration testbench, none
of which were authored against Verilator's more restrictive timing/
procedural-code semantics, for a scope this repository's standing rule
("do not regenerate or unnecessarily modify completed RTL, testbenches,
assertions, scripts, or documentation") counsels against absent a more
explicit instruction to actually port them. Wrote
`scripts/verilator_lint.sh` (lint-only, RTL-source-only, no testbench
touched); source list re-derived and cross-checked against `rtl/`'s
actual module names, same discipline as the prior session's
`synth_yosys.sh`. No RTL, architecture, register-map, or existing
testbench/assertion/script file was modified. **Not yet executed** — no
`verilator` binary reachable in this sandbox. If full Verilator-based
simulation (replacing or supplementing Icarus for the unit/integration
tbs) is actually wanted, that is a larger, separate piece of work
worth its own explicit go-ahead given the testbench-semantics risk
above — flagged here rather than silently attempted.

## Repository State Note (this session — Verilator compile+simulate)

This session's request was explicit: "Yes we run verilator compilation
and simulation for all." Read `IMPLEMENTATION_STATUS.md` first per
standing practice, confirming Checkpoint 6 was in progress with
`synth_yosys.sh` (Yosys) and `verilator_lint.sh` (Verilator lint-only)
both already written but unexecuted, and the prior session's own
repository-state note explicitly flagging full Verilator compile+
simulate as "a larger, separate piece of work worth its own explicit
go-ahead" — this session's request is exactly that go-ahead. Wrote
`scripts/run_all_unit_tests_verilator.sh` and
`scripts/run_integration_test_verilator.sh` using `verilator --binary
--timing`, with every per-test source list copied from the existing
Icarus scripts and cross-checked by an actual `diff` (not just a visual
read-through) against the originals to guarantee an identical file set
per test — see entry 17 under "Files Completed" above for the full
compatibility-review methodology and its explicit caveat. Consistent
with this repository's standing rule against unnecessary modification,
**no existing RTL, testbench, or assertion file was changed** to
produce this — the new scripts compile the same source files in place
under a different tool, which is exactly what "run X for all [the
existing tests]" calls for, not a rewrite of the tests themselves.
Toolchain availability was re-checked directly this session yet again
(`which verilator` → not found; a live `apt-get install -y verilator`
attempt returned the same `403 Forbidden` every check in this sandbox
has hit; `apt-cache policy verilator` confirms the package is known to
the configured repo, 5.020-1, but unreachable) — not assumed carried
over from the prior session's check. Consistent with this repository's
standing rule, this session does **not** claim any testbench was
actually compiled or simulated under Verilator, nor does it claim the
new scripts are bug-free — it claims exactly what was done: written,
reviewed for known Verilator/Icarus construct-compatibility gaps (none
found by grep sweep), and source-list-verified byte-for-byte against
the already-reviewed Icarus scripts. Running these two new scripts
(plus `synth_yosys.sh`, `verilator_lint.sh`, and the original two
Icarus scripts) the moment any toolchain is reachable is now the
entirety of the remaining work in this repository — no further RTL,
testbench, or script authoring is anticipated before that point unless
a real run finds something that needs fixing.

## Repository State Note (this session)

This session (a "CONTINUE" request) read `MASTER_ARCHITECTURE.md`,
`IMPLEMENTATION_STATUS.md`, `REGISTER_MAP.md`, and
`PCA9685_reference_notes.md` directly from the uploaded ZIP first.
`IMPLEMENTATION_STATUS.md`'s own "Next Module To Implement" list (entry
#9) recorded the next task exactly: `rtl/i2c/i2c_tx.sv` +
`tb/unit/i2c/i2c_tx_tb.sv`, the read-path shift register/open-drain
driver honoring the `tx_load_o`/`tx_drive_en_o` contract `i2c_rx.sv`
already documented. This session wrote both files (RTL + unit tb in one
pass, since no prior session had already started either half), hooked
the testbench into `scripts/run_all_unit_tests.sh`, and updated this
file. Toolchain availability was re-checked directly this session (both
`which iverilog vvp yosys` and a live `apt-get install -y iverilog`
attempt, which returned `403 Forbidden`) — still unavailable, not
assumed carried over. Consistent with this repository's standing rule,
this session does **not** claim the new files were compiled or
simulated — it claims exactly what was done: written, read through,
structurally sanity-checked (module/endmodule, begin/end, task/endtask,
paren/brace/bracket balance, both files confirmed exactly balanced), and
every instantiated module's port list manually cross-checked name-by-
name, direction, and width against its actual declaration in the RTL
source. No bugs were found during this review (unlike the prior
session's `i2c_rx_tb.sv` authoring, which caught two). No architecture,
register-map, or PPA decisions were changed; `i2c_rx.sv`,
`i2c_bus_sync.sv`, `address_decode.sv`, `register_decode.sv`, and
`register_bank.sv` were read but not modified. Per the standing "stop at
one clean, self-contained unit" practice, this session stops here (RTL +
unit tb for `i2c_tx.sv` is a complete, self-contained deliverable) and
does not start `i2c_slave.sv`, the final file of Checkpoint 4.

## Repository State Note (this session — merge)

This session received two inputs: the prior checkpoint ZIP, and four
loose files from a later session that had reached the integration-tb
stage (step 13) but stalled before packaging a ZIP:
`tb/integration/semfonix_pwm16_tb.sv`, `tb/models/i2c_bfm.sv`,
`tb/models/pwm_ref_model.sv`, `scripts/run_integration_test.sh`. All
four were placed at the paths their own headers/`run_integration_test.sh`
already expected, checked for duplicate/conflicting filenames (none
found), structurally sanity-checked (module/endmodule, begin/end,
task/endtask, paren/brace/bracket balance — all four exactly balanced),
and had every instantiation (`i2c_bfm`, `pwm_ref_model`,
`semfonix_pwm16_top`) cross-checked port-by-port against each module's
actual declaration — all matched exactly, no RTL or script fixes were
needed. No already-complete RTL or unit-tb file was touched. This
document was updated to reflect step 13 as done (Checkpoint 5 now 3 of
4); no next RTL module (step 14, `tb/assertions/*`) was started, per
this session's own scope.

## Repository State Note (this session)

This session (a "CONTINUE" request) read `MASTER_ARCHITECTURE.md`,
`IMPLEMENTATION_STATUS.md`, `REGISTER_MAP.md`, and
`PCA9685_reference_notes.md` directly from the uploaded ZIP first, as
instructed. `IMPLEMENTATION_STATUS.md`'s own status recorded Checkpoint
5 as complete (4 of 4 files) and Checkpoint 6 (Section 22 step 15,
Yosys synthesis) as the sole remaining step, not yet started. This
session wrote `scripts/synth_yosys.sh` + `yosys/synth.tcl` (see "Files
Completed" / entry 15 above for full detail), re-derived the RTL
source list directly from `find rtl -name '*.sv'` rather than assuming
the prior session's file listing was still exhaustive, and cross-
checked every module name against its own `module` declaration before
writing it into the synthesis source list. No RTL, architecture,
register-map, or existing testbench/assertion file was modified.
Toolchain availability was re-checked directly this session (`which
iverilog vvp yosys` → none found; a live `apt-get install -y yosys
iverilog` attempt returned `403 Forbidden` fetching from
`archive.ubuntu.com`/`security.ubuntu.com` for every package in the
dependency chain, including `yosys`, `yosys-abc`, and `iverilog`
themselves) — not assumed carried over from prior sessions' notes,
still unavailable, no network egress to install one. Consistent with
this repository's standing rule, this session does **not** claim the
new synthesis script was run or that the design is synthesis-clean —
it claims exactly what was done: written, read through, and
structurally reviewed (RTL source list and module names cross-checked
against actual source; a grep sweep for non-synthesizable constructs
across `rtl/**` found none; the Tcl script's brace/paren/bracket
balance confirmed programmatically; the wrapper shell script's syntax
checked with `bash -n`). Per the standing "stop at one clean,
self-contained unit" practice, and because this is also the final item
in the entire Section 22 implementation order, this session stops here
rather than inventing further scope — the only work left anywhere in
this repository is toolchain-gated re-execution of the simulation and
synthesis scripts already written.

## Repository Structure Note

The ZIP handed off at the end of the prior session's Checkpoint 1 was
flat (all `.sv`/`.md` files at the repository root), even though that
session's own docs/scripts already referenced the nested `rtl/`, `tb/`,
`docs/`, `scripts/` layout. That session moved every file into the path
its own header comments and `scripts/run_all_unit_tests.sh` already
expected, with no content changes to the moved files. Current layout:
```
docs/{MASTER_ARCHITECTURE.md, IMPLEMENTATION_STATUS.md,
      architecture/REGISTER_MAP.md, architecture/ADDRESSING.md,
      product/PCA9685_reference_notes.md, product/COMPETITIVE_REVIEW_2026.md}
rtl/{pwm/*.sv, registers/*.sv, control/*.sv, i2c/*.sv, clock/*.sv, top/*.sv}
tb/unit/{pwm/*.sv, registers/*.sv, control/*.sv, i2c/*.sv, clock/*.sv}
tb/integration/semfonix_pwm16_tb.sv
tb/models/{i2c_bfm.sv, pwm_ref_model.sv}
tb/assertions/*.sv   (step 14, 7 files, bound via `bind`/`ifdef SIMULATION`)
scripts/{run_all_unit_tests.sh, run_integration_test.sh, synth_yosys.sh,
         verilator_lint.sh, run_all_unit_tests_verilator.sh,
         run_integration_test_verilator.sh}
yosys/synth.tcl      (step 15, generic Yosys synthesis flow)
```
(This tree was updated this session to reflect the repository as it
actually stands post-merge — `clock/`, `top/`, `tb/integration/`,
`tb/models/`, and `tb/assertions/` did not exist yet when this diagram
was first written; no files were moved to produce this update, only
the diagram text. `yosys/`, `scripts/synth_yosys.sh`,
`scripts/verilator_lint.sh`, and — this session —
`scripts/run_all_unit_tests_verilator.sh`/
`scripts/run_integration_test_verilator.sh` are all new. `build/` —
created on demand by every script above (`build/unit/`,
`build/integration/`, `build/synth/`, `build/verilator_lint/`,
`build/unit_verilator/`, `build/integration_verilator/`) — is
intentionally not part of the delivered ZIP; it holds only
tool-generated output.)

---

## Current Checkpoint

**CHECKPOINT 2 is COMPLETE** (prior session; `register_bank.sv`,
`register_decode.sv`, `address_decode.sv`, `shadow_active_ctrl.sv`,
`prescale_gate.sv`, all 5 of 5 steps).

**CHECKPOINT 3 is COMPLETE** (prior session; `pwm_engine.sv`, sole step).

**CHECKPOINT 4 is COMPLETE** (prior sessions; `i2c_bus_sync.sv`,
`i2c_rx.sv`, `i2c_tx.sv`, `i2c_slave.sv`, all with unit tbs, all 4 of 4
files — `i2c_slave.sv` + `tb/unit/i2c/i2c_slave_tb.sv` are present in
the repository and listed in `scripts/run_all_unit_tests.sh`; this
narrative section previously read "IN PROGRESS (3 of 4 files)" even
though the Checkpoint Status checklist above and the "Files Completed"
list both already recorded `i2c_slave.sv` as done — a stale-narrative
inconsistency, not a missing file, found and corrected this session
per this repository's cross-check instructions. No RTL, architecture,
or register-map content was affected — this correction only touched
this file's own prose to match the repository the ZIP actually
contains.)

**CHECKPOINT 5 is COMPLETE (4 of 4 files).** History:
`rtl/clock/clk_reset_sync.sv` + unit tb (step 11); `rtl/top/
semfonix_pwm16_top.sv` (step 12, pure structural wiring of all 9
children); `tb/integration/semfonix_pwm16_tb.sv` + `tb/models/i2c_bfm.sv`
+ `tb/models/pwm_ref_model.sv` + `scripts/run_integration_test.sh`
(step 13, merged from a prior stalled session, reviewed and
port-cross-checked, no mismatches). **This session:** merged step 14
(`tb/assertions/*`) from a second stalled session — three files arrived
intact (`pwm_compare_assertions.sv`, `pwm_counter_assertions.sv`,
`pwm_channel_assertions.sv`), reviewed and port-cross-checked against
`pwm_compare.sv`/`pwm_counter.sv`/`pwm_channel.sv`, no mismatches — and
the four that did not survive the stall (clock, register, control, I2C)
were authored fresh this session in the same style, reading each
target RTL module's actual ports/internal signals directly from source
before writing each `bind`. `scripts/run_all_unit_tests.sh` and
`scripts/run_integration_test.sh` were updated: `-DSIMULATION` added to
both `iverilog` invocations, and each assertion file added to every
test/integration source list whose DUT set includes the RTL module it
binds to. No duplicate or conflicting files; no RTL, architecture, or
register-map changes. **Not yet executed** (no toolchain in this
sandbox) — see the "SVA assertions" subsection above for the full list
and what each file checks.

**CHECKPOINT 6 is IN PROGRESS**: `scripts/synth_yosys.sh` +
`yosys/synth.tcl` (Yosys), `scripts/verilator_lint.sh` (Verilator
lint-only), and `scripts/run_all_unit_tests_verilator.sh` +
`scripts/run_integration_test_verilator.sh` (Verilator compile+
simulate, this session, on explicit request) are all written and
reviewed — see "Yosys Status" above and the step-16/17 entries below
for exactly what was done and what remains. **None yet executed** (no
`yosys` or `verilator` in this sandbox). Also still pending,
independent of all of these: run `scripts/run_all_unit_tests.sh` and
`scripts/run_integration_test.sh` (Icarus) for real the moment a
toolchain is reachable, and fix anything any of them surfaces.

## Next Module To Implement

1. ~~`rtl/registers/register_bank.sv` + `tb/unit/registers/register_bank_tb.sv`
   (+ `docs/architecture/REGISTER_MAP.md`)~~ — DONE (prior session).
2. ~~`rtl/registers/register_decode.sv` + `tb/unit/registers/register_decode_tb.sv`~~
   — DONE (prior session). Control-register pointer register, auto-increment
   (`MODE1.AI`, sourced from `register_bank`'s `active_ai_o`), wrap logic
   (LED_LAST->0, PRE_SCALE->0 skipping 0xFF), drives `register_bank`'s
   `rb_addr`/`rb_wr_en`/`rb_rd_en` from a documented byte-stream event
   contract (`ptr_set_i`/`wr_byte_i`/`rd_byte_i`) that the not-yet-built
   `i2c_rx` will need to honor; also derives `ack4_event_o` for
   `shadow_active_ctrl`. Testbench instantiates a real
   `register_bank` alongside the DUT with a small byte-stream driver
   stand-in, as anticipated.
3. ~~`rtl/registers/address_decode.sv` + `tb/unit/registers/address_decode_tb.sv`
   (+ `docs/architecture/ADDRESSING.md`)~~ — DONE (prior session).
   Slave/all-call/sub-addr/general-call 7-bit address matching
   (Section 11), purely combinational, against `register_bank`'s
   `active_allcalladr_o`/`active_subadr_o[3]`/`active_allcall_o`/
   `active_subx_en_o` (all already implemented and exposed) plus a
   `hw_addr_i[5:0]`-derived fixed slave address. Five independent
   comparators, one aggregate `addr_match_o`, no priority resolution
   between simultaneous matches (documented rationale in
   `ADDRESSING.md`). No dependency on `register_decode.sv` or `i2c_rx`
   internals beyond the address byte itself, so it was built and unit
   tested standalone before `i2c_rx` exists, same as `register_decode`
   was.
4. ~~`rtl/control/shadow_active_ctrl.sv` + `tb/unit/control/shadow_active_ctrl_tb.sv`~~
   — DONE (prior session). Purely combinational OR of the four Section 13
   commit sources (no FSM, per Section 18 point 2): OCH-selected
   STOP-commit (`stop_event_i && dirty_i`, `dirty_i` from
   `register_bank`'s `dirty_o`) vs. ACK-commit (`ack4_event_i` from
   `register_decode`'s `ack4_event_o`), OR'd with the always-active
   `group_update_req_i` (`register_bank`'s `group_update_req_o`) and a
   locally-synchronized+edge-detected `sync_update_i` (2-FF + 1
   previous-value flop, since this is the one place in the design an
   external async pin needs synchronizing). `stop_event_i` has no real
   driver yet (`i2c_rx` is Checkpoint 4), so the testbench drives it
   directly as a stand-in, same pattern used for `register_decode`'s
   byte-stream ports. Testbench instantiates real `register_bank` +
   `register_decode` alongside the DUT (not stubs), so every check
   confirms `commit_pulse_o`'s actual effect on `active_cfg_o`/`dirty_o`.
5. ~~`rtl/control/prescale_gate.sv` + `tb/unit/control/prescale_gate_tb.sv`~~
   — DONE this session. Purely combinational, no clk/rst ports (same
   pattern as `address_decode.sv`): `presc_write_allow_o = sleep_i`,
   consuming `register_bank`'s `active_sleep_o` (already implemented and
   exposed) to drive `presc_write_allow_i`. Testbench uses a bare DUT
   instance to directly prove the combinational property, plus a real
   `register_bank` integration instance to confirm the guard's actual
   effect on `PRE_SCALE` storage and `active_prescale_o`. **CHECKPOINT 2
   COMPLETE.**
6. ~~`rtl/pwm/pwm_engine.sv` + `tb/unit/pwm/pwm_engine_tb.sv`~~ — DONE
   (prior session). 16x `pwm_channel` integration (via `generate` loop)
   against `register_bank`'s `active_cfg_o` array and `pwm_counter`'s
   shared `count_o`; `ALL_LED_*` broadcast is already handled inside
   `register_bank.sv` (Section 9), so this module's job was the fan-out
   wiring/instantiation only, not re-implementing broadcast logic.
   Testbench instantiates real `register_bank` + `pwm_counter` alongside
   the DUT (regbus driven directly, no `register_decode`/i2c needed),
   covering reset defaults, normal duty-cycle compare against the live
   free-running counter, the SEMFONIX enable gate, full-on override,
   per-channel polarity, global MODE2.INVRT, the `oe_n_i`/OUTNE forced-
   state mux, and per-channel independence. **CHECKPOINT 3 COMPLETE.**
7. ~~`rtl/i2c/i2c_bus_sync.sv` + `tb/unit/i2c/i2c_bus_sync_tb.sv`~~ —
   DONE this session. Two independent 2-flop synchronizer chains for the
   raw async `scl_i`/`sda_i` pins (Section 6), reset to idle-high, no
   edge/spike-filter logic (that's `i2c_rx`'s job, Section 7.2). No
   dependency on any other not-yet-built module, so it was built and
   unit tested standalone, same "lowest-dependency leaf first" pattern
   used for `pwm_compare.sv`/`address_decode.sv`. **Checkpoint 4 now
   in progress (1 of 4 files).**
8. ~~`rtl/i2c/i2c_rx.sv`~~ — RTL DONE (prior session). Receive-path
   protocol FSM per Section 7.1: spike-filtered START/STOP/repeated-
   START detection on `i2c_bus_sync`'s synchronized SCL/SDA, address-
   byte capture feeding `address_decode`, ACK generation, and the
   byte-stream event contract (`ptr_set_i`/`wr_byte_i`/`rd_byte_i`) that
   `register_decode` already documents and expects, plus a documented
   forward contract for the not-yet-built `i2c_tx.sv`.
   ~~`tb/unit/i2c/i2c_rx_tb.sv`~~ — **DONE this session.** Two DUT
   groupings (real-dependency integration group + two bare instances for
   the spike filter and SCL-held-low timeout); see "Files Completed"
   above for full coverage. **Written and structurally/port reviewed,
   not yet executed** (no toolchain) — real compile+run is the immediate
   next action once one is reachable. **Checkpoint 4 now in progress
   (RTL + unit tb for 2 of 4 files).**
9. ~~`rtl/i2c/i2c_tx.sv` + `tb/unit/i2c/i2c_tx_tb.sv`~~ — **DONE this
   session.** Read-data shift register + open-drain SDA drive for read
   transactions, per the `tx_load_o`/`tx_drive_en_o` contract `i2c_rx.sv`
   already documented and drives; owns no protocol-FSM state of its own,
   derives its own (deliberately unfiltered — see file header rationale)
   SCL falling-edge timing from `scl_sync_i` to shift the byte out
   MSB-first. Testbench uses a bare DUT instance (bit order, shift
   timing, mid-byte disable safety, load-before-enable timing, a
   5,000-iteration randomized sweep) plus a real 6-module integration
   instance (`i2c_bus_sync` + `i2c_rx` + `address_decode` +
   `register_decode` + `register_bank` + this module, `sda_o`/`sda_oe`
   muxed on `tx_drive_en_o` in the testbench as a stand-in for the
   not-yet-built `i2c_slave.sv`) proving actual end-to-end I2C reads
   against real register storage. **Written and structurally/port
   reviewed, not yet executed** (no toolchain) — real compile+run is the
   immediate next action once one is reachable. **Checkpoint 4 now in
   progress (RTL + unit tb for 3 of 4 files).**
10. ~~`rtl/i2c/i2c_slave.sv` + `tb/unit/i2c/i2c_slave_tb.sv`~~ — **DONE.**
    Top-level I²C wrapper (`i2c_bus_sync` + `i2c_rx` + `i2c_tx` +
    `address_decode`), including the real `sda_o`/`sda_oe` mux on
    `tx_drive_en_o` that `i2c_tx_tb.sv` previously performed manually as
    a stand-in. `scripts/run_all_unit_tests.sh` updated to include
    `i2c_slave_tb`. **Written, not yet executed** (no toolchain in this
    sandbox). **CHECKPOINT 4 COMPLETE.**
11. ~~`rtl/clock/clk_reset_sync.sv` + `tb/unit/clock/clk_reset_sync_tb.sv`~~
    — **DONE.** Standard active-low async-assert/
    sync-release 2-flop reset synchronizer per Section 6; the sole file
    of the "clock" area. Deliberately does not consume `extclk_sel_i`
    (resolved entirely as a register-bank status bit — see file header
    rationale). `scripts/run_all_unit_tests.sh` updated to include
    `clk_reset_sync_tb`. **Written, not yet executed** (no toolchain in
    this sandbox).
12. ~~`rtl/top/semfonix_pwm16_top.sv`~~ — **DONE this session.**
    Top-level integration: pure structural wiring of all 9 children per
    Section 4's hierarchy (`clk_reset_sync`, `i2c_slave`,
    `address_decode`, `register_decode`, `register_bank`,
    `shadow_active_ctrl`, `prescale_gate`, `pwm_counter`, `pwm_engine`)
    plus the `scl_o`/`scl_oe` tie-off (Section 5.1). Every instantiation
    port-by-port reviewed against each child's actual module
    declaration. `i2c_slave.swrst_o`, `pwm_counter.frame_tick_o`, and
    `address_decode.allcall_match_o`/`.sub_match_o`/`.regular_match_o`
    are intentionally left unconnected (documented reasons in the file's
    own header — no invented consumer logic added). No unit tb of its
    own by design; first gets simulation coverage at step 13's
    integration testbench. **Written, not yet executed** (no toolchain
    in this sandbox). **Checkpoint 5 now in progress (2 of 4 files).**
13. ~~`tb/integration/semfonix_pwm16_tb.sv` + `tb/models/i2c_bfm.sv` +
    `tb/models/pwm_ref_model.sv`~~ — **DONE.** Authored by a prior
    session that stalled before packaging its output; merged into the
    repository this session and reviewed (structurally sanity-checked,
    every instantiation port-by-port cross-checked — no mismatches).
    Black-box integration tb + independent reference model + I2C BFM,
    per Section 23. `scripts/run_integration_test.sh` added as a
    separate runner from `scripts/run_all_unit_tests.sh`. **Written,
    not yet executed** (no toolchain in this sandbox). **Checkpoint 5
    then in progress (3 of 4 files).**
14. ~~`tb/assertions/*`~~ — **DONE this session.** Seven SVA assertion
    files, one per bound RTL module, per Section 23 ("SVA properties in
    `tb/assertions/*.sv`, bound (via `bind`) into the relevant RTL
    modules for simulation-only checking"). Three
    (`pwm_compare_assertions.sv`, `pwm_counter_assertions.sv`,
    `pwm_channel_assertions.sv`) were authored by a session that
    stalled before packaging its output and were merged in this session
    after review (structurally sanity-checked, `bind` port lists
    cross-checked against each target module's actual declaration — no
    mismatches, no changes needed). The other four
    (`clk_reset_sync_assertions.sv`, `register_bank_assertions.sv`,
    `shadow_active_ctrl_assertions.sv`, `i2c_slave_assertions.sv`) did
    not survive that stall and were authored fresh this session in the
    same file-per-module/`` `ifdef SIMULATION ``/`bind`-`.*` style,
    each read against its target RTL's actual ports and internal
    signal names (see "SVA assertions" under "Files Completed" above
    for exactly what each one checks). `scripts/run_all_unit_tests.sh`
    and `scripts/run_integration_test.sh` were updated to pass
    `-DSIMULATION` and to compile each assertion file alongside every
    DUT set that instantiates the RTL module it binds to. **Written,
    not yet executed** (no toolchain in this sandbox). **CHECKPOINT 5
    COMPLETE (4 of 4 files).**
15. `scripts/synth_yosys.sh` + `yosys/synth.tcl` — **DONE this
    session.** Generic Yosys synthesis flow (Section 22 step 15, the
    sole step of Checkpoint 6): `read_verilog -sv` over all 15
    `rtl/**/*.sv` files (never `tb/**`), `hierarchy -check`, `synth
    -top semfonix_pwm16_top -noabc` (technology-mapping to Yosys's own
    internal generic-cell set, `abc` deliberately skipped as a separate
    unavailable binary — see file header), `check -noinit`, and three
    reports to `build/synth/` (`stat_report.txt`, a synthesized-netlist
    Verilog dump, and a JSON netlist). The wrapper script checks for
    `yosys` on `PATH` first, then greps its own log for a
    `SYNTH_TCL_COMPLETE` sentinel and any `^ERROR` line before trusting
    yosys's exit code, and reports a `Warning:` count distinctly (a
    nonzero count leaves the checkpoint open, per its own "warning
    cleanup" scope). RTL source list and module names manually
    re-derived from the actual `rtl/` tree and cross-checked against
    every file's own `module` declaration (all 15 match); a grep sweep
    found no `$display`/`$fatal`/`$finish`/delay/`real`/`time`-typed
    constructs anywhere in `rtl/**` (every match was inside a comment).
    **Written, not yet executed** — `yosys` confirmed absent this
    session (`which yosys` → not found; a live `apt-get install -y
    yosys iverilog` attempt returned `403 Forbidden`, same no-egress
    result as every prior session's check). **CHECKPOINT 6 IN
    PROGRESS** — running this script for real on a machine with
    `yosys`, and triaging whatever it reports, is one remaining piece
    of synthesis-side work (see step 16 below for the other).
16. `scripts/verilator_lint.sh` — **DONE this session**, added on
    explicit request to bring Verilator into the toolchain story.
    Verilator `--lint-only -Wall` over the same 15 `rtl/**/*.sv` files
    (never `tb/**`), run as a second, independent lint/synthesizability
    opinion alongside `synth_yosys.sh` — not a replacement for it, and
    no existing testbench was converted to Verilator (Verilator's
    timing/procedural-code support differs meaningfully from Icarus
    Verilog's, which every existing `tb/unit/`/`tb/integration/` file
    was authored and reviewed against; converting them is nontrivial,
    out of scope for a lint-only RTL-source addition, and was not
    requested). **Written, not yet executed** — `verilator` confirmed
    absent this session (`which verilator` → not found; both a live
    `apt-get install -y verilator` and a `pip install verilator
    --break-system-packages` attempt failed — the former with the same
    `403 Forbidden` every toolchain check here hits (including on
    Verilator's own `libsystemc`/`libsystemc-dev` build dependencies),
    the latter because no such PyPI package exists, confirmed directly
    rather than assumed). **CHECKPOINT 6 STILL IN PROGRESS** — running
    step 15's, 16's, and (this session's) 17's scripts and triaging
    their output is the only remaining work in the entire Section 22
    implementation order.
17. `scripts/run_all_unit_tests_verilator.sh` +
    `scripts/run_integration_test_verilator.sh` — **DONE this
    session**, added on explicit request ("Yes we run verilator
    compilation and simulation for all"). Genuine Verilator
    compile-AND-run counterparts to `run_all_unit_tests.sh`/
    `run_integration_test.sh` (not lint-only, unlike step 16):
    `verilator --binary --timing` builds each of the 12 unit
    testbenches and the integration testbench into a standalone
    executable and runs it, PASS/FAIL read from the executable's own
    exit code — the same convention `run_all_unit_tests.sh` already
    relies on for `vvp`'s exit code. Per-test source lists were copied
    verbatim from the Icarus scripts and diffed programmatically
    (`grep -oE` extraction + `diff`) to confirm an exact file-for-file,
    order-for-order match — same 15 RTL files, 7 assertion files, 12
    unit testbenches, integration testbench, and 2 `tb/models/*.sv`
    files; no RTL or testbench file modified or duplicated. A
    compatibility review (grep sweep of every `tb/**/*.sv` file for
    `$random`/`class`/`mailbox`/`semaphore`/`virtual interface`/`DPI`/
    `fork`-`join`) found none of those constructs in actual use — a few
    string hits were comments, not code; the one real randomization
    construct present, `$urandom_range` (used in several testbenches'
    randomized sweeps), is Verilator-supported. This is explicitly not
    a substitute for an actual compile: both scripts' own header
    comments carry a "COMPATIBILITY CAVEAT" explaining that Verilator's
    SystemVerilog subset support (especially under `--timing`) has
    edges a grep sweep and read-through don't reliably catch, and that
    the first real run is expected to surface some number of fixable
    issues, to be resolved and recorded then rather than pre-emptively
    guessed at now. **Written, not yet executed** — `verilator` still
    absent this session (re-checked directly: `which verilator` → not
    found; `apt-get install -y verilator` attempted again live,
    returning the same `403 Forbidden` every prior attempt in this
    sandbox has hit; `apt-cache policy verilator` confirms a candidate,
    5.020-1, exists in the configured repo but cannot be fetched). No
    compile result, simulation result, or pass/fail count is known or
    claimed for any testbench under Verilator. **CHECKPOINT 6 STILL IN
    PROGRESS** — this is now the only remaining work anywhere in the
    Section 22 implementation order: running all four Checkpoint-6
    scripts (`synth_yosys.sh`, `verilator_lint.sh`,
    `run_all_unit_tests_verilator.sh`, `run_integration_test_verilator.sh`)
    plus the two original Icarus scripts on a machine with the
    respective toolchains, and triaging whatever any of them reports.

## Remaining Work

See Section 22 (Implementation Order) of MASTER_ARCHITECTURE.md for the
full remaining sequence, steps 10-15 (Checkpoint 4 = step 10, Checkpoint
5 = steps 11-14, Checkpoint 6 = step 15). Checkpoints 0-5 (steps 1-14)
are complete. Checkpoint 6 (step 15, Yosys synthesis) is now IN
PROGRESS: `scripts/synth_yosys.sh` + `yosys/synth.tcl` are written and
structurally reviewed but **not yet executed** (no `yosys` toolchain in
this sandbox — see "Yosys Status" above). The remaining work to close
out Checkpoint 6, and the entire Section 22 implementation order, is
purely toolchain-gated: run the synthesis script, run both simulation
scripts, and resolve whatever either surfaces — no further RTL, tb, or
docs authoring is anticipated to be needed before that point unless a
real run finds a bug.

## Yosys Status

**Script written this session, not yet executed.**
`scripts/synth_yosys.sh` + `yosys/synth.tcl` now exist: `read_verilog
-sv` over every `rtl/**/*.sv` file (never `tb/**`, which includes
simulation-only constructs like the `` `ifdef SIMULATION ``-guarded
assertion binds), `hierarchy -check`, a generic `synth -noabc` pass
(technology-mapping to Yosys's own internal cell set, deliberately
skipping the separate `abc` binary — see `yosys/synth.tcl`'s header for
the full rationale), a structural `check`, and three reports written to
`build/synth/`: `stat_report.txt` (cell-count/structural report — no
PDK exists or is in scope per Section 1, so this is a generic-cell
tally, not a $/um² number), `semfonix_pwm16_top.synth.v`, and
`semfonix_pwm16_top.synth.json`. `scripts/synth_yosys.sh` checks for
`yosys` on `PATH` before doing anything (exit 2, matching
`run_all_unit_tests.sh`'s own pattern for a missing `iverilog`), then
after running greps its captured log for a `SYNTH_TCL_COMPLETE`
sentinel and any `^ERROR` line before trusting yosys's own exit code,
and reports a `^Warning:` count distinctly — Checkpoint 6's own title
is "Yosys synthesis, reports, **warning cleanup**", so a nonzero
warning count is treated by the script's own output as "checkpoint not
yet closed," not silently ignored.
**Not run this session** — `yosys` confirmed absent (`which yosys` →
not found) and a live `apt-get install -y yosys iverilog` attempt
returned `403 Forbidden` across every package in the dependency chain
(re-confirmed directly this session, not assumed carried over from any
prior session's note — this is the same no-network-egress sandbox every
prior checkpoint hit). No cell count, warning count, or pass/fail
synthesis result is known yet — do not report one until this script is
actually run on a machine with `yosys` on `PATH`.
**Next (a future session):** run `scripts/synth_yosys.sh` and
`scripts/verilator_lint.sh` for real the moment a toolchain is
reachable; triage `build/synth/stat_report.txt` /
`build/verilator_lint/verilator_lint.log` and any warnings either
surfaces (fix in RTL, or record a documented reason each is expected —
for Verilator, via an inline `/* verilator lint_off ... */` with a
comment, not a blanket `-Wno-` flag added silently to the script); if
`abc` also turns out to be available, re-run `synth -top
semfonix_pwm16_top` without `-noabc` as a strict superset check per
`synth.tcl`'s own note; only then mark Checkpoint 6 (and the whole
Section 22 implementation order) complete. Independent of both:
`scripts/run_all_unit_tests.sh` and `scripts/run_integration_test.sh`
still also await a real run — see their own sections above.

## Important Architectural Decisions So Far

- ADR-0001: single shared `pwm_counter`, replicated `pwm_compare` per
  channel, all state lives in `register_bank` (not duplicated in
  `pwm_channel`). See MASTER_ARCHITECTURE.md Section 9 and ADR log.
- ADR-0002: 2026 competitive feature/PPA review at the Checkpoint 2
  boundary — no architecture changes (TLC59116 group dimming/blinking
  evaluated and rejected; see `docs/product/COMPETITIVE_REVIEW_2026.md`
  and MASTER_ARCHITECTURE.md ADR log).

## IMPORTANT — Toolchain Availability In This Sandbox

`iverilog`/`vvp`/`yosys` are **not installed** in this execution sandbox
and the sandbox has no network access to install them (`apt-get` returns
403/forbidden — no egress). This means:

- RTL and testbenches below are written to be simulator-ready
  (Icarus Verilog `-g2012` compatible subset) and synthesis-ready
  (Yosys `read_verilog -sv` compatible subset), but **have not been
  compiled or executed in this session** — "tests written" does not yet
  mean "tests passed" until run on a machine with the toolchain.
- Every unit testbench is self-checking (prints PASS/FAIL, sets a
  non-zero exit code on failure) specifically so it can be run
  immediately once a toolchain is available, with no further authoring.
- `scripts/run_all_unit_tests.sh` and `scripts/synth_yosys.sh` are
  provided and are the exact commands to run once iverilog/yosys are
  available (locally, in CI, or in a future session that does have
  network/toolchain access).
- This status will be corrected the moment any test is actually run and
  its real pass/fail result is known — do not report simulated results as
  if they were real without re-verifying tool availability first.

## Simulator / Toolchain Assumptions

- Testbenches target Icarus Verilog (`iverilog`/`vvp`) with SystemVerilog
  subset compatible with `-g2012`, since that's the most likely locally
  available open-source simulator for this environment. Assertions in
  `tb/assertions/` use `bind` and are written to degrade gracefully
  (guarded by `` `ifdef SIMULATION ``) if not supported by a given tool.
- Yosys synthesis script targets Yosys's native SystemVerilog support
  (`read_verilog -sv`) or falls back to a lint-clean synthesizable subset.
- No proprietary/vendor simulator assumed anywhere in this repo.
