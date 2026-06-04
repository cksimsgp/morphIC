#!/bin/bash
# Vivado Synthesis and Implementation Script for I2C Master on FTDI MorphIC II

PROJECT_NAME="i2c_master_morphic"
DEVICE_PART="xc7a35tftg256-1"  # Artix-7 (adjust for your specific FPGA)
TOP_MODULE="morphic_top"
VERILOG_FILES="rtl/*.v"
XDC_FILE="constraints/morphic.xdc"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}I2C Master Vivado Build Script${NC}"
echo -e "${YELLOW}========================================${NC}"

# Check if Vivado is available
if ! command -v vivado &> /dev/null; then
    echo -e "${RED}ERROR: Vivado not found in PATH${NC}"
    echo "Please source Vivado settings before running this script"
    exit 1
fi

# Create project directory
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}Removing existing project...${NC}"
    rm -rf $PROJECT_NAME
fi

echo -e "${GREEN}Creating new Vivado project: $PROJECT_NAME${NC}"

# Run Vivado with TCL script
vivado -mode batch -source - <<EOL
    
    # Create project
    create_project $PROJECT_NAME ./$PROJECT_NAME -part $DEVICE_PART -force
    
    # Add RTL files
    add_files -fileset sources_1 $VERILOG_FILES
    
    # Add constraints if file exists
    if {[file exists $XDC_FILE]} {
        add_files -fileset constrs_1 $XDC_FILE
    }
    
    # Set top module
    set_property top $TOP_MODULE [current_fileset]
    
    # Run synthesis
    echo "Running Synthesis..."
    run_synth_design -mode out_of_context
    
    # Run implementation
    echo "Running Implementation..."
    run_implement_design
    
    # Generate bitstream
    echo "Generating Bitstream..."
    write_bitstream -force ${PROJECT_NAME}.bit
    
    # Generate reports
    write_timing_summary -max 10 -file timing_summary.txt
    report_timing -delay_type all > timing_report.txt
    report_utilization > utilization_report.txt
    
    # Close project
    close_project
    
    echo "Build Complete!"

EOL

echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}Output: $PROJECT_NAME/${PROJECT_NAME}.bit${NC}"
echo -e "${GREEN}Reports: $PROJECT_NAME/*.txt${NC}"
echo -e "${YELLOW}========================================${NC}"
