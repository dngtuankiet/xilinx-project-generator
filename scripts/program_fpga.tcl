# FPGA Programming Script
# This script programs the FPGA with the specified bitstream file

if { $argc != 1 } {
    puts "Usage: vivado -mode batch -source program_fpga.tcl -tclargs <bitstream_file>"
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

# Get available hardware targets
set hw_targets [get_hw_targets]
if { [llength $hw_targets] == 0 } {
    puts "ERROR: No hardware targets found!"
    puts "Make sure your FPGA board is connected via USB/JTAG"
    close_hw_manager
    exit 1
}

# Use the first available target
set hw_target [lindex $hw_targets 0]
puts "Using hardware target: $hw_target"

# Open the target
current_hw_target $hw_target
open_hw_target

# Get available hardware devices
set hw_devices [get_hw_devices]
if { [llength $hw_devices] == 0 } {
    puts "ERROR: No hardware devices found!"
    puts "Make sure your FPGA board is powered on and connected"
    close_hw_target
    close_hw_manager
    exit 1
}

# Use the first available device (should be the FPGA)
set hw_device [lindex $hw_devices 0]
puts "Using hardware device: $hw_device"

# Set the device as current
current_hw_device $hw_device

# Set the bitstream file
set_property PROGRAM.FILE $bitstream_file $hw_device

# Program the device
puts "Programming device..."
program_hw_devices $hw_device

# Wait a moment for programming to complete
after 1000

# Refresh and verify programming was successful
puts "Verifying programming status..."
refresh_hw_device $hw_device

# Check if PROGRAM.DONE property exists and get its value
if { [catch {
    set program_done [get_property PROGRAM.DONE $hw_device]
    if { $program_done } {
        puts "SUCCESS: FPGA programming completed successfully!"
        puts "Device is configured and ready to use."
    } else {
        puts "WARNING: Programming may not be complete (PROGRAM.DONE = false)"
    }
} result] } {
    # If PROGRAM.DONE property doesn't exist, try alternative verification
    puts "Note: PROGRAM.DONE property not available on this device"
    
    # Try to check if device is in user mode
    if { [catch {
        set device_state [get_property REGISTER.IR.BIT6_DONE $hw_device]
        if { $device_state } {
            puts "SUCCESS: Device appears to be programmed (alternative check)"
        } else {
            puts "WARNING: Device state unclear"
        }
    } ] } {
        # If no properties work, just report that programming command completed
        puts "Programming command completed. Please verify manually that the design is working."
        puts "Check LEDs on your FPGA board to confirm the design is running."
    }
}

# Close hardware manager
close_hw_target
close_hw_manager

puts "FPGA programming complete."
