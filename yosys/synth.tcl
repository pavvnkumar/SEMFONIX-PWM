# =============================================================================
# yosys/synth.tcl
#
# CHECKPOINT 6 (Section 22 step 15) synthesis script. Invoked by
# scripts/synth_yosys.sh via `yosys -c yosys/synth.tcl`, never run directly
# (the wrapper script is what sets up the output directory and checks for
# the yosys binary first).
#
# Scope, per MASTER_ARCHITECTURE.md Section 1 ("RTL + RTL verification +
# Yosys-clean synthesis only. No OpenLane/OpenROAD/PDK/floorplan/place/
# route/DRC/LVS/GDS work is in scope, ever"): this script proves the RTL
# is synthesizable and produces an area/cell-count report using Yosys's
# own internal generic-cell library, NOT a vendor standard-cell library or
# FPGA architecture mapping -- there is no PDK in this repository and none
# is in scope. This is the generic `synth` pass with technology mapping
# (the `abc`-driven final gate-mapping step) skipped via `-noabc`,
# because `abc` is a separate binary from `yosys` itself and this
# sandbox's toolchain-availability note (see IMPLEMENTATION_STATUS.md)
# applies to it too -- `-noabc` keeps the flow to the parts Yosys performs
# internally (hierarchy check, proc, memory, opt, fsm, generic techmap to
# Yosys's own internal cell set) without depending on a second external
# tool, while still exercising every synthesizability-relevant pass
# (unresolved hierarchy, multi-driven nets, combinational loops, latch
# inference, width mismatches -- all caught well before `abc` would ever
# run). If `abc` is confirmed present on a future machine, re-running
# `synth -top semfonix_pwm16_top` without `-noabc` is a strict superset
# check and is noted as a follow-up in IMPLEMENTATION_STATUS.md rather
# than assumed here.
#
# Source list: every file under rtl/**/*.sv, in leaf-to-top dependency
# order (matching scripts/run_integration_test.sh's own SOURCES order,
# since that list is already a verified-by-review correct elaboration
# order for this exact hierarchy). Deliberately NEVER reads anything
# under tb/** -- tb/assertions/*.sv is simulation-only (bind + `ifdef
# SIMULATION`, per Section 23: "kept out of the synthesizable RTL files
# themselves") and has no business in a synthesis run; tb/unit,
# tb/integration, and tb/models are testbench-side and not
# synthesizable (many use $display/tasks/dynamic arrays freely).
#
# `-sv` is passed to `read_verilog` for full SystemVerilog construct
# support (packed structs, always_comb/always_ff, logic type), matching
# every RTL file's own header comments and the simulator-side `-g2012`
# flag scripts/run_all_unit_tests.sh already uses for the same source
# files.
# =============================================================================

set top "semfonix_pwm16_top"

# --- Read RTL sources (leaf-to-top order; tb/** never touched) ---
read_verilog -sv rtl/pwm/pwm_compare.sv
read_verilog -sv rtl/pwm/pwm_counter.sv
read_verilog -sv rtl/pwm/pwm_channel.sv
read_verilog -sv rtl/pwm/pwm_engine.sv
read_verilog -sv rtl/registers/register_bank.sv
read_verilog -sv rtl/registers/register_decode.sv
read_verilog -sv rtl/registers/address_decode.sv
read_verilog -sv rtl/control/shadow_active_ctrl.sv
read_verilog -sv rtl/control/prescale_gate.sv
read_verilog -sv rtl/i2c/i2c_bus_sync.sv
read_verilog -sv rtl/i2c/i2c_rx.sv
read_verilog -sv rtl/i2c/i2c_tx.sv
read_verilog -sv rtl/i2c/i2c_slave.sv
read_verilog -sv rtl/clock/clk_reset_sync.sv
read_verilog -sv rtl/top/semfonix_pwm16_top.sv

# --- Elaborate and check hierarchy before doing anything else ---
# -check flags unresolved references (a wrong port name/width in any
# instantiation, exactly the class of bug every IMPLEMENTATION_STATUS.md
# session so far has only been able to catch by manual port-by-port
# review -- this is the first point in the project's history an actual
# tool checks it).
hierarchy -check -top $top

# --- Generic synthesis flow, technology-mapping (abc) skipped ---
# See file header for -noabc rationale. This still runs proc, opt,
# memory (collapses the register_bank/shadow storage arrays), fsm
# (there are no explicit `case`-based FSMs outside i2c_rx.sv/i2c_tx.sv;
# yosys's fsm pass is a no-op elsewhere and harmless), techmap to
# Yosys's internal generic-cell set, and opt again.
synth -top $top -noabc

# --- Structural sanity check on the synthesized design ---
# Flags combinational loops, multi-driven wires that survived synthesis,
# and other structural problems synth's own passes don't always abort on.
check -noinit

# --- Reports ---
# stat: cell-count / area-proxy report (no PDK, so this is Yosys's own
# generic-cell tally, not a $/um^2 number -- exactly what "Yosys-clean
# synthesis only, no PDK" scope implies is available at this checkpoint).
tee -o build/synth/stat_report.txt stat

# Human-readable structural netlist dump, useful for spot-checking the
# synthesized hierarchy without a viewer.
write_verilog -noattr build/synth/semfonix_pwm16_top.synth.v

# JSON netlist -- portable format if a later session wants to feed this
# into a viewer (e.g. netlistsvg) or a further Yosys pass, without
# re-running elaboration.
write_json build/synth/semfonix_pwm16_top.synth.json

# Final explicit log line the wrapper script's grep checks for, so the
# wrapper can tell "yosys ran to completion and reported clean" apart
# from "yosys silently produced a truncated log because it crashed
# partway" without relying on exit-code plumbing alone.
log "SYNTH_TCL_COMPLETE"
