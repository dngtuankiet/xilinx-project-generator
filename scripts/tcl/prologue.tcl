set ip_vivado_tcls {}

while {[llength $argv]} {
  set argv [lassign $argv[set argv {}] flag]
  switch -glob $flag {
    -proj-name {
      set argv [lassign $argv[set argv {}] proj_name]
    }
    -top-module {
      set argv [lassign $argv[set argv {}] top]
    }
    -src-dir {
      set argv [lassign $argv[set argv {}] src_dir]
    }
    -build-dir {
      set argv [lassign $argv[set argv {}] build_dir]
    }
    -F {
      # This should be a simple file format with one filepath per line
      set argv [lassign $argv[set argv {}] vsrc_manifest]
    }
    -board {
      set argv [lassign $argv[set argv {}] board]
    }
    -ip-vivado-tcls {
      set argv [lassign $argv[set argv {}] ip_vivado_tcls]
    }
    -pre-impl-debug-tcl {
      set argv [lassign $argv[set argv {}] pre_impl_debug_tcl]
    }
    -post-impl-debug-tcl {
      set argv [lassign $argv[set argv {}] post_impl_debug_tcl]
    }
    -env-var-srcs {
      set argv [lassign $argv[set argv {}] env_var_srcs]
    }
    default {
      return -code error [list {unknown option} $flag]
    }
  }
}

# Check if required arguments are provided
if {![info exists proj_name]} {
  return -code error [list {--proj_name option is required}]
}
if {![info exists top]} {
  return -code error [list {--top-module option is required}]
}
if {![info exists board]} {
    return -code error [list {--board option is required}]
}
if {![info exists src_dir]} {
    return -code error [list {--src-dir option is required}]
}
if {![info exists build_dir]} {
    return -code error [list {--build-dir option is required}]
}

set src_dir [file normalize $src_dir]
set constraints_dir [file join $src_dir "constraints"]
set build_dir [file normalize $build_dir]
set board_dir [file normalize [file join [file dirname [info script]] ".." "boards" $board]]
source [file join $board_dir tcl "board.tcl"]

# Set the IP directory - this is where the IPs for the board are defined
# set ip_dir [file join $board_dir "tcl" "ip"]
set ip_dir [file join $build_dir "ip"]




create_project $proj_name -part $part_fpga -force $top

set_param messaging.defaultLimit 1000000

# Set the board part
set_property -dict [list \
	BOARD_PART $part_board \
	TARGET_LANGUAGE {Verilog} \
	DEFAULT_LIB {xil_defaultlib} \
	IP_REPO_PATHS $ip_dir \
	] [current_project]


# Add source files
if {[get_filesets -quiet sources_1] eq ""} {
	create_fileset -srcset sources_1
}
set obj [current_fileset]
add_files -fileset $obj [glob $src_dir/*.*]
# Set the top module
set_property top $top [current_fileset]

# Add IP Vivado TCL
if {$ip_vivado_tcls ne {}} {
  # Split string into words even with multiple consecutive spaces
  # http://wiki.tcl.tk/989
  set ip_vivado_tcls [regexp -inline -all -- {\S+} $ip_vivado_tcls]
}

# Constraint files
if {[get_filesets -quiet constrs_1] eq ""} {
	create_fileset -constrset constrs_1
}
set obj [current_fileset -constrset]
add_files -quiet -norecurse -fileset $obj [lsort [glob -directory $constraints_dir -nocomplain {*.xdc}]]
# if {[llength $constr_files] > 0} {
#   add_files -quiet -norecurse -fileset $obj $constr_files
#   set_property file_type "XDC" [lindex $constr_files 0]
#   set_property top $top [lindex $constr_files 0]
# }


# Print all the source files and constraints files to check
puts "Source files in the project:"
foreach file [get_files -all] {
    puts "  $file"
}