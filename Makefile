#################################################################################
# Makefile for I2C Master Project (FTDI MorphIC II)
#
# Targets:
#   make sim         - Run simulation
#   make clean       - Clean simulation files
#   make synthesis   - Run Vivado synthesis
#   make docs        - Generate documentation
#   make all         - Simulate and generate docs
#################################################################################

# Directories
RTL_DIR = rtl
TB_DIR = tb
SIM_DIR = sim
DOC_DIR = doc
BUILD_DIR = build

# Vivado settings
VIVADO_PROJECT = i2c_master_morphic
VIVADO_DEVICE = xc7a35tftg256-1

# Quartus II settings
QUARTUS_PROJECT = i2c_master_morphic
QUARTUS_DEVICE = EP2C5F256C8N

# Tool variables
VLOG = vlog
VSIM = vsim
VLIB = vlib
VIVADO = vivado
QUARTUS_SH = quartus_sh

# Files
RTL_FILES = $(RTL_DIR)/i2c_master.v $(RTL_DIR)/morphic_top.v
TB_FILES = $(TB_DIR)/i2c_slave_model.v $(TB_DIR)/morphic_top_tb.v
ALL_FILES = $(RTL_FILES) $(TB_FILES)

# Work directory
WORK_DIR = work

# Compilation flags
VLOG_FLAGS = -work $(WORK_DIR)
VSIM_FLAGS = -work $(WORK_DIR) -voptargs="+acc"

# Simulation top module
SIM_TOP = morphic_top_tb

.PHONY: sim clean synthesis quartus all docs help

# ============================================================================
# Help Target
# ============================================================================

help:
	@echo "=========================================="
	@echo "I2C Master Project Makefile"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  sim         - Run ModelSim simulation"
	@echo "  clean       - Remove simulation artifacts"
	@echo "  synthesis   - Run Vivado synthesis"
	@echo "  quartus     - Run Quartus II 13.0sp1 build"
	@echo "  docs        - Generate documentation"
	@echo "  all         - Full build and simulation"
	@echo "  help        - Display this message"
	@echo ""

# ============================================================================
# Simulation Targets
# ============================================================================

sim: $(WORK_DIR) compile
	@echo ""
	@echo "=========================================="
	@echo "Starting Simulation..."
	@echo "=========================================="
	$(VSIM) $(VSIM_FLAGS) $(SIM_TOP) -do "run -all; quit"
	@echo "=========================================="
	@echo "Simulation Complete!"
	@echo "VCD file: morphic_i2c_sim.vcd"
	@echo "=========================================="

$(WORK_DIR):
	@echo "Creating work directory..."
	$(VLIB) $(WORK_DIR)

compile: $(WORK_DIR) $(RTL_FILES) $(TB_FILES)
	@echo ""
	@echo "=========================================="
	@echo "Compiling Verilog Files..."
	@echo "=========================================="
	$(VLOG) $(VLOG_FLAGS) $(RTL_FILES)
	$(VLOG) $(VLOG_FLAGS) $(TB_FILES)
	@echo "Compilation complete!"

# ============================================================================
# Clean Target
# ============================================================================

clean:
	@echo "Cleaning simulation artifacts..."
	rm -rf $(WORK_DIR)
	rm -f *.wdb *.log *.vcd transcript
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# ============================================================================
# Synthesis Targets
# ============================================================================

synthesis:
	@echo ""
	@echo "=========================================="
	@echo "Running Vivado Synthesis..."
	@echo "=========================================="
	bash $(SIM_DIR)/vivado_build.sh
	@echo "Synthesis complete!"
	@echo "Check $(VIVADO_PROJECT)/ for results"
	@echo "=========================================="

quartus:
	@echo ""
	@echo "=========================================="
	@echo "Running Quartus II 13.0sp1 Build..."
	@echo "=========================================="
	bash $(SIM_DIR)/quartus_build.sh
	@echo "Quartus build complete!"
	@echo "Check $(QUARTUS_PROJECT)/ for results"
	@echo "Output: $(QUARTUS_PROJECT)/morphic.sof"
	@echo "=========================================="

# ============================================================================
# Documentation Target
# ============================================================================

docs:
	@echo ""
	@echo "=========================================="
	@echo "Documentation is available in:"
	@echo "  - README.md (project overview)"
	@echo "  - $(DOC_DIR)/I2C_MASTER_SPEC.md (RTL specification)"
	@echo "  - $(DOC_DIR)/BUILD_GUIDE.md (build instructions)"
	@echo "=========================================="

# ============================================================================
# All Target
# ============================================================================

all: clean sim docs
	@echo ""
	@echo "=========================================="
	@echo "Full build complete!"
	@echo "=========================================="

# ============================================================================
# Default Target
# ============================================================================

.DEFAULT_GOAL := help
