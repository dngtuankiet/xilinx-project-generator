set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets fast_ring_osc/n[4]]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets slow_ring_osc/n[19]]

# The slow_ring_osc output is used as a local clock, but its frequency is unknown and depends on the ring length and process/voltage/temperature.
# We cannot specify a period constraint, but we can:
# 1. Declare a generated clock for timing analysis tools (without a period).
# 2. Set false path constraints to prevent timing violations from/to this clock domain.

# Declare a generated clock for the slow ring oscillator output (no period specified)
create_clock -name slow_ring_clk [get_pins slow_ring_osc/osc_out]

# Set false path from the slow ring oscillator to all other clocks
set_false_path -from [get_clocks slow_ring_clk]
set_false_path -to [get_clocks slow_ring_clk]

# Optionally, you may want to set false paths to/from asynchronous logic driven by this clock as well.