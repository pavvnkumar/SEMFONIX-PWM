#!/usr/bin/env bash
# =============================================================================
# synth_yosys.sh
#
# CHECKPOINT 6 (Section 22 step 15): runs Yosys generic synthesis over every
# rtl/**/*.sv file (never tb/**) via yosys/synth.tcl, top module
# semfonix_pwm16_top, and reports cell-count/warning results. Per
# MASTER_ARCHITECTURE.md Section 1 ("RTL + RTL verification + Yosys-clean
# synthesis only"), this is generic-cell synthesis -- no PDK, no vendor
# standard-cell library, no FPGA architecture target. See yosys/synth.tcl's
# own header for exactly which passes run and why `-noabc` is used.
#
# Requires: yosys on PATH.
#
# Usage:
#   ./scripts/synth_yosys.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v yosys >/dev/null 2>&1; then
  echo "ERROR: yosys not found on PATH. Install Yosys to run synthesis."
  echo "(See docs/IMPLEMENTATION_STATUS.md 'IMPORTANT -- Toolchain"
  echo " Availability' note -- this sandbox has neither yosys nor network"
  echo " egress to install it; run this script on a machine that has it.)"
  exit 2
fi

BUILD_DIR="build/synth"
mkdir -p "$BUILD_DIR"

LOG="$BUILD_DIR/yosys.log"

echo "=== Running Yosys synthesis (yosys/synth.tcl, top=semfonix_pwm16_top) ==="
if ! yosys -c yosys/synth.tcl 2>&1 | tee "$LOG"; then
  echo "!!! YOSYS EXITED WITH A NON-ZERO STATUS -- see $LOG"
  exit 1
fi

# yosys itself can exit 0 while still having hit an internal error message
# on some passes, so don't trust the exit code alone -- confirm the
# script's own final log line landed, and separately confirm no line
# starting with "ERROR" appears anywhere in the log.
if ! grep -q "SYNTH_TCL_COMPLETE" "$LOG"; then
  echo "!!! yosys/synth.tcl did not reach its final log line -- treat as a"
  echo "    failed/incomplete run even though yosys exited 0. See $LOG"
  exit 1
fi

if grep -qE "^ERROR" "$LOG"; then
  echo "!!! One or more ERROR lines found in $LOG despite reaching"
  echo "    SYNTH_TCL_COMPLETE -- inspect before trusting this run."
  exit 1
fi

WARN_COUNT="$(grep -cE "^Warning:" "$LOG" || true)"

echo ""
echo "================================================================"
echo "Yosys synthesis completed for top=semfonix_pwm16_top."
echo "Warnings reported: $WARN_COUNT"
if [ "$WARN_COUNT" -gt 0 ]; then
  echo ""
  echo "Warning lines (see $LOG for full context):"
  grep -E "^Warning:" "$LOG"
  echo ""
  echo "Per Checkpoint 6's 'warning cleanup' scope, a nonzero count here"
  echo "means this checkpoint is not yet closed out -- triage each"
  echo "warning against the matching RTL file and either fix it or"
  echo "record a documented reason it's expected, in"
  echo "docs/IMPLEMENTATION_STATUS.md, before calling Checkpoint 6 done."
fi
echo ""
echo "Cell-count / structural report: $BUILD_DIR/stat_report.txt"
echo "Synthesized netlist (Verilog):  $BUILD_DIR/semfonix_pwm16_top.synth.v"
echo "Synthesized netlist (JSON):     $BUILD_DIR/semfonix_pwm16_top.synth.json"
echo "================================================================"

exit 0
