# Arty-100T XDC constraint for ring oscillator
# Connect osc_out to a user LED (e.g., LED0)
set_property PACKAGE_PIN E18 [get_ports osc_out]
set_property IOSTANDARD LVCMOS33 [get_ports osc_out]

# set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets osc_out]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets n[4]]