#!/usr/bin/env bash
# =============================================================================
# run_integration_test_verilator.sh
#
# Compiles AND SIMULATES tb/integration/semfonix_pwm16_tb.sv using
# Verilator (`--binary --timing`), reporting PASS/FAIL -- the Verilator
# counterpart to run_integration_test.sh (Icarus Verilog), added on
# explicit request alongside run_all_unit_tests_verilator.sh. Kept as a
# separate script for the same reason run_integration_test.sh itself is
# kept separate from the unit-test runner: a meaningfully different,
# full-chip source list and verification tier (Section 23) from any
# single unit test.
#
# SOURCES below is copied verbatim from run_integration_test.sh's own
# SOURCES array -- same files, same order -- so this exercises the exact
# same design-under-test the Icarus integration run already targets.
#
# See run_all_unit_tests_verilator.sh's header for the full --binary/
# --timing rationale and, importantly, its COMPATIBILITY CAVEAT: this
# script has been reviewed for known-unsupported constructs (none found
# in a targeted grep of tb/integration/semfonix_pwm16_tb.sv and
# tb/models/*.sv for $random/classes/mailboxes/semaphores/virtual
# interfaces/DPI/fork-join) but has NOT been proven to actually compile
# under Verilator -- that caveat applies here in full, and doubly so
# given this is the largest single source list in the repository (all 15
# RTL files, 7 assertion files, both tb/models files, and the top-level
# testbench itself).
#
# Requires: verilator on PATH (5.006+ for --timing).
#
# Usage:
#   ./scripts/run_integration_test_verilator.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: verilator not found on PATH. Install Verilator (5.006+, for"
  echo "--timing support) to run this script."
  exit 2
fi

BUILD_DIR="build/integration_verilator"
mkdir -p "$BUILD_DIR"

TOP="semfonix_pwm16_tb"
OUT_BIN="$BUILD_DIR/V${TOP}"

SOURCES=(
  rtl/registers/register_bank.sv
  rtl/registers/register_decode.sv
  rtl/registers/address_decode.sv
  rtl/control/shadow_active_ctrl.sv
  rtl/control/prescale_gate.sv
  rtl/pwm/pwm_compare.sv
  rtl/pwm/pwm_channel.sv
  rtl/pwm/pwm_counter.sv
  rtl/pwm/pwm_engine.sv
  rtl/i2c/i2c_bus_sync.sv
  rtl/i2c/i2c_rx.sv
  rtl/i2c/i2c_tx.sv
  rtl/i2c/i2c_slave.sv
  rtl/clock/clk_reset_sync.sv
  rtl/top/semfonix_pwm16_top.sv
  tb/assertions/pwm_compare_assertions.sv
  tb/assertions/pwm_counter_assertions.sv
  tb/assertions/pwm_channel_assertions.sv
  tb/assertions/register_bank_assertions.sv
  tb/assertions/shadow_active_ctrl_assertions.sv
  tb/assertions/i2c_slave_assertions.sv
  tb/assertions/clk_reset_sync_assertions.sv
  tb/models/i2c_bfm.sv
  tb/models/pwm_ref_model.sv
  tb/integration/semfonix_pwm16_tb.sv
)

echo "=== Building semfonix_pwm16_tb (integration, verilator --binary --timing) ==="
if ! verilator --binary --timing -sv -DSIMULATION \
     -Wno-fatal \
     --top-module "$TOP" \
     --Mdir "$BUILD_DIR" \
     -o "V${TOP}" \
     "${SOURCES[@]}"; then
  echo "!!! COMPILE FAILED: semfonix_pwm16_tb (verilator)"
  exit 1
fi

echo "=== Running semfonix_pwm16_tb (integration, verilator) ==="
if "$OUT_BIN"; then
  echo "ALL INTEGRATION TESTS PASSED (verilator)"
  exit 0
else
  echo "FAILED: semfonix_pwm16_tb (verilator)"
  exit 1
fi
