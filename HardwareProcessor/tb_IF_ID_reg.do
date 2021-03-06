#########################################################################
## John Brose
## Student Iowa State University
#########################################################################
## tb_alu.do
#########################################################################
## DESCRIPTION: This file contains a do file for the testbench.
##              It adds some useful signals for testing
##              functionality and debugging the system. It also formats
##              the waveform and runs the simulation.
##              
## 03/24/2021 by JB::Design created.
#########################################################################

# Setup the wave form with useful signals

# Add the standard, non-data clock and reset input signals.

# Add data inputs that are specific to this design. These are the ones set during our test cases.
# Note that I've set the radix to unsigned, meaning that the values in the waveform will be displayed
# as unsigned decimal values. This may be more convenient for your debugging. However, you should be
# careful to look at the radix specifier (e.g., the decimal value 32'd10 is the same as the hexidecimal
# value 32'hA.
add wave -noupdate -divider {control_unit}
add wave -noupdate -divider {input}
add wave -noupdate -label i_PC_4 -radix binary /tb_IF_ID_reg/s_i_PC_4
add wave -noupdate -label i_instruction -radix binary /tb_IF_ID_reg/s_i_instruction


add wave -noupdate -divider {output}
add wave -noupdate -label clock /tb_IF_ID_reg/s_CLK
add wave -noupdate -label o_PC_4 /tb_IF_ID_reg/s_o_PC_4
add wave -noupdate -label o_instruction /tb_IF_ID_reg/s_o_instruction


# The following command will add all of the signals within the DUT0 module's scope (but not internal
# signals to submodules).
####add wave -noupdate /tb_mux2t1_N/DUT0/*



# Run for 100 timesteps (default is 1ns per timestep, but this can be modified so be aware).
run 500