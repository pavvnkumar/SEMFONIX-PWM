#!/usr/bin/env bash
# =============================================================================
# run_all_unit_tests.sh
#
# Compiles and runs every unit-level testbench under tb/unit/ with Icarus
# Verilog, reporting a final PASS/FAIL summary. Each testbench is
# self-checking ($display PASS/FAIL + $fatal on failure), so this script
# just needs to invoke each one and track vvp's exit code.
#
# Requires: iverilog, vvp (Icarus Verilog) on PATH.
#
# Usage:
#   ./scripts/run_all_unit_tests.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v iverilog >/dev/null 2>&1; then
  echo "ERROR: iverilog not found on PATH. Install Icarus Verilog to run tests."
  exit 2
fi

BUILD_DIR="build/unit"
mkdir -p "$BUILD_DIR"

total=0
passed=0
failed_list=()

run_test () {
  local name="$1"
  shift
  local sources=("$@")
  local out="$BUILD_DIR/${name}.vvp"
  total=$((total+1))
  echo "=== Building $name ==="
  if ! iverilog -g2012 -DSIMULATION -o "$out" "${sources[@]}"; then
    echo "!!! COMPILE FAILED: $name"
    failed_list+=("$name (compile)")
    return
  fi
  echo "=== Running $name ==="
  if vvp "$out"; then
    passed=$((passed+1))
  else
    failed_list+=("$name (runtime)")
  fi
}

# --- PWM unit tests ---
run_test pwm_compare_tb \
  rtl/pwm/pwm_compare.sv \
  tb/assertions/pwm_compare_assertions.sv \
  tb/unit/pwm/pwm_compare_tb.sv

run_test pwm_counter_tb \
  rtl/pwm/pwm_counter.sv \
  tb/assertions/pwm_counter_assertions.sv \
  tb/unit/pwm/pwm_counter_tb.sv

run_test pwm_channel_tb \
  rtl/pwm/pwm_compare.sv \
  rtl/pwm/pwm_channel.sv \
  tb/assertions/pwm_compare_assertions.sv \
  tb/assertions/pwm_channel_assertions.sv \
  tb/unit/pwm/pwm_channel_tb.sv

# --- Register/control unit tests (Checkpoint 2) ---
run_test register_bank_tb \
  rtl/registers/register_bank.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/unit/registers/register_bank_tb.sv

run_test register_decode_tb \
  rtl/registers/register_bank.sv \
  rtl/registers/register_decode.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/unit/registers/register_decode_tb.sv

run_test address_decode_tb \
  rtl/registers/address_decode.sv \
  tb/unit/registers/address_decode_tb.sv

run_test shadow_active_ctrl_tb \
  rtl/registers/register_bank.sv \
  rtl/registers/register_decode.sv \
  rtl/control/shadow_active_ctrl.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/assertions/shadow_active_ctrl_assertions.sv \
  tb/unit/control/shadow_active_ctrl_tb.sv

run_test prescale_gate_tb \
  rtl/registers/register_bank.sv \
  rtl/control/prescale_gate.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/unit/control/prescale_gate_tb.sv

# --- PWM integration unit test (Checkpoint 3) ---
run_test pwm_engine_tb \
  rtl/registers/register_bank.sv \
  rtl/pwm/pwm_compare.sv \
  rtl/pwm/pwm_channel.sv \
  rtl/pwm/pwm_counter.sv \
  rtl/pwm/pwm_engine.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/assertions/pwm_compare_assertions.sv \
  tb/assertions/pwm_channel_assertions.sv \
  tb/assertions/pwm_counter_assertions.sv \
  tb/unit/pwm/pwm_engine_tb.sv

# --- I2C unit tests (Checkpoint 4) ---
run_test i2c_bus_sync_tb \
  rtl/i2c/i2c_bus_sync.sv \
  tb/unit/i2c/i2c_bus_sync_tb.sv

run_test i2c_rx_tb \
  rtl/i2c/i2c_bus_sync.sv \
  rtl/i2c/i2c_rx.sv \
  rtl/registers/address_decode.sv \
  rtl/registers/register_decode.sv \
  rtl/registers/register_bank.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/unit/i2c/i2c_rx_tb.sv

run_test i2c_tx_tb \
  rtl/i2c/i2c_bus_sync.sv \
  rtl/i2c/i2c_rx.sv \
  rtl/i2c/i2c_tx.sv \
  rtl/registers/address_decode.sv \
  rtl/registers/register_decode.sv \
  rtl/registers/register_bank.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/unit/i2c/i2c_tx_tb.sv

run_test i2c_slave_tb \
  rtl/i2c/i2c_bus_sync.sv \
  rtl/i2c/i2c_rx.sv \
  rtl/i2c/i2c_tx.sv \
  rtl/i2c/i2c_slave.sv \
  rtl/registers/address_decode.sv \
  rtl/registers/register_decode.sv \
  rtl/registers/register_bank.sv \
  tb/assertions/register_bank_assertions.sv \
  tb/assertions/i2c_slave_assertions.sv \
  tb/unit/i2c/i2c_slave_tb.sv

# --- Clock/reset unit test (Checkpoint 5, step 11) ---
run_test clk_reset_sync_tb \
  rtl/clock/clk_reset_sync.sv \
  tb/assertions/clk_reset_sync_assertions.sv \
  tb/unit/clock/clk_reset_sync_tb.sv

# NOTE: additional run_test lines are appended here as later checkpoints
# (i2c, top-level) add their own unit testbenches. See
# docs/IMPLEMENTATION_STATUS.md for what has been added so far.

echo ""
echo "================================================================"
echo "Unit test summary: $passed / $total passed"
if [ ${#failed_list[@]} -gt 0 ]; then
  echo "FAILED:"
  for f in "${failed_list[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
echo "ALL UNIT TESTS PASSED"
exit 0
