# See LICENSE for license details.

# Only read IP if there are any .xci files in $ip_dir
set xci_files [glob -nocomplain -directory $ip_dir *.xci]
if {[llength $xci_files] > 0} {
  read_ip $xci_files
}

# Synthesize the design
synth_design -top $top -flatten_hierarchy rebuilt

# Checkpoint the current design
write_checkpoint -force [file join $build_dir post_synth]
