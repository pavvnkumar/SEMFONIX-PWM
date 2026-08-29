# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Make include file with class lists
#
# This file lists generated Verilated files, for including in higher level makefiles.
# See Vi2c_tx_tb.mk for the caller.

### Switches...
# C11 constructs required?  0/1 (always on now)
VM_C11 = 1
# Timing enabled?  0/1
VM_TIMING = 1
# Coverage output mode?  0/1 (from --coverage)
VM_COVERAGE = 0
# Parallel builds?  0/1 (from --output-split)
VM_PARALLEL_BUILDS = 1
# Tracing output mode?  0/1 (from --trace/--trace-fst)
VM_TRACE = 0
# Tracing output mode in VCD format?  0/1 (from --trace)
VM_TRACE_VCD = 0
# Tracing output mode in FST format?  0/1 (from --trace-fst)
VM_TRACE_FST = 0

### Object file lists...
# Generated module classes, fast-path, compile with highest optimization
VM_CLASSES_FAST += \
	Vi2c_tx_tb \
	Vi2c_tx_tb___024root__DepSet_h51d6c990__0 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__0 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__1 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__2 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__3 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__4 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__5 \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__6 \
	Vi2c_tx_tb__main \

# Generated module classes, non-fast-path, compile with low/medium optimization
VM_CLASSES_SLOW += \
	Vi2c_tx_tb___024root__Slow \
	Vi2c_tx_tb___024root__DepSet_h51d6c990__0__Slow \
	Vi2c_tx_tb___024root__DepSet_ha515e91e__0__Slow \

# Generated support classes, fast-path, compile with highest optimization
VM_SUPPORT_FAST += \

# Generated support classes, non-fast-path, compile with low/medium optimization
VM_SUPPORT_SLOW += \
	Vi2c_tx_tb__Syms \

# Global classes, need linked once per executable, fast-path, compile with highest optimization
VM_GLOBAL_FAST += \
	verilated \
	verilated_timing \
	verilated_threads \

# Global classes, need linked once per executable, non-fast-path, compile with low/medium optimization
VM_GLOBAL_SLOW += \


# Verilated -*- Makefile -*-
