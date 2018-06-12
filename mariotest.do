o#Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns supermario.v

# Load simulation using lab4part2 as the top level simulation module.
vsim datapath

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


###TESTING FSM
#force {go} 0 0, 1 45, 0 95
#force {clk} 0 0, 1 10 -r 20
#force {resetn} 1 0, 0 5, 1 11
#force {left} 0 0, 1 150, 0 300
#force {right} 0 0, 1 450, 0 600
#force {jump} 0 0

#TESTING DATAPATH
force {left_en} 0 0
force {right_en} 0 0, 1 15
force {clk} 0 0, 1 10 -r 20
force resetn 1 0, 0 5, 1 11


#force {CLOCK_50} 0 0, 1 10 -r 20
#force {KEY[0]} 1 0, 0 5, 1 11
#force {KEY[3]} 0 0, 1 45, 0 95
#force {KEY[1]} 0 0, 1 145, 0 195, 1 845, 0 895 
#force {SW[9]} 1 0
#force {SW[8]} 0 0
#
#force {SW[7]} 0 0
#
#force {SW[6]} 0 0
#force {SW[5]} 0 0
#force {SW[4]} 0 0
#force {SW[3]} 1 0
#force {SW[2]} 1 0
#force {SW[1]} 1 0
#force {SW[0]} 1 0

run 100000ns