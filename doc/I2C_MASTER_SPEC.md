# I2C Master Controller - RTL Specification

## Document Information
- **Title:** I2C Master Controller (10-bit Addressing)
- **Version:** 1.0
- **Date:** 2025
- **Target:** FTDI MorphIC II FPGA Board
- **Language:** SystemVerilog/Verilog

---

## 1. Overview

The I2C Master Controller is a production-grade synthesizable Verilog module that implements the I2C (Inter-Integrated Circuit) protocol with support for 10-bit addressing. The design targets a clock frequency of 3.4 Mbps (I2C High-Speed Mode) and is optimized for the FTDI MorphIC II hardware platform.

### Key Features
- **10-bit Slave Addressing:** Full support for 10-bit address mode as per I2C specification
- **High-Speed Mode:** 3.4 Mbps operation
- **Configurable Parameters:** Slave address and read length are runtime configurable
- **Clock Stretching:** Support for slave-initiated clock stretching
- **Production Quality:** Proper synchronization, metastability protection, and error handling
- **Synthesizable:** Clean RTL code optimized for FPGA synthesis

---

## 2. Architecture

### 2.1 Top-Level Hierarchy

```
morphic_top (Top-level wrapper)
└── i2c_master (Core I2C Master Controller)
```

### 2.2 I2C Master Block Diagram

```
┌─────────────────────────────────────────┐
│         I2C Master Controller            │
├─────────────────────────────────────────┤
│                                          │
│  ┌──────────────────────────────────┐   │
│  │    Clock Generation (50MHz)      │   │
│  │  Divider: 50MHz/(4*3.4MHz) = 4   │   │
│  └──────────────────────────────────┘   │
│                 │                        │
│                 ▼                        │
│  ┌──────────────────────────────────┐   │
│  │    Main FSM                       │   │
│  │  (8 states)                       │   │
│  │  - IDLE, START, ADDR_HI, ADDR_LO │   │
│  │  - RW_BIT, ACK, READ, STOP       │   │
│  └──────────────────────────────────┘   │
│                 │                        │
│                 ▼                        │
│  ┌──────────────────────────────────┐   │
│  │   I2C Line Control (Open-Drain)  │   │
│  │  - SDA pull/release              │   │
│  │  - SCL pull/release              │   │
│  └──────────────────────────────────┘   │
│                                          │
└─────────────────────────────────────────┘
```

---

## 3. Module Interfaces

### 3.1 i2c_master Module

#### Parameters
```verilog
parameter CLK_FREQ_MHZ = 50              // Input clock frequency
parameter I2C_FREQ_KHZ = 3400            // I2C clock frequency (3.4 Mbps)
parameter SLAVE_ADDR = 10'h24A           // Default slave address
parameter NUM_BYTES = 8'h01              // Default read length
```

#### Ports

##### Clock and Reset
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| clk | 1 | Input | System clock (50 MHz) |
| rst_n | 1 | Input | Active-low asynchronous reset |

##### I2C Interface
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| sda | 1 | Inout | I2C Serial Data (open-drain, pulled up externally) |
| scl | 1 | Inout | I2C Serial Clock (open-drain, pulled up externally) |

##### Configuration
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| cfg_slave_addr | 10 | Input | Runtime slave address configuration |
| cfg_num_bytes | 8 | Input | Number of bytes to read (1-255) |

##### Control
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| start_transaction | 1 | Input | Pulse to initiate I2C read transaction |

##### Status
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| busy | 1 | Output | Transaction in progress |
| done | 1 | Output | Transaction completed successfully |
| error | 1 | Output | Error occurred (NACK, timeout, etc.) |

##### Data Output
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| read_data | 8 | Output | Read data byte from slave |
| data_valid | 1 | Output | Read data is valid (pulses for each byte) |

##### Debug
| Port | Width | Direction | Description |
|------|-------|-----------|-------------|
| state | 4 | Output | Current FSM state |

---

## 4. Finite State Machine (FSM)

### 4.1 State Definitions

