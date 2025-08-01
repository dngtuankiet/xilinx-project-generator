# Script to list available FPGA hardware devices

puts "Scanning for connected FPGA devices..."

# Open hardware manager
open_hw_manager

# Try to connect to hardware server
if { [catch {
    connect_hw_server -allow_non_jtag
} result] } {
    puts "ERROR: Failed to connect to hardware server"
    puts "Make sure Vivado hardware drivers are installed"
    close_hw_manager
    exit 1
}

puts "Connected to hardware server successfully"

# Get available hardware targets
set hw_targets [get_hw_targets]
puts "Found [llength $hw_targets] hardware target(s):"

if { [llength $hw_targets] == 0 } {
    puts "  No hardware targets found"
    puts "  Check USB/JTAG cable connection"
} else {
    foreach target $hw_targets {
        puts "  Target: $target"
        
        # Try to open each target and list devices
        if { [catch {
            current_hw_target $target
            open_hw_target
            
            set hw_devices [get_hw_devices]
            puts "    Devices: [llength $hw_devices]"
            
            foreach device $hw_devices {
                puts "      Device: $device"
                set part [get_property PART $device]
                puts "        Part: $part"
                
                # Check if device is programmed (with error handling)
                if { [catch {
                    set is_programmed [get_property PROGRAM.DONE $device]
                    puts "        Programmed: $is_programmed"
                } ] } {
                    # Try alternative method if PROGRAM.DONE doesn't exist
                    if { [catch {
                        set device_state [get_property REGISTER.IR.BIT6_DONE $device]
                        puts "        Programmed: $device_state (alternative check)"
                    } ] } {
                        puts "        Programmed: Unable to determine"
                    }
                }
            }
            
            close_hw_target
        } result] } {
            puts "    Error opening target: $result"
        }
    }
}

# Close hardware manager
close_hw_manager

puts "Device scan complete."
