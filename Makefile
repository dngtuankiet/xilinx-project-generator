# Vivado Makefile for Arty-100T Project
# Usage:
#   make           # Create project and build bitstream
#   make clean     # Remove build directory

VIVADO ?= vivado
PROJ_NAME := basic_trng_prj
TOP_MODULE := top
BOARD := arty_a7_100
SRC_DIR := src
BUILD_DIR := build
BIT_FILE := $(BUILD_DIR)/$(TOP_MODULE).bit

all: $(BIT_FILE)

$(BIT_FILE): $(wildcard $(SRC_DIR)/*.*)
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && \
	$(VIVADO) -nojournal -mode batch \
	-source ../scripts/vivado.tcl \
	-tclargs \
		-proj-name "$(PROJ_NAME)" \
		-top-module "$(TOP_MODULE)" \
		-board "$(BOARD)" \
		-src-dir "../$(SRC_DIR)" \
		-ip-vivado-tcls "../scripts/boards/$(BOARD)/tcl/ip.tcl" \
		-build-dir "." 2>&1 | tee vivado.log

clean:
	rm -rf $(BUILD_DIR)

program-fpga: $(BIT_FILE)
	@echo "Programming FPGA with $(BIT_FILE)..."
	@echo "Make sure your FPGA board is connected and powered on."
	$(VIVADO) -mode batch -source scripts/program_fpga.tcl -tclargs $(BIT_FILE)

program-fpga-simple: $(BIT_FILE)
	@echo "Programming FPGA with $(BIT_FILE) (simple mode)..."
	@echo "Make sure your FPGA board is connected and powered on."
	$(VIVADO) -mode batch -source scripts/program_fpga_simple.tcl -tclargs $(BIT_FILE)

program-fpga-gui: $(BIT_FILE)
	@echo "Opening Vivado Hardware Manager GUI for manual programming..."
	@echo "Bitstream file: $(BIT_FILE)"
	$(VIVADO) -mode gui scripts/open_hw_manager.tcl

list-hw-devices:
	@echo "Detecting connected FPGA devices..."
	$(VIVADO) -mode batch -source scripts/list_devices.tcl

.PHONY: all clean program-fpga program-fpga-simple program-fpga-gui list-hw-devices
