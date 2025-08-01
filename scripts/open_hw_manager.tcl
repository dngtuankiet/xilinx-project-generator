# Script to open Hardware Manager GUI for manual FPGA programming

puts "Opening Vivado Hardware Manager..."

# Start Hardware Manager in GUI mode
start_gui

# Open hardware manager
open_hw_manager

# Try to auto-connect if possible
if { [catch {
    connect_hw_server -allow_non_jtag
    set hw_targets [get_hw_targets]
    if { [llength $hw_targets] > 0 } {
        set hw_target [lindex $hw_targets 0]
        current_hw_target $hw_target
        open_hw_target
        puts "Connected to hardware target: $hw_target"
        
        set hw_devices [get_hw_devices]
        if { [llength $hw_devices] > 0 } {
            set hw_device [lindex $hw_devices 0]
            current_hw_device $hw_device
            puts "Selected hardware device: $hw_device"
        }
    }
} ] } {
    puts "Auto-connection failed. Please connect manually in the GUI."
}

puts "Hardware Manager GUI is now open."
puts "To program the FPGA:"
puts "1. Right-click on your device"
puts "2. Select 'Program Device'"
puts "3. Browse to select the bitstream file: build/top.bit"
puts "4. Click 'Program'"
