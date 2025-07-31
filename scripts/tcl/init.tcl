# Only build IP if there are IP TCL scripts specified
if {[info exists ip_vivado_tcls] && [llength $ip_vivado_tcls] > 0} {
  # Create a directory for IPs
  file mkdir $ip_dir

  # Update the IP catalog
  update_ip_catalog -rebuild

  # # Generate IP implementation
  # foreach ip_vivado_tcl $ip_vivado_tcls {
  #   source $ip_vivado_tcl
  # }

  # Optional board-specific ip script
  set boardiptcl [file join $board_dir tcl ip.tcl]
  if {[file exists $boardiptcl]} {
    source $boardiptcl
  }

  # AR 58526 <http://www.xilinx.com/support/answers/58526.html>
  set xci_files [get_files -all {*.xci}]
  foreach xci_file $xci_files {
    set_property GENERATE_SYNTH_CHECKPOINT {false} -quiet $xci_file
  }

  # Get a list of IPs in the current design
  set obj [get_ips]

  # Generate target data for the included IPs in the design
  generate_target all $obj

  # Export the IP user files
  export_ip_user_files -of_objects $obj -no_script -force
}

# Get the list of active source and constraint files
set obj [current_fileset]

#Xilinx bug workaround
#scrape IP tree for directories containing .vh files
#[get_property include_dirs] misses all IP core subdirectory includes if user has specified -dir flag in create_ip
set property_include_dirs [get_property include_dirs $obj]

# Include generated files for the IPs in the design
set ip_include_dirs $property_include_dirs
# set ip_include_dirs [concat $property_include_dirs [findincludedir $ip_dir "*.vh"]]
# set ip_include_dirs [concat $ip_include_dirs [findincludedir $src_dir "*.h"]]
# set ip_include_dirs [concat $ip_include_dirs [findincludedir $src_dir "*.vh"]]