| State | Value | Description |
|-------|-------|-------------|
| STATE_IDLE | 0x0 | Waiting for start_transaction |
| STATE_START | 0x1 | Generate START condition |
| STATE_ADDR_HI | 0x2 | Transmit address high byte (10-bit mode) |
| STATE_ADDR_LO | 0x3 | Transmit address low byte + R/W bit |
| STATE_RW_BIT | 0x4 | Transmit R/W bit (not used in current implementation) |
| STATE_ACK_ADDR | 0x5 | Wait for ACK from slave |
| STATE_READ_BYTE | 0x6 | Read data byte from slave |
| STATE_ACK_DATA | 0x7 | Send ACK/NACK for data byte |
| STATE_STOP | 0x8 | Generate STOP condition |
| STATE_ERROR | 0x9 | Error state |

### 4.2 State Transition Diagram

```
    ┌─────────────────────────────────────────────────────────┐
    │                                                           │
    ▼                                                           │
[IDLE] ─start_transaction─► [START] ─────────► [ADDR_HI]      │
    ▲                                              │            │
    │                                              ▼            │
    │                                          [ADDR_LO]        │
    │                                              │            │
    │                                              ▼            │
    │   [ERROR] ◄─── NACK ─── [ACK_ADDR]        │            │
    │      │                       ▲              ▼            │
    │      └──────────────────────┘           [READ_BYTE]      │
    │                                              │            │
    │   More bytes? ─────► [ACK_DATA] ────────┘   │            │
    │                          │                  │            │
    │                          └─────► [READ_BYTE]            │
    │                                              │            │
    └──────────────── [STOP] ◄──────────────────┘             │
         done=1
```

---

## 5. I2C Protocol Implementation

### 5.1 10-bit Addressing Format

The I2C 10-bit addressing mode uses a special address format:

#### First Byte (Address High)
```
Bit 7-5: 110 (fixed pattern indicating 10-bit mode)
Bit 4-0: Address[9:5] (upper 5 bits of slave address)
```

#### Second Byte (Address Low + R/W)
```
Bit 7-1: Address[4:0] + padding (lower 5 bits of slave address)
Bit 0:   R/W bit (0=write, 1=read)
```

### 5.2 START Condition
- SCL is released (HIGH)
- SDA goes LOW while SCL is HIGH
- Marks the beginning of I2C transmission

### 5.3 STOP Condition
- SCL is released (HIGH)
- SDA goes HIGH while SCL is HIGH
- Marks the end of I2C transmission

### 5.4 ACK/NACK
- **ACK:** Slave pulls SDA LOW during the 9th clock pulse
- **NACK:** Slave releases SDA (stays HIGH) during the 9th clock pulse

### 5.5 Clock Stretching
- Slave can hold SCL LOW to pause transmission
- Master waits for SCL to be released
- Implementation synchronizes SCL with metastability protection

---

## 6. Timing Specifications

### 6.1 Clock Frequencies

| Parameter | Value | Notes |
|-----------|-------|-------|
| System Clock | 50 MHz | Input clock frequency |
| I2C Clock | 3.4 MHz | High-Speed I2C mode |
| Clock Divider | 4 | 50MHz / (4 * 3.4MHz) ≈ 3.7 |

### 6.2 I2C Timing

| Parameter | Value | Unit |
|-----------|-------|------|
| Quarter Period | ~73.5 | ns |
| Half Period | ~147 | ns |
| Full Period | ~294 | ns |
| Bit Time | ~1.18 | µs |
| Byte Time | ~9.4 | µs |

### 6.3 Transaction Timing

For a single byte read:
- START condition: ~1 µs
- Address transmission (10-bit): ~18.8 µs
- ACK: ~1.18 µs
- Data byte reception: ~9.4 µs
- ACK/NACK: ~1.18 µs
- STOP condition: ~1 µs
- **Total:** ~32 µs (approximately)

---

## 7. Open-Drain I2C Line Control

### 7.1 I2C Pull-ups

The I2C lines (SDA and SCL) require external pull-up resistors:
- **Recommended Pull-up Value:** 1.5 kΩ to 4.7 kΩ (depending on bus capacitance)
- **Pull-up Voltage:** 3.3V (or 5V for 5V I2C systems)

### 7.2 Open-Drain Behavior

```verilog
// In Verilog:
assign scl = scl_en ? 1'bz : 1'b0;  // 1=release (pulled high), 0=pull low
assign sda = sda_en ? 1'bz : 1'b0;
```

- **scl_en = 1:** SCL released (tri-state, pulled high by external resistor)
- **scl_en = 0:** SCL actively pulled LOW by FPGA output
- Same logic applies to SDA

