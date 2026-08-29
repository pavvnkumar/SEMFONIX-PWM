VERILATOR ?= verilator

BUILD_DIR := build/verilator

RTL := \
  rtl/registers/semfonix_regmap_pkg.sv \
  rtl/pwm/pwm_compare.sv \
  rtl/pwm/pwm_counter.sv \
  rtl/pwm/pwm_channel.sv \
  rtl/pwm/pwm_engine.sv \
  rtl/registers/register_bank.sv \
  rtl/registers/register_decode.sv \
  rtl/registers/address_decode.sv \
  rtl/control/shadow_active_ctrl.sv \
  rtl/control/prescale_gate.sv \
  rtl/i2c/i2c_bus_sync.sv \
  rtl/i2c/i2c_rx.sv \
  rtl/i2c/i2c_tx.sv \
  rtl/i2c/i2c_slave.sv \
  rtl/clock/clk_reset_sync.sv \
  rtl/top/semfonix_pwm16_top.sv

UNIT_TBS := $(shell find tb/unit -name '*_tb.sv' | sort)

UNIT_NAMES := $(basename $(notdir $(UNIT_TBS)))

UNIT_TARGETS := $(addprefix unit/,$(UNIT_NAMES))

.PHONY: all lint unit integration clean

all: lint unit integration

# -----------------------------------------------------------------------------
# Lint
# -----------------------------------------------------------------------------

lint:
	@rm -rf $(BUILD_DIR)/lint
	@mkdir -p $(BUILD_DIR)/lint
	$(VERILATOR) --lint-only -sv -Wall -Wno-DECLFILENAME \
	  --top-module semfonix_pwm16_top \
	  --Mdir $(BUILD_DIR)/lint \
	  $(RTL)

# -----------------------------------------------------------------------------
# Unit tests
# -----------------------------------------------------------------------------

unit: $(UNIT_TARGETS)

unit/%:
	@set -e; \
	name=$*; \
	tb=$$(find tb/unit -name '$*.sv' | head -n 1); \
	if [ -z "$$tb" ]; then \
	  echo "ERROR: testbench not found for $$name"; \
	  exit 1; \
	fi; \
	echo "=== Building $$name ==="; \
	mkdir -p $(BUILD_DIR)/unit/$$name; \
	$(VERILATOR) -sv -DSIMULATION --timing --binary -Wno-fatal \
	  --top-module $$name \
	  --Mdir $(BUILD_DIR)/unit/$$name \
	  -o V$$name \
	  $(RTL) $$tb; \
	echo "=== Running $$name ==="; \
	$(BUILD_DIR)/unit/$$name/V$$name

# -----------------------------------------------------------------------------
# Integration test
# -----------------------------------------------------------------------------

integration:
	@rm -rf $(BUILD_DIR)/integration
	@mkdir -p $(BUILD_DIR)/integration
	$(VERILATOR) -sv -DSIMULATION --timing --binary -Wno-fatal \
	  --top-module semfonix_pwm16_tb \
	  --Mdir $(BUILD_DIR)/integration \
	  -o Vsemfonix_pwm16_tb \
	  $(RTL) \
	  $$(find tb/assertions -name '*.sv' | sort) \
	  $$(find tb/models -name '*.sv' | sort) \
	  tb/integration/semfonix_pwm16_tb.sv
	$(BUILD_DIR)/integration/Vsemfonix_pwm16_tb

# -----------------------------------------------------------------------------
# Clean
# -----------------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)