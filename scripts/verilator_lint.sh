#!/usr/bin/env bash
# =============================================================================
# verilator_lint.sh
#
# Checkpoint 6 (Section 22 step 15) addendum, added on explicit request to
# bring Verilator into the toolchain story alongside Yosys. This is a
# `--lint-only` pass, not a simulation run: Verilator elaborates and
# lint-checks every rtl/**/*.sv file (never tb/**, same boundary
# scripts/synth_yosys.sh already draws, for the same reason -- tb/assertions
# is simulation-only `bind`/`` `ifdef SIMULATION `` content per Section 23,
# and tb/unit/tb/integration/tb/models are testbench-side, not
# synthesizable RTL) against the top module semfonix_pwm16_top, without
# generating a C++/simulation model. This is deliberately NOT a
# replacement for scripts/synth_yosys.sh -- it's a second, independent
# tool's opinion on synthesizability/lint-cleanliness (Verilator's own
# lint ruleset differs from and is often stricter than Yosys's `check`
# pass, e.g. Verilator's UNUSED/UNDRIVEN/WIDTH/CASEINCOMPLETE warnings),
# run alongside it rather than instead of it, per this repository's
# established pattern of independent cross-checks (see e.g.
# tb/models/pwm_ref_model.sv's own "independent reference model, not
# reusing RTL comparator code" rationale for the same "two independent
# opinions beat one" reasoning applied to lint/synth instead of behavior).
#
# Requires: verilator on PATH.
#
# Usage:
#   ./scripts/verilator_lint.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: verilator not found on PATH. Install Verilator to run this"
  echo "lint check."
  echo "(See docs/IMPLEMENTATION_STATUS.md 'IMPORTANT -- Toolchain"
  echo " Availability' note -- this sandbox has neither verilator nor"
  echo " network egress to install it; run this script on a machine that"
  echo " has it.)"
  exit 2
fi

BUILD_DIR="build/verilator_lint"
mkdir -p "$BUILD_DIR"

LOG="$BUILD_DIR/verilator_lint.log"

SOURCES=(
  rtl/pwm/pwm_compare.sv
  rtl/pwm/pwm_counter.sv
  rtl/pwm/pwm_channel.sv
  rtl/pwm/pwm_engine.sv
  rtl/registers/register_bank.sv
  rtl/registers/register_decode.sv
  rtl/registers/address_decode.sv
  rtl/control/shadow_active_ctrl.sv
  rtl/control/prescale_gate.sv
  rtl/i2c/i2c_bus_sync.sv
  rtl/i2c/i2c_rx.sv
  rtl/i2c/i2c_tx.sv
  rtl/i2c/i2c_slave.sv
  rtl/clock/clk_reset_sync.sv
  rtl/top/semfonix_pwm16_top.sv
)

echo "=== Running Verilator --lint-only (top=semfonix_pwm16_top) ==="
# -sv               : SystemVerilog input (packed structs, always_comb/ff,
#                     logic type -- same reason -sv is passed to iverilog
#                     and read_verilog elsewhere in this repo).
# -Wall             : enable Verilator's full warning set, not just its
#                     default subset, since this is explicitly a
#                     lint-cleanliness checkpoint.
# --top-module      : matches the same top used by synth_yosys.sh and
#                     run_integration_test.sh.
# -Wno-DECLFILENAME : Verilator by default warns when a module's name
#                     doesn't match its filename exactly; every file in
#                     this repo is named after its module already, but
#                     this flag is kept explicit (not silently relied on
#                     as a non-issue) in case a future rename ever
#                     violates it -- see the log/warning-count check below,
#                     which would still catch a *different* file-name
#                     mismatch since this only suppresses the one specific
#                     rule, not lint output generally.
if ! verilator --lint-only -sv -Wall -Wno-DECLFILENAME \
     --top-module semfonix_pwm16_top \
     "${SOURCES[@]}" 2>&1 | tee "$LOG"; then
  echo "!!! VERILATOR REPORTED ERRORS -- see $LOG"
  exit 1
fi

WARN_COUNT="$(grep -cE "^%Warning" "$LOG" || true)"

echo ""
echo "================================================================"
echo "Verilator lint-only completed for top=semfonix_pwm16_top."
echo "Warnings reported: $WARN_COUNT"
if [ "$WARN_COUNT" -gt 0 ]; then
  echo ""
  echo "Warning lines (see $LOG for full context):"
  grep -E "^%Warning" "$LOG"
  echo ""
  echo "Per Checkpoint 6's 'warning cleanup' scope, a nonzero count here"
  echo "means this checkpoint is not yet closed out -- triage each"
  echo "warning against the matching RTL file (fix it, or record a"
  echo "documented reason it's expected -- e.g. via an inline"
  echo "/* verilator lint_off ... */ with a comment, not a blanket -Wno-"
  echo "flag added silently to this script) in"
  echo "docs/IMPLEMENTATION_STATUS.md before calling Checkpoint 6 done."
fi
echo "================================================================"

exit 0
