#!/bin/bash
# Modelsim/Questa Simulation Script

WORK_DIR="work"
SIM_TOP="morphic_top_tb"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}I2C Master Simulation Script${NC}"
echo -e "${YELLOW}========================================${NC}"

# Create work directory
if [ ! -d "$WORK_DIR" ]; then
    echo "Creating work directory..."
    vlib $WORK_DIR
fi

echo -e "${GREEN}Compiling RTL files...${NC}"
vlog -work $WORK_DIR \
    rtl/i2c_master.v \
    rtl/morphic_top.v

echo -e "${GREEN}Compiling Testbench files...${NC}"
vlog -work $WORK_DIR \
    tb/i2c_slave_model.v \
    tb/morphic_top_tb.v

echo -e "${GREEN}Starting Simulation...${NC}"
vsim -work $WORK_DIR -voptargs="+acc" $SIM_TOP -do "
    add wave -noupdate /morphic_top_tb/clk
    add wave -noupdate /morphic_top_tb/rst_n
    add wave -noupdate /morphic_top_tb/sda
    add wave -noupdate /morphic_top_tb/scl
    add wave -noupdate /morphic_top_tb/start_read
    add wave -noupdate /morphic_top_tb/read_busy
    add wave -noupdate /morphic_top_tb/read_done
    add wave -noupdate /morphic_top_tb/read_error
    add wave -noupdate /morphic_top_tb/read_byte_out
    add wave -noupdate /morphic_top_tb/data_valid_out
    add wave -noupdate /morphic_top_tb/slave_addr_cfg
    add wave -noupdate /morphic_top_tb/num_bytes_cfg
    
    run -all
"

echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Simulation Complete!${NC}"
echo -e "${GREEN}VCD file: morphic_i2c_sim.vcd${NC}"
echo -e "${YELLOW}========================================${NC}"
