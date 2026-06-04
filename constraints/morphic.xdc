##################################################################################################
# FTDI MorphIC II I2C Master Constraints
# Vivado Design Constraint File (XDC)
#
# Pin Assignment and Timing Constraints for I2C Master on FTDI MorphIC II
# Adjust pin numbers based on your specific board configuration
##################################################################################################

# System Clock - 50 MHz
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk -period 20.00 -waveform {0 10} [get_ports clk]

# Reset Button - Active Low
set_property -dict { PACKAGE_PIN D9 IOSTANDARD LVCMOS33 } [get_ports rst_n]

# I2C Interface Pins
# Note: Adjust these pin numbers for your specific MorphIC II board
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 PULL UP } [get_ports sda]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4 PULL UP } [get_ports scl]

# GPIO Input Ports
set_property -dict { PACKAGE_PIN A9 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[0]]
set_property -dict { PACKAGE_PIN B10 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[1]]
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[2]]
set_property -dict { PACKAGE_PIN C10 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[3]]
set_property -dict { PACKAGE_PIN B9 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[4]]
set_property -dict { PACKAGE_PIN C9 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[5]]
set_property -dict { PACKAGE_PIN E9 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[6]]
set_property -dict { PACKAGE_PIN A8 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[7]]
set_property -dict { PACKAGE_PIN B8 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[8]]
set_property -dict { PACKAGE_PIN C8 IOSTANDARD LVCMOS33 } [get_ports slave_addr_cfg[9]]

# GPIO Input Ports - num_bytes_cfg
set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[0]]
set_property -dict { PACKAGE_PIN E8 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[1]]
set_property -dict { PACKAGE_PIN A7 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[2]]
set_property -dict { PACKAGE_PIN B7 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[3]]
set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[4]]
set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[5]]
set_property -dict { PACKAGE_PIN E7 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[6]]
set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS33 } [get_ports num_bytes_cfg[7]]

# Control Signals
set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports start_read]

# Status Output Signals - LEDs or GPIO
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_busy]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_done]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_error]

# Data Output
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[0]]
set_property -dict { PACKAGE_PIN B3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[1]]
set_property -dict { PACKAGE_PIN C3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[2]]
set_property -dict { PACKAGE_PIN D3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[3]]
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[4]]
set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[5]]
set_property -dict { PACKAGE_PIN G3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[6]]
set_property -dict { PACKAGE_PIN H3 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports read_byte_out[7]]

# Data Valid Signal
set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 SLEW FAST } [get_ports data_valid_out]

##################################################################################################
# Timing Constraints
##################################################################################################

# Input Delay Constraints
set_input_delay -clock sys_clk -add_delay 2 [get_ports start_read]
set_input_delay -clock sys_clk -add_delay 2 [get_ports slave_addr_cfg*]
set_input_delay -clock sys_clk -add_delay 2 [get_ports num_bytes_cfg*]

# Output Delay Constraints
set_output_delay -clock sys_clk -add_delay 3 [get_ports read_busy]
set_output_delay -clock sys_clk -add_delay 3 [get_ports read_done]
set_output_delay -clock sys_clk -add_delay 3 [get_ports read_error]
set_output_delay -clock sys_clk -add_delay 3 [get_ports read_byte_out*]
set_output_delay -clock sys_clk -add_delay 3 [get_ports data_valid_out]

##################################################################################################
# I2C Bus Timing Constraints
##################################################################################################

# I2C lines are asynchronous, so no direct clock constraints
# However, we constrain based on the I2C state machine clock
# SCL and SDA changes happen on the falling edge of the state machine clock

# Delay for I2C output signals (state machine controlled)
set_output_delay -clock sys_clk -add_delay 5 [get_ports scl]
set_output_delay -clock sys_clk -add_delay 5 [get_ports sda]

# Input setup/hold for synchronized inputs
set_input_delay -clock sys_clk -add_delay 2 [get_ports scl]
set_input_delay -clock sys_clk -add_delay 2 [get_ports sda]

##################################################################################################
# Configuration
##################################################################################################

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Bank 14 voltage
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 14]]

##################################################################################################
# False Paths (if needed)
##################################################################################################

# I2C is asynchronous, but we use internal synchronization
# Synchronizer registers should have relaxed constraints
set_false_path -from [get_ports scl] -to [get_clocks sys_clk]
set_false_path -from [get_ports sda] -to [get_clocks sys_clk]

##################################################################################################
# Area and Placement
##################################################################################################

# Optional: Group I2C-related logic for placement
# create_pblock pblock_i2c
# add_cells_to_pblock [get_pblocks pblock_i2c] [get_cells -hierarchical i2c_master_inst]
# resize_pblock [get_pblocks pblock_i2c] -add {SLICE_X0Y0:SLICE_X20Y30}

##################################################################################################
# End of Constraints File
##################################################################################################
