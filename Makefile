# Vivado Makefile for Arty-100T Project
# Usage:
#   make           # Create project and build bitstream
#   make clean     # Remove build directory

VIVADO ?= vivado
PROJ_NAME := xilinx_project_generator
TOP_MODULE := ring_oscillator
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
