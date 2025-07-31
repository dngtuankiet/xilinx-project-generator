# Vivado TCL script for Xilinx project automation

set script_dir [file dirname [info script]]

# Create project and set properties
source [file join $script_dir "tcl" "prologue.tcl"]

# Initialization
source [file join $script_dir "tcl" "init.tcl"]

# Synthesis
source [file join $script_dir "tcl" "synth.tcl"]

# Optimization
source [file join $script_dir "tcl" "opt.tcl"]

# Place and Route
source [file join $script_dir "tcl" "place.tcl"]
source [file join $script_dir "tcl" "route.tcl"]

# Generate bitstream and save verilog netlist
source [file join $script_dir "tcl" "bitstream.tcl"]

# Reporting
source [file join $script_dir "tcl" "report.tcl"]