# Simple FPGA Programming Script
# This script programs the FPGA with minimal status checking

if { $argc != 1 } {
    puts "Usage: vivado -mode batch -source program_fpga_simple.tcl -tclargs <bitstream_file>"
    exit 1
}

set bitstream_file [lindex $argv 0]

# Check if bitstream file exists
if { ![file exists $bitstream_file] } {
    puts "ERROR: Bitstream file '$bitstream_file' not found!"
    exit 1
}

puts "Programming FPGA with: $bitstream_file"

# Open hardware manager
open_hw_manager

# Connect to hardware server
connect_hw_server -allow_non_jtag

# Auto-connect to first available device
set hw_targets [get_hw_targets]
if { [llength $hw_targets] == 0 } {
    puts "ERROR: No hardware targets found!"
    close_hw_manager
    exit 1
}

set hw_target [lindex $hw_targets 0]
current_hw_target $hw_target
open_hw_target

set hw_devices [get_hw_devices]
if { [llength $hw_devices] == 0 } {
    puts "ERROR: No hardware devices found!"
    close_hw_target
    close_hw_manager
    exit 1
}

set hw_device [lindex $hw_devices 0]
puts "Programming device: $hw_device"

# Set the bitstream file and program
current_hw_device $hw_device
set_property PROGRAM.FILE $bitstream_file $hw_device

puts "Starting programming process..."
program_hw_devices $hw_device

puts "Programming command completed successfully!"
puts "Please verify that your design is working by checking:"
puts "  - LEDs on the FPGA board"
puts "  - Serial output from your design"
puts "  - Any other expected behavior"

# Close hardware manager
close_hw_target
close_hw_manager

puts "Hardware manager closed. Programming process complete."
