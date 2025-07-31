# Vivado Arty-100T Project Workspace

This workspace is structured for FPGA development targeting the Arty-100T board using Xilinx Vivado. It uses a Makefile to automate project setup, IP integration, and bitstream generation.

## Directory Structure
- `src/` - Place your HDL (Verilog/VHDL) source files here. Constraint files should be in `src/constraints/`.
- `build/` - Vivado will generate all output files here (project files, bitstream, logs, reports, etc).
- `scripts/` - Project automation scripts and board/IP definitions.
- `Makefile` - Automates Vivado project creation, build, and cleaning.

## Quick Start

1. **Add your source files**
   - HDL: Place Verilog/VHDL files in `src/`.
   - Constraints: Place XDC files in `src/constraints/`.

2. **Build the project**
   - Run the following command to create the Vivado project, integrate IP, and generate the bitstream:
     ```bash
     make
     ```
   - The Vivado log will be saved to `build/vivado.log` and progress will be shown in the terminal.

3. **Generated outputs**
   - Bitstream and all Vivado-generated files will be in the `build/` directory.
   - Reports (timing, utilization, etc.) are in `build/report/`.

4. **Clean the build**
   - To remove all generated files and start fresh:
     ```bash
     make clean
     ```

## Requirements
- Xilinx Vivado installed and available in your PATH.
- Arty-100T board (or compatible target, see `scripts/boards/`).

## Advanced Usage
- Board and IP definitions are in `scripts/boards/` and `scripts/tcl/`.
- Modify or add TCL scripts in `scripts/tcl/` to customize the build flow.
- The Makefile and TCL scripts support modular, reproducible builds for larger projects.

---