---

## 8. Synchronization and Metastability

### 8.1 CDC (Clock Domain Crossing)

The design uses proper synchronization for the I2C lines:

```verilog
// 2-stage synchronization register
always @(posedge clk) begin
    scl_sync1 <= scl;
    scl_sync2 <= scl_sync1;
    sda_sync1 <= sda;
    sda_sync2 <= sda_sync1;
end

wire scl_line = scl_sync2;  // Synchronized SCL
```

This protects against metastability issues when the asynchronous I2C lines transition during clock domain crossing.

---

## 9. Error Handling

### 9.1 Error Conditions

1. **Address NACK:** Slave does not respond to address (SDA not pulled LOW)
2. **Data Corruption:** Bit errors (detected through protocol violations)
3. **Bus Timeout:** Clock stretching timeout (not implemented in current version)

### 9.2 Error Response

When an error is detected:
- `error` signal is asserted
- `busy` signal is cleared
- STOP condition is generated
- Controller returns to IDLE state

---

## 10. Configuration

### 10.1 Parameterization

All key parameters can be configured at module instantiation:

```verilog
i2c_master #(
    .CLK_FREQ_MHZ(50),           // Adjust to your system clock
    .I2C_FREQ_KHZ(3400),         // Change I2C speed
    .SLAVE_ADDR(10'h24A),        // Default address
    .NUM_BYTES(8'h01)            // Default read length
) i2c_inst (...)
```

### 10.2 Runtime Configuration

Slave address and read length can be changed before each transaction:

```verilog
// Change configuration
slave_addr_cfg <= 10'h100;  // New address
num_bytes_cfg <= 8'h04;     // Read 4 bytes

// Start transaction
start_transaction <= 1'b1;
```

---

## 11. Design Quality Metrics

### 11.1 Synthesis Considerations

- **Clock Domains:** Single clock domain (50 MHz)
- **Asynchronous Reset:** Uses rst_n for clean reset
- **Open-Drain Logic:** Proper tri-state handling for I2C bus
- **Timing Closure:** Quarter-period clocking avoids critical paths

### 11.2 Recommended Synthesis Constraints

```tcl
# TimeQuest/Vivado constraints
create_clock -period 20 -name clk [get_ports clk]
set_input_delay -clock clk -add_delay 2 [get_ports start_transaction]
set_output_delay -clock clk -add_delay 2 [get_ports busy]
```

---

## 12. Simulation and Testbench

### 12.1 Testbench Structure

The testbench includes:
- **I2C Master DUT** (Device Under Test)
- **I2C Slave Model** (Behavioral slave simulator)
- **Test Scenarios:** Single byte, multiple bytes, configuration changes

### 12.2 Test Cases

1. **Test 1:** Single byte read from default address (0x24A)
2. **Test 2:** Multiple byte read (4 bytes)
3. **Test 3:** Configuration verification

### 12.3 Running Simulation

```bash
# Using ModelSim
make sim

# Or manually:
vlib work
vlog -work work rtl/*.v tb/*.v
vsim -work work morphic_top_tb -do "run -all; quit"
```

---

## 13. Known Limitations

1. **Single Master Only:** No support for multi-master arbitration
2. **No Timeout Detection:** Clock stretching timeout not implemented
3. **Write Not Supported:** Current version supports read-only operations
4. **No Burst Transfers:** Each transaction resets the state machine

These limitations can be addressed in future versions if needed.

---

## 14. References

- I2C Specification: https://www.nxp.com/docs/en/user-manual/UM10204.pdf
- FTDI MorphIC II Documentation: See vendor documentation
- Verilog Language Reference: IEEE 1364-2005

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025 | HDL Team | Initial specification |

---

## Appendix A: Parameter Calculation

### I2C Clock Divider Calculation

Given:
- System clock: 50 MHz (CLK_FREQ_MHZ = 50)
- I2C frequency: 3.4 MHz (I2C_FREQ_KHZ = 3400)

Clock divider formula:
```
CLK_DIV = (CLK_FREQ_MHZ * 1000) / (I2C_FREQ_KHZ * 4)
        = (50 * 1000) / (3400 * 4)
        = 50000 / 13600
        ≈ 3.68 (rounds to 4)
```

This generates a quarter-period clock that is used to sequence the I2C state machine.

---

**End of Document**
