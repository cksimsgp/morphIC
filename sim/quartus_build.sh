#!/bin/bash
# Quartus II 13.0sp1 Build Script for I2C Master Controller
#
# This script automates the synthesis and implementation process
# for the I2C Master on Quartus II 13.0sp1

PROJECT_NAME="i2c_master_morphic"
DEVICE_PART="EP2C5F256C8N"            # Cyclone II (FTDI MorphIC II)
TOP_MODULE="morphic_top"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Quartus II 13.0sp1 Build Script${NC}"
echo -e "${YELLOW}I2C Master Controller${NC}"
echo -e "${YELLOW}========================================${NC}"

# Check if Quartus is available
if ! command -v quartus_sh &> /dev/null; then
    echo -e "${RED}ERROR: Quartus II 13.0sp1 not found in PATH${NC}"
    echo "Please ensure Quartus II 13.0sp1 is installed and in PATH"
    exit 1
fi

# Display Quartus version
echo "Quartus II Version:"
quartus_sh --version

echo ""
echo -e "${GREEN}Creating Quartus project...${NC}"

# Remove old project if exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}Removing old project directory...${NC}"
    rm -rf $PROJECT_NAME
fi

# Create TCL script for project setup
cat > build_project.tcl << 'QUARTUS_TCL'

# Create new project
project_new -revision morphic -overwrite

# Set device
set_global_assignment -name FAMILY "Cyclone II"
set_global_assignment -name DEVICE EP2C5F256C8N
set_global_assignment -name ORIGINAL_QUARTUS_VERSION "13.0 SP1"
set_global_assignment -name PROJECT_CREATION_TIME_DATE "2025-06-04 12:00:00"
set_global_assignment -name LAST_QUARTUS_VERSION "13.0 SP1"

# Add source files
set_global_assignment -name VERILOG_FILE rtl/i2c_master.v
set_global_assignment -name VERILOG_FILE rtl/morphic_top.v

# Set top-level module
set_global_assignment -name TOP_LEVEL_ENTITY morphic_top

# Configure settings
set_global_assignment -name SMART_RECOMPILE ON
set_global_assignment -name SAVE_DISK_SPACE OFF
set_global_assignment -name NUM_PARALLEL_PROCESSORS 4

# Optimization settings
set_global_assignment -name OPTIMIZATION_MODE "BALANCED"
set_global_assignment -name FITTER_AGGRESSIVE_ROUTABILITY_OPTIMIZATION "ALWAYS"

# Device settings
set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "SINGLE IMAGE"
set_global_assignment -name USE_CONFIGURATION_DEVICE OFF
set_global_assignment -name CRC_ERROR_CHECKING OFF
set_global_assignment -name OUTPUT_IO_DEFAULT LVCMOS33

# Timing analysis
set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON
set_global_assignment -name SMART_COMPILE_ACTION "FULL_COMPILATION"

# Fitter/Place and Route
set_global_assignment -name FITTER_EFFORT "STANDARD FIT"
set_global_assignment -name INI_VARS "SYN_PARAMS=SYNPLIFY_OPTIONS=set_option -run_prop_extract 1; set_option -maxfan 10000; set_option -clock_globalthreshold 2; set_option -async_globalthreshold 12; set_option -globalthreshold 5000; set_option -low_power_ram_decomp 0; set_option -pipe 1; set_option -retiming 0; set_option -update_models_cp 0; set_option -useslew 0; set_option -define set_option -set_param synplify_options=hdl_parallel_generation=1"

# Save project
project_save

echo "Project created successfully"
QUARTUS_TCL

echo -e "${GREEN}Running Quartus TCL script...${NC}"
quartus_sh -t build_project.tcl

echo ""
echo -e "${GREEN}Performing full compilation...${NC}"
quartus_sh -t compile_project.tcl

echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}Output: $PROJECT_NAME/$PROJECT_NAME.sof${NC}"
echo -e "${YELLOW}========================================${NC}"

# Create SOF file (SRAM Object File)
if [ -f "$PROJECT_NAME/morphic.sof" ]; then
    echo -e "${GREEN}✓ SRAM Object File (.sof) generated${NC}"
    echo -e "${GREEN}Ready for FPGA programming${NC}"
fi

# Generate reports
if [ -f "$PROJECT_NAME/morphic.fit.rpt" ]; then
    echo -e "${GREEN}✓ Fitting report generated${NC}"
fi

if [ -f "$PROJECT_NAME/morphic.sta.rpt" ]; then
    echo -e "${GREEN}✓ Static timing analysis report generated${NC}"
fi
