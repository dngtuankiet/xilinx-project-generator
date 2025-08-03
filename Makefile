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

remove-vivado-logs:
	@echo "Removing Vivado logs..."
	rm -f *.vivado.log
	rm -f vivado.log
	rm -f *.backup.log
	rm -f *.jou
	rm -f *.str

program-fpga: $(BIT_FILE) 
	@echo "Programming FPGA with $(BIT_FILE) (simple mode)..."
	@echo "Make sure your FPGA board is connected and powered on."
	$(VIVADO) -nojournal -mode batch -source "scripts/program_fpga.tcl" -tclargs $(BIT_FILE)
	$(MAKE) remove-vivado-logs

program-fpga-gui: $(BIT_FILE)
	@echo "Opening Vivado Hardware Manager GUI for manual programming..."
	@echo "Bitstream file: $(BIT_FILE)"
	$(VIVADO) -nojournal -mode gui scripts/open_hw_manager.tcl
	$(MAKE) remove-vivado-logs

clean:
	rm -rf $(BUILD_DIR)
	$(MAKE) remove-vivado-logs

.PHONY: all clean program-fpga program-fpga-gui