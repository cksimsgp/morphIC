# Build and Implementation Guide

## Table of Contents
1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Simulation](#simulation)
5. [Synthesis and Implementation](#synthesis-and-implementation)
6. [Hardware Deployment](#hardware-deployment)
7. [Troubleshooting](#troubleshooting)

---

## Project Overview

This document provides step-by-step instructions for building and implementing the I2C Master Controller on the FTDI MorphIC II FPGA board.

**Project Details:**
- **Target Clock Frequency:** 50 MHz
- **I2C Clock Frequency:** 3.4 Mbps (High-Speed Mode)
- **Addressing Mode:** 10-bit
- **Default Slave Address:** 0x24A
- **Language:** Verilog

---

## Prerequisites

### 1. Software Tools

You'll need one of the following FPGA design tools:

#### Option A: Altera Quartus II 13.0sp1 (Recommended)
- **Version:** 13.0 Service Pack 1
- **Installation:** Download from https://www.altera.com/downloads/download-center.html
- **License:** Web Edition (free) or full license
- **Note:** This is the primary target platform for this project

#### Option B: Xilinx Vivado
- **Version:** 2021.2 or later
- **Installation:** Download from https://www.xilinx.com/products/design-tools/vivado.html
- **License:** WebPACK (free) or full license

#### Option C: Intel Quartus Prime
- **Version:** 21.1 or later
- **Installation:** Download from https://www.intel.com/content/www/us/en/programmable/downloads/download-center.html
- **License:** Lite edition (free)

### 2. Additional Tools

```bash
# Linux/macOS
sudo apt-get install git make bash

# Windows
# Use Git Bash or WSL2 for shell commands
```

### 3. Hardware Requirements

- **FTDI MorphIC II Board** with:
  - Artix-7 FPGA (xc7a35t typical)
  - 50 MHz reference clock
  - I2C pull-up resistors (1.5k - 4.7k Ω)
  - Programming cable (USB or JTAG)

### 4. I2C Bus Setup

External pull-up resistors are required:
```
VCC (3.3V or 5V)
  |
  R1 (1.5k-4.7k Ω)
  |
  ├─── SCL
  |
  R2 (1.5k-4.7k Ω)
  |
  ├─── SDA
  |
  I2C Slave Device
```

---

## Directory Structure

```
morphic/
├── README.md                          # Project overview
├── Makefile                           # Build automation
├── rtl/                               # RTL source files
│   ├── i2c_master.v                   # Main I2C master controller
│   └── morphic_top.v                  # Top-level wrapper
├── tb/                                # Testbench files
│   ├── i2c_slave_model.v              # I2C slave simulator
│   └── morphic_top_tb.v               # Top-level testbench
├── sim/                               # Simulation scripts
│   ├── run_sim.sh                     # ModelSim simulation
│   └── vivado_build.sh                # Vivado build script
├── doc/                               # Documentation
│   ├── I2C_MASTER_SPEC.md             # RTL specification
│   └── BUILD_GUIDE.md                 # This file
└── constraints/
    └── morphic.xdc                    # Vivado constraints file
```

---

## Simulation

### Option 1: Using Makefile (Recommended)

The easiest way to run simulation:

```bash
cd /path/to/morphic

# Run simulation with default settings
make sim

# View help
make help

# Clean simulation files
make clean
```

### Option 2: Manual ModelSim Simulation

```bash
cd /path/to/morphic

# Create work directory
vlib work

# Compile RTL
vlog -work work rtl/i2c_master.v rtl/morphic_top.v

# Compile testbench
vlog -work work tb/i2c_slave_model.v tb/morphic_top_tb.v

# Run simulation
vsim -work work morphic_top_tb -do "run -all; quit"
```

### Option 3: Using Shell Script

```bash
chmod +x sim/run_sim.sh
./sim/run_sim.sh
```

### Simulation Output

After successful simulation, you should see:

```
========================================
I2C Master 10-bit Mode Testbench
========================================
Clock Frequency: 50 MHz
I2C Frequency: 3.4 Mbps
Slave Address: 0x24A (10-bit)
Test Data: 0xA5
========================================

[0 ns] Starting I2C Read Transaction

========================================
TEST 1 RESULTS: Single Byte Read
========================================
[PASS] Transaction completed successfully
[INFO] Read Data: 0xA5
[PASS] Data matches expected value (0xA5)
========================================
```

### Waveform Analysis

After simulation, view the waveform in ModelSim:

```tcl
# In ModelSim GUI
open_wave_file morphic_i2c_sim.vcd

# Or view in GTKWave (Linux/Mac)
gtkwave morphic_i2c_sim.vcd
```

---

## Synthesis and Implementation

### Using Quartus II 13.0sp1 (Recommended)

#### Step 1: Setup Environment

```bash
# Set Quartus II 13.0sp1 in PATH
export PATH=/path/to/quartus/13.0sp1/bin:$PATH

# Verify installation
quartus_sh --version
```

#### Step 2: Run Automated Build

```bash
# Option A: Using Makefile
cd /path/to/morphic
make quartus

# Option B: Manual script
chmod +x sim/quartus_build.sh
./sim/quartus_build.sh
```

#### Step 3: Build Output

After successful completion:
- **SOF File:** `i2c_master_morphic/morphic.sof` (SRAM object file for programming)
- **Reports:** 
  - `morphic.fit.rpt` - Fitter report
  - `morphic.sta.rpt` - Timing analysis
  - `morphic_timing.rpt` - Detailed timing

#### Step 4: Generate Programming Files

If you need different output formats:

```bash
# Generate POF file (for NAND flash)
quartus_cpf -c i2c_master_morphic/morphic.sof morphic.pof

# Generate JAM file
quartus_cpf -c i2c_master_morphic/morphic.sof morphic.jam
```

### Using Vivado (Xilinx)

#### Step 1: Create Project

```bash
# Option A: Using script
chmod +x sim/vivado_build.sh
./sim/vivado_build.sh

# Option B: Manual Vivado flow
cd /path/to/morphic
vivado
```

#### Step 2: Create New Project (if manual)

1. Launch Vivado
2. Click **Create Project**
3. Enter project name: `i2c_master_morphic`
4. Select project location
5. Choose **RTL Project**
6. Click **Next**

#### Step 3: Add Sources

1. Click **Add Files**
2. Select from `rtl/` directory:
   - `i2c_master.v`
   - `morphic_top.v`
3. Click **Next**
4. Click **Finish**

#### Step 4: Set Top Module

1. Right-click **morphic_top** in design sources
2. Select **Set as Top**

#### Step 5: Add Constraints

1. Click **Add Files** in Constraints
2. Add `constraints/morphic.xdc` (if available)
3. If no constraint file exists, skip this step

#### Step 6: Run Synthesis

1. Click **Run Synthesis**
2. Wait for completion
3. Review synthesis report

#### Step 7: Run Implementation

1. Click **Run Implementation**
2. Monitor progress
3. Review implementation report

#### Step 8: Generate Bitstream

1. Click **Generate Bitstream**
2. Wait for completion
3. Bitstream generated: `morphic_top.bit`

### Using Quartus (Intel/Altera)

#### Step 1: Create New Project

```bash
cd /path/to/morphic
quartus --new_project i2c_master_morphic
```

#### Step 2: Add RTL Files

1. Project → Add Files
2. Select `rtl/i2c_master.v` and `rtl/morphic_top.v`

#### Step 3: Set Device

1. Assignments → Device
2. Select appropriate Intel FPGA (check board documentation)
3. Click **OK**

#### Step 4: Run Full Compilation

```bash
quartus_sh -t quartus_flow.tcl
```

#### Step 5: Generate Programming File

1. Processing → Start → Start Full Compilation
2. Generates `.sof` or `.pof` file for programming

---

## Hardware Deployment

### Step 1: Connect FPGA Board

1. Connect programming cable (USB-Blaster or JTAG) to computer
2. Connect I2C slave device:
   - Pin SCL to I2C_CLK
   - Pin SDA to I2C_SDA
   - Connect pull-up resistors (see circuit above)

### Step 2: Program FPGA

#### Using Quartus II 13.0sp1

**Option A: Quartus GUI**
1. Open Quartus II
2. Go to Tools → Programmer
3. Click "Hardware Setup" and verify USB-Blaster is detected
4. Add Device and select `morphic.sof`
5. Click "Start"

**Option B: Command Line**
```bash
# Program FPGA using quartus_pgm
quartus_pgm --cable="USB-Blaster" -m JTAG -o "P;i2c_master_morphic/morphic.sof"
```

**Option C: TCL Script**
```tcl
# Program using TCL
load_package hw_api
set cable_names [get_hardware_names]
open_hw [lindex $cable_names 0]
set device_names [get_device_names -hardware [lindex $cable_names 0]]
program_device -device [lindex $device_names 0] -file morphic.sof
close_hw
```

#### Using Vivado Hardware Manager

```tcl
# In Vivado
open_hw_manager
connect_hw_server
open_hw_target

# Program bitstream
program_hw_devices -file morphic_top.bit
close_hw_target
```

#### Using Quartus Programmer

```bash
quartus_pgm -c "USB-Blaster" -m JTAG -o "P;i2c_master_morphic.sof"
```

#### Using Command Line Tools

```bash
# Vivado
vivado -mode batch -source vivado_program.tcl

# Quartus
quartus_pgm --cable=USB-Blaster i2c_master_morphic.cdf
```

### Step 3: Verify Functionality

1. Apply power to FPGA board
2. Check I2C bus with logic analyzer
3. Verify START condition
4. Verify address transmission
5. Verify data reception

---

## Troubleshooting

### Simulation Issues

#### Problem: Compilation Errors
```
Error: Can't find package 'unisim'
```
**Solution:** Ensure ModelSim is properly installed and licensed

#### Problem: Timeout in Simulation
```
[WARNING] Simulation timeout - transaction may be stalled
```
**Solution:** 
- Check clock divider calculation
- Verify slave model is responding
- Review I2C line state in waveform

#### Problem: NACK on Address
```
[FAIL] Transaction completed with error
```
**Solution:**
- Verify slave address matches
- Check slave model implementation
- Review I2C timing

### Synthesis Issues

#### Problem: Unresolved Modules
```
ERROR: [synth 8-119] Unresolved module in circuit 'morphic_top'
```
**Solution:**
- Verify all RTL files are added
- Check for typos in module names
- Ensure correct file encoding (UTF-8)

#### Problem: Missing Constraints
```
WARNING: No timing constraints specified
```
**Solution:**
- Create `constraints/morphic.xdc` with timing constraints
- Or ignore if not required for initial prototyping

#### Problem: Timing Violation
```
ERROR: [route 35-39] TIMING-14 Timing Violation - Critical Path
```
**Solution:**
- Relax timing constraints (increase clock period)
- Reduce I2C frequency
- Optimize RTL code

### Hardware Deployment Issues

#### Problem: Board Not Detected
```
ERROR: No USB device found
```
**Solution:**
- Check USB cable connection
- Install FTDI drivers
- Update firmware if needed

#### Problem: Programming Failure
```
ERROR: Configuration CRC error
```
**Solution:**
- Regenerate bitstream
- Verify device selection matches board
- Check power supply

#### Problem: I2C Not Working on Board
- Verify I2C pull-up resistors are installed
- Check SCL/SDA pin connections
- Measure voltage levels with multimeter
- Use logic analyzer to debug

---

## Running Tests

### Comprehensive Test Suite

Run all tests including synthesis:

```bash
make all
```

This will:
1. Clean old files
2. Run simulation
3. Generate documentation

### Individual Tests

```bash
# Simulation only
make sim

# Documentation
make docs

# Synthesis (Vivado)
make synthesis

# Clean
make clean
```

---

## Performance Metrics

After successful synthesis, you can check resource utilization:

```bash
# In Vivado
report_utilization
report_timing

# In Quartus
quartus_map morphic
quartus_fit morphic
quartus_asm morphic
```

**Expected resource usage (Artix-7 xc7a35t):**
- Slice LUTs: ~200
- Slice Registers: ~150
- BRAM: 0
- Timing: ~250 MHz (achievable)

---

## Advanced Configuration

### Changing I2C Frequency

Edit `rtl/i2c_master.v`:

```verilog
i2c_master #(
    .I2C_FREQ_KHZ(400)    // Change from 3400 to 400 kHz
) i2c_inst (...)
```

Supported I2C speeds:
- 100 kHz (Standard Mode)
- 400 kHz (Fast Mode)
- 1000 kHz (Fast+ Mode)
- 3400 kHz (High-Speed Mode)

### Changing Slave Address

Edit `rtl/morphic_top.v`:

```verilog
i2c_master #(
    .SLAVE_ADDR(10'h200)  // New address
) i2c_inst (...)
```

---

## Additional Resources

- I2C Specification: https://www.nxp.com/docs/en/user-manual/UM10204.pdf
- Vivado Documentation: https://www.xilinx.com/support/documentation
- Quartus Documentation: https://www.intel.com/content/www/us/en/design/support.html
- FTDI MorphIC II: Consult FTDI documentation

---

## Support and Contact

For issues or questions:
1. Check this guide
2. Review RTL specification (`doc/I2C_MASTER_SPEC.md`)
3. Consult `README.md` for overview
4. Review testbench for expected behavior

---

**Document Version:** 1.0  
**Last Updated:** 2025
