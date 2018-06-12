#Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns supermario.v

# Load simulation using lab4part2 as the top level simulation module.
vsim supermario
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}



force {clk} 0 0, 1 10 -r 20
force {resetn} 1 0, 0 5, 1 11
force {go} 0 0, 1 15, 0 55
force {left} 0 0, 1 12000
force {right} 0 0, 1 60, 0 10000


run 30000ns