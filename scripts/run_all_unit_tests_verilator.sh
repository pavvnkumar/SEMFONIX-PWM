#!/usr/bin/env bash
# =============================================================================
# run_all_unit_tests_verilator.sh
#
# Compiles AND SIMULATES every unit-level testbench under tb/unit/ using
# Verilator, reporting a final PASS/FAIL summary -- a Verilator-based
# alternative to run_all_unit_tests.sh (Icarus Verilog), added on explicit
# request. This is a genuine second compile+run path, not a lint-only
# check like verilator_lint.sh: each testbench is built into a standalone
# simulation binary via `verilator --binary` and actually executed, with
# PASS/FAIL determined the same way run_all_unit_tests.sh already
# determines it for vvp -- by the simulation binary's own exit code, since
# every testbench here is self-checking ($display PASS/FAIL,
# `$fatal(1)`/nonzero exit on any mismatch, `$finish(0)`/exit 0 on success,
# per this repository's own testbench-writing convention -- see
# docs/IMPLEMENTATION_STATUS.md's "Tests Passed / Failed" section).
#
# Per-test SOURCES lists below are copied verbatim from
# run_all_unit_tests.sh's own `run_test` calls -- same files, same order,
# same dependency grouping -- so this script exercises the exact same
# design-under-test each unit test already targets under Icarus, not a
# reduced or reshuffled set. No RTL or testbench file is modified or
# duplicated to make this work; Verilator compiles the same .sv sources
# in place.
#
# --binary --timing:
#   --binary   Verilator's single-command "compile a runnable simulation
#              executable and place it at the requested output path" mode
#              (introduced in Verilator 4.202+), avoiding a hand-written
#              C++ testbench harness -- appropriate here since every
#              testbench in this repository is self-contained SystemVerilog
#              that drives its own clock/reset and does its own checking,
#              with no need for a C++-side driver.
#   --timing   Enables Verilator's (Verilator 5.006+) support for
#              procedural timing controls (#delay, @(posedge ...), `wait`)
#              in ordinary (non-DPI) SystemVerilog code -- required because
#              every testbench here uses delay-based stimulus generation
#              (`#10 clk = ~clk`-style clock generators, `#1` settle delays,
#              etc.), which is normal, idiomatic testbench code under
#              Icarus but requires this explicit opt-in flag under
#              Verilator, whose default (non---timing) mode targets
#              synthesizable RTL only.
#
# IMPORTANT -- COMPATIBILITY CAVEAT (read before trusting a clean run):
# This script's SOURCES lists and flags were prepared by static review
# (grepping every tb/**/*.sv file for constructs Verilator's --timing mode
# is known not to support -- $random/classes/mailboxes/semaphores/virtual
# interfaces/DPI/fork-join were all searched for and none were found; the
# one $urandom_range-based randomized sweep in pwm_compare_tb.sv is
# Verilator-supported). This is NOT the same thing as an actual successful
# compile -- Verilator's SystemVerilog subset support, especially under
# --timing, has sharper edges than Icarus Verilog's in places neither a
# grep sweep nor a human read-through reliably catches (e.g. specific
# always_comb/always_ff sensitivity-list inference differences, certain
# packed-struct-array port connection patterns, or `bind`-based assertion
# scoping quirks). The FIRST real run of this script on a machine with
# Verilator is expected to surface some number of compile errors or
# warnings that require small, targeted fixes (either to this script's
# flags, e.g. an additional `-Wno-<RULE>`, or -- only if a genuine
# Verilator-vs-Icarus semantic gap is found, not just a stricter lint
# rule -- to the affected testbench itself, decided and recorded at that
# time, not pre-emptively guessed at here). Treat this script exactly as
# every other not-yet-executed file in this repository is treated: written
# and reviewed, not yet proven to compile or pass.
#
# Requires: verilator on PATH (Verilator 5.006+ for --timing; the version
# available via this sandbox's own package candidate, 5.020-1, satisfies
# this).
#
# Usage:
#   ./scripts/run_all_unit_tests_verilator.sh
# =============================================================================
set -u
cd "$(dirname "$0")/.."

if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: verilator not found on PATH. Install Verilator (5.006+, for"
  echo "--timing support) to run this script."
  exit 2
fi

BUILD_DIR="build/unit_verilator"
mkdir -p "$BUILD_DIR"

total=0
passed=0
failed_list=()

run_test () {
  local name="$1"
  shift
  local sources=("$@")
  local out_dir="$BUILD_DIR/$name"
  local out_bin="$out_dir/V${name}"
  total=$((total+1))
  echo "=== Building $name (verilator --binary --timing) ==="
  mkdir -p "$out_dir"
  if ! verilator --binary --timing -sv -DSIMULATION \
       -Wno-fatal \
       --top-module "$name" \
       --Mdir "$out_dir" \
       -o "V${name}" \
       "${sources[@]}"; then
    echo "!!! COMPILE FAILED: $name"
    failed_list+=("$name (compile)")
    return
  fi
  echo "=== Running $name ==="
  if "$out_bin"; then
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

echo ""
echo "================================================================"
echo "Verilator unit test summary: $passed / $total passed"
if [ ${#failed_list[@]} -gt 0 ]; then
  echo "FAILED:"
  for f in "${failed_list[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
echo "ALL UNIT TESTS PASSED (verilator)"
exit 0
