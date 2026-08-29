#!/usr/bin/env bash
# =============================================================================
# run_integration_test.sh
#
# Compiles and runs tb/integration/semfonix_pwm16_tb.sv (step 13 of the
# Section 22 implementation order) with Icarus Verilog, reporting PASS/FAIL.
# Kept as a separate script from run_all_unit_tests.sh (rather than a new
# run_test line appended there) because the integration testbench pulls in
# every RTL file in the design plus both tb/models/*.sv files -- a
# meaningfully different, full-chip source list from any single unit test's
# short dependency list, and per Section 23 a functionally different
# verification tier (black-box top-level checking vs. per-module unit
# checking), so keeping the two runners separate keeps each script's source
# list legible at a glance.
#
# Requires: iverilog, vvp (Icarus Verilog) on PATH.
#
# Usage:
#   ./scripts/run_integration_test.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v iverilog >/dev/null 2>&1; then
  echo "ERROR: iverilog not found on PATH. Install Icarus Verilog to run tests."
  exit 2
fi

BUILD_DIR="build/integration"
mkdir -p "$BUILD_DIR"

OUT="$BUILD_DIR/semfonix_pwm16_tb.vvp"

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

echo "=== Building semfonix_pwm16_tb (integration) ==="
if ! iverilog -g2012 -DSIMULATION -o "$OUT" "${SOURCES[@]}"; then
  echo "!!! COMPILE FAILED: semfonix_pwm16_tb"
  exit 1
fi

echo "=== Running semfonix_pwm16_tb (integration) ==="
if vvp "$OUT"; then
  echo "ALL INTEGRATION TESTS PASSED"
  exit 0
else
  echo "FAILED: semfonix_pwm16_tb"
  exit 1
fi